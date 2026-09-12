#include <Arduino.h>
#include <WiFi.h>
#include <esp_partition.h>
#include <esp_heap_caps.h>
#include <mbedtls/sha256.h>
#include <time.h>
#include <atomic>
#include "player.h"
#include "secure_http.h"
#include "ota.h"
#include "word_storage.h"

namespace player {
namespace {
constexpr size_t kRows = 15, kBlock = 320 * kRows * 2, kBlocks = 240 / kRows;
constexpr size_t kBytes = kBlock * kBlocks, kSlot = 0x27000;
constexpr uint32_t kMagic = 0x4D545631;  // "MTV1"
uint32_t* blocks[kBlocks] = {};
// Only the display task uses this ordinary byte-accessible scanline.
alignas(4) uint16_t displayRow[320];
QueueHandle_t readyQueue = nullptr, freeQueue = nullptr;
bool displayed = false;
std::atomic<bool> serverVerified{false};
uint32_t lastDisplay = 0, sequence = 0, lastCache = 0;
int cacheSlot = -1;
String currentId, cachedId;
const esp_partition_t* cache = nullptr;
struct Record { uint32_t magic; uint32_t sequence; uint8_t digest[32]; char id[33]; };

void hashFrame(uint8_t* digest) {
  uint8_t scratch[1024];
  mbedtls_sha256_context hash;
  mbedtls_sha256_init(&hash);
  mbedtls_sha256_starts_ret(&hash, 0);
  for (auto block : blocks) {
    for (size_t offset = 0; offset < kBlock; offset += sizeof(scratch)) {
      const size_t amount = min(sizeof(scratch), kBlock - offset);
      loadWordBytes(block, offset, scratch, amount);
      mbedtls_sha256_update_ret(&hash, scratch, amount);
    }
  }
  mbedtls_sha256_finish_ret(&hash, digest);
  mbedtls_sha256_free(&hash);
}

bool loadSlot(int slot, Record& record) {
  uint8_t scratch[1024];
  if (esp_partition_read(cache, slot * kSlot, &record, sizeof(record)) != ESP_OK ||
      record.magic != kMagic || record.id[32] != '\0') return false;
  uint8_t id[16];
  if (!hexBytes(String(record.id), id, sizeof(id))) return false;
  for (size_t i = 0; i < kBlocks; ++i) {
    for (size_t offset = 0; offset < kBlock; offset += sizeof(scratch)) {
      const size_t amount = min(sizeof(scratch), kBlock - offset);
      if (esp_partition_read(cache, slot * kSlot + 4096 + i * kBlock + offset, scratch, amount) != ESP_OK)
        return false;
      storeWordBytes(blocks[i], offset, scratch, amount);
    }
  }
  uint8_t digest[32];
  hashFrame(digest);
  return memcmp(digest, record.digest, 32) == 0;
}

bool loadCache() {
  cache = esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_ANY, "tvcache");
  if (!cache || cache->size < kSlot * 2) return false;
  Record a{}, b{};
  bool validA = loadSlot(0, a), validB = loadSlot(1, b);
  if (!validA && !validB) return false;
  cacheSlot = validB && (!validA || b.sequence > a.sequence) ? 1 : 0;
  Record chosen{};
  if (!loadSlot(cacheSlot, chosen)) return false;
  sequence = chosen.sequence;
  cachedId = chosen.id;
  // Ask for the first picture on startup; the cached snapshot may be anywhere in the order.
  Serial.println("[Cache] Verified offline snapshot loaded.");
  return true;
}

void saveCache() {
  if (!cache || cachedId == currentId ||
      (cacheSlot >= 0 && millis() - lastCache < 6UL * 60 * 60 * 1000)) return;
  const int target = cacheSlot == 0 ? 1 : 0;
  uint8_t scratch[1024];
  Record record{};
  record.magic = kMagic;
  record.sequence = sequence + 1;
  hashFrame(record.digest);
  currentId.toCharArray(record.id, sizeof(record.id));
  if (esp_partition_erase_range(cache, target * kSlot, kSlot) != ESP_OK) return;
  for (size_t i = 0; i < kBlocks; ++i) {
    for (size_t offset = 0; offset < kBlock; offset += sizeof(scratch)) {
      const size_t amount = min(sizeof(scratch), kBlock - offset);
      loadWordBytes(blocks[i], offset, scratch, amount);
      if (esp_partition_write(cache, target * kSlot + 4096 + i * kBlock + offset, scratch, amount) != ESP_OK)
        return;
    }
  }
  // Commit metadata last. An interrupted write leaves the other slot intact.
  if (esp_partition_write(cache, target * kSlot, &record, sizeof(record)) != ESP_OK) return;
  cacheSlot = target;
  sequence = record.sequence;
  cachedId = currentId;
  lastCache = millis();
  Serial.println("[Cache] Offline snapshot saved.");
}

bool fetchFrame() {
  uint8_t scratch[1024];
  WiFiClientSecure tls;
  HTTPClient http;
  if (!prepareHttp(http, tls, "/device/next?after=" + currentId)) return false;
  const char* headers[] = {"X-Photo-ID", "X-Frame-SHA256"};
  http.collectHeaders(headers, 2);
  const uint32_t requestStarted = millis();
  int code = http.GET();
  reportHttpAttempt("frame", code, requestStarted, tls);
  if (code == 204) { serverVerified = true; http.end(); return false; }
  uint8_t id[16], expected[32];
  String nextId = http.header("X-Photo-ID");
  bool good = code == 200 && http.getSize() == static_cast<int>(kBytes) &&
      hexBytes(nextId, id, sizeof(id)) && hexBytes(http.header("X-Frame-SHA256"), expected, 32);
  size_t received = 0;
  uint32_t started = millis(), active = started;
  auto* stream = http.getStreamPtr();
  while (good && received < kBytes) {
    int available = stream->available();
    if (available > 0) {
      size_t amount = min(sizeof(scratch), min(static_cast<size_t>(available), kBlock - received % kBlock));
      int count = stream->read(scratch, amount);
      if (count <= 0) { good = false; break; }
      storeWordBytes(blocks[received / kBlock], received % kBlock, scratch, count);
      received += count;
      active = millis();
    } else {
      if (!stream->connected() || millis() - active > 5000) good = false;
      vTaskDelay(pdMS_TO_TICKS(10));
    }
    if (millis() - started > 60000) good = false;
  }
  http.end();
  if (good) {
    uint8_t actual[32];
    hashFrame(actual);
    good = memcmp(actual, expected, 32) == 0;
  }
  if (good) { currentId = nextId; serverVerified = true; }
  else Serial.printf("[Player] Frame unavailable or incomplete (HTTP %d); keeping current picture.\n", code);
  return good;
}

void heartbeat() {
  WiFiClientSecure tls;
  HTTPClient http;
  if (!prepareHttp(http, tls, "/device/heartbeat")) return;
  const uint32_t requestStarted = millis();
  int code = http.POST(String(""));
  reportHttpAttempt("heartbeat", code, requestStarted, tls);
  http.end();
  Serial.printf("[Server] Check-in HTTP %d.\n", code);
}

void worker(void*) {
  uint8_t token = 1;
  bool ownsBuffer = true;
  bool networkReported = false;
  if (loadCache()) {
    xQueueSend(readyQueue, &token, portMAX_DELAY);
    ownsBuffer = false;
  }
  uint32_t lastBeat = millis() - 30000, lastOta = millis() - 600000, lastFetch = millis() - 5000;
  for (;;) {
    if (!ownsBuffer) ownsBuffer = xQueueReceive(freeQueue, &token, 0) == pdTRUE;
    if (WiFi.status() == WL_CONNECTED && time(nullptr) >= 1735689600) {
      if (!networkReported) {
        IPAddress resolved;
        if (WiFi.hostByName(TV_SERVER_HOST, resolved)) {
          Serial.print("[HTTPS] Server resolves to ");
          Serial.println(resolved);
        } else Serial.println("[HTTPS] Server DNS lookup failed.");
        Serial.printf("[HTTPS] Clock epoch=%lld; free byte RAM=%u; largest=%u.\n",
                      static_cast<long long>(time(nullptr)), heap_caps_get_free_size(MALLOC_CAP_8BIT),
                      heap_caps_get_largest_free_block(MALLOC_CAP_8BIT));
        networkReported = true;
      }
      if (millis() - lastBeat >= 30000) { lastBeat = millis(); heartbeat(); }
      if (ownsBuffer && millis() - lastFetch >= 5000) {
        lastFetch = millis();
        if (fetchFrame()) {
          saveCache();
          xQueueSend(readyQueue, &token, portMAX_DELAY);
          ownsBuffer = false;
        } else {
          // Includes empty/single-picture catalogues; avoid continuous polling.
          vTaskDelay(pdMS_TO_TICKS(1000));
        }
      }
      if (millis() - lastOta >= 600000) { lastOta = millis(); ota::check(); }
    }
    vTaskDelay(pdMS_TO_TICKS(100));
  }
}
}

