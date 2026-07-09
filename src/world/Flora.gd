class_name Flora
extends RefCounted
## Deepforage — the low-poly flora library. Static factories that each return a
## ready-to-place Node3D built from cheap primitive meshes, tuned via MaterialLib
## so every plant automatically speaks the shared material language.
##
## Silhouette identity (docs/ART_DIRECTION.md §5) is the whole job here:
##   Glowcap    — tall single stalk, broad glowing umbrella cap (dark on top, glows below).
##   Ironbark   — squat, thick, heavily-branched, dark hardwood, NO glow. Mass and weight.
##   Palewillow — slender pale trunk, drooping withes toward water. Soft and curved.
##   Berry bush — rounded foliage mound studded with small round accent-coloured dots.
##   Herb clump — low, spiky/frondy blades, shorter and sparser than a bush.
## Low radial-segment meshes are used deliberately (facets, not smooth curves) to
## keep the chunky low-poly read honest per the material bible.

## Convenience: pick the right small forageable visual for a category.
static func forageable_visual(item_id: String, category: String) -> Node3D:
    if category == "herb":
        return herb_clump(item_id)
    return berry_bush(item_id)

## --- Glowcap Pillar-tree ----------------------------------------------------

## Tall tapered stalk + a broad faceted luminescent umbrella cap with a gill
## underside, casting real light like the old `_add_glowcap`. Trunk has real
## cylinder collision so it reads (and blocks) like the rest of the world.
static func glowcap_tree(height: float, glow: Color) -> Node3D:
    var root := StaticBody3D.new()
    root.name = "GlowcapTree"

    var col := CollisionShape3D.new()
    var cyl_shape := CylinderShape3D.new()
    cyl_shape.height = height
    cyl_shape.radius = 0.45
    col.shape = cyl_shape
    col.position = Vector3(0, height * 0.5, 0)
    root.add_child(col)

    # Tapered stalk, low radial segments so it facets rather than rounds off.
    var stalk := MeshInstance3D.new()
    var stalk_mesh := CylinderMesh.new()
    stalk_mesh.height = height
    stalk_mesh.top_radius = 0.28
    stalk_mesh.bottom_radius = 0.55
    stalk_mesh.radial_segments = 7
    stalk.mesh = stalk_mesh
    stalk.position = Vector3(0, height * 0.5, 0)
    stalk.material_override = MaterialLib.trunk()
    root.add_child(stalk)

    var cap_y := height + 0.35
    # Cap topside: dark, unlit, faceted — a low-segment cone-ish cylinder (wide
    # top disc tapering slightly), per "dark on top, glowing from below."
    var cap_top := MeshInstance3D.new()
    var cap_mesh := CylinderMesh.new()
    cap_mesh.height = 1.1
    cap_mesh.top_radius = 1.7
    cap_mesh.bottom_radius = 1.15
    cap_mesh.radial_segments = 9
    cap_top.mesh = cap_mesh
    cap_top.position = Vector3(0, cap_y + 0.55, 0)
    cap_top.material_override = MaterialLib.foliage(true)
    root.add_child(cap_top)

    # Gill underside: a broader, flatter glowing disc peeking out below the cap
    # rim — this is the light-emitting surface the concept art reads first.
    var gills := MeshInstance3D.new()
    var gill_mesh := CylinderMesh.new()
    gill_mesh.height = 0.18
    gill_mesh.top_radius = 1.55
    gill_mesh.bottom_radius = 1.55
    gill_mesh.radial_segments = 9
    gills.mesh = gill_mesh
    gills.position = Vector3(0, cap_y, 0)
    gills.material_override = MaterialLib.glow(glow, 3.2)
    root.add_child(gills)

    var light := OmniLight3D.new()
    light.position = Vector3(0, cap_y, 0)
    light.light_color = glow
    light.light_energy = 2.2
    light.omni_range = 16.0
    root.add_child(light)

    return root

## --- Ironbark Deeproot ------------------------------------------------------

