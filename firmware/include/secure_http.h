#pragma once
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <esp_heap_caps.h>
#include "server_roots.h"
#include "tv_settings.h"
#include "firmware_version.h"
inline bool prepareHttp(HTTPClient& http, WiFiClientSecure& tls, const String& path) {
  tls.setCACert(kServerRootCertificates);
  // Allow for public Funnel relay/TLS latency; this runs on the network worker.
  tls.setHandshakeTimeout(30);
  http.useHTTP10(true);
  http.setConnectTimeout(5000);
  http.setTimeout(5000);
  http.setReuse(false);
  http.setFollowRedirects(HTTPC_DISABLE_FOLLOW_REDIRECTS);
  if (!http.begin(tls, TV_SERVER_HOST, 443, path, true)) return false;
  http.setAuthorization(TV_SERVER_USER, TV_SERVER_PASSWORD);
  http.setUserAgent("Mini-TV/" MINI_TV_VERSION_NAME);
  return true;
}
inline void reportHttpAttempt(const char* operation, int status, uint32_t started,
                              WiFiClientSecure& tls) {
  Serial.printf("[HTTPS] %s: HTTP %d after %lu ms; byte RAM=%u; largest=%u.\n",
                operation, status, static_cast<unsigned long>(millis() - started),
                heap_caps_get_free_size(MALLOC_CAP_8BIT),
                heap_caps_get_largest_free_block(MALLOC_CAP_8BIT));
  if (status < 0) {
    char message[128];
    const int error = tls.lastError(message, sizeof(message));
    // Numeric TLS diagnostics only: never log headers, credentials or response bodies.
    Serial.printf("[HTTPS] TLS error code=%d; handshake limit=30 seconds.\n", error);
  }
}
inline bool hexBytes(const String& value, uint8_t* out, size_t count) {
  if (value.length() != count * 2) return false;
  for (size_t i = 0; i < count; ++i) {
    int byte = 0;
    for (int j = 0; j < 2; ++j) {
      char c = value[i * 2 + j];
      if (c >= '0' && c <= '9') byte = byte * 16 + c - '0';
      else if (c >= 'a' && c <= 'f') byte = byte * 16 + c - 'a' + 10;
      else return false;
    }
    out[i] = byte;
  }
  return true;
}
