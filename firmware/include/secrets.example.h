#pragma once

// Copy this file to secrets.h and enter your 2.4 GHz network details locally.
// An empty SSID leaves Wi-Fi disabled so the photo test still works.
constexpr char WIFI_SSID[] = "";
constexpr char WIFI_PASSWORD[] = "";

// Optional second network is tried first; the primary network above is the fallback.
constexpr char REMOTE_WIFI_SSID[] = "";
constexpr char REMOTE_WIFI_PASSWORD[] = "";
constexpr char TV_SERVER_HOST[] = "photos.example.com";
constexpr char TV_SERVER_USER[] = "tv-remote";
constexpr char TV_SERVER_PASSWORD[] = "";
