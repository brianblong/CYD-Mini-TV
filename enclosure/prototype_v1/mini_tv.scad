// Mini-TV prototype V1. Millimeters. Parts export in their PRINT orientations.
// Construction layout: X right/Y up as viewed from FRONT; depth rearward is +Z.
// That drawing convention is left-handed. PRINT exports mirror X so the actual
// face-down print has its knobs on the right when viewed upright from the front.
// Assembly previews instead mirror Z, equivalent to rotating the physical print.
include <../cyd_dimensions.scad>

part = "assembly"; // housing, back, knobs, antennas, fit_coupon, assembly, exploded
$fn = 64;
eps = 0.02;

case_w = 150;
case_h = 80;
case_d = 40;
wall = 2.4;
front_t = 2.4;
corner_r = 6;
board_xy = [12,(case_h-pcb_height)/2];
board_front_z = glass_above_pcb_front; // Glass plane = 4 - 4 = 0, flush.
board_back_z = board_front_z + pcb_thickness;
screen_clearance = 0.2; // Per side, beyond the successfully tested opening.
screen_xy = board_xy + fit_test_opening_xy;
screen_wh = fit_test_opening;
board_boss_r = 3.6;

nut_af = 5.8; // Pocket for standard M3 nuts: nominal AF 5.5, height 2.4.
nut_slot_h = 2.6;
nut_slot_floor = 0.6;
screw_clearance_d = 3.4;
rear_boss_r = 4.8;
rear_centers = [[6,6],[case_w-6,6],[6,case_h-6],[case_w-6,case_h-6]];
rear_nut_floor = case_d-6.6;
back_t = 2.4;
back_lip_h = 1.6;
back_lip_gap = 0.3;
back_lip_w = 1.2;

knob_x = 136;
knob_ys = [29,53];
knob_r = 8;
knob_t = 5;
knob_recess = 0.6;
knob_peg_d = 4;
knob_peg_length = 5;
peg_fit = 0.35; // Diametral clearance, deliberately a slip fit.
knob_flat_x = 1.25;

antenna_base_xs = [43,67];
antenna_base_r = 6;
antenna_base_depth = 16;
antenna_angle = 22;
antenna_peg_d = 3.5;
antenna_peg_length = 6;
antenna_socket_depth = 7;
antenna_socket_d = antenna_peg_d + peg_fit;
antenna_flat_z = -1.25; // Flat underside for horizontal printing.

// Measured connector envelope with 0.2 mm clearance per side.
cable_connector_wh = [13,5];
cable_clearance = 0.2;
cable_exit_wh = cable_connector_wh + [2*cable_clearance,2*cable_clearance];
cable_exit_y = 39;
cable_exit_x = 126;
cable_plug_projection = 30;

assert(abs(board_front_z-glass_above_pcb_front)<0.001, "Glass must be flush.");
assert(board_back_z == 5 && total_assembly_thickness == 11);
assert(board_front_z-(nut_slot_floor+nut_slot_h) >= 0.8-eps,
       "Board nut pockets need a retaining roof.");
assert(board_xy[0]+pcb_width+cable_plug_projection < knob_x-5,
       "USB plug corridor hits a knob socket.");
assert(case_d-back_lip_h > total_assembly_thickness+10);
assert(screen_xy[0]-screen_clearance > board_xy[0]+4+board_boss_r);
assert(cable_exit_x+cable_exit_wh[0]/2 < case_w-wall-back_lip_w);

module rounded_rect(w,h,r) {
    hull() for (x=[r,w-r]) for (y=[r,h-r]) translate([x,y]) circle(r=r);
}
module case_outline() { rounded_rect(case_w,case_h,corner_r); }
module screen_cut(h=10,z=-eps) {
    translate([screen_xy[0]-screen_clearance,screen_xy[1]-screen_clearance,z])
        cube([screen_wh[0]+2*screen_clearance,screen_wh[1]+2*screen_clearance,h]);
}
module board_positions() {
    for (p=mount_hole_centers) translate([board_xy[0]+p[0],board_xy[1]+p[1],0]) children();
}
// Hex has horizontal upper/lower flats. The side-loading slot preserves a roof
// above the nut: a rear-open nut recess would NOT retain the board in the case.
module nut_cavity(x,y,z,entry_side,entry_length) {
    translate([x,y,z]) {
        cylinder(d=nut_af/cos(30),h=nut_slot_h,$fn=6);
        translate([entry_side<0 ? -entry_length : 0,-nut_af/2,0])
            cube([entry_length,nut_af,nut_slot_h]);
    }
}
module d_peg(d,h,flat) {
    intersection() {
        cylinder(d=d,h=h);
        translate([-d,-d,-eps]) cube([d+flat,2*d,h+2*eps]);
    }
}
module antenna_cross_section() {
    r=antenna_socket_d/2;
    // Teardrop roof prints at 45 degrees; round lower section locates the peg.
    union() {
        circle(r=r);
        polygon([[-r/sqrt(2),r/sqrt(2)],[r/sqrt(2),r/sqrt(2)],[0,r*sqrt(2)]]);
    }
}
function antenna_dir(side) = [side*sin(antenna_angle),cos(antenna_angle),0];
function antenna_entry(i) = [antenna_base_xs[i],case_h,antenna_base_depth/2]
    + antenna_dir(i==0 ? -1 : 1)*(antenna_base_r+0.05);

