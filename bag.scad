// ============================================================================
//  PARAMETRIC "FAKE LOUIS VUITTON" 2D-INSPIRED SHOULDER BAG
// ----------------------------------------------------------------------------
//  A flap shoulder bag recreated from the design spec sheet, in the flat /
//  comic / hand-drawn style: bold outlined edges, hatch shading, graphic text.
//  Split into a WHITE part and a BLACK part that share one origin and never
//  overlap, so each exports as its own STL and keeps its colour in Bambu Studio.
//
//  Guarantee:  white = (body + flap) - black,   black = black.
//
//  Coordinate system (mm / degrees):
//    X = width  (240)   left  <-> right
//    Z = height (170)   down  <-> up
//    Y = depth  (65)    back  <-> FRONT (-Y is the flap / lettered face)
//
//  Spec: 24 x 17 x 6.5 cm, ~450 g.  No chain strap.
//
//  Export:
//    openscad -D 'part="white"' -o bag_white.stl bag.scad
//    openscad -D 'part="black"' -o bag_black.stl bag.scad
//
//  Reference views (headless: prefix `xvfb-run -a`):
//    openscad -D 'part="both"' --camera=0,0,0,90,0,0,640  --imgsize=900,640 -o front.png  bag.scad
//    openscad -D 'part="both"' --camera=0,0,0,90,0,90,520 --imgsize=600,640 -o side.png   bag.scad
//    openscad -D 'part="both"' --camera=0,0,0,205,0,0,620 --imgsize=900,520 -o bottom.png bag.scad
// ============================================================================


/* [Part Selection] */
// Which part to render / export. "both" is a colored preview only.
part = "both";               // [white, black, both]


/* [Overall Dimensions] */
// Width across X (mm)
body_w = 240;                // [50:1:500]
// Height across Z (mm)
body_h = 170;                // [50:1:400]
// Depth across Y, front-to-back (mm)
body_d = 65;                 // [15:1:200]
// Corner radius of the rounded-rectangle body (mm)
r_corner = 15;               // [2:1:60]


/* [Flap] */
// Flap height down the front face (mm)
flap_height = 112;           // [20:1:300]
// Flap inset from each side edge (mm)
flap_side_inset = 5;         // [0:0.5:40]
// Rounded corner radius of the flap (mm)
flap_corner_r = 26;          // [2:1:90]
// How far the flap stands proud of the front face (mm)
flap_proud = 4;              // [1:0.5:20]


/* [Black Detail - global] */
// How deep every black feature cuts into the white surface (mm)
inset_depth = 2.0;           // [0.4:0.1:8]
// How far black features stand proud of the surface (mm)
proud_height = 1.4;          // [0:0.1:6]
// Overlap epsilon so booleans never leave zero-thickness skins (mm)
eps = 0.04;                  // [0.01:0.01:0.2]


/* [Outlined Edges] */
// Cross-section size of the bold outline piping (mm)
pipe_width = 7;              // [1:0.5:20]
// How far the piping band reaches onto each adjoining face from the edge (mm)
edge_mask_band = 6;          // [1:0.5:30]
// Width of the black border ring tracing the flap perimeter (mm)
flap_outline_w = 6;          // [1:0.5:24]


/* [Text] */
// Font (must be installed; Liberation Sans Bold is a close heavy sans)
text_font = "Liberation Sans:style=Bold";   // [Liberation Sans:style=Bold, DejaVu Sans:style=Bold]
text_line1 = "Fake";
text_line2 = "Louis";
text_line3 = "Vuitton";
// Glyph cap height (mm)
text_size = 27;              // [8:1:120]
// Vertical distance between the 3 baselines (mm)
line_spacing = 32;           // [8:1:160]
// Width of the black outline ring around each glyph (mm)
text_outline_w = 3.2;        // [0.5:0.1:14]
// Drop-shadow offset X (mm)
text_shadow_dx = 2.4;        // [-14:0.1:14]
// Drop-shadow offset Z (mm)
text_shadow_dz = -2.4;       // [-14:0.1:14]
// Vertical center of the text block on the flap (mm from body center)
text_block_v = 32;           // [-80:1:120]


