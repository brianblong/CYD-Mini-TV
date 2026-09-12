# Mini TV deployment template

This guide deliberately uses placeholders. Replace them locally; do not commit
real hostnames, addresses, usernames, passwords, photographs, or private keys.

## 1. Prepare private server configuration

Copy `homelab/portal/portal.env.example` to a private server configuration named
`portal.env`. Generate the required secrets and choose optional display names.
Keep this file outside the application source directory when practical.

Create persistent server directories for photos and private firmware releases:

```bash
mkdir -p /opt/mini-tv/data/photos
mkdir -p /opt/mini-tv/data/private/firmware/tv-local
mkdir -p /opt/mini-tv/data/private/firmware/tv-remote
chmod 700 /opt/mini-tv/data/private
```

Configure your container deployment to:

- mount the photo directory at `/data`
- mount the firmware directory at `/firmware` as read-only
- load the private `portal.env`
- expose the portal only to the private container network
- route browser and device traffic through NGINX with HTTPS

## 2. Configure device authentication

Create separate NGINX Basic Auth users for `tv-local` and `tv-remote`, or update
the generic identifiers consistently in the firmware, portal, tests, and release
tool. Use unique generated passwords for each device.

The device endpoints must not bypass NGINX. The Flask application trusts the
identity header that the included NGINX configuration replaces after successful
authentication.

## 3. Configure firmware locally

Copy `firmware/include/secrets.example.h` to
`firmware/include/secrets.h`. Enter the Wi-Fi networks, HTTPS hostname, device
username, and matching device password. Confirm that Git ignores this file before
building.

## 4. Install over USB

Build and upload the correct display environment through PlatformIO. Keep physical
access to the device during the first installation. Verify:

- correct orientation and colors
- successful connection to each configured 2.4 GHz network
- valid HTTPS connection to the portal
- changing slideshow frames
- offline snapshot behavior after disconnecting the network
- status check-ins on the portal

## 5. Prepare signed updates

Run `python tools/release.py init` once to generate an ECDSA P-256 signing identity.
The resulting private key and installation-specific public-key header are ignored
by Git. Back up the private key securely.

Increase the firmware version before each release, build with the intended device
identity, and package it with `tools/release.py`. The resulting firmware binary
contains credentials and must stay in private deployment storage.

Upload the binary before its manifest, restrict both files to the deployment
account, and publish the manifest atomically. Test failed downloads and interrupted
updates while USB recovery remains available.

## 6. Back up the personal installation

Back up these private components separately from the public repository:

- `portal.env` and the Basic Auth password file
- the photo catalogue and image data
- each device's ignored `secrets.h`
- the OTA private signing key
- private firmware release binaries

Use encrypted storage with at least one additional copy. A GitHub repository,
including a private repository, is not a substitute for a secrets vault or a photo
backup.
