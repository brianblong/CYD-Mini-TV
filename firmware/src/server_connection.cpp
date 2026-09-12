#include <Arduino.h>
#include <time.h>
#include "server_connection.h"
#include "player.h"
#include "ota.h"
namespace server_connection {
void begin() { ota::begin(); player::begin(); }
void onWifiConnected() {
  configTime(0, 0, "time.cloudflare.com", "pool.ntp.org", "time.google.com");
  Serial.println("[Clock] Synchronizing time for verified HTTPS.");
}
void update() { ota::tick(player::healthy()); }
}
