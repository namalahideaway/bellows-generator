# Parametric Bellows / Way-Cover Generator

A parametric generator for 3D-printable **bellows / machine way covers**, designed
to be published on MakerWorld so people can generate and print their own.

## What this is (and the video it's based on)

It recreates the **3D-printed accordion way covers** James (Clough42) makes in
[*"Good Idea? I 3D Printed Custom Way Covers For My Milling Machine!"*](https://www.youtube.com/watch?v=eit2H0NPXNg),
which itself uses the **TPU + interface-layer** trick popularised by *Functional
Print Friday*. The key ideas, taken from the video:

- A machine way cover is a flexible accordion sleeve that goes **over the ways**
  of a mill/lathe axis and **completely encloses** them (top *and* sides) so
  chips and coolant can't reach the bearing surfaces. It's mounted to a bracket
  at each end and **collapses in a controlled way** as the axis moves.
- It is printed **flat, fully collapsed** — every pleat squashed into a short
  stack — in flexible **TPU**. A second material (Clough42 used **PLA**, then
  **PETG** for the carbon-fibre "Fiberflex CF" TPU) is printed as **interface /
  support layers in the fold gaps**. The two don't bond, so after printing you
  **peel the support out of the gaps** and the part stretches open into a bellows.
- Cross-sections are a constant-width loop around the dovetail (Clough42 used a
  rounded rectangle, ~30 mm wall height, e.g. 10 mm inner / 40 mm outer radius);
  walls are just **2–3 print layers** thick (0.4–0.6 mm) so they stay flexible.
- The cover is open at the back (against the column) — that's the `open_back`
  **U-channel** variant here. Mounting is via flat end caps + sheet-metal
  brackets — that's what the `flange` / `collar` / `socket` / `lip` connectors are.
- Real-world gotcha from the video: a rectangular bellows with smooth (un-pleated)
  corners pulls its side walls inward as it stretches, so leave clearance around
  the part it covers (or add corner relief).

## Deliverables

| File | What it is | Status |
|------|-----------|--------|
| `bellows/bellows.scad` | **MakerWorld customizer model.** Faithful port of the web tool to OpenSCAD. | ✅ Done & verified |
| `bellows/web/standalone.html` | **Self-contained web generator** (Three-free inline WebGL, no CDN). Source of truth. | ✅ Working |
| `bellows/web/index.html` | Redirects to `standalone.html`. | ✅ |
| `verify/` | Node + OpenSCAD verification harness. | ✅ |

The old modular web build (`app.js`, `geometry.js`, `style.css`) was the stale
pre-`open_back` version and has been removed.

## Using it

**On MakerWorld:** upload `bellows/bellows.scad` to the Parametric Model Maker.
Every parameter (fold style, cross-section, folds, both end connectors, variant,
quality) appears as a slider / dropdown. The model is generated **collapsed**
(printable). Slice it flat in TPU with a non-bonding interface/support material
(PLA for plain TPU; PETG for CF-TPU). In the slicer set support **Z-distance and
interface spacing to 0** so the support fills the model's built-in fold gaps and
forms a clean separable face; after printing, peel the support out of the folds.

**In a browser / on a phone:** open `bellows/web/standalone.html` directly and
hit **Download STL (collapsed)**. No internet needed.

The `.scad` and the web tool produce the **same mesh, triangle-for-triangle**
(verified — see below), so the in-browser preview matches the MakerWorld output.

## Modeled to the print recipe (so it actually prints)

The collapsed fold **pitch is not a free value** — it is built as

```
fold pitch = wall_thickness + interface_gap
```

so the gap the slicer fills with peel-away support is exactly `interface_gap`,
an independent, always-positive parameter. This matters: in the earlier model
the spacing was independent, so picking `wall ≥ spacing` collapsed the membranes
into a **fused solid block** — still watertight and CGAL-valid, but unprintable
(no gap to peel, no bellows). That class of mistake is now impossible to express.
`layer_height` is exposed too, and both tools warn if `interface_gap` drops below
one layer (support can't print) or the wall is under two layers (too fragile to
peel). A cross-section of the default collapsed part — stacked TPU membranes with
clean support gaps between them — is in `out/img/xsection_default.png`.

## The MakerWorld / CGAL question (resolved)

The open question in the handoff was whether the model would survive MakerWorld's
**CGAL** kernel, which rejects self-intersecting / non-manifold polyhedra
(feared at tight collapsed folds), and the prior sandbox couldn't run OpenSCAD.

It can. `bellows.scad` builds the shell as a single `polyhedron()` mirroring the
web tool's vertex/face math, and a portable **OpenSCAD 2021.01** (CGAL-only — the
strictest, oldest widely-deployed kernel; if it passes here it passes on
MakerWorld) was installed and used to render the whole parameter space through a
real CGAL boolean. Every configuration comes back **`Simple: yes`** (a clean
2-manifold solid), including the tight-collapsed-fold stress cases.

