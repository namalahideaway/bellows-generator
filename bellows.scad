// ============================================================================
//  PARAMETRIC BELLOWS / WAY-COVER GENERATOR  (MakerWorld customizer edition)
// ----------------------------------------------------------------------------
//  Generates flexible accordion bellows / machine way-covers for 3D printing.
//
//  This is a faithful port of the web tool `standalone.html`: it mirrors the
//  exact same vertex/face math and produces the same watertight shell, so the
//  STL you get here matches the in-browser generator triangle-for-triangle.
//
//  The intended print process (Clough42 / "Functional Print Friday" method):
//  the part is generated in its COLLAPSED state — every pleat squashed into a
//  short flat stack — and printed flat in flexible TPU, laying down PLA / PETG
//  "interface" layers in the fold gaps as throw-away support. After printing
//  you peel the support out of the gaps and the part stretches open into a
//  bellows. The collapsed pitch = wall_thickness + interface_gap, so the
//  support gap is always positive (= the print recipe from the video).
//
//  Reference: https://www.youtube.com/watch?v=eit2H0NPXNg  (Clough42 way covers)
//
//  MakerWorld: upload this .scad to the Parametric Model Maker. Every variable
//  in the groups below shows up as a slider / dropdown / checkbox.
//
//  All units are millimetres / degrees.
// ============================================================================


/* [Print State] */
// flat_layer = Clough42 / FPF Z-fold (prints flat, peel PLA out of gaps). accordion = classic rounded/sharp convolutions.
fold_style = "flat_layer";   // [flat_layer, accordion]
// Geometry to build. Printable form is ALWAYS collapsed; extended is preview only.
state = "collapsed";         // [collapsed, extended]
// Print layer height. Wall + gap should be whole multiples of this. (mm)
layer_height = 0.2;          // [0.08:0.02:0.4]
// Support/interface gap left between stacked folds — what you peel out. >= 1 layer. (mm)
interface_gap = 0.4;         // [0.1:0.05:8]
// Height when stretched open (extended preview only) (mm)
extended_height = 160;       // [10:1:1000]


/* [Shape (bottom)] */
// Cross-section profile of the bellows
cross_section_shape = "rounded_square"; // [circle, square, triangle, rounded_square]
// Width across X at the BOTTOM mouth (mm)
size_x = 60;                 // [5:1:400]
// Depth across Y at the BOTTOM mouth (mm)
size_y = 60;                 // [5:1:400]
// Corner radius at the bottom (rounded_square only) (mm)
corner_radius = 12;          // [0:0.5:200]


/* [Shape (top — for tapered / dust-boot bellows)] */
// Width across X at the TOP mouth. Same as bottom = straight tube. Different = tapered. (mm)
top_size_x = 60;             // [5:1:400]
// Depth across Y at the top mouth (mm)
top_size_y = 60;             // [5:1:400]
// Corner radius at the top (mm)
top_corner_radius = 12;      // [0:0.5:200]


/* [Folds] */
// Number of folds / convolutions
pleat_count = 12;            // [1:1:120]
// How far peaks stick out past valleys — radial fold depth (mm)
pleat_depth = 8;             // [0.5:0.5:60]
// Wall thickness of the flexible bellows body (mm). In TPU typically 2-4 print layers (0.4-0.8 mm).
wall_thickness = 0.8;        // [0.4:0.1:6]
// Wall thickness of the rigid cuffs (collar/flange/socket/lip). Defaults to bellows wall = uniform. Set thicker for more rigid mounting. (mm)
cuff_wall_thickness = 0.8;   // [0.4:0.1:12]
// Fold cross-section (accordion only)
fold_profile = "sharp";      // [sharp, round, trapezoid]
// Flat dwell at peaks/valleys, fraction of half-pleat (accordion + trapezoid only)
tip_flat_fraction = 0.25;    // [0:0.01:0.45]
// Start the first fold on a peak (outer) instead of a valley
start_with_peak = false;


