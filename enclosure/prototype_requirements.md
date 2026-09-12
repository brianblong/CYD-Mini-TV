# First full prototype

## User requirements

- Retro TV cabinet with no text or lettering.
- Display face flush with the exterior front surface, not recessed behind a lip.
- Fit-tested PCB outline: 86 x 50.5 mm.
- Fit-tested mounting centers: (4,4), (82.5,4), (4,46), (82.5,46).
- Revised gauge's 70 x 50.5 opening fits. This confirms aperture fit, not a
  precision measurement of the glass, its height, or its edge clearances.
- Concealed board fasteners accessible from the rear; support PCB, not glass.
- Separate removable rear cover, upper/lower ventilation, USB-C cable exit.
- Cable plugs into the PCB inside the cabinet and runs to an external USB adapter.
- P1S without AMS: separate printable housing, rear cover, knobs and antennas.
- Two black decorative knobs with locating pegs and matching housing sockets.
- Two gray antennas with pegs fitting sockets in small rounded top bases.
- Include assembly clearances in peg/socket fits; verify fit on a small coupon.

## Measurements supplied for V1

- Front glass to front PCB surface: 4 mm.
- PCB thickness: 1 mm.
- Front glass to furthest rear component: 11 mm.
- USB-C exits right from the front view; cable/plug projection is 30 mm.
- User specifies a closed rear opening for a 13 x 5 mm connector to pass through
  first. V1 adds 0.2 mm on each side. The earlier seam-notch option is superseded.

V1 source and separate STLs are in prototype_v1/. Support height is 4 mm; the
body is 150 x 80 x 40 mm to accommodate the board, plug corridor and knob sockets.
Fasteners use side-loaded M3 nuts, M3 x 4 board screws, and M3 x 10 cover screws.
Actual fastener clearances, print fits, cable bend and temperature need testing.

## V2 styling revision, 2026-09-06

The user requested less space on the knob side, equal screen-to-knob and
knob-to-right-edge gaps, and half-sphere antenna bases centered on the top.
V2 is 132 mm wide with 12.9 mm equal gaps and two radius-6 mm domes centered at
X=54/78 and depth=20. Knob/antenna parts are unchanged. The back retains its
design with a narrower horizontal layout. Confirmed USB-C center is 24 mm above
PCB bottom; an internal lower-knob support relief clears that plug envelope.
V2 is saved separately in prototype_v2; V1 remains available.
