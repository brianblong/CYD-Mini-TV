# Device protocol v1

HTTPS only through NGINX Basic Auth. The portal's TCP port must stay private.
NGINX replaces `X-Mini-TV-User` with the authenticated account, clears upstream
Authorization, and the app accepts only `tv-local` or `tv-remote` with
`DEVICE_HEARTBEATS_ENABLED=true`.

- `POST /device/heartbeat`: updates server-side last-seen time; intended every 30 s.
- `GET /device/next?after=<32 lowercase hex id>`: returns the next catalogue picture,
  wrapping to the first. Unknown/deleted/absent cursor starts at the first picture.
  HTTP 204 means empty catalogue or the cursor already names the sole picture.
  HTTP 200 is exactly 153600 bytes of row-major, big-endian RGB565, 320 by 240.
  `X-Photo-ID` supplies the cursor, `X-Frame-SHA256` supplies the lowercase SHA-256
  digest. Clients validate the complete buffer before displaying it. The response
  is generated from stored PNGs, so no public-storage migration is needed.
- `GET /device/firmware/manifest.txt`: reads only the authenticated device's folder
  below FIRMWARE_DIR (default `/firmware`). Missing release returns 404 normally.
- `GET /device/firmware/<64 lowercase hex SHA256>.bin`: same per-device restriction.
  This mount belongs outside the NGINX public directory; binaries contain credentials.

Signed manifest is ASCII with LF line endings, including a final LF:

```text
MINITV1
tv-remote
cyd-st7789-4m-v1
10001
<decimal image length>
<lowercase SHA256 hex>
<DER ECDSA signature as lowercase hex>
```

The signature uses P-256 / SHA-256 over the first six lines, including their LFs.
The seventh line is excluded. The authenticated device, hardware/layout identifier,
increasing release number, size and digest are therefore bound by the signature.
The image itself is verified against that digest before activating its OTA slot.
HTTP redirects are disabled. Digest-named images are immutable; publish manifest
last via atomic rename. Signing keys never belong on the server.
