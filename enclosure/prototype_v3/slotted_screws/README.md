# Slotted hex-head screws

Physical testing found that the V3 screws tighten successfully, but the small Allen-key
recess strips. These screws change only the head: a straight rectangular slot
replaces the 2.1 mm hex socket, and six exterior flats replace the round rim.
The slot is 4.2 mm long, 1.0 mm wide and 1.2 mm deep, leaving 1.2 mm of plastic
between its floor and the underside of the head. Maximum head diameter stays
5.5 mm and head height stays 2.4 mm. The hex measures approximately 4.76 mm
across flats; it is not a standard 5 mm wrench size.

The successful shaft/thread module is imported unchanged from the original
source: 2.88 mm major diameter, 0.5 mm right-hand pitch, same tapered tip,
4 mm PCB length and 10 mm back-cover length. Existing housing holes need no
changes, and no housing reprint is required.

## Print and test

1. Print `test_screw.stl` first, using the settings that worked for your threads.
   Keep 100% scale, head flat on the bed, shaft upward, and supports off.
   Use 100% infill for these small screws.
2. After removal from the bed, clear any brim/first-layer residue from the slot.
   The slot is on the bottom face in the supplied print orientation.
3. Use a small FLAT-HEAD screwdriver, not the Allen key. Choose a blade that
   fits fully into the 4.2 x 1.0 mm opening with little sideways play; around
   3.5–4 mm blade width with thickness below 1 mm is a starting point.
4. Test gently in the existing threaded coupon with its thick spacer and the
   10 mm test screw. Seat the blade fully and keep it straight. Stop when snug.
   If access permits, the outside flats offer another grip, but do not squeeze
   or twist hard with pliers: the printed screw can still break.
5. If the grip works, print `pcb_screws_m3x4.stl` (four screws) and
   `back_screws_m3x10.stl` (four screws). Never use 10 mm screws on the PCB.

These remain experimental printed hardware. A larger slot spreads contact over
a wider area but does not guarantee resistance to stripping or over-tightening.
The revised head's tool fit and strength still need physical testing.

`screws.scad` is the editable source; `build.ps1` exports all three files.
