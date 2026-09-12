#pragma once

#if defined(MINI_TV_USE_EXAMPLE_SETTINGS)
#include "secrets.example.h"
#elif __has_include("secrets.h")
#include "secrets.h"
#else
#include "secrets.example.h"
#endif