void begin() {
  // Dedicated IRAM is preferred before DRAM; preserve byte-accessible RAM for TLS.
  size_t iramBytes = 0;
  for (auto& block : blocks) {
    block = static_cast<uint32_t*>(heap_caps_malloc(kBlock, MALLOC_CAP_EXEC | MALLOC_CAP_32BIT));
    if (block) iramBytes += kBlock;
    else block = static_cast<uint32_t*>(malloc(kBlock));
    if (!block) {
      for (auto& allocation : blocks) { free(allocation); allocation = nullptr; }
      Serial.println("[Player] Insufficient RAM; startup screen remains visible.");
      return;
    }
    // Partial network words use read/modify/write, so initialize with word stores.
    volatile uint32_t* words = block;
    for (size_t i = 0; i < kBlock / sizeof(uint32_t); ++i) words[i] = 0;
    if (!checkWordStorage(words, kBlock)) {
      for (auto& allocation : blocks) { free(allocation); allocation = nullptr; }
      Serial.println("[Player] Frame memory self-test failed; startup screen retained.");
      return;
    }
  }
  Serial.printf("[Player] Frame storage: %u bytes IRAM, %u bytes DRAM.\n",
                static_cast<unsigned>(iramBytes), static_cast<unsigned>(kBytes - iramBytes));
  Serial.println("[Player] Frame memory self-test passed.");
  Serial.printf("[Player] Free byte RAM=%u; largest block=%u (before Wi-Fi).\n",
                heap_caps_get_free_size(MALLOC_CAP_8BIT), heap_caps_get_largest_free_block(MALLOC_CAP_8BIT));
  readyQueue = xQueueCreate(1, sizeof(uint8_t));
  freeQueue = xQueueCreate(1, sizeof(uint8_t));
  if (!readyQueue || !freeQueue ||
      xTaskCreatePinnedToCore(worker, "tv-network", 12288, nullptr, 1, nullptr, 0) != pdPASS)
    Serial.println("[Player] Could not start network worker.");
}

void drawReady(TFT_eSPI& display) {
  if (!readyQueue || (displayed && millis() - lastDisplay < 5000)) return;
  uint8_t token;
  if (xQueueReceive(readyQueue, &token, 0) != pdTRUE) return;
  // Wire-format RGB565 is already big-endian; do not swap again.
  display.setSwapBytes(false);
  for (size_t i = 0; i < kBlocks; ++i) {
    for (size_t row = 0; row < kRows; ++row) {
      loadWordBytes(blocks[i], row * sizeof(displayRow), reinterpret_cast<uint8_t*>(displayRow), sizeof(displayRow));
      display.pushImage(0, i * kRows + row, 320, 1, displayRow);
    }
  }
  lastDisplay = millis();
  displayed = true;
  xQueueSend(freeQueue, &token, 0);
}

bool healthy() { return displayed && serverVerified; }
}
