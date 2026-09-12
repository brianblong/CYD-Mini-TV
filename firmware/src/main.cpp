#include <Arduino.h>
#include <TFT_eSPI.h>
#include <WiFi.h>
#include <esp_system.h>
#include <esp_task_wdt.h>
#include "tv_settings.h"
#include "server_connection.h"
#include "player.h"
#include "firmware_version.h"
#define MINI_TV_STRINGIFY_INNER(x) #x
#define MINI_TV_STRINGIFY(x) MINI_TV_STRINGIFY_INNER(x)
const char kReleaseMarker[] = "MINITV:" MINI_TV_HARDWARE ":" MINI_TV_STRINGIFY(MINI_TV_VERSION);
constexpr char userCharacter(size_t i) { return i < sizeof(TV_SERVER_USER) ? TV_SERVER_USER[i] : '\0'; }
const char kDeviceMarker[] = {'M','I','N','I','T','V','D','E','V','I','C','E',':',
  userCharacter(0), userCharacter(1), userCharacter(2), userCharacter(3), userCharacter(4),
  userCharacter(5), userCharacter(6), userCharacter(7), userCharacter(8), '\0'};

#ifndef MINI_TV_TFT_SETUP
#error "Project TFT setup was not injected by PlatformIO"
#endif

namespace {
TFT_eSPI tft;
constexpr uint8_t kRotation = 1;
constexpr uint32_t kHeartbeatMs = 5000;
uint32_t lastHeartbeat = 0;

// Each connection attempt gets 20 seconds, followed by 10 seconds before retrying.
constexpr uint32_t kWifiTimeoutMs = 20000;
constexpr uint32_t kWifiRetryMs = 10000;
enum class WifiState { Disabled, Connecting, Connected, Waiting };
WifiState wifiState = WifiState::Disabled;
uint32_t wifiStateStarted = 0;
struct WifiNetwork { const char* name; const char* password; const char* label; };
const WifiNetwork networks[] = {
    {REMOTE_WIFI_SSID, REMOTE_WIFI_PASSWORD, "secondary"},
    {WIFI_SSID, WIFI_PASSWORD, "primary"},
};
size_t networkIndex = 0;

const char* wifiStateName() {
  switch (wifiState) {
    case WifiState::Connecting: return "connecting";
    case WifiState::Connected: return "connected";
    case WifiState::Waiting: return "waiting to retry";
    default: return "disabled";
  }
}

void scheduleWifiRetry() {
  // Cancel the current attempt, but leave the station interface enabled.
  WiFi.disconnect();
  const size_t other = 1 - networkIndex;
  if (networks[other].name[0] != '\0') networkIndex = other;
  wifiState = WifiState::Waiting;
  wifiStateStarted = millis();
  Serial.println("[WiFi] Retrying in 10 seconds; the photo stays on screen.");
}

void connectWifi() {
  Serial.printf("[WiFi] Connecting to %s network... (20-second timeout)\n", networks[networkIndex].label);
  if (!WiFi.mode(WIFI_STA)) {
    Serial.println("[WiFi] Could not start station mode.");
    scheduleWifiRetry();
    return;
  }
  wifiState = WifiState::Connecting;
  wifiStateStarted = millis();
  // begin() starts the attempt. We check its progress in loop(), not a while loop.
  // Its return value can still reflect the previous attempt's asynchronous status.
  // Let updateWifi() observe success or the deadline instead of cancelling early.
  WiFi.begin(networks[networkIndex].name, networks[networkIndex].password);
}

void startWifi() {
  if (WIFI_SSID[0] == '\0' && REMOTE_WIFI_SSID[0] == '\0') {
    Serial.println("[WiFi] Disabled: enter your network details in include/secrets.h, then upload.");
    return;
  }
  WiFi.persistent(false);  // Keep connection settings in RAM instead of saving to NVS.
  WiFi.setAutoReconnect(false);  // This program owns the retry timing.
  WiFi.setHostname("mini-tv");
  networkIndex = REMOTE_WIFI_SSID[0] != '\0' ? 0 : 1;
  connectWifi();
}

void updateWifi() {
  if (wifiState == WifiState::Disabled) return;

  const uint32_t now = millis();
  if (wifiState == WifiState::Waiting) {
    // Unsigned subtraction also works when millis() wraps around.
    if (now - wifiStateStarted >= kWifiRetryMs) connectWifi();
    return;
  }

  const wl_status_t status = WiFi.status();
  if (status == WL_CONNECTED) {
    if (wifiState != WifiState::Connected) {
      wifiState = WifiState::Connected;
      Serial.println("[WiFi] Connected");
      Serial.print("[WiFi] IP address: ");
      Serial.println(WiFi.localIP());
      Serial.printf("[WiFi] Signal: %ld dBm\n", static_cast<long>(WiFi.RSSI()));
      server_connection::onWifiConnected();
    }
    return;
  }

  if (wifiState == WifiState::Connected) {
    Serial.printf("[WiFi] Connection lost (status=%d).\n", static_cast<int>(status));
    scheduleWifiRetry();
  } else if (now - wifiStateStarted >= kWifiTimeoutMs) {
    // Status alone cannot reliably distinguish every password/router/DHCP problem.
    Serial.printf("[WiFi] Timed out (status=%d). Check SSID, password, 2.4 GHz and signal.\n",
                  static_cast<int>(status));
    scheduleWifiRetry();
  }
}

struct ColorBlock {
  uint16_t color;
  uint16_t text;
  const char* label;
};

void printDiagnostics() {
  setup_t actual;
  tft.getSetup(actual);  // Compiled library settings, not hardware detection.
  Serial.println("\n=== Mini TV " MINI_TV_VERSION_NAME " ===");
  Serial.println(kReleaseMarker);
  Serial.println(kDeviceMarker);
#ifdef MINI_TV_USE_EXAMPLE_SETTINGS
  Serial.println("MINITV_CHECK_BUILD_DO_NOT_RELEASE");
#endif
  Serial.println("Startup screen: color test");
  Serial.printf("Build: %s %s\n", __DATE__, __TIME__);
  Serial.printf("Chip: %s rev %u, CPU: %u MHz\n", ESP.getChipModel(),
                ESP.getChipRevision(), ESP.getCpuFreqMHz());
  Serial.printf("Flash: %u bytes, free heap: %u bytes, reset reason: %d\n",
                ESP.getFlashChipSize(), ESP.getFreeHeap(),
                static_cast<int>(esp_reset_reason()));
  Serial.printf("TFT_eSPI: %s; setup: %s\n", TFT_ESPI_VERSION, USER_SETUP_INFO);
  Serial.printf("Selected panel: %s; library driver: 0x%04X\n",
                MINI_TV_PANEL_NAME, actual.tft_driver);
  Serial.printf("Library pins: MOSI=%d MISO=%d SCLK=%d CS=%d DC=%d RST=%d\n",
                actual.pin_tft_mosi, actual.pin_tft_miso, actual.pin_tft_clk,
                actual.pin_tft_cs, actual.pin_tft_dc, actual.pin_tft_rst);
  Serial.printf("Backlight: GPIO %d active HIGH; HSPI: %u Hz; SPI mode: %u\n",
                TFT_BL, SPI_FREQUENCY, TFT_SPI_MODE);
  Serial.println("Panel selection is configuration, NOT detected hardware identity.");
  Serial.println("Secure slideshow, offline snapshot and signed OTA updates.");
}

void drawColorTest() {
  const int16_t width = tft.width();
  const int16_t height = tft.height();
  const ColorBlock blocks[] = {
      {TFT_RED, TFT_WHITE, "RED"},
      {TFT_GREEN, TFT_BLACK, "GREEN"},
      {TFT_BLUE, TFT_WHITE, "BLUE"},
      {TFT_CYAN, TFT_BLACK, "CYAN"},
      {TFT_MAGENTA, TFT_BLACK, "MAGENTA"},
      {TFT_YELLOW, TFT_BLACK, "YELLOW"},
  };
  tft.fillScreen(TFT_BLACK);
  tft.setTextDatum(MC_DATUM);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.drawString("MINI TV", width / 2, 23, 4);

  constexpr int16_t top = 48;
  const int16_t bottom = height - 30;
  for (int i = 0; i < 6; ++i) {
    const int col = i % 3;
    const int row = i / 3;
    const int16_t x0 = col * width / 3;
    const int16_t x1 = (col + 1) * width / 3;
    const int16_t y0 = top + row * (bottom - top) / 2;
    const int16_t y1 = top + (row + 1) * (bottom - top) / 2;
    tft.fillRect(x0, y0, x1 - x0, y1 - y0, blocks[i].color);
    tft.setTextColor(blocks[i].text, blocks[i].color);
    tft.drawString(blocks[i].label, (x0 + x1) / 2, (y0 + y1) / 2, 2);
  }
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.drawString("READY FOR SETUP", width / 2, height - 15, 2);
  tft.drawRect(0, 0, width, height, TFT_WHITE);
}
}  // namespace

