# Validation — 2026-09-08

## 2026-09-09: 1.0.2 TLS timeout diagnostics

Physical 1.0.1 testing confirms 4 MB flash, frame-memory self-test success and primary Wi-Fi
connection. It still fails TLS: attempts return -1 about 10 seconds after starting,
with roughly 23-26 KB heap remaining during the handshake. Unlike the earlier run,
this capture does not show an explicit allocation error. Inspected Arduino's SSL
implementation: its handshake deadline returns -1 without an mbedTLS error message.

Read-only Windows probes using TLS 1.2, without credentials or ALPN, reached both
resolved addresses (209.177.145.97 and 209.177.145.192), completed TLS in under one
second and received the expected HTTP 401 authentication challenge. This establishes
Windows reachability, not equivalence to the CYD's network or TLS implementation.
A separate DNS query to 1.1.1.1 returned NXDOMAIN; device-side DNS logging was added
to help resolve the discrepancy rather than assuming a route/certificate cause.

1.0.2 allows a 30-second TLS handshake and records safe connection diagnostics.
Certificate verification and Basic Auth remain enabled. Runtime success awaits
another physical test; do not treat this change alone as a confirmed fix.

## 2026-09-09 correction: 1.0.1

The physical 1.0.0 test failed HTTPS handshakes with SSL allocation error -32512
while approximately 78 KB of byte RAM remained. A successful compile did not
establish adequate runtime TLS memory. 1.0.1 moves frame storage into available
IRAM before falling back to DRAM. All IRAM accesses use volatile aligned 32-bit
loads/stores; small byte buffers bridge network, SHA-256, cache and display calls.
The 320x240 RGB565 format, server endpoints, certificate checks, cache records and
partition map are unchanged. Failed/empty frame polls now wait at least five seconds.

Every allocated block is checked at startup for fragmented copies, odd offsets,
surrounding-byte preservation and end-of-block handling. This self-test and actual
TLS headroom must be confirmed in the next physical run; a new upload is required.
The memory access constraints follow [Espressif's allocation documentation](https://docs.espressif.com/projects/esp-idf/en/v4.4.8/esp32/api-reference/system/mem_alloc.html).

Production `cyd_st7789` compile passed: 1,030,157 bytes program flash in the
1,769,472-byte slot and 47,972 bytes static RAM. No physical upload was performed
by the agent; successful HTTPS and slideshow playback still await the user's test.

The following results describe the original 1.0.0 build, not the correction.

Prepared firmware 1.0.0 (numeric release 10000) for the ST7789 remote TV and portal
2.2.0. These are local software results, not a claim of successful hardware deployment.

## Passed

- PlatformIO `cyd_st7789` production build using the existing local settings:
  1,028,917 bytes program flash out of a 1,769,472-byte OTA slot; 47,332 bytes static
  RAM out of 327,680. No credentials were changed.
- PlatformIO `cyd_st7789_check` example-settings build:
  1,028,845 bytes program flash; 47,332 bytes static RAM.
- 16 portal tests: the existing 12 checks plus device authentication/enablement,
  RGB565 dimensions/byte order/digest, catalogue next/wrap/reorder/deletion behavior,
  and firmware route isolation between device accounts.
- Four release-tool tests: valid signing and altered metadata rejection; rejection
  of wrong device/version/check binaries; preserving an existing signing identity;
  and non-overlapping 4 MB partitions with equal OTA slots and enough cache space.
- Inspected the linked ELF: `verifyRollbackLater` is the strong C-linkage override,
  so Arduino's early automatic confirmation is replaced by the player self-test.

The touchscreen warning is expected: this firmware does not use touch input.
Static RAM figures do not include the dynamically allocated 153600-byte image
buffer, network stack, worker stack and TLS allocations.

## Not yet tested

- Actual board flash capacity, boot with the new partition table, frame colors and
  orientation, TLS peak memory, Wi-Fi fallback/reconnection and sustained playback.
- Installing an OTA on the physical device; interrupted download/write, invalid
  new boot, watchdog reset, rollback and offline-cache power-loss behavior.
- The updated portal image under Docker/NGINX on the Ubuntu VM. Docker is not
  installed on this Windows host. Portal tests ran locally with Flask/Pillow.
- Connectivity from the secondary Wi-Fi. No server credentials or network
  settings were exercised against the live site during this build.

Follow DEPLOYMENT.md before treating the remote unit as ready for unattended use.
