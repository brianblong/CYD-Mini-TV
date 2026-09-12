# Measurement record (millimeters)

Latest correction, 2026-09-05: PCB 86 x 50.5; hole spacing 78.5 x 42.
Earlier bottom-left offset (4,4) is provisional. Derived right/top offsets are
3.5/4.5, pending alignment test. Hole diameter 3.2 is manufacturer nominal only.

Superseded readings: PCB 88 x 51; spacing 78 x 42.
Earlier frame: 70 x 51, left gap 10, right gap 8, flush top/bottom.
These cannot all hold with the latest PCB dimensions. Frame size/location are
undefined pending reconciliation; possible overhang must not be ruled out.
Earlier USB-C report: 19 to 29 from bottom-right corner, height 3. Edge direction,
Z position, cable plug size and bend clearance remain unverified.
PCB thickness, total assembly depth, active display position, SD/button access
remain unverified. No finished case fit is claimed.

Fit-test result: the 70 mm opening width and all four mounting holes align. The
original gauge's 8 mm top/bottom rails covered the display because its module is
flush with the PCB at those edges. The revised gauge moves its connecting bridges
outside the PCB and leaves a 70 x 50.5 mm full-height module opening.

User subsequently confirmed the revised test fits perfectly. The opening and
four-hole layout are accepted for the prototype. See prototype_requirements.md
for the flush-front design and the remaining depth/cable measurements.

## Full-prototype depth measurements supplied afterward

- Glass front is 4 mm above the PCB's front surface.
- PCB thickness is 1 mm.
- PCB plus rear connectors reach 7 mm, giving 11 mm total from glass to rear.
- USB-C exits right when viewing the display. Plugged cable extends at most
  30 mm beyond that PCB edge.
- Connector passage needs 13 mm width x 5 mm height; the plug must pass through
  first. V1 uses a closed 13.4 x 5.4 mm rear hole with 0.2 mm per-side allowance.
- V1 screen opening uses the fit-tested location and dimensions plus 0.2 mm
  per-side assembly clearance. Exact active-area position is still unknown and
  is not needed for the full-face flush opening.

Actual cable bend stiffness, rear component locations, board screw-head clearance
and enclosed temperature remain physical prototype checks.

## V2 confirmation (2026-09-06)

USB-C center is 24 mm above the PCB bottom when viewing the screen with the port
on the right (user confirmed). With the PCB's 14.75 mm bottom offset in the case,
that is Y=38.75. The 13 mm connector envelope is reserved about that center while
narrowing the knob compartment. Board dimensions and fitted hole layout are unchanged.