module housing() {
    difference() {
        union() {
            difference() {
                linear_extrude(case_d) case_outline();
                translate([wall,wall,front_t]) linear_extrude(case_d)
                    rounded_rect(case_w-2*wall,case_h-2*wall,corner_r-wall);
            }
            board_positions() cylinder(r=board_boss_r,h=board_front_z);
            for (p=rear_centers) translate(p) cylinder(r=rear_boss_r,h=case_d);
            for (y=knob_ys) translate([knob_x,y,0]) cylinder(r=5,h=8);
            // Half-round top bases are solid from the print bed, with no floating underside.
            for (x=antenna_base_xs) translate([x,case_h,0])
                cylinder(r=antenna_base_r,h=antenna_base_depth);
            // Two integral feet. Fronts lie on Z=0, like the main housing.
            for (x=[22,116]) translate([x,-5,0]) cube([12,7,32]);
        }
        screen_cut(case_d+2*eps);
        for (p=mount_hole_centers) {
            x=board_xy[0]+p[0]; y=board_xy[1]+p[1];
            side=p[0]<pcb_width/2 ? -1 : 1;
            nut_cavity(x,y,nut_slot_floor,side,12); // Room to drop a nut beside the roof, then slide it in.
            translate([x,y,nut_slot_floor])
                cylinder(d=screw_clearance_d,h=board_front_z-nut_slot_floor+eps);
        }
        for (p=rear_centers) {
            side=p[0]<case_w/2 ? 1 : -1;
            nut_cavity(p[0],p[1],rear_nut_floor,side,12);
            translate([p[0],p[1],case_d-10]) cylinder(d=screw_clearance_d,h=10+eps);
        }
        for (y=knob_ys) {
            translate([knob_x,y,-eps]) cylinder(r=knob_r+0.25,h=knob_recess+eps);
            translate([knob_x,y,-eps]) d_peg(knob_peg_d+peg_fit,6.3,knob_flat_x+peg_fit/2);
        }
        for (i=[0,1]) translate(antenna_entry(i))
            rotate([0,0,(i==0 ? 1 : -1)*antenna_angle]) rotate([90,0,0])
                translate([0,0,-eps]) linear_extrude(antenna_socket_depth+eps)
                    antenna_cross_section();
    }
}

module slot2d(length,width) {
    hull() for (x=[width/2,length-width/2]) translate([x,width/2]) circle(d=width);
}
module cable_hole(z,h) {
    translate([cable_exit_x-cable_exit_wh[0]/2,cable_exit_y-cable_exit_wh[1]/2,z])
        cube([cable_exit_wh[0],cable_exit_wh[1],h]);
}
// Back cover PRINT orientation: exterior on bed, locating lip points up.
module back_profile() {
    difference() {
        union() {
            linear_extrude(back_t) case_outline();
            translate([wall+back_lip_gap,wall+back_lip_gap,back_t])
                linear_extrude(back_lip_h) difference() {
                    rounded_rect(case_w-2*(wall+back_lip_gap),case_h-2*(wall+back_lip_gap),3.3);
                    translate([back_lip_w,back_lip_w])
                        rounded_rect(case_w-2*(wall+back_lip_gap+back_lip_w),
                                     case_h-2*(wall+back_lip_gap+back_lip_w),2.1);
                }
        }
        for (p=rear_centers) {
            translate([p[0],p[1],-eps]) cylinder(d=screw_clearance_d,h=back_t+back_lip_h+2*eps);
            // Interrupt lip near bosses; solid plate still supports screw heads.
            translate([p[0],p[1],back_t-eps]) cylinder(r=rear_boss_r+0.4,h=back_lip_h+2*eps);
        }
        // Lower and upper rear vent banks; ribs remain between every slot.
        for (y=[12,19,26,52,59,66]) for (x=[22,40,58,76,94,112])
            translate([x,y,-eps]) linear_extrude(back_t+2*eps) slot2d(12,3);
        cable_hole(-eps,back_t+back_lip_h+2*eps);
        // Tie-down slots beside the cable exit for a loose strain-relief cable tie.
        for (x=[116,134]) translate([x,45,-eps]) cube([2.5,4,back_t+2*eps]);
    }
}

// Mirror Y in the print layout; rotating the physical cover into place then
// puts its asymmetric cable exit at the intended height in the assembly.
module back_cover() { translate([0,case_h,0]) mirror([0,1,0]) back_profile(); }

module knob() {
    difference() {
        union() {
            cylinder(r=knob_r,h=knob_t);
            translate([0,0,knob_t]) d_peg(knob_peg_d,knob_peg_length,knob_flat_x);
        }
        // Recessed indicator groove; no text. Printable front face remains mostly flat.
        translate([-0.7,0,-eps]) cube([1.4,6.5,0.6+eps]);
        for (a=[0:30:330]) rotate([0,0,a]) translate([knob_r+0.45,0,-eps])
            cylinder(r=0.8,h=knob_t+2*eps);
    }
}
module knobs_print() { for (x=[knob_r,3*knob_r+5]) translate([x,knob_r,0]) knob(); }

