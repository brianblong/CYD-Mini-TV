# Prototype V3: threads built into the housing

Physical testing confirmed the screws tighten successfully. For the Allen-key
recess slipping, the optional [slotted-head screws](slotted_screws/README.md)
provide a wider flat-head drive and six outer flats with unchanged threads.
No housing change is needed for those screws.

All eight nut pockets are removed. The PCB supports and rear corner posts now
contain blind, right-handed threaded holes using the existing printed screws'
0.5 mm pitch and the printed nuts' 0.30 mm diametral trial clearance. No nuts
are required. This is an experimental fit, not a certified M3 thread.

Keep the existing screws: four M3 x 4 mm for the PCB and four M3 x 10 mm for the
back. The unchanged printed screw STLs remain in
`../prototype_v2/experimental_screws/`. Do not use 10 mm screws on the PCB.

The PCB screw passes through the 1 mm board and penetrates the support by 3 mm.
Its hole is 3.4 mm deep, with a 0.4 mm tip gap and 0.6 mm closed floor protecting
the front face. The rear screw passes through the 2.4 mm back and penetrates
7.6 mm into an 8.2 mm hole. The screw's tapered tip and hole entrance chamfer
reduce full thread engagement below these penetration lengths.

The PCB contact plane remains 4 mm behind the case front, keeping the measured
glass flush. Body dimensions, hole locations, screen opening, knobs, antennas,
vents and enlarged 13.4 x 8.4 mm cable opening are unchanged. Reuse the V2 back
cover, knobs and antennas. Their V3 STLs are identical copies. V2 remains intact.

## Print the small test first

1. Import `fit_coupon.stl` and `test_spacers.stl` into Bambu Studio as separate
   objects. Keep 100% scale and supplied orientations. Do not mirror them.
2. Use your P1S and actual nozzle profile. Try your requested 0.20 mm layer height,
   4 walls and 100% infill on these small test objects, with supports off.
3. The 0.5 mm thread pitch spans only 2.5 layers at 0.20 mm. Inspect the sliced
   threads. If they do not form or bind, try 0.08 or 0.10 mm layers with the
   appropriate printer profile before printing the full housing. Printed fit
   and strength have not yet been confirmed.
4. Put the smaller, 1 mm thick spacer over the SHORT post, then use an existing
   4 mm PCB screw. This simulates the PCB without risking the real electronics.
5. Put the larger, 2.4 mm thick spacer over the TALL post, then use an existing
   10 mm back-cover screw. This simulates the cover. Turn clockwise gently.
6. Each screw should start by hand and snug the spacer without spinning freely
   or stopping while the spacer is loose. Do not force a binding screw. The
   two spacers are for this test only, not extra washers for final assembly.

## Housing and assembly

After the test succeeds, print `housing.stl` front down, cavity up at 100% scale.
Use the successful thread settings from the coupon. A starting point for the
housing is 4 walls, 5 top/bottom layers and 15% infill. As with V2, manually paint
local supports under the lower external curves of the antenna half-spheres.
Keep supports out of the threads and other sockets. Inspect the sliced supports.

With power unplugged, insert the PCB from the rear, USB-C pointing toward the
knob side. Seat all four corners on the support pads; check the glass is flush.
Fit the 4 mm screws through the PCB into the integrated threads. Snug gently by
hand; do not bend the PCB. Route the USB cable through the existing enlarged
back opening, attach the back, and use the 10 mm screws in its corner posts.
Use no nuts or test spacers in the enclosure.

Integrated threads provide more continuous plastic for the screw to engage,
but do not establish that insufficient engagement caused the previous failure.
Poor thread resolution, fit clearance or stripping can still prevent clamping.
Repeated assembly can wear printed threads; physical retention needs testing.

## Source and validation

`mini_tv.scad` is the editable source. It imports the unchanged V2 screw geometry
and shared `../cyd_dimensions.scad`. `build.ps1` exports and checks the models.
`finish_meshes.py` cleans microscopic export slivers using the existing helper.
`verify_meshes.py` checks mesh closure, winding, volume, bodies and bounds.
`verify_threads.py` checks the actual exported holes for pitch, handedness and
blind depth. The cutter is pre-mirrored because the case print transform also
mirrors X; omitting that compensation would create left-handed holes.