One real bug surfaced and was fixed: the `open_back` variant's cap faces were
wound **opposite** to the walls. The mesh is still edge-2-manifold (so the web
tool's own "every edge shared by 2 triangles" test passed it), but the
inconsistent winding made CGAL report it as *"not closed."* `bellows.scad` winds
those caps consistently, so all `open_back` way-covers now render in CGAL.
(`standalone.html` keeps the original winding — harmless for slicers, which
auto-repair normals, and the exported triangles are identical either way.)

## Verifying

```
node verify/verify.js      # parity + watertight + CGAL across 15 configs
```

For each config it: builds the reference mesh from `standalone.html`'s `buildMesh`,
renders `bellows.scad` to a binary STL via OpenSCAD, and checks

1. **Parity** — the `.scad` triangles equal the web-tool triangles (winding-independent),
2. **Watertight** — every undirected edge is shared by exactly 2 triangles,
3. **CGAL** — a forced Nef boolean reports `Simple: yes`,
4. **Printable** — the collapsed support gap (`interface_gap`) is positive and ≥ one layer.

Current result: **all 15 configs pass all four checks (100% parity).**
`node verify/inspect_fold.js` separately shows the fold pitch / support-gap math
and that the old fuse-into-a-block failure mode is now unreachable.

### Independent cross-check (`verify/independent_check.py`)

Because the JS harness and the web tool could in principle share a blind spot,
the actual exported STLs are also validated with **trimesh** (a standard
third-party mesh library) over 18 configs incl. extremes (1–120 pleats, deep
folds, thin walls, every shape/variant/connector). Each must be: watertight,
winding-consistent, positive volume, **one connected body** (so it peels as a
single piece), correct Euler characteristic (0 = full tube ≅ torus, 2 = open_back
≅ sphere), and — via a vertical ray cast through a wall band — show
**≈ 4 × pleat_count surface crossings**, which proves the fold membranes are
genuinely separated (a fused block would give 2) *and* that the requested fold
count is present. Current result: **all 18 OK.**

### Actually slices (PrusaSlicer)

The exported STL is sliced headless with **PrusaSlicer** (`prusa-slicer-console`,
same engine lineage as the Bambu Studio used in the video) with support enabled
and 0 contact distance — `verify/analyze_gcode.py` then parses the G-code. Both
the full bellows and the open_back way-cover slice cleanly and generate **support
material at 100+ distinct Z-heights spread across the whole part height** (not
just a base), i.e. peel-away support fills every fold gap — the printable
TPU-membrane + interface-layer structure the technique relies on. To print for
real you'd assign the support/interface to a second (non-bonding) material
(PLA for TPU, PETG for CF-TPU) as in the video.

> Not verifiable here: an actual physical print. Everything short of pushing
> filament — geometry, topology, single-piece connectivity, the MakerWorld CGAL
> kernel, and slicing into valid support-in-the-gaps G-code — is checked.

`verify/diag_open.js` and `verify/fix_open.js` are the diagnostics that found and
fixed the open-back winding issue.

> The harness expects OpenSCAD at
> `C:\Users\computer\cyryo\tools\openscad-2021.01\openscad.exe` (portable build,
> installed during this work). Adjust the `OPENSCAD` constant in `verify/verify.js`
> if it lives elsewhere.
