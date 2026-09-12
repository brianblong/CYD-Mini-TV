# CYD enclosure

## Latest: V3 integrated-thread fit trial

Use [prototype_v3/README.md](prototype_v3/README.md) for the housing with threaded
PCB supports and rear posts, eliminating all eight nuts. Existing screw lengths
and the flush display position stay the same. Start with its threaded test
coupon and spacers before reprinting the housing. Reuse the V2 back with the
enlarged 13.4 x 8.4 mm cable opening, knobs and antennas. Printed thread fit is
not yet physically confirmed. The earlier nut-based V2 remains available below.

## Previous: V2

Use [prototype_v2/README.md](prototype_v2/README.md) for the revised housing and
back. Width is 132 mm with equal 12.9 mm gaps beside the unchanged knobs.
The antenna sockets now sit in hemisphere bases centered on the case top.
The back keeps its vent/cable/fastener design, resized horizontally to match.
The V1 knobs, antenna rods and small fit coupon can be reused unchanged.
V2 housing requires local supports beneath the domes when printed front-down.

## Full prototype V1

The fitted housing, removable back, separate knobs/antennas and a small socket
test are retained in [prototype_v1](prototype_v1/README.md). Those instructions
describe V1 only. The older files below are retained as reference and gauge history.

V1 uses the now-measured 4 mm glass projection, 1 mm PCB and 11 mm total depth.
Its glass is flush with the front; its right compartment allows the 30 mm USB-C
plug projection. The closed rear hole is 13.4 x 5.4 mm for the measured 13 x 5 plug.

Latest PCB dimensions: 86 x 50.5 mm. Latest hole center spacing: 78.5 x 42 mm.
These supersede earlier measurements. All model dimensions are in millimeters.

## First alignment test

Import `cyd_alignment_test.stl` into Bambu Studio, select your P1S, keep scale at
100%, and check dimensions are 86 x 58.5 x 1.6 mm. The extra 8 mm is the pair
of outside bridges; the PCB reference area remains 86 x 50.5 mm. Keep the broad flat face on the
plate. Use your normal PLA profile with 0.20 mm layers and no supports. Slice,
inspect the preview, and print using your normal printer workflow.

After cooling, disconnect the board from power. Compare the printed outline and
four holes with the PCB without pressing against glass or rear components.
Do not force screws through or tighten the board onto this gauge.
Report which holes or edges fail to align together.

The origin is lower-left viewed from the display side. Keep that orientation:
flipping the gauge swaps the unequal margins. Provisional centers are (4,4),
(82.5,4), (4,46), (82.5,46). Left/bottom margins are 4; right is 3.5; top is 4.5.
The earlier claim of 4 mm at every edge cannot hold with the latest dimensions.
The physical test will check the provisional offsets.

The revised gauge has 8 mm side rails and 3.4 mm holes, 0.2 mm above nominal
board-hole diameter. Its 4 mm top and bottom connecting bridges sit outside the
PCB outline, leaving a 70 x 50.5 mm full-height opening so they do not cover the
flush display.
Printing tolerances make this an approximate layout test, not a precision gauge.
This verifies the outer display-module clearance, not the smaller illuminated area.

## OpenSCAD files

- `cyd_dimensions.scad`: shared adjustable board measurements and verification flags.
- `cyd_alignment_test.scad`: printable outline/hole gauge; open and press F5.
- `cyd_reference.scad`: board reference; 0.4 mm sheet thickness is illustrative only.
- `cyd_nominal_footprint.svg`: latest outline/provisional holes for paper comparison,
  not a verified drilling template. Print actual size and measure the result.
- `retro_tv_concept.scad`: styling only, not a fitted printable enclosure.

`include` reads dimensions, `difference` subtracts the middle and holes, and
`linear_extrude` gives the gauge thickness. After editing, F6 renders the model;
File > Export > Export as STL updates the printable file.

The reference's blue rectangle is the nominal 57.6 x 43.2 active display area,
shown separately because its position is unknown. PCB thickness, frame geometry,
assembly depth, USB cutouts, microSD and button access remain undefined.
`require_verified=true` rejects finalization while required measurements are missing.
See `measurement_notes.md` for conflicting earlier readings.

## Final case intentions

Retro TV, decorative knobs, mini top antennas, no lettering or front screw heads.
Board screws will be accessed from the rear into internal standoffs, supporting
PCB rather than glass. Screw lengths and standoff heights require depth and
component-clearance measurements. A separate back cover will have upper/lower
vents, with a rear cable notch and strain relief for an internal USB-C cable
running to an external USB power adapter. These features are not in the test gauge.

The archived manufacturer PDF in `reference` illustrates a micro-USB-only board,
so its 86 x 50 outline, 78 x 42 spacing and 3.2 diameter do not verify this revision.
Actual user measurements override nominal values; hole diameter remains unverified.
