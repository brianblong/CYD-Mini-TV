# V2 validation

## Cable-opening revision after the first full print

Physical testing found a good overall fit, with the rear cable opening too short.
The regenerated back cover increases only that opening from 13.4 x 5.4 to
13.4 x 8.4 mm at the same center. Its STL aperture corner coordinates were
checked directly. The mesh passes closed-manifold, winding, positive-volume,
single-body and bed-placement checks: 12,104 triangles, bounds 132 x 80 x 4 mm.
The updated rear preview was inspected. Housing, original fit coupon, knobs,
antennas and hardware geometry are unchanged. The enlarged opening still needs
a physical connector fit test. The historical validation below predates this change.

## Original V2 checks

Independent STL checks passed: closed manifold edges, consistent winding,
positive volume, no degenerate faces, correct connected-part counts and bed Z=0.

| Part | Connected bodies | STL bounds (mm) |
| --- | ---: | --- |
| Housing | 1 | 132 x 90.9928 x 40 |
| Back cover | 1 | 132 x 80 x 4 |
| Knobs | 2 | 36.9374 x 15.9374 x 10 |
| Antennas | 2 | 16.5 x 39.9976 x 4 |
| Fit coupon | 1 | 45 x 32 x 8 |

Housing height includes the unchanged 5 mm feet and the 6 mm dome rise. The
0.0072 mm difference from nominal height is the sphere mesh's faceting.

V1/V2 knob, antenna and fit-coupon STL SHA-256 hashes match exactly.
Source assertions check equal 12.9 mm knob-edge gaps, centered domes, retained
PCB/glass depths, rear-hole placement, 2.4 mm minimum vent webs and 0.8 mm minimum
wall at the local lower-knob relief. Actual remaining socket wall is 0.825 mm.

Assembly/front, housing-interior and rear-cover previews were inspected. The
rear design retains 36 slots of 12 x 3 mm, with the same row heights; hole/slot
sizes and all fastener dimensions are preserved while horizontal layout narrows.

The modeled housing intersection with the board, back, knobs, antenna rods and
connector envelope was empty. The separate plug-versus-knobs intersection was
also empty. Intended seating contacts were separated by 0.01 mm during this
check to avoid coplanar artifacts. OpenSCAD exit code 1 with "Current top level
object is empty" is the expected passing result of the intersection export.

Physical fit, plug/cable flexibility, support removal and temperature remain
prototype checks. The hemisphere undersides require local print supports.