/* [Bottom Connector] */
// none | collar (straight tube) | flange (flat mounting plate) | socket (slip-fit) | lip (snap)
bottom_connector = "collar"; // [none, collar, flange, socket, lip]
// Connector length / height (mm)
bottom_length = 6;           // [0:0.5:80]
// Flange / lip overhang length (flange or lip) (mm)
bottom_flange_length = 8;    // [1:0.5:60]
// Flange plate thickness (flange only) (mm)
bottom_flange_thickness = 2; // [0.4:0.1:12]
// Slip-fit radial clearance (socket only) (mm)
bottom_socket_clearance = 0.4; // [0:0.1:5]


/* [Top Connector] */
// none | collar | flange | socket | lip
top_connector = "collar";    // [none, collar, flange, socket, lip]
// Connector length / height (mm)
top_length = 6;              // [0:0.5:80]
// Flange / lip overhang length (flange or lip) (mm)
top_flange_length = 8;       // [1:0.5:60]
// Flange plate thickness (flange only) (mm)
top_flange_thickness = 2;    // [0.4:0.1:12]
// Slip-fit radial clearance (socket only) (mm)
top_socket_clearance = 0.4;  // [0:0.1:5]


/* [Variant] */
// full = closed tube. open_back = U-channel way-cover, open arc against the column (+Y).
variant = "full";            // [full, open_back]
// Fraction of the perimeter left open at the back (open_back only)
open_back_fraction = 0.25;   // [0.05:0.01:0.49]


/* [Quality] */
// Facets around a circle profile
circle_facets = 64;          // [12:1:256]
// Facets per rounded corner (rounded_square)
corner_facets = 10;          // [1:1:48]
// Z subdivisions per pleat (accordion; higher = smoother round/trapezoid)
segments_per_pleat = 8;      // [2:2:48]


/* [Hidden] */
// Reverse polyhedron face winding. The ported mesh is built outward-CCW (STL
// style); OpenSCAD wants CW-from-outside, so faces are reversed by default.
flip_winding = true;
// Force a full CGAL Nef render (manifold + self-intersection validation).
// Left false so previews/exports stay fast; the raw polyhedron is already a
// valid manifold. Set true (or just use F6 / MakerWorld export) to validate.
render_check = false;
$fn = 64;

// ============================================================================
//  Below here is geometry — none of it shows up in the customizer.
//  It is a 1:1 port of the functions in standalone.html.
// ============================================================================

function clampv(x, lo, hi) = max(lo, min(hi, x));
function frac(x) = x - floor(x);
function hyp(dx, dy) = sqrt(dx*dx + dy*dy);

// ---- 2D base cross-section (CCW points, centred on origin) -----------------
function rrect(w, h, r, seg) =
    let (rr = clampv(r, 0, min(w/2, h/2)),
         cx = w/2 - rr, cy = h/2 - rr,
         corners = [[cx,-cy,-90],[cx,cy,0],[-cx,cy,90],[-cx,-cy,180]])
    [ for (c = [0:3]) for (i = [0:seg])
        let (a = corners[c][2] + i*90/seg)
        [ corners[c][0] + rr*cos(a), corners[c][1] + rr*sin(a) ] ];

function base_profile(shape, sx, sy, cr, fn, cfn) =
    shape == "circle"         ? [ for (i = [0:fn-1]) let (a = i*360/fn) [ (sx/2)*cos(a), (sy/2)*sin(a) ] ] :
    shape == "triangle"       ? [ [-sx/2,-sy/2], [sx/2,-sy/2], [0,sy/2] ] :
    shape == "rounded_square" ? rrect(sx, sy, cr, cfn) :
                                [ [-sx/2,-sy/2], [sx/2,-sy/2], [sx/2,sy/2], [-sx/2,sy/2] ];

