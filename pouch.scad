// ============================================================================
//  PARAMETRIC "FAKE LOUIS VUITTON" POUCH  (MakerWorld customizer edition)
// ----------------------------------------------------------------------------
//  A stylized two-color toiletry pouch recreated from a reference line-art
//  drawing. The model is split into a WHITE part and a BLACK part that share
//  the same origin and never overlap, so exporting each as its own STL keeps
//  the colors when you assign two filaments in Bambu Studio / PrusaSlicer.
//
//  The core guarantee:  white = body - black,  black = black.
//  Because the white body literally has every black solid carved out of it,
//  the two parts share no volume and meet on exactly coincident surfaces.
//
//  Coordinate system (all units mm / degrees):
//    X = width  (285)   left  <-> right
//    Z = height (180)   down  <-> up
//    Y = depth  (120)   back  <-> FRONT (+Y is the lettered face)
//
//  Export the two parts:
//    openscad -D 'part="white"' -o pouch_white.stl pouch.scad
//    openscad -D 'part="black"' -o pouch_black.stl pouch.scad
//  Then import both into Bambu Studio (same origin = already aligned),
//  assign white & black filaments.
//
//  Render reference views for parity checking (the lettered face is -Y):
//    openscad -D 'part="both"' --camera=0,0,0,90,0,0,750   --imgsize=900,600 -o front.png  pouch.scad
//    openscad -D 'part="both"' --camera=0,0,0,68,0,-28,830 --imgsize=900,700 -o tq.png     pouch.scad
//    openscad -D 'part="both"' --camera=0,0,0,200,0,0,800  --imgsize=900,600 -o bottom.png pouch.scad
//  (headless: prefix with `xvfb-run -a`)
// ============================================================================


/* [Part Selection] */
// Which part to render / export. "both" is a colored preview only.
part = "both";               // [white, black, both]


/* [Overall Dimensions] */
// Width across X (mm)
body_w = 285;                // [50:1:600]
// Height across Z (mm)
body_h = 180;                // [50:1:400]
// Depth across Y, front-to-back (mm)
body_d = 120;                // [20:1:300]


/* [Body Shape] */
// Corner radius at the TOP (soft rounded top) (mm)
r_top = 12;                  // [2:1:90]
// Corner radius at the BOTTOM (flatter so it sits) (mm)
r_bot = 8;                   // [2:1:80]


/* [Black Detail - global] */
// How deep every black feature cuts into the white body (mm)
inset_depth = 2.0;           // [0.4:0.1:8]
// How far black features stand proud of the surface (mm)
proud_height = 1.4;          // [0:0.1:6]
// Overlap epsilon so booleans never leave zero-thickness skins (mm)
eps = 0.04;                  // [0.01:0.01:0.2]


/* [Edge Piping / Outline] */
// Cross-section size of the cartoon outline piping (mm)
pipe_width = 8;              // [1:0.5:20]
// How far the piping band reaches onto each adjoining face from the edge (mm)
edge_mask_band = 6.5;        // [1:0.5:30]


/* [Zipper] */
// Diameter of the zipper backbone bead (mm)
zipper_width = 9;            // [2:0.5:24]
// Spacing between teeth along the zipper (mm)
zipper_tooth_pitch = 7;      // [2:0.5:30]
// Tooth size (mm)
zipper_tooth_size = 4;       // [1:0.25:14]
// Pull-tab position along the top, 0=left 1=right
pull_tab_x_frac = 0.80;      // [0.05:0.01:0.95]
// Pull-tab outer width (mm)
pull_tab_w = 26;             // [4:0.5:60]
// Pull-tab outer height (mm)
pull_tab_h = 34;             // [4:0.5:80]
// Pull-tab ring thickness (mm)
pull_tab_ring = 5;           // [1:0.25:14]


/* [Text] */
// Font (must be installed; Liberation Sans Bold is a close heavy sans)
text_font = "Liberation Sans:style=Bold";   // [Liberation Sans:style=Bold, DejaVu Sans:style=Bold]
text_line1 = "Fake";
text_line2 = "Louis";
text_line3 = "Vuitton";
// Glyph cap height (mm)
text_size = 32;              // [10:1:120]
// Vertical distance between the 3 baselines (mm)
line_spacing = 40;           // [10:1:160]
// Left margin: distance from the left edge to the start of the text (mm)
text_margin = 34;            // [0:1:160]
// Width of the black outline ring around each glyph (mm)
text_outline_w = 4;          // [0.5:0.1:14]
// Drop-shadow offset X (mm)
text_shadow_dx = 3;          // [-14:0.1:14]
// Drop-shadow offset Z (mm)
text_shadow_dz = -3;         // [-14:0.1:14]
// Vertical center of the whole text block on the front face (mm from center)
text_block_v = 14;           // [-80:1:80]


