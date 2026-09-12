#include <Arduino.h>
#include <Preferences.h>
#include <atomic>
#include <esp_ota_ops.h>
#include <mbedtls/pk.h>
#include <mbedtls/sha256.h>
#include "ota.h"
#if defined(MINI_TV_USE_EXAMPLE_SETTINGS)
#include "ota_public_key.example.h"
#elif __has_include("ota_public_key.h")
#include "ota_public_key.h"
#else
#include "ota_public_key.example.h"
#endif
#include "secure_http.h"

// Delay Arduino's automatic OTA confirmation until the main loop tests the player.
extern "C" bool verifyRollbackLater() { return true; }
namespace ota {
namespace {
std::atomic<bool> pending{false};
uint32_t bootTime = 0;
Preferences state;
bool storageReady = false;
bool decimal(const String& text, uint32_t& value) {
  if (text.length() == 0 || text.length() > 10) return false;
  uint64_t parsed = 0;
  for (size_t i = 0; i < text.length(); ++i) {
    if (text[i] < '0' || text[i] > '9') return false;
    parsed = parsed * 10 + text[i] - '0';
  }
  if (parsed == 0 || parsed > 2147483647) return false;
  value = parsed;
  return true;
}
bool getManifest(String& result) {
  WiFiClientSecure tls;
  HTTPClient http;
  if (!prepareHttp(http, tls, "/device/firmware/manifest.txt")) return false;
  int code = http.GET(), size = http.getSize();
  if (code != 200 || size < 100 || size > 700) { http.end(); return false; }
  auto* stream = http.getStreamPtr();
  result.reserve(size);
  uint32_t started = millis();
  while (result.length() < static_cast<size_t>(size) && millis() - started < 10000) {
    if (stream->available()) result += static_cast<char>(stream->read());
    else if (!stream->connected()) break;
    else vTaskDelay(pdMS_TO_TICKS(10));
  }
  http.end();
  return result.length() == static_cast<size_t>(size);
}
bool verify(const String& message, const String& signature) {
  if (signature.length() < 16 || signature.length() > 144 || signature.length() % 2) return false;
  uint8_t sig[72], digest[32];
  if (!hexBytes(signature, sig, signature.length() / 2)) return false;
  mbedtls_sha256_ret(reinterpret_cast<const uint8_t*>(message.c_str()), message.length(), digest, 0);
  mbedtls_pk_context key;
  mbedtls_pk_init(&key);
  bool ok = mbedtls_pk_parse_public_key(&key, reinterpret_cast<const uint8_t*>(kOtaPublicKey), sizeof(kOtaPublicKey)) == 0 &&
    mbedtls_pk_verify(&key, MBEDTLS_MD_SHA256, digest, sizeof(digest), sig, signature.length() / 2) == 0;
  mbedtls_pk_free(&key);
  return ok;
}
void install(uint32_t version, uint32_t size, const String& hashText, const uint8_t* expected) {
  const esp_partition_t* partition = esp_ota_get_next_update_partition(nullptr);
  if (!partition || size > partition->size) return;
  WiFiClientSecure tls;
  HTTPClient http;
  if (!prepareHttp(http, tls, "/device/firmware/" + hashText + ".bin")) return;
  int code = http.GET();
  if (code != 200 || http.getSize() != static_cast<int>(size)) { http.end(); return; }
  esp_ota_handle_t handle;
  if (esp_ota_begin(partition, size, &handle) != ESP_OK) { http.end(); return; }
  mbedtls_sha256_context hash;
  mbedtls_sha256_init(&hash);
  mbedtls_sha256_starts_ret(&hash, 0);
  uint8_t buffer[1024], actual[32];
  uint32_t received = 0, started = millis(), active = started;
  bool ok = true;
  auto* stream = http.getStreamPtr();
  while (ok && received < size) {
    int available = stream->available();
    if (available > 0) {
      size_t amount = min(static_cast<size_t>(available), min(sizeof(buffer), static_cast<size_t>(size - received)));
      int count = stream->read(buffer, amount);
      if (count <= 0 || esp_ota_write(handle, buffer, count) != ESP_OK) { ok = false; break; }
      mbedtls_sha256_update_ret(&hash, buffer, count);
      received += count;
      active = millis();
    } else {
      if (!stream->connected() || millis() - active > 5000) ok = false;
      vTaskDelay(pdMS_TO_TICKS(10));
    }
    if (millis() - started > 180000) ok = false;
  }
  mbedtls_sha256_finish_ret(&hash, actual);
  mbedtls_sha256_free(&hash);
  http.end();
  if (!ok || memcmp(actual, expected, 32) != 0) {
    esp_ota_abort(handle);
    Serial.println("[OTA] Incomplete/altered download; current firmware retained.");
    return;
  }
  if (esp_ota_end(handle) != ESP_OK) return;
  // Persist before activation so rollback cannot repeatedly install a bad release.
  if (state.putUInt("attempt", version) != sizeof(uint32_t)) return;
  if (esp_ota_set_boot_partition(partition) != ESP_OK) return;
  Serial.println("[OTA] Verified update ready; restarting for self-test.");
  delay(250);
  ESP.restart();
}
}
void begin() {
  bootTime = millis();
  storageReady = state.begin("mini-tv-ota", false);
  esp_ota_img_states_t status;
  pending = esp_ota_get_state_partition(esp_ota_get_running_partition(), &status) == ESP_OK && status == ESP_OTA_IMG_PENDING_VERIFY;
  if (pending) Serial.println("[OTA] New firmware awaiting display self-test.");
}
void tick(bool frameDisplayed) {
  if (!pending) return;
  if (frameDisplayed && millis() - bootTime >= 60000) {
    if (esp_ota_mark_app_valid_cancel_rollback() == ESP_OK) {
      pending = false;
      Serial.println("[OTA] Player self-test passed; update confirmed.");
    }
  } else if (millis() - bootTime >= 180000) {
    Serial.println("[OTA] Self-test timed out; returning to previous firmware.");
    esp_ota_mark_app_invalid_rollback_and_reboot();
  }
}
void check() {
#ifndef MINI_TV_PANEL_ST7789
  return;
#endif
  if (!storageReady || pending) return;
  String manifest;
  if (!getManifest(manifest)) return;
  String fields[7];
  int start = 0, end = 0, signatureStart = 0;
  for (int i = 0; i < 7; ++i) {
    if (i == 6) signatureStart = start;
    end = manifest.indexOf('\n', start);
    if (end < 0) return;
    fields[i] = manifest.substring(start, end);
    start = end + 1;
  }
  if (start != static_cast<int>(manifest.length()) || fields[0] != "MINITV1" || fields[1] != TV_SERVER_USER || fields[2] != MINI_TV_HARDWARE) return;
  uint32_t version, size;
  uint8_t digest[32];
  if (!decimal(fields[3], version) || !decimal(fields[4], size) || size > 0x1B0000 ||
      !hexBytes(fields[5], digest, 32) || version <= MINI_TV_VERSION || version <= state.getUInt("attempt", 0)) return;
  if (!verify(manifest.substring(0, signatureStart), fields[6])) {
    Serial.println("[OTA] Rejected unsigned or altered release.");
    return;
  }
  install(version, size, fields[5], digest);
}
}