// ---- mitred offset of a convex CCW polygon (matches OpenSCAD offset(delta)) -
function edge_normal(a, b) =
    let (dx = b[0]-a[0], dy = b[1]-a[1], L = max(1e-9, hyp(dx,dy)))
    [ dy/L, -dx/L ];

function line_intersect(p, dp, q, dq) =
    let (den = dp[0]*dq[1] - dp[1]*dq[0])
    abs(den) < 1e-9 ? undef
    : let (t = ((q[0]-p[0])*dq[1] - (q[1]-p[1])*dq[0]) / den)
      [ p[0] + t*dp[0], p[1] + t*dp[1] ];

function offset_vertex(pts, d, j) =
    let (n = len(pts),
         e0 = (j-1+n)%n,
         A = pts[(j-1+n)%n], B = pts[j], C = pts[(j+1)%n],
         enE0 = edge_normal(pts[e0], pts[(e0+1)%n]),
         enJ  = edge_normal(pts[j],  pts[(j+1)%n]),
         p0 = [ B[0] + d*enE0[0], B[1] + d*enE0[1] ],
         p1 = [ B[0] + d*enJ[0],  B[1] + d*enJ[1] ],
         hit = line_intersect(p0, [B[0]-A[0], B[1]-A[1]], p1, [C[0]-B[0], C[1]-B[1]]))
    hit != undef ? hit
    : let (nx = (enE0[0]+enJ[0])/2, ny = (enE0[1]+enJ[1])/2, LL = max(1e-9, hyp(nx,ny)))
      [ B[0] + d*nx/LL, B[1] + d*ny/LL ];

function offset_polygon(pts, d) =
    abs(d) < 1e-9 ? pts
    : [ for (j = [0:len(pts)-1]) offset_vertex(pts, d, j) ];

// ---- fold profile -> radial offset over one pleat (f in [0,1)) -------------
function trap_shape(f, ff) =
    let (ff2 = clampv(ff, 0, 0.24), span = 0.5 - 2*ff2)
    f < ff2       ? 0 :
    f < 0.5 - ff2 ? (f - ff2)/span :
    f < 0.5 + ff2 ? 1 :
    f < 1 - ff2   ? 1 - (f - (0.5 + ff2))/span :
                    0;

function pleat_delta(f, depth, profile, tip) =
    profile == "round"     ? depth * (0.5 - 0.5*cos(360*f)) :
    profile == "trapezoid" ? depth * trap_shape(f, tip) :
                             depth * (1 - abs(2*f - 1));

// ---- connector points appended to the meridian (list of [u,z,w]) -----------
function connector_pts(type, isBottom, attachZ, wall, len, fl, ft, so) =
    type == "none" ? [] :
    isBottom ? (
        type == "collar" ? [ [0,attachZ-len,wall], [0,attachZ,wall] ] :
        type == "socket" ? [ [so,attachZ-len,wall], [so,attachZ,wall], [0,attachZ,wall] ] :
        type == "flange" ? [ [fl,attachZ-len,ft], [0,attachZ-len,ft], [0,attachZ,wall] ] :
        type == "lip"    ? [ [fl,attachZ-len,wall], [0,attachZ-len,wall], [0,attachZ,wall] ] : []
    ) : (
        type == "collar" ? [ [0,attachZ,wall], [0,attachZ+len,wall] ] :
        type == "socket" ? [ [0,attachZ,wall], [so,attachZ,wall], [so,attachZ+len,wall] ] :
        type == "flange" ? [ [0,attachZ,wall], [0,attachZ+len,wall], [fl,attachZ+len,ft] ] :
        type == "lip"    ? [ [0,attachZ,wall], [0,attachZ+len,wall], [fl,attachZ+len,wall] ] : []
    );

// ---- fold meridian points (list of [u,z,w]) --------------------------------
function flat_layer_pts(nHalf, ph, depth, wall, dz) =
    [ for (k = [0:nHalf-1]) each
        let (tU = ((k+ph)%2 == 0) ? depth : 0)
        [ [tU, k*dz, wall], [tU, (k+1)*dz, wall] ] ];