/* [Stitching] */
// Length of each stitch dash (mm)
stitch_dash_len = 5;         // [1:0.25:20]
// Gap between dashes (mm)
stitch_gap = 4;              // [1:0.25:20]
// Stitch thread radius (mm)
stitch_r = 1.1;             // [0.3:0.1:5]
// How far the stitch line is inset from the panel edge (mm)
stitch_inset = 13;           // [2:0.5:60]


/* [Bottom Feet] */
// Number of feet/studs along the bottom
foot_count = 5;              // [0:1:12]
// Foot diameter (mm)
foot_d = 16;                 // [4:0.5:40]
// Foot height proud of the base (mm)
foot_h = 6;                  // [1:0.5:20]
// How far the foot row is inset from the long bottom edge (mm)
foot_inset = 24;             // [4:1:80]


/* [Preview Colors] */
white_color = "white";       // [white]
black_color = "#1a1a1a";     // ["#1a1a1a"]


/* [Quality] */
// Facets on the body corner spheres. NOTE: export white & black at the SAME
// quality settings so their shared (flush) surfaces match exactly.
body_fn = 36;                // [12:1:160]
// Facets on small round details
detail_fn = 16;              // [6:1:96]
// Facets used by text() curves
text_fn = 24;                // [6:1:96]


/* [Hidden] */
$fn = 32;
// Set false (via `include`) to suppress the top-level render, e.g. for tests.
run_part = true;

// ============================================================================
//  Below here is geometry — none of it shows up in the customizer.
// ============================================================================

text_lines = [text_line1, text_line2, text_line3];

// ---- low-level helpers -----------------------------------------------------

// Rounded capsule between two 3D points.
module bar(p1, p2, r) {
    hull() {
        translate(p1) sphere(r, $fn = detail_fn);
        translate(p2) sphere(r, $fn = detail_fn);
    }
}

// Axis-aligned rounded box of size sz with corner radius r.
module rounded_box(sz, r) {
    hull()
        for (sx = [-1, 1]) for (sy = [-1, 1]) for (sz2 = [-1, 1])
            translate([sx * (sz[0]/2 - r), sy * (sz[1]/2 - r), sz2 * (sz[2]/2 - r)])
                sphere(r, $fn = detail_fn);
}

// The rounded-brick body. `grow` offsets the whole surface outward by `grow`
// (centers stay put, only radii grow), so it doubles as an offset operator.
module body_core(grow = 0) {
    hull() {
        for (sx = [-1, 1]) for (sy = [-1, 1]) {
            // top corners (soft)
            translate([sx * (body_w/2 - r_top), sy * (body_d/2 - r_top), body_h/2 - r_top])
                sphere(r_top + grow, $fn = body_fn);
            // bottom corners (flatter)
            translate([sx * (body_w/2 - r_bot), sy * (body_d/2 - r_bot), -(body_h/2 - r_bot)])
                sphere(r_bot + grow, $fn = body_fn);
        }
    }
}

// A thin shell straddling the body surface (g_in < 0 inside, g_out > 0 outside).
module body_shell(g_out, g_in) {
    difference() {
        body_core(g_out);
        body_core(g_in);
    }
}

// Place 2D children onto the FRONT face (-Y), upright and not mirrored, with
// local +Z extruding outward (-Y). Designed to read correctly from OpenSCAD's
// standard front camera [90,0,0] (X right, Z up). v shifts the block vertically.
module place_on_front(v = 0) {
    translate([0, -body_d/2, v])
        rotate([90, 0, 0])
            children();
}

// ---- WHITE: text glyph faces ----------------------------------------------

module text_lines_2d() {
    translate([-body_w/2 + text_margin, 0, 0])
        for (i = [0:len(text_lines)-1])
            translate([0, (1 - i) * line_spacing, 0])
                text(text_lines[i], size = text_size, font = text_font,
                     halign = "left", valign = "center", $fn = text_fn);
}

module white_glyphs() {
    place_on_front(text_block_v)
        translate([0, 0, -eps])
            linear_extrude(height = proud_height + eps, convexity = 10)
                text_lines_2d();
}

// ---- BLACK features --------------------------------------------------------

// Cartoon outline piping along all 12 edges.
module edge_frame(band) {
    // vertical edges
    for (sx = [-1, 1]) for (sy = [-1, 1])
        translate([sx * body_w/2, sy * body_d/2, 0])
            cube([2*band, 2*band, body_h + 4*band], center = true);
    // edges running along X (top/bottom of front & back faces)
    for (sz = [-1, 1]) for (sy = [-1, 1])
        translate([0, sy * body_d/2, sz * body_h/2])
            cube([body_w + 4*band, 2*band, 2*band], center = true);
    // edges running along Y (top/bottom of left & right faces)
    for (sz = [-1, 1]) for (sx = [-1, 1])
        translate([sx * body_w/2, 0, sz * body_h/2])
            cube([2*band, body_d + 4*band, 2*band], center = true);
}

module piping() {
    intersection() {
        body_shell(proud_height, -inset_depth);
        edge_frame(edge_mask_band);
    }
}