## Squat, thick, angular dark hardwood — no glow, reads as structural mass. A
## few blocky boughs plus sparse deep-foliage canopy make it a landmark rather
## than a light source.
static func ironbark_tree(height: float) -> Node3D:
    var root := StaticBody3D.new()
    root.name = "IronbarkTree"

    var col := CollisionShape3D.new()
    var cyl_shape := CylinderShape3D.new()
    cyl_shape.height = height
    cyl_shape.radius = 0.75
    col.shape = cyl_shape
    col.position = Vector3(0, height * 0.5, 0)
    root.add_child(col)

    # Thick angular trunk — heavy taper, few radial segments for a hewn look.
    var trunk_mesh := MeshInstance3D.new()
    var tm := CylinderMesh.new()
    tm.height = height
    tm.top_radius = 0.55
    tm.bottom_radius = 0.95
    tm.radial_segments = 6
    trunk_mesh.mesh = tm
    trunk_mesh.position = Vector3(0, height * 0.5, 0)
    trunk_mesh.material_override = MaterialLib.trunk(true)
    root.add_child(trunk_mesh)

    # A lighter bark-face wedge on one side so the trunk doesn't read as a flat
    # cylinder silhouette — an angular highlight slab.
    var face := MeshInstance3D.new()
    var face_mesh := BoxMesh.new()
    face_mesh.size = Vector3(0.4, height * 0.7, 0.35)
    face.mesh = face_mesh
    face.position = Vector3(0.55, height * 0.42, 0)
    face.rotation_degrees = Vector3(0, 14, 0)
    face.material_override = MaterialLib.trunk(false)
    root.add_child(face)

    # A few blocky boughs jutting from the upper trunk.
    var bough_specs := [
        [Vector3(0.7, height * 0.72, 0.1), Vector3(1.3, 0.35, 0.4), 22.0],
        [Vector3(-0.65, height * 0.62, -0.2), Vector3(1.1, 0.32, 0.35), -30.0],
        [Vector3(0.1, height * 0.85, 0.75), Vector3(1.0, 0.3, 0.32), 100.0],
    ]
    for spec in bough_specs:
        var bough := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = spec[1]
        bough.mesh = bm
        bough.position = spec[0]
        bough.rotation_degrees = Vector3(0, spec[2], 12)
        bough.material_override = MaterialLib.trunk(true)
        root.add_child(bough)

    # Sparse deep-foliage canopy clumps (blocky, faceted, no glow).
    var canopy_specs := [
        Vector3(0.5, height + 0.4, 0.3),
        Vector3(-0.6, height + 0.55, -0.35),
        Vector3(0.05, height + 0.75, -0.6),
    ]
    for i in range(canopy_specs.size()):
        var clump := MeshInstance3D.new()
        var pm := PrismMesh.new()
        pm.size = Vector3(1.1 - i * 0.12, 0.9, 1.0)
        clump.mesh = pm
        clump.position = canopy_specs[i]
        clump.rotation_degrees = Vector3(0, 30.0 * i, 0)
        clump.material_override = MaterialLib.foliage(true)
        root.add_child(clump)

    # Roots gripping the base rock — a few short splayed wedges at ground level.
    for i in range(4):
        var root_wedge := MeshInstance3D.new()
        var rm := PrismMesh.new()
        rm.size = Vector3(0.4, 0.5, 1.0)
        root_wedge.mesh = rm
        var ang := deg_to_rad(90.0 * i + 20.0)
        root_wedge.position = Vector3(cos(ang) * 0.65, 0.05, sin(ang) * 0.65)
        root_wedge.rotation_degrees = Vector3(0, rad_to_deg(ang) + 90.0, -70.0)
        root_wedge.material_override = MaterialLib.trunk(true)
        root.add_child(root_wedge)

    return root

## --- Weeping Palewillow -----------------------------------------------------