function accordion_pts(pleatCount, seg, pitch, ph, depth, profile, tip, wall) =
    [ for (i = [1:pleatCount*seg])
        [ pleat_delta(frac(i/seg + ph), depth, profile, tip), (i/seg)*pitch, wall ] ];

// Collapsed fold pitch = one TPU wall + one interface/support gap, so the gap
// the slicer fills with peel-away support is ALWAYS positive (the print recipe).
function dz_value() =
    max(0.05, state == "collapsed"
        ? (wall_thickness + interface_gap)
        : extended_height / (2*max(1, pleat_count)));

// raw meridian before normalise / dedupe
function raw_meridian() =
    let (wall = wall_thickness, depth = pleat_depth, dz = dz_value(),
         nHalf = 2*pleat_count,
         botC = connector_pts(bottom_connector, true, 0, cuff_wall_thickness, bottom_length,
                              bottom_flange_length, bottom_flange_thickness,
                              bottom_socket_clearance + cuff_wall_thickness),
         needSeed = (len(botC) == 0) ||
                    abs(botC[len(botC)-1][0]) > 1e-9 ||
                    abs(botC[len(botC)-1][1]) > 1e-9,
         seed = needSeed ? [ [0,0,wall] ] : [],
         folds = fold_style == "flat_layer"
            ? flat_layer_pts(nHalf, start_with_peak ? 1 : 0, depth, wall, dz)
            : accordion_pts(pleat_count, max(2, segments_per_pleat), 2*dz,
                            start_with_peak ? 0.5 : 0, depth, fold_profile,
                            tip_flat_fraction, wall),
         pre = concat(botC, seed, folds),
         pleatTop = pre[len(pre)-1][1],
         topC = connector_pts(top_connector, false, pleatTop, cuff_wall_thickness, top_length,
                             top_flange_length, top_flange_thickness,
                             top_socket_clearance + cuff_wall_thickness))
    concat(pre, topC);

// normalise so the lowest surface sits at z=0, then drop consecutive dups
function build_meridian() =
    let (M0 = raw_meridian(),
         minz = min([ for (i = [0:len(M0)-1]) M0[i][1] - M0[i][2]/2 ]),
         M = [ for (i = [0:len(M0)-1]) [ M0[i][0], M0[i][1]-minz, M0[i][2] ] ])
    [ for (i = [0:len(M)-1])
        if (i == 0 ||
            abs(M[i][0]-M[i-1][0]) > 1e-7 ||
            abs(M[i][1]-M[i-1][1]) > 1e-7 ||
            abs(M[i][2]-M[i-1][2]) > 1e-7)
          M[i] ];

// ---- perimeter index selection (full loop, or open arc against +Y) ---------
function ang_from_top(p) = abs(((atan2(p[1],p[0]) - 90) % 360 + 540) % 360 - 180);
function keep_list(base, half) = [ for (i = [0:len(base)-1]) ang_from_top(base[i]) > half ];
function find_start(keep, n, i=0) =
    i >= n ? -1
    : (keep[i] && !keep[(i-1+n)%n]) ? i
    : find_start(keep, n, i+1);
function take_run(keep, n, start, c=0) =
    c >= n ? []
    : let (i = (start+c)%n)
      keep[i] ? concat([i], take_run(keep, n, start, c+1)) : [];

function perim_idx(base) =
    (variant != "open_back" || open_back_fraction <= 0)
        ? [ for (i = [0:len(base)-1]) i ]
        : let (n = len(base), half = min(0.49, open_back_fraction)*180,
               keep = keep_list(base, half), start = find_start(keep, n))
          start < 0 ? [ for (i = [0:len(base)-1]) i ] : take_run(keep, n, start);

