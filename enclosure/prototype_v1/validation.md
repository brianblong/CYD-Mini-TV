# Prototype V1 validation

OpenSCAD rendered the five printable exports as simple solids. Independent STL
checks confirmed that every mesh edge has two incident faces, winding is
consistent, volumes are positive, no degenerate triangles exist, and the lowest
Z coordinate is zero. The pair exports intentionally contain two bodies.

| Part | Bodies | Measured STL bounding box, mm |
| --- | ---: | --- |
| Housing | 1 | 150 x 91 x 40 |
| Back cover | 1 | 150 x 80 x 4 |
| Knobs | 2 | 36.9374 x 15.9374 x 10 |
| Antennas | 2 | 16.5 x 39.9976 x 4 |
| Fit coupon | 1 | 45 x 32 x 8 |

Knurling and faceted circular tips account for the small differences from nominal
part bounding dimensions. Preview images were inspected for assembly placement,
the flush display face, separate accessories, internal mounts and rear openings.

The modeled housing-versus-board/cover/accessory intersection was empty after
allowing 0.01 mm at intentional seating contacts. OpenSCAD's exit code 1 with
"Current top level object is empty" is the expected passing result for this
intersection export. The final board-nut entry slots were subsequently lengthened
by removing more material, which cannot introduce a new overlap with those parts.

Measured inputs: PCB 86 x 50.5; accepted hole pitch 78.5 x 42; accepted aperture
70 x 50.5; glass projection 4; PCB thickness 1; overall assembly depth 11; right
USB-C plug projection 30; connector passage envelope 13 x 5.

The virtual component model does not contain the actual connector/component
shapes or screw heads. Physical tests must confirm PCB screw access, cable bend,
actual peg/nut fits and operating temperature. Geometry checks do not establish
those measurements or constitute a completed physical test of this prototype.