/* [Hatch Shading] */
// Turn the comic hatch lines on/off
hatch_on = true;
// Spacing between hatch lines (mm)
hatch_spacing = 5.5;         // [2:0.25:20]
// Hatch line thickness radius (mm)
hatch_r = 1.0;               // [0.3:0.1:4]
// Hatch angle (degrees)
hatch_angle = 45;            // [0:1:90]
// Size of each corner hatch patch (mm)
hatch_patch = 52;            // [10:1:140]


/* [Top Closure] */
// Show a thin zipper seam line along the top opening
zipper_on = true;
// Zipper bead radius (mm)
zipper_r = 2.2;              // [0.5:0.1:8]


/* [Preview Colors] */
white_color = "white";       // [white]
black_color = "#1a1a1a";     // ["#1a1a1a"]


/* [Quality] */
// Facets on the body corner spheres. Export white & black at the SAME quality
// so their shared (flush) surfaces match exactly.
body_fn = 40;                // [12:1:160]
// Facets on small round details
detail_fn = 16;              // [6:1:96]
// Facets used by text() curves
text_fn = 24;                // [6:1:96]


/* [Hidden] */
$fn = 32;
// Set false (via `include`) to suppress the top-level render, e.g. for tests.
run_part = true;

// ============================================================================
//  Geometry
// ============================================================================

text_lines = [text_line1, text_line2, text_line3];

// flap vertical extent (world Z), measured from just under the top edge down
flap_top_z    = body_h/2 - 2;
flap_bottom_z = flap_top_z - flap_height;
flap_center_z = (flap_top_z + flap_bottom_z) / 2;
flap_w        = body_w - 2 * flap_side_inset;

// ---- low-level helpers -----------------------------------------------------

module bar(p1, p2, r) {
    hull() {
        translate(p1) sphere(r, $fn = detail_fn);
        translate(p2) sphere(r, $fn = detail_fn);
    }
}

module rounded_box(sz, r) {
    hull()
        for (sx = [-1, 1]) for (sy = [-1, 1]) for (sz2 = [-1, 1])
            translate([sx*(sz[0]/2 - r), sy*(sz[1]/2 - r), sz2*(sz[2]/2 - r)])
                sphere(r, $fn = detail_fn);
}

// 2D rounded rectangle centered at origin.
module rrect(w, h, r) {
    hull()
        for (sx = [-1, 1]) for (sy = [-1, 1])
            translate([sx*(w/2 - r), sy*(h/2 - r)]) circle(r, $fn = detail_fn);
}

// Rounded-rectangular-prism body. `grow` offsets the surface outward by `grow`.
module body_core(grow = 0) {
    hull()
        for (sx = [-1, 1]) for (sy = [-1, 1]) for (sz = [-1, 1])
            translate([sx*(body_w/2 - r_corner), sy*(body_d/2 - r_corner),
                       sz*(body_h/2 - r_corner)])
                sphere(r_corner + grow, $fn = body_fn);
}

module body_shell(g_out, g_in) {
    difference() { body_core(g_out); body_core(g_in); }
}

// Place 2D children onto the FRONT face (-Y), upright & not mirrored, local +Z
// extruding outward (-Y). `v` shifts vertically; `yoff` pushes the base plane
// outward (e.g. onto the proud flap surface).
module place_on_front(v = 0, yoff = 0) {
    translate([0, -(body_d/2 + yoff), v])
        rotate([90, 0, 0])
            children();
}

// ---- flap (white) ----------------------------------------------------------

module flap_2d() {
    rrect(flap_w, flap_height, flap_corner_r);
}

module flap() {
    place_on_front(flap_center_z)
        translate([0, 0, -eps])
            linear_extrude(height = flap_proud + eps, convexity = 6)
                flap_2d();
}

module white_base() {
    union() { body_core(0); flap(); }
}

// ---- text ------------------------------------------------------------------

module text_lines_2d() {
    for (i = [0:len(text_lines)-1])
        translate([0, (1 - i) * line_spacing, 0])
            text(text_lines[i], size = text_size, font = text_font,
                 halign = "center", valign = "center", $fn = text_fn);
}

