# Retro mini-TV: first full prototype

All dimensions are millimeters. The body is 150 wide x 80 high x 40 deep;
feet and antenna bases extend beyond that body. The back adds 2.4 mm of depth.
The side beside the knobs reserves a 30 mm cable-plug corridor beyond the PCB.
Physical fit, cable bend, fastener access and temperature still need testing.

## Files to print

| STL | Contents | Color / orientation |
| --- | --- | --- |
| `housing.stl` | Main shell, internal supports, feet, rounded antenna bases | Your body color; front face down, cavity up |
| `back_cover.stl` | Removable back, vents, cable hole, tie slots | Body color; flat exterior down, locating lip up |
| `knobs.stl` | Two matching decorative knobs | Black; faces down, pegs up |
| `antennas.stl` | Two matching antenna rods with insertion pegs | Gray; already lying on their flat undersides |
| `fit_coupon.stl` | Small connector, peg/socket and M3-nut fit test | Same filament/profile as housing; keep supplied orientation |

The knob and antenna STLs each contain two disconnected printable parts, by
design. Import each file separately; no AMS or filament change within a print
is needed. `mini_tv.scad` is the editable source, not a file to slice.

## Print the small parts first

Use your P1S and installed nozzle profile. A starting point for a 0.4 mm nozzle
is 0.20 mm layers, 3 walls, 5 top/bottom layers and 15% infill, using your normal
PLA profile. Keep 100% scale and the supplied orientations. There are short
bridges over nut pockets and an angled roof in each antenna socket. The design
avoids support-filled sockets; inspect those layers in the slicer preview.
Start without supports. A brim can help keep the narrow antenna rods attached.

1. Import `fit_coupon.stl`, `knobs.stl`, and `antennas.stl` on separate plates or
   print runs for the desired colors. Slice, inspect, and print.
2. On the coupon, test the D-shaped knob socket from its top and the antenna
   socket from its side. Both are slip fits; do not force them.
3. Slide a standard M3 hex nut into the side slot of the low, 4 mm tall section.
   Its retaining roof is the same thickness as the PCB supports in the case.
4. Feed the actual USB-C plug through the rectangular opening in the thin tab.
   It measures 13.4 x 5.4, allowing 0.2 per side around the supplied 13 x 5 plug.
5. If these fits work, print the housing and back cover. If a fit needs changing,
   change the source clearance and regenerate; do not scale the complete case.

## Flush screen and hidden board screws

The measured front glass is 4 mm above the front of the PCB. The support pads
place that PCB face 4 mm behind the case's exterior front, so the glass and case
front are at the same plane. PCB back is 5 mm behind the front; the furthest
rear component is 11 mm behind it. No front lip overlaps or clamps the glass.
The whole tested display-face opening is exposed, including its inactive border.
The preview's dark rectangle represents that whole face, not the active pixels.

The opening is 70.4 x 50.9: the accepted 70 x 50.5 opening plus 0.2 clearance per
side. Board mounting uses the accepted four-hole pattern. The glass stays off
the plastic; screw force is taken by the four PCB supports.

Use the following hardware (not included in the STLs):

- Four M3 x 4 mm pan/button-head machine screws for the PCB, no extra washers
  assumed in this length. Avoid substituting a longer screw.
- Four M3 x 10 mm pan/button-head machine screws for the rear cover.
- Eight regular M3 hex nuts, nominal 5.5 across flats x 2.4 thick. No locknuts
  or heat-set inserts: the pockets are 5.8 across flats x 2.6 high.
- One small cable tie for the pair of strain-relief slots on the back.

The standard M3 nut height is documented in the manufacturer
[Accu M3 DIN 934 datasheet](https://www.accu.co.uk/api/product-datasheet?id=268686).
Check the particular nuts you buy against the pocket dimensions and coupon.
The earlier discussion of M3 x 6 screws and heat-set inserts does not apply to V1.

Nuts enter horizontally through side-loading pockets and are trapped beneath
plastic roofs. This is essential: simply dropping nuts into rear-open recesses
would not secure the PCB to the housing. The shallow PCB nut roofs are 0.8 mm
thick; snug the board screws gently by hand. The 4 mm PCB screw length accounts
for the 1 mm PCB, 0.8 mm roof and approximately 2.2 mm of nut engagement.

## Assemble

1. With the board unplugged, slide four nuts into the shallow board-support
   pockets. Use tweezers or a small blunt tool if helpful. Slide four more nuts
   into the side pockets near the ends of the tall corner posts.
2. Insert the CYD from the rear. From the FRONT, USB-C must face right, toward
   the knobs. From the open BACK, that same socket appears on the left.
3. Rest the PCB on all four support pads. Check that its front glass is level
   with the case and that components and screw heads have clearance. If it
   rocks or the glass is pushed against an edge, stop and adjust the model.
4. Install the four M3 x 4 board screws from the rear. They pass through the PCB
   into the captured nuts. Tighten only enough to hold the board on its pads.
5. Feed the USB-C connector from outside the rear cover through its rectangular
   hole, then plug it into the board. Arrange the cable's natural curve in the
   right-hand compartment and loosely secure it with the cable tie. Do not use
   the cover to force a stiff plug/cable into a tighter bend.
6. Seat the back cover's locating lip, then install four M3 x 10 screws. Removing
   the back later does not release the PCB. BOOT/RESET and microSD are accessed
   with the cover removed in this prototype.
7. Align each knob's D-shaped peg with its socket and insert gently. Insert each
   antenna peg into its rounded top base until its wider collar reaches the base.
   The rods point outward. These are decorative, not electrically connected.

The peg/socket diameter clearance is 0.35 mm. It is a slip-fit prototype, not a
guaranteed friction lock. If loose after testing, a tiny amount of suitable glue
on the pegs can retain them; apply with electronics removed and let it cure.
Try all fits before permanent attachment.

Use an external USB power adapter. Ventilation is provided by 36 rear slots,
split between upper and lower banks. Temperature performance is unmeasured:
check it during the first enclosed run and keep both vent banks unobstructed.

## Editable source and checks

Open `mini_tv.scad` in OpenSCAD and press F5 to see the colored assembly. Change
`part` to `exploded` for separation, or to `housing`, `back`, `knobs`, `antennas`,
or `fit_coupon` for individual parts. For a part, F6 then File > Export > Export
as STL creates its file. The assembly includes an illustrative board; do not
export the assembly as a printable object.

Part exports are oriented for printing. The construction drawing uses X right,
Y up from the screen side, with depth toward the rear. Export transforms account
for looking at the front from the opposite side of the build plate. Do not mirror
parts in Bambu Studio; that would reverse the fitted board-hole layout.

`build.ps1` regenerates the five STLs using the installed OpenSCAD CLI.
`verify_meshes.py` checks closed edges, winding, connected-part counts, print-bed
placement, positive volume and bounding dimensions. `part="collision_check"`
checks modeled housing overlaps against the board, cover, knobs and antennas,
with 0.01 mm separation at intended seating contacts to avoid coplanar artifacts.
It does not model actual rear component shapes, cable flexibility or hardware
head clearance; those remain physical prototype checks.
