#pragma once

// Safe compile-only placeholder. Run `python tools/release.py init` to create a
// private signing key and the ignored ota_public_key.h used by real builds.
// OTA signature verification deliberately fails while this placeholder is used.
constexpr char kOtaPublicKey[] = "OTA signing is not configured";