// Rod axis is +Y. Flat underside lets both antennas print lying down.
module antenna() {
    intersection() {
        union() {
            rotate([-90,0,0]) cylinder(d=antenna_peg_d,h=antenna_peg_length);
            translate([0,antenna_peg_length,0]) rotate([-90,0,0]) cylinder(d=5.5,h=2);
            translate([0,antenna_peg_length+2,0]) rotate([-90,0,0]) cylinder(d=3.2,h=30);
            translate([0,antenna_peg_length+32,0]) sphere(d=4);
        }
        translate([-5,-eps,antenna_flat_z]) cube([10,50,10]);
    }
}
module antennas_print() { for (x=[3,14]) translate([x,0,-antenna_flat_z]) antenna(); }

module fit_coupon() {
    // Same horizontal antenna socket and roof as housing; nut roofs also match.
    difference() {
        union() { cube([45,20,8]); translate([0,-12,0]) cube([45,12,back_t]); }
        translate([8,8,1.7]) d_peg(knob_peg_d+peg_fit,6.4,knob_flat_x+peg_fit/2);
        translate([21,20,4]) rotate([90,0,0]) linear_extrude(antenna_socket_depth)
            antenna_cross_section();
        nut_cavity(35,8,nut_slot_floor,1,11);
        // Coupon board-support top at 4 mm, like the case.
        translate([29,0,4]) cube([17,16,5]);
        translate([35,8,nut_slot_floor]) cylinder(d=screw_clearance_d,h=8);
        translate([5,-9,-eps]) cube([cable_exit_wh[0],cable_exit_wh[1],back_t+2*eps]);
    }
}

module visual_board(offset=0) {
    translate([board_xy[0],board_xy[1],offset]) {
        color("SeaGreen") difference() {
            translate([0,0,board_front_z]) cube([pcb_width,pcb_height,pcb_thickness]);
            for (p=mount_hole_centers) translate([p[0],p[1],board_front_z-eps])
                cylinder(d=mount_hole_diameter,h=pcb_thickness+2*eps);
        }
        color("DarkSlateGray") translate([fit_test_opening_xy[0],fit_test_opening_xy[1],0])
            cube([fit_test_opening[0],fit_test_opening[1],glass_above_pcb_front]);
        // No assumed active-pixel rectangle or rear component locations.
    }
}
module assembly(explode=0) {
    color("BurlyWood") housing();
    visual_board(explode*0.4);
    color("SaddleBrown") translate([0,case_h,case_d+back_t+explode]) rotate([180,0,0]) back_cover();
    color("DimGray") for (y=knob_ys) translate([knob_x,y,knob_recess-knob_t-explode*0.25]) knob();
    color("Silver") for (i=[0,1]) {
        side=i==0 ? -1 : 1;
        translate(antenna_entry(i)+antenna_dir(side)*(-antenna_peg_length+explode*0.2))
            rotate([0,0,-side*antenna_angle]) antenna();
    }
}

module collision_check() {
    // Move seating surfaces apart by 0.01 mm to avoid CGAL coplanar-contact
    // artifacts. Positive volume after that tolerance signals an overlap.
    contact_tolerance=0.01;
    intersection() {
        housing();
        union() {
            visual_board(contact_tolerance);
            translate([0,case_h,case_d+back_t+contact_tolerance]) rotate([180,0,0]) back_cover();
            for (y=knob_ys) translate([knob_x,y,knob_recess-knob_t-contact_tolerance]) knob();
            for (i=[0,1]) translate(antenna_entry(i)-antenna_dir(i==0 ? -1 : 1)*antenna_peg_length)
                rotate([0,0,(i==0 ? 1 : -1)*antenna_angle]) antenna();
        }
    }
}

if (part=="housing") translate([case_w,0,0]) mirror([1,0,0]) housing();
else if (part=="back") translate([case_w,0,0]) mirror([1,0,0]) back_cover();
else if (part=="knobs") translate([4*knob_r+5,0,0]) mirror([1,0,0]) knobs_print();
else if (part=="antennas") antennas_print(); // Symmetric about each rod's X axis.
else if (part=="fit_coupon") translate([45,12,0]) mirror([1,0,0]) fit_coupon();
else if (part=="collision_check") collision_check();
else if (part=="exploded") mirror([0,0,1]) assembly(36);
else if (part=="assembly") mirror([0,0,1]) assembly();
else assert(false,"Unknown part selection.");

echo("V1 body:",[case_w,case_h,case_d],"front glass plane:",board_front_z-glass_above_pcb_front);
echo("PCB front/back and maximum assembly depth:",board_front_z,board_back_z,total_assembly_thickness);
echo("Screen opening:",screen_wh+[2*screen_clearance,2*screen_clearance]);
echo("Cable projection:",cable_plug_projection,"rear opening:",cable_exit_wh);
