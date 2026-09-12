#pragma once

// Project-owned TFT_eSPI configuration. See ../README.md for board evidence.
#if defined(MINI_TV_PANEL_ILI9341) == defined(MINI_TV_PANEL_ST7789)
#error "Select exactly one mini-tv panel profile in platformio.ini"
#endif

#define MINI_TV_TFT_SETUP 1
#define USER_SETUP_INFO "mini-tv project-local CYD setup"

#if defined(MINI_TV_PANEL_ILI9341)
#define MINI_TV_PANEL_NAME "ILI9341 (ILI9341_2_DRIVER)"
#define ILI9341_2_DRIVER
#define TFT_MISO 12
#define TFT_RGB_ORDER TFT_BGR
#define TFT_SPI_MODE SPI_MODE0
#else
// Documented ESP32-2432S028Rv3 ST7789 profile, not every USB-C board.
#define MINI_TV_PANEL_NAME "ST7789 (ST7789_DRIVER)"
#define ST7789_DRIVER
// This panel showed a negative image with the library's default INVON.
// Override it after initialization; verify black margins after uploading.
#define TFT_INVERSION_OFF
#define TFT_MISO -1  // No display readback in the referenced v3 profile.
#define TFT_RGB_ORDER TFT_BGR
#define TFT_SPI_MODE SPI_MODE3
#endif

#define TFT_WIDTH 240
#define TFT_HEIGHT 320
#define TFT_MOSI 13
#define TFT_SCLK 14
#define TFT_CS 15
#define TFT_DC 2
#define TFT_RST -1  // No independently controlled TFT reset GPIO.
#define TFT_BL 21
#define TFT_BACKLIGHT_ON HIGH
#define USE_HSPI_PORT

// Conservative first-test speed; adjust only after the pattern is correct.
#define SPI_FREQUENCY 20000000
#define SPI_READ_FREQUENCY 10000000
#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4

// Do not define TOUCH_CS: CYD touch uses different SPI pins from the LCD.
