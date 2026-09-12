# Mini TV

Mini TV is a DIY Wi-Fi-connected picture frame built around an ESP32-2432S028 display. It combines embedded firmware, a self-hosted photo portal, and a printable retro television enclosure.

The project can:

- display an ordered slideshow from a private photo server
- retain a fallback image for temporary offline use
- report device status to the server
- receive signed firmware updates
- manage pictures through a browser
- fit inside a printable retro-TV enclosure

## Project structure

- `firmware/` contains the ESP32 firmware and setup instructions.
- `homelab/portal/` contains the self-hosted photo-management website.
- `enclosure/` contains the OpenSCAD models and printable parts.

## Privacy

Personal photos, passwords, network details, signing keys, and deployment-specific configuration are not included in the repository. Example configuration files show users how to supply their own settings locally.

Never commit Wi-Fi credentials, server passwords, private signing keys, personal photographs, or firmware binaries containing credentials.

## Getting started

1. Read the [firmware setup guide](firmware/README.md).
2. Configure the [self-hosted photo portal](homelab/portal/README.md).
3. Follow the generic [deployment template](firmware/DEPLOYMENT.md).
4. Review the [enclosure and printing notes](enclosure/README.md).

Start with blank/example configuration, verify the local color test, and add real
credentials and photographs only in ignored or external private storage.