void setup() {
  Serial.begin(115200);
  delay(600);  // Bounded startup delay; no dependency on an open monitor.
  printDiagnostics();
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, LOW);
  Serial.println("Initializing TFT...");
  tft.init();
  digitalWrite(TFT_BL, LOW);  // init() may enable the backlight.
  tft.setRotation(kRotation);
  Serial.printf("Logical display: %d x %d, rotation: %u\n",
                tft.width(), tft.height(), kRotation);
  const uint32_t started = micros();
  drawColorTest();
  digitalWrite(TFT_BL, TFT_BACKLIGHT_ON);
  Serial.printf("Display draw calls completed in %lu us. Visually verify the panel.\n",
                static_cast<unsigned long>(micros() - started));
  lastHeartbeat = millis();
  server_connection::begin();
  startWifi();
  esp_task_wdt_init(30, true);
  esp_task_wdt_add(nullptr);
}

void loop() {
  esp_task_wdt_reset();
  updateWifi();
  server_connection::update();
  player::drawReady(tft);
  const uint32_t now = millis();
  if (now - lastHeartbeat >= kHeartbeatMs) {
    lastHeartbeat = now;
    Serial.printf("[alive] uptime=%lu ms, free heap=%u bytes, frame=1, WiFi=%s\n",
                  static_cast<unsigned long>(now), ESP.getFreeHeap(), wifiStateName());
  }
  delay(10);
}