function perim_closed(base) =
    (variant != "open_back" || open_back_fraction <= 0) ? true
    : let (n = len(base), half = min(0.49, open_back_fraction)*180,
           keep = keep_list(base, half))
      find_start(keep, n) < 0 ? true : false;

// ---- sweep meridian around base -> outer & inner 3D rings ------------------
function level_normal_uz(M, i) =
    let (L = len(M), pa = M[max(0,i-1)], pb = M[min(L-1,i+1)],
         tu = pb[0]-pa[0], tz = pb[1]-pa[1], tl = max(1e-9, hyp(tu,tz)))
    [ tz/tl, -(tu/tl) ];   // [nu, nz]

function level_outer(base, idx, M, i) =
    let (nrm = level_normal_uz(M, i), nu = nrm[0], nz = nrm[1], hw = M[i][2]/2,
         ro = offset_polygon(base, M[i][0] + nu*hw), zo = M[i][1] + nz*hw)
    [ for (t = [0:len(idx)-1]) [ ro[idx[t]][0], ro[idx[t]][1], zo ] ];

function level_inner(base, idx, M, i) =
    let (nrm = level_normal_uz(M, i), nu = nrm[0], nz = nrm[1], hw = M[i][2]/2,
         ri = offset_polygon(base, M[i][0] - nu*hw), zi = M[i][1] - nz*hw)
    [ for (t = [0:len(idx)-1]) [ ri[idx[t]][0], ri[idx[t]][1], zi ] ];

// ---- assemble polyhedron points + faces ------------------------------------
function flatten(ll) = [ for (a = ll) for (b = a) b ];

module bellows() {
    // Bottom base — used ONLY for perimeter-index pattern (count + ordering).
    // Per-level absolute coords are recomputed below by lerping cross-section
    // dimensions from bottom to top, so the bellows can taper (dust-boot form).
    base   = base_profile(cross_section_shape, size_x, size_y, corner_radius,
                          circle_facets, corner_facets);
    idx    = perim_idx(base);
    closed = perim_closed(base);
    m      = len(idx);
    M      = build_meridian();
    L      = len(M);
    zmin   = min([ for (i=[0:L-1]) M[i][1] - M[i][2]/2 ]);
    zmax   = max([ for (i=[0:L-1]) M[i][1] + M[i][2]/2 ]);
    zspan  = max(1e-9, zmax - zmin);

    outer  = [ for (i = [0:L-1])
                 let (tt = (M[i][1] - zmin) / zspan,
                      sx = size_x       + (top_size_x       - size_x)       * tt,
                      sy = size_y       + (top_size_y       - size_y)       * tt,
                      cr = corner_radius + (top_corner_radius - corner_radius) * tt,
                      base_lvl = base_profile(cross_section_shape, sx, sy, cr, circle_facets, corner_facets))
                 level_outer(base_lvl, idx, M, i) ];
    inner  = [ for (i = [0:L-1])
                 let (tt = (M[i][1] - zmin) / zspan,
                      sx = size_x       + (top_size_x       - size_x)       * tt,
                      sy = size_y       + (top_size_y       - size_y)       * tt,
                      cr = corner_radius + (top_corner_radius - corner_radius) * tt,
                      base_lvl = base_profile(cross_section_shape, sx, sy, cr, circle_facets, corner_facets))
                 level_inner(base_lvl, idx, M, i) ];
    points = concat(flatten(outer), flatten(inner));

    // index helpers into `points`
    // O(i,t) = i*m + t ; I(i,t) = L*m + i*m + t
    span = closed ? m : m-1;

    wall_faces = [ for (i = [0:L-2]) for (t = [0:span-1])
        let (k = closed ? (t+1)%m : t+1,
             Oit = i*m+t, Oik = i*m+k, Oi1t = (i+1)*m+t, Oi1k = (i+1)*m+k,
             Iit = L*m+i*m+t, Iik = L*m+i*m+k, Ii1t = L*m+(i+1)*m+t, Ii1k = L*m+(i+1)*m+k)
        each [
            [Oit, Oik, Oi1k], [Oit, Oi1k, Oi1t],   // outer wall
            [Iit, Ii1t, Ii1k], [Iit, Ii1k, Iik]    // inner wall
        ] ];