## Slender pale trunk with drooping withes angled toward the ground/water — the
## one soft, curved-line silhouette among the three trees. Light collision only
## (a thin capsule-ish box) since it's dressing, not a landmark blocker.
static func palewillow_tree(height: float) -> Node3D:
    var root := Node3D.new()
    root.name = "PalewillowTree"

    var body := StaticBody3D.new()
    var col := CollisionShape3D.new()
    var cyl_shape := CylinderShape3D.new()
    cyl_shape.height = height
    cyl_shape.radius = 0.22
    col.shape = cyl_shape
    col.position = Vector3(0, height * 0.5, 0)
    body.add_child(col)
    root.add_child(body)

    # Slender pale-barked trunk.
    var trunk_mesh := MeshInstance3D.new()
    var tm := CylinderMesh.new()
    tm.height = height
    tm.top_radius = 0.14
    tm.bottom_radius = 0.24
    tm.radial_segments = 7
    trunk_mesh.mesh = tm
    trunk_mesh.position = Vector3(0, height * 0.5, 0)
    trunk_mesh.material_override = MaterialLib.trunk()
    root.add_child(trunk_mesh)

    # A soft rounded crown mass where the withes hang from.
    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 0.55
    crown_mesh.height = 0.9
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    crown.mesh = crown_mesh
    crown.position = Vector3(0, height + 0.1, 0)
    crown.material_override = MaterialLib.palewillow()
    root.add_child(crown)

    # Drooping withes: thin elongated boxes angled downward and outward, in a
    # ring around the crown — the curved, trailing silhouette the tree is named
    # for. Rotated so each leans out then droops.
    var withe_count := 8
    for i in range(withe_count):
        var withe := MeshInstance3D.new()
        var wm := BoxMesh.new()
        wm.size = Vector3(0.06, height * 0.45, 0.06)
        withe.mesh = wm
        var ang := TAU * float(i) / float(withe_count)
        var outward := Vector3(cos(ang), 0, sin(ang)) * 0.55
        withe.position = Vector3(0, height + 0.05, 0) + outward
        # Lean outward and down so the withe droops toward the water/ground.
        withe.rotation = Vector3(0, -ang, deg_to_rad(58.0))
        withe.material_override = MaterialLib.palewillow()
        root.add_child(withe)

    return root

## --- Berry bush --------------------------------------------------------------

## Low rounded foliage mound (a couple of clustered faceted forms) studded with
## small berry spheres tinted via Palette.ingredient_color. Fruit colour reads
## before leaf shape, per the bible's "colour-forward" rule.
static func berry_bush(item_id: String) -> Node3D:
    var root := Node3D.new()
    root.name = "BerryBush_" + item_id
    var berry_color := Palette.ingredient_color(item_id)

    # Clustered mound: two overlapping faceted low domes so the silhouette isn't
    # a single perfect sphere.
    var mound_specs := [
        [Vector3(0, 0.28, 0), 0.5],
        [Vector3(0.28, 0.22, 0.16), 0.36],
        [Vector3(-0.24, 0.2, -0.2), 0.34],
    ]
    for spec in mound_specs:
        var lobe := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = spec[1]
        sm.height = float(spec[1]) * 1.7
        sm.radial_segments = 8
        sm.rings = 5
        lobe.mesh = sm
        lobe.position = spec[0]
        lobe.material_override = MaterialLib.foliage()
        root.add_child(lobe)

    # Small berry dots studding the mound — the colour-forward accent.
    var berry_mat := MaterialLib.accent(berry_color)
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(item_id)
    for i in range(7):
        var berry := MeshInstance3D.new()
        var bm := SphereMesh.new()
        bm.radius = 0.075
        bm.height = 0.13
        bm.radial_segments = 6
        bm.rings = 3
        berry.mesh = bm
        var a := rng.randf_range(0.0, TAU)
        var r := rng.randf_range(0.15, 0.45)
        berry.position = Vector3(cos(a) * r, rng.randf_range(0.22, 0.5), sin(a) * r)
        berry.material_override = berry_mat
        root.add_child(berry)

    return root

## --- Herb clump ---------------------------------------------------------------

## Low ground tuft of a few upright thin faceted blades in the accent colour —
## shorter and sparser than a bush, texture-forward rather than colour-forward.
static func herb_clump(item_id: String) -> Node3D:
    var root := Node3D.new()
    root.name = "HerbClump_" + item_id
    var herb_color := Palette.ingredient_color(item_id)
    var mat := MaterialLib.accent(herb_color, false)
    mat.emission_enabled = true
    mat.emission = herb_color
    mat.emission_energy_multiplier = 0.25

    var rng := RandomNumberGenerator.new()
    rng.seed = hash(item_id) + 1
    var blade_count := 5
    for i in range(blade_count):
        var blade := MeshInstance3D.new()
        var pm := PrismMesh.new()
        var h := rng.randf_range(0.22, 0.34)
        pm.size = Vector3(0.05, h, 0.14)
        blade.mesh = pm
        var a := TAU * float(i) / float(blade_count) + rng.randf_range(-0.2, 0.2)
        var r := rng.randf_range(0.0, 0.1)
        blade.position = Vector3(cos(a) * r, h * 0.5, sin(a) * r)
        blade.rotation = Vector3(deg_to_rad(rng.randf_range(-8, 8)), a, deg_to_rad(rng.randf_range(-10, 10)))
        blade.material_override = mat
        root.add_child(blade)

    return root
