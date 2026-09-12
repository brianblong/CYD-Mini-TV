# Experimental printed screws

These are trial parts for learning and checking whether your printer can resolve
the thread. They have not been physically tested or strength-rated. Real metal
M3 screws remain the recommended fasteners for the finished TV, especially the
PCB. Tiny printed threads and heads can strip or snap under tightening.

The case still requires its eight METAL M3 nuts. These files replace neither
those nuts nor any housing parts. Keep the existing screw lengths unchanged.

| File | Contents | Under-head length | Total height |
| --- | --- | --- | --- |
| `test_screw.stl` | One trial screw; print this first | 10 mm | 12.4 mm |
| `pcb_screws_m3x4.stl` | Four experimental PCB screws | 4 mm | 6.4 mm |
| `back_screws_m3x10.stl` | Four experimental back-cover screws | 10 mm | 12.4 mm |

The head is 5.5 mm diameter x 2.4 mm tall, with a 2.1 mm hex recess intended for
a 2 mm key. Screw length is measured from the head's bearing surface to the tip,
not from the top of the head. This preserves the PCB screw's depth limit.

## First print and fit check

1. Import only `test_screw.stl` into Bambu Studio. Keep its head on the plate and
   shaft upright, at 100% scale. No supports on the threads.
2. With your installed nozzle profile, use a fine layer height such as 0.08 mm
   if supported, rather than the 0.20 mm used for the case. Start with PLA,
   100% infill and a slow outer-wall speed (around 20 mm/s). Use a small brim
   if necessary for adhesion. These are trial settings, not a verified recipe.
3. Inspect the sliced preview: a 0.5 mm pitch needs recognizable separate thread
   turns. After printing and cooling, remove stray filament without crushing it.
4. Try it by hand in a LOOSE metal M3 nut, away from the PCB and the housing's
   captive pockets. It should turn through the nut smoothly with light force.
   Do not use a drill, pliers or a driver to force a poor fit.
5. If it binds, breaks or spins without engaging, do not use it in the case.
   Metal M3 x 4 / M3 x 10 screws are the straightforward reliable option.
6. Only after a successful loose-nut trial, consider the pair of four-screw files
   for a gentle experimental assembly. Use minimal tightening force and check
   the head's component clearance. Never put the 10 mm screws through the PCB.

A smaller nozzle may improve detail but does not establish fastener strength.
The test screw's fit alone is not a load test. I recommend metal screws for
holding the actual board even if these trial screws appear to work.

## Geometry and adjustment

`printed_screws.scad` is self-contained. The model has a single-start right-hand
helix, 0.5 mm pitch, truncated 60-degree flanks and a short tip taper. The root
is simplified and flat rather than a production screw's rounded root.

[Bossard's metric thread table](https://www.bossard.com/-/media/bossard-group/website/documents/technical-resources/en/f-079-en.pdf)
lists M3 coarse pitch as 0.5 mm and the 6g maximum major diameter as 2.980 mm.
The model subtracts a trial **0.10 mm diametral print compensation**, giving a
2.88 mm modeled major diameter. This is not a claim of ISO tolerance compliance.
Actual printed fit depends on extrusion, cooling and material.

If a loose-nut test justifies a small adjustment, change `diameter_compensation`
(0 to 0.20 mm allowed) and regenerate a single test. Increasing it makes the
thread smaller and weaker; decreasing it makes it larger. Do NOT scale the STL:
scaling would change pitch and screw length as well as diameter.

In OpenSCAD choose `part="test"`, `"pcb"` or `"back"`, press F6, then export STL.
The supplied files also receive numerical mesh finishing and verification;
`build.ps1` repeats the complete export/finish/check workflow. Finishing merges
CAD-export edges shorter than 0.00003 mm, without rescaling or smoothing threads.
Use the supplied STLs directly for printing.
These are standalone experimental files and do not change the V2 case or the
main print instructions recommending metal hardware.
# Printed nut fit tests

Optional experimental printed nuts are now available: see
[PRINTED_NUTS.md](PRINTED_NUTS.md) for the single test nut and eight-nut STL.
The metal-hardware recommendations below still apply to final assembly.