    // open-arc caps. standalone.html wound these OPPOSITE to the walls — the
    // mesh is still edge-2-manifold (its own watertight test passes) but the
    // faces are not consistently oriented, so CGAL rejects it as "not closed".
    // We reverse every open-cap triangle so it orients with the walls; parity
    // is winding-independent, so the exported triangles are still identical.
    open_caps = concat(
        [ for (t = [0:m-2]) let (
            Ot=0*m+t, Ot1=0*m+t+1, It=L*m+0*m+t, It1=L*m+0*m+t+1)
            each [ [Ot, Ot1, It1], [Ot, It1, It] ] ],                       // bottom ribbon
        [ for (t = [0:m-2]) let (
            Ot=(L-1)*m+t, Ot1=(L-1)*m+t+1, It=L*m+(L-1)*m+t, It1=L*m+(L-1)*m+t+1)
            each [ [Ot, It, It1], [Ot, It1, Ot1] ] ],                       // top ribbon
        [ for (i = [0:L-2]) let (
            O0=i*m+0, O10=(i+1)*m+0, I0=L*m+i*m+0, I10=L*m+(i+1)*m+0,
            Oe=i*m+m-1, O1e=(i+1)*m+m-1, Ie=L*m+i*m+m-1, I1e=L*m+(i+1)*m+m-1)
            each [
                [O0, I0, I10], [O0, I10, O10],                              // cut wall t=0
                [Oe, O1e, I1e], [Oe, I1e, Ie]                               // cut wall t=m-1
            ] ]
    );

    cap_faces = closed
        ? concat(
            [ for (t = [0:m-1]) let (k=(t+1)%m,
                Ot=0*m+t, Ok=0*m+k, It=L*m+0*m+t, Ik=L*m+0*m+k)
                each [ [Ot, It, Ik], [Ot, Ik, Ok] ] ],                      // bottom ring
            [ for (t = [0:m-1]) let (k=(t+1)%m,
                Ot=(L-1)*m+t, Ok=(L-1)*m+k, It=L*m+(L-1)*m+t, Ik=L*m+(L-1)*m+k)
                each [ [Ot, Ok, Ik], [Ot, Ik, It] ] ]                       // top ring
          )
        : [ for (f = open_caps) [ f[0], f[2], f[1] ] ];                     // reversed

    raw_faces = concat(wall_faces, cap_faces);
    faces = flip_winding
        ? [ for (f = raw_faces) [ f[0], f[2], f[1] ] ]
        : raw_faces;

    polyhedron(points = points, faces = faces, convexity = 12);
}

// render_check forces a real CGAL boolean (intersection with a huge cube),
// which converts the polyhedron to a Nef solid and so rejects any
// non-manifold / self-intersecting input — i.e. the same validation
// MakerWorld's CGAL kernel performs. Default off so previews stay instant.
module bellows_validated() {
    intersection() {
        bellows();
        translate([-5000, -5000, -5000]) cube(10000);
    }
}

// Printability guidance. The slider minimums keep interface_gap > 0, so the
// folds can never fuse into a solid block; these just flag fragile choices.
echo(str("Collapsed fold pitch = ", wall_thickness + interface_gap,
         " mm  (wall ", wall_thickness, " + gap ", interface_gap,
         " = ", interface_gap / layer_height, " support layers)"));
if (state == "collapsed" && interface_gap < layer_height)
    echo("WARNING: interface_gap < one layer — support can't print between folds; they will fuse. Increase interface_gap.");
if (wall_thickness < 2 * layer_height)
    echo("WARNING: wall_thickness is under 2 layers — likely too fragile to peel.");

if (render_check) bellows_validated(); else bellows();
