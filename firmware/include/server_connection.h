#pragma once

// These calls currently run in the main loop while the screen shows a static photo.
// Move HTTP work into the download worker when timed slideshow playback is added.
namespace server_connection {
void begin();
void onWifiConnected();
void update();
}
