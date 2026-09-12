#pragma once
#include <TFT_eSPI.h>
namespace player {
void begin();
void drawReady(TFT_eSPI& display);
bool healthy();
}
