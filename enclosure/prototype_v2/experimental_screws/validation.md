# Experimental screw geometry checks

All three delivered binary STLs passed closed-manifold, winding, positive-volume,
zero-degenerate-face, connected-part and print-bed placement checks.

| File | Bodies | Bounds, mm |
| --- | ---: | --- |
| test_screw.stl | 1 | 5.5 x 5.5 x 12.4 |
| pcb_screws_m3x4.stl | 4 | 14.5 x 14.5 x 6.4 |
| back_screws_m3x10.stl | 4 | 14.5 x 14.5 x 12.4 |

Head thickness is 2.4 mm; this leaves the required 4 and 10 mm under-head lengths.
Ray checks on the exported test screw confirm a 2.88 mm crest diameter at two
successive 0.5 mm pitch positions. A crest advances 0.125 mm axially through a
positive 90-degree turn, confirming right-handed geometry. The opposite phase
matches the modeled 2.26657 mm core diameter.

Numerical finishing collapsed microscopic short edges introduced by CAD Boolean
intersections and ASCII precision. Maximum vertex displacement was approximately
0.00001415 mm. The supplied files are then saved as binary STL and independently
checked. This is mesh cleanup only, not a physical tolerance or strength claim.

No physical print, metal-nut fit, torque, fatigue or load test has been performed.
These are experimental specimens; metal screws remain recommended for final use.