// Top zipper: backbone bead + teeth + pull tab.
module zipper() {
    zt = body_h/2;
    run = body_w - 2*r_top;     // flat run along the top
    // backbone bead, sunk so it straddles the top surface
    translate([0, 0, -zipper_width/2 + proud_height])
        bar([-run/2, 0, zt], [run/2, 0, zt], zipper_width/2);
    // teeth, alternating sides of the center line
    n = floor(run / zipper_tooth_pitch);
    for (i = [0:n]) {
        x = -run/2 + i * zipper_tooth_pitch;
        off = (i % 2 == 0) ? 1 : -1;
        translate([x, off * zipper_tooth_size * 0.55, zt + proud_height - zipper_tooth_size/2])
            rotate([0, 0, 25 * off])
                cube([zipper_tooth_size * 0.7, zipper_tooth_size * 1.4, zipper_tooth_size],
                     center = true);
    }
    zipper_pull();
}

module zipper_pull() {
    zt = body_h/2;
    px = (body_w/2 - r_top) * pull_tab_x_frac;
    translate([px, 0, zt + proud_height]) {
        // slider body sitting astride the zipper
        rounded_box([pull_tab_w * 0.55, zipper_width * 1.5, zipper_width], 2);
        // flat pull tab standing up (thin in Y), with a finger hole
        translate([0, 0, pull_tab_h * 0.5])
            rotate([90, 0, 0])
                difference() {
                    rounded_box([pull_tab_w, pull_tab_h, pull_tab_ring], pull_tab_w * 0.35);
                    translate([0, pull_tab_h * 0.12, 0])
                        cylinder(h = pull_tab_ring + 2*eps, center = true,
                                 d = min(pull_tab_w, pull_tab_h) * 0.5, $fn = detail_fn);
                }
    }
}

// Black text: outline ring + drop shadow (disjoint from the white glyphs).
module text_black_2d() {
    // outline ring = outset glyphs minus glyphs
    difference() {
        offset(r = text_outline_w) text_lines_2d();
        text_lines_2d();
    }
    // drop shadow = shifted outset, minus the outline footprint (and glyphs)
    difference() {
        translate([text_shadow_dx, text_shadow_dz]) offset(r = text_outline_w) text_lines_2d();
        offset(r = text_outline_w) text_lines_2d();
    }
}

module black_text() {
    place_on_front(text_block_v)
        translate([0, 0, -inset_depth])
            linear_extrude(height = proud_height + inset_depth, convexity = 10)
                text_black_2d();
}

// Dashed stitch line between two 3D points.
module stitch_line(p1, p2) {
    d = norm([p2[0]-p1[0], p2[1]-p1[1], p2[2]-p1[2]]);
    step = stitch_dash_len + stitch_gap;
    n = floor(d / step);
    dir = [(p2[0]-p1[0])/d, (p2[1]-p1[1])/d, (p2[2]-p1[2])/d];
    for (i = [0:n]) {
        a = [p1[0]+dir[0]*i*step, p1[1]+dir[1]*i*step, p1[2]+dir[2]*i*step];
        b = [a[0]+dir[0]*stitch_dash_len, a[1]+dir[1]*stitch_dash_len, a[2]+dir[2]*stitch_dash_len];
        bar(a, b, stitch_r);
    }
}

// Stitching around the front-face panel and the bottom panel.
module stitching() {
    yf = -body_d/2 - proud_height + stitch_r;
    xL = body_w/2 - stitch_inset; zT = body_h/2 - stitch_inset;
    // front perimeter
    stitch_line([-xL, yf,  zT], [ xL, yf,  zT]);
    stitch_line([-xL, yf, -zT], [ xL, yf, -zT]);
    stitch_line([-xL, yf, -zT], [-xL, yf,  zT]);
    stitch_line([ xL, yf, -zT], [ xL, yf,  zT]);
    // bottom perimeter
    zb = -body_h/2 - proud_height + stitch_r;
    yB = body_d/2 - stitch_inset;
    stitch_line([-xL, -yB, zb], [ xL, -yB, zb]);
    stitch_line([-xL,  yB, zb], [ xL,  yB, zb]);
}

// Bottom feet/studs.
module feet() {
    if (foot_count > 0) {
        zb = -body_h/2;
        span = body_w - 2*r_bot - foot_d;
        ystud = -(body_d/2 - foot_inset);
        for (i = [0:foot_count-1]) {
            x = (foot_count == 1) ? 0 : -span/2 + i * span/(foot_count-1);
            translate([x, ystud, zb - foot_h + inset_depth])
                cylinder(h = foot_h + eps, d = foot_d, $fn = detail_fn);
        }
    }
}

// Everything black, unioned once so the white carve is a single difference.
module black_all() {
    piping();
    zipper();
    black_text();
    stitching();
    feet();
}

// ---- parts -----------------------------------------------------------------

module white_part() {
    union() {
        difference() {
            body_core(0);
            black_all();
        }
        white_glyphs();
    }
}

module black_part() {
    black_all();
}

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
