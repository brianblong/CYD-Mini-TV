# Mini TV firmware

This PlatformIO project targets ESP32-2432S028 displays. It connects to a private
photo portal, downloads display-ready frames, keeps an offline snapshot, reports
device status, and supports application-level signed OTA updates.

The repository contains blank example settings only. A fresh build starts with a
neutral color test until a server frame is available.

## Requirements

- VS Code with the PlatformIO IDE extension
- an ESP32-2432S028-compatible display
- a data-capable USB cable
- access to a configured Mini TV photo portal

## Private configuration

Copy `include/secrets.example.h` to `include/secrets.h` and enter your own values.
The completed file is ignored by Git.

```cpp
constexpr char WIFI_SSID[] = "";
constexpr char WIFI_PASSWORD[] = "";
constexpr char REMOTE_WIFI_SSID[] = "";
constexpr char REMOTE_WIFI_PASSWORD[] = "";
constexpr char TV_SERVER_HOST[] = "photos.example.com";
constexpr char TV_SERVER_USER[] = "tv-remote";
constexpr char TV_SERVER_PASSWORD[] = "";
```

The optional second Wi-Fi network is tried first and the primary network is used
as a fallback. Leave the second network blank if it is unnecessary.

Never commit `secrets.h`. Credentials are compiled into normal firmware binaries,
so do not publish or share release binaries built with real settings.

## Build and upload

Open the `firmware` directory as the VS Code folder. In PlatformIO, use:

1. **Project Tasks → cyd_st7789 → General → Build**
2. **Project Tasks → cyd_st7789 → General → Upload**
3. **Project Tasks → cyd_st7789 → General → Monitor**

The default monitor speed is 115200 baud. If automatic serial-port detection is
ambiguous, set `upload_port` and `monitor_port` in `platformio.ini` to the port
shown by your operating system.

The `cyd_st7789_check` environment compiles with blank example settings for safe
validation. Do not flash that environment to a device you expect to connect.

## Display profiles

The default profile is the ST7789 revision. An alternate `cyd_ili9341` environment
is included because ESP32-2432S028 boards exist with different display controllers.
Board labels alone may not identify the panel revision; validate colors, rotation,
and pin behavior on your hardware.

## OTA signing

Run `python tools/release.py init` once to create `keys/ota-private.pem` and
`include/ota_public_key.h`. Both installation-specific files are ignored by Git;
the repository ships a compile-only placeholder instead. Keep the private key out
of Git and back it up in encrypted storage. Losing it requires a USB installation
of firmware containing a new signing identity.

See [DEPLOYMENT.md](DEPLOYMENT.md) for the generic server and device workflow.