module white_glyphs() {
    place_on_front(text_block_v, flap_proud)
        translate([0, 0, -eps])
            linear_extrude(height = proud_height + eps, convexity = 10)
                text_lines_2d();
}

module text_black_2d() {
    difference() { offset(r = text_outline_w) text_lines_2d(); text_lines_2d(); }
    difference() {
        translate([text_shadow_dx, text_shadow_dz]) offset(r = text_outline_w) text_lines_2d();
        offset(r = text_outline_w) text_lines_2d();
    }
}

module black_text() {
    place_on_front(text_block_v, flap_proud)
        translate([0, 0, -inset_depth])
            linear_extrude(height = proud_height + inset_depth, convexity = 10)
                text_black_2d();
}

// ---- black: outlined edges -------------------------------------------------

module edge_frame(band) {
    for (sx = [-1, 1]) for (sy = [-1, 1])
        translate([sx*body_w/2, sy*body_d/2, 0])
            cube([2*band, 2*band, body_h + 4*band], center = true);
    for (sz = [-1, 1]) for (sy = [-1, 1])
        translate([0, sy*body_d/2, sz*body_h/2])
            cube([body_w + 4*band, 2*band, 2*band], center = true);
    for (sz = [-1, 1]) for (sx = [-1, 1])
        translate([sx*body_w/2, 0, sz*body_h/2])
            cube([2*band, body_d + 4*band, 2*band], center = true);
}

module body_piping() {
    intersection() {
        body_shell(proud_height, -inset_depth);
        edge_frame(edge_mask_band);
    }
}

// Black border ring tracing the flap perimeter (the "outlined edge").
module flap_outline() {
    place_on_front(flap_center_z, 0)
        translate([0, 0, -inset_depth])
            linear_extrude(height = flap_proud + proud_height + inset_depth, convexity = 8)
                difference() {
                    offset(r =  flap_outline_w/2) flap_2d();
                    offset(r = -flap_outline_w/2) flap_2d();
                }
}

// ---- black: hatch shading --------------------------------------------------

module hatch_2d(w, h) {
    intersection() {
        square([w, h], center = true);
        rotate(hatch_angle)
            for (i = [-ceil(max(w,h)/hatch_spacing) : ceil(max(w,h)/hatch_spacing)])
                translate([i*hatch_spacing, 0])
                    square([2*hatch_r, 2.4*max(w,h)], center = true);
    }
}

// One hatch patch on the front face at local (cx, cz). on_flap raises it.
module hatch_patch_at(cx, cz, w, h, on_flap = false) {
    place_on_front(cz, on_flap ? flap_proud : 0)
        translate([cx, 0, -inset_depth])
            linear_extrude(height = proud_height + inset_depth, convexity = 6)
                translate([0, 0]) hatch_2d(w, h);
}

module hatching() {
    if (hatch_on) {
        // lower front corners (below the flap), clipped to the body surface
        zc = (-body_h/2 + flap_bottom_z)/2;
        xc = body_w/2 - r_corner - hatch_patch/2 + 4;
        intersection() {
            union() {
                hatch_patch_at(-xc, zc, hatch_patch, hatch_patch);
                hatch_patch_at( xc, zc, hatch_patch, hatch_patch);
            }
            body_core(proud_height);
        }
    }
}

// ---- black: top closure ----------------------------------------------------

module zipper() {
    if (zipper_on) {
        zt = body_h/2;
        run = body_w - 2*r_corner;
        translate([0, 0, -zipper_r + proud_height])
            bar([-run/2, 0, zt], [run/2, 0, zt], zipper_r);
    }
}

// ---- assembly --------------------------------------------------------------

module black_all() {
    body_piping();
    flap_outline();
    black_text();
    hatching();
    zipper();
}

module white_part() {
    union() {
        difference() { white_base(); black_all(); }
        white_glyphs();
    }
}

module black_part() { black_all(); }

// ---- dispatch --------------------------------------------------------------

if (run_part) {
    if (part == "white")
        color(white_color) white_part();
    else if (part == "black")
        color(black_color) black_part();
    else {
        color(white_color) white_part();
        color(black_color) black_part();
    }
}
