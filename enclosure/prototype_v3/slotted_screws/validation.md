# Slotted screw checks — 2026-09-08

All three STLs pass closed-manifold, consistent-winding, positive-volume,
nondegenerate-face, bed-placement and connected-body checks. Test file has
one screw; PCB/back sets each have four. Heights are 12.4 mm for the test/back
screws and 6.4 mm for PCB screws, retaining 2.4 mm head height.

Ray checks verify each of the nine screws' slot interior, boundary and 1.2 mm
depth. Sampled shaft surfaces at 24 angle/height combinations per screw,
including the tapered tip, match the old exports within 0.001 mm (reported
maximum discrepancy rounds to 0.00000000 mm). The shaft module is imported
directly from the unchanged original source.

Head maximum diameter remains 5.5 mm; across flats is 4.7631 mm. The head preview
was visually inspected. CAD-export sliver cleanup moved vertices by no more
than 0.0000142 mm. Housing files and existing screw files were not modified.

Physical screwdriver fit and resistance to stripping remain untested. Testing
confirmed the original threads tighten well; this revision changes only heads.
