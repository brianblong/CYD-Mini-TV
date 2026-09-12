# V3 checks — 2026-09-07

Follow-up testing found that the screws tighten well, but the Allen-key
recess slips. The optional `slotted_screws` revision changes the drive head
while reusing the successful threaded shaft. Its physical head fit remains
to be tested. The original CAD checks below are retained as history.

- Housing: one closed, consistently wound mesh; 94,150 triangles; positive
  volume 67,164.2 mm³; bounds 132 x 90.9928 x 40 mm, bed Z=0.
- Coupon: one closed mesh; 22,060 triangles; bounds 34 x 16 x 12 mm.
- Test spacers: two closed bodies; bounds 25.5 x 11 x 2.4 mm.
- All six delivered STL files pass topology, winding, positive-volume,
  connected-body, print-bed and dimensional checks.
- Ray intersections against the actual exported housing and coupon verify
  all ten holes' 0.5 mm pitch, right-handed direction and blind depth.
  PCB hole depth is 3.4 mm; rear hole depth is 8.2 mm.
- Source assertions retain the flush glass plane and confirm screw-tip gaps.
- The back cover, knobs and antennas match the latest V2 STLs byte for byte.
- The thread-coupon preview and exported-housing rear view were inspected.
- Numerical export cleanup moved no housing vertex more than 0.00002 mm.

No new physical fit, clamp-load or durability test has been performed. The
coupon/spacer trial is required to establish printed screw fit, especially at
the requested 0.20 mm layers. The previous fastener failure's cause is unproven.
Full assembly collision checks from V2 were not rerun for V3; thread direction,
depth and unchanged accessory geometry were checked as described above.

`preview_housing.scad` provides a fast view of the exported mesh. The editable
source evaluates detailed thread cutters for F5 and may take over a minute;
a full F6/CLI housing export took about seven minutes on this machine.
