# Experimental printed nuts

Print `test_nut.stl` first. `nuts_m3_set_of_8.stl` contains all eight nuts:
four for the PCB supports and four for the rear-cover posts.

Each nut is 5.5 mm across flats and **2.0 mm tall**. Physical tests found
the original 2.4 mm nut too thick and the 1.4 mm revision slightly loose. This
revision follows a 1.7 mm trial and increases height to 2.0 mm,
retaining the width and thread pitch.
Reimport the updated STL and slice
at 100%; do not scale its height in the slicer, which would alter the pitch.
Existing pockets are nominally 5.8 mm across flats and 2.6 mm high in CAD. The
cause of the reduced physical slot clearance has not been established. Confirm
the actual pocket fit before assuming standard 2.4 mm metal nuts will fit.
The right-handed internal helix uses the existing printed screw's 0.5 mm pitch.
Its cutting profile is enlarged by 0.30 mm diametrally in XY only as an initial
print-fit allowance; this is not a certified M3 thread or a measured fit.
Small lead-in chamfers are provided on both faces.

Use the installed nozzle's profile, 100% scale, 0.08 mm layers, 100% infill,
and about 20 mm/s outer walls for a first trial. Print flat as supplied, with
the threaded hole vertical, supports off. These tiny threads may not resolve
well on a 0.4 mm nozzle. Inspect the sliced hole before printing. A brim can
help adhesion, but must be removed completely before testing the nut slot.

1. Try one printed nut on the printed test screw away from the electronics.
   Turn clockwise to tighten. Do not force it if the threads bind.
2. Try the nut in the original fit coupon's side-loading slot before inserting
   it into the case. The coupon's old cable aperture is unrelated to this test.
3. If both fits work, print the set of eight. Slide each nut into its slot and
   align its hole with the screw hole before assembling.
4. Use the 4 mm screws for the PCB and 10 mm screws only for the back cover.
   Tighten gently by hand. Avoid crushing or bending the PCB.

These parts are for prototype fit checks, not reliable final retention. Printed
threads can strip and printed nuts can split; the thinner nuts have less thread
engagement. Use metal M3 screws and metal nuts with verified pocket fit for the
final assembly. No strength or revised physical fit has been
verified by generating these files.

Source: `printed_nuts.scad`; it imports `printed_screws.scad`. Export with
`part="test"` or `part="eight"`, then use the existing `finish_stls.py` with
`test_nut nuts_m3_set_of_8` to clean microscopic export slivers.
