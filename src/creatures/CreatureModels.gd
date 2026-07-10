class_name CreatureModels
extends RefCounted
## Deepforage — bespoke low-poly silhouettes for the currently-spawned species.
##
## Every other creature in the roster (docs/ART_DIRECTION.md §8.3) still uses the
## generic quadruped rig built inline in Creature.gd's `_build_body()`. These three
## — Mosslamb, Ashjackal, Gloamstalker Lynx — are the first to get a real, distinct
## silhouette per the exact specs in that section. Matches src/world/Flora.gd's
## established pattern: a static-func mesh library built from low-radial-segment
## primitives (faceted, not smooth) for the honest chunky low-poly read.
##
## IMPORTANT — the shared-material contract: `mat` passed into `build()` is the
## Creature's own `_body_mat`, ONE StandardMaterial3D instance that `_glow()`
## toggles emission on/off across the whole creature for the red wind-up tell and
## the blue-white stagger flash. Every "main body" mesh part below (torso/legs/
## head/tail/ears/snout/ridges) MUST use that same shared `mat` instance via
## `material_override`, never a fresh material — otherwise the tell system silently
## stops working on these three species. Only small dedicated glow *accents* (eye-
## shine, lichen flecks, ruff-flecks, patch markings) get their own separate
## material, since those need to hold their own colour regardless of the body's
## tell state.

const MODELED_SPECIES := ["mosslamb", "ashjackal", "gloamstalker_lynx"]

## True if `species_id` has a bespoke builder below; false falls through to the
## generic rig in Creature.gd.
static func has_model(species_id: String) -> bool:
    return MODELED_SPECIES.has(species_id)

## Dispatches to the right species builder. `parent` gets the mesh children added
## directly to it (parent is the Creature node itself). `mat` is the Creature's
## shared `_body_mat` — reuse it for every "main body" mesh part so `_glow()`'s
## wind-up/stagger emission tells keep working; this function OVERRIDES mat's
## albedo_color to the correct species tone (Main.gd still sets a generic tier
## colour via TIER_TUNING — your species colour takes precedence).
static func build(species_id: String, parent: Node3D, mat: StandardMaterial3D, body_height: float) -> void:
    match species_id:
        "mosslamb":
            _mosslamb(parent, mat, body_height)
        "ashjackal":
            _ashjackal(parent, mat, body_height)
        "gloamstalker_lynx":
            _gloamstalker_lynx(parent, mat, body_height)

## --- Mosslamb ---------------------------------------------------------------
## Tier 1 grazer. "A stack of smooth rounded boulders" under a mossy felted
## coat — barrel-bodied, low and heavy, blunt moss-tufted horn-stubs, permanently
## half-lidded eyes. No aggressive geometry at all (§8.2 Tier 1 rule).
static func _mosslamb(parent: Node3D, mat: StandardMaterial3D, body_height: float) -> void:
    mat.albedo_color = Palette.STONE_LIT

    var leg_len: float = body_height * 0.32   # short + stubby — reads low and heavy
    var torso_y: float = leg_len + 0.16
    var total_h: float = torso_y + 0.5

    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.85, total_h, 1.25)
    col.shape = box
    col.position = Vector3(0, total_h * 0.5, 0)
    parent.add_child(col)

    # Barrel torso: two overlapping faceted "boulder" spheres (front + rear)
    # instead of one smooth capsule — the single biggest silhouette
    # differentiator from the generic rig.
    var boulder_specs := [
        [Vector3(0, torso_y, -0.24), 0.36],
        [Vector3(0, torso_y + 0.02, 0.22), 0.40],
    ]
    for spec in boulder_specs:
        var boulder := MeshInstance3D.new()
        var bm := SphereMesh.new()
        bm.radius = spec[1]
        bm.height = float(spec[1]) * 1.9
        bm.radial_segments = 8
        bm.rings = 5
        boulder.mesh = bm
        boulder.position = spec[0]
        boulder.material_override = mat
        parent.add_child(boulder)

    # Four short stubby legs.
    for lx in [-0.26, 0.26]:
        for lz in [-0.3, 0.3]:
            var leg := MeshInstance3D.new()
            var lm := CylinderMesh.new()
            lm.top_radius = 0.11
            lm.bottom_radius = 0.10
            lm.height = leg_len
            lm.radial_segments = 7
            leg.mesh = lm
            leg.position = Vector3(lx, leg_len * 0.5, lz)
            leg.material_override = mat
            parent.add_child(leg)

    # Rounded, blunt head — no elongated snout.
    var head_pos := Vector3(0, torso_y + 0.2, -0.58)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.28
    hm.height = 0.5
    hm.radial_segments = 8
    hm.rings = 5
    head.mesh = hm
    head.position = head_pos
    head.material_override = mat
    parent.add_child(head)

    # Two blunt moss-tufted horn-stubs — short, blunt-tipped, NOT the sharp
    # predator-ear cones the generic rig uses for is_predator; these are horns.
    for hx in [-0.13, 0.13]:
        var horn := MeshInstance3D.new()
        var horn_m := CylinderMesh.new()
        horn_m.top_radius = 0.045
        horn_m.bottom_radius = 0.065
        horn_m.height = 0.14
        horn_m.radial_segments = 6
        horn.mesh = horn_m
        horn.position = head_pos + Vector3(hx, 0.24, 0.05)
        horn.rotation = Vector3(deg_to_rad(-12.0), 0.0, deg_to_rad(sign(hx) * -8.0))
        horn.material_override = mat
        parent.add_child(horn)

    # Small rounded prey ears (same register as the generic rig's prey-ear shape).
    for ex in [-0.16, 0.16]:
        var ear := MeshInstance3D.new()
        var earm := CylinderMesh.new()
        earm.top_radius = 0.05
        earm.bottom_radius = 0.08
        earm.height = 0.15
        earm.radial_segments = 6
        ear.mesh = earm
        ear.position = head_pos + Vector3(ex, 0.16, 0.08)
        ear.rotation = Vector3(0.0, 0.0, deg_to_rad(sign(ex) * 35.0))
        ear.material_override = mat
        parent.add_child(ear)

    # Small tail.
    var tail := MeshInstance3D.new()
    var tlm := CylinderMesh.new()
    tlm.top_radius = 0.04
    tlm.bottom_radius = 0.08
    tlm.height = 0.3
    tlm.radial_segments = 6
    tail.mesh = tlm
    tail.rotation = Vector3(deg_to_rad(60.0), 0.0, 0.0)
    tail.position = Vector3(0, torso_y + 0.08, 0.56)
    tail.material_override = mat
    parent.add_child(tail)

    # Half-lidded eyes: small flattened dark slits, distinct from the generic
    # rig's lack of visible eyes entirely. Uses a plain small dark accent, not
    # the shared `mat`, so it stays readable regardless of body-tell state.
    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Palette.CHARCOAL_BLACK
    eye_mat.roughness = 0.5
    eye_mat.metallic = 0.0
    for sx in [-0.14, 0.14]:
        var eye := MeshInstance3D.new()
        var em := BoxMesh.new()
        em.size = Vector3(0.09, 0.03, 0.05)
        eye.mesh = em
        eye.position = head_pos + Vector3(sx, 0.02, -0.24)
        eye.rotation = Vector3(0.0, 0.0, deg_to_rad(sign(sx) * -6.0))
        eye.material_override = eye_mat
        parent.add_child(eye)

    # 1-2 tiny dim GLOW_TEAL back-lichen flecks — a faint accent, not a beacon.
    var lichen_mat := MaterialLib.glow(Palette.GLOW_TEAL, 0.8)
    var lichen_specs := [
        Vector3(0.1, torso_y + 0.34, -0.1),
        Vector3(-0.14, torso_y + 0.3, 0.28),
    ]
    for pos in lichen_specs:
        var fleck := MeshInstance3D.new()
        var fm := SphereMesh.new()
        fm.radius = 0.045
        fm.height = 0.05
        fm.radial_segments = 6
        fm.rings = 3
        fleck.mesh = fm
        fleck.position = pos
        fleck.scale = Vector3(1.0, 0.4, 1.0)   # flattened fleck, not a bead
        fleck.material_override = lichen_mat
        parent.add_child(fleck)

## --- Ashjackal ----------------------------------------------------------------
## Tier 2 small hunter, pack canid. Lean and angular — sharp shoulder ridges,
## narrow snout, alert triangular ears. §8.2 Tier 2: "first angular note," small
## AMBER_EYESHINE tell rather than full bioluminescence.
static func _ashjackal(parent: Node3D, mat: StandardMaterial3D, body_height: float) -> void:
    mat.albedo_color = Palette.ASH_GREY

    var leg_len: float = body_height * 0.48   # longer/thinner — lean stance
    var torso_y: float = leg_len + 0.1
    var total_h: float = torso_y + 0.45

    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.55, total_h, 1.35)
    col.shape = box
    col.position = Vector3(0, total_h * 0.5, 0)
    parent.add_child(col)

    # Leaner, thinner torso than the generic rig's capsule.
    var torso := MeshInstance3D.new()
    var tm := CapsuleMesh.new()
    tm.radius = 0.19
    tm.height = 1.0
    tm.radial_segments = 8
    tm.rings = 2
    torso.mesh = tm
    torso.rotation = Vector3(deg_to_rad(90), 0.0, 0.0)
    torso.position = Vector3(0, torso_y, 0)
    torso.material_override = mat
    parent.add_child(torso)

    # Longer, thinner legs.
    for lx in [-0.16, 0.16]:
        for lz in [-0.36, 0.36]:
            var leg := MeshInstance3D.new()
            var lm := CylinderMesh.new()
            lm.top_radius = 0.065
            lm.bottom_radius = 0.055
            lm.height = leg_len
            lm.radial_segments = 7
            leg.mesh = lm
            leg.position = Vector3(lx, leg_len * 0.5, lz)
            leg.material_override = mat
            parent.add_child(leg)

    # Smaller head sphere with a tapered cone snout protruding forward — the
    # "narrow snout" read the generic rig has zero equivalent of.
    var head_pos := Vector3(0, torso_y + 0.16, -0.56)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.19
    hm.height = 0.34
    hm.radial_segments = 7
    hm.rings = 4
    head.mesh = hm
    head.position = head_pos
    head.material_override = mat
    parent.add_child(head)

    var snout := MeshInstance3D.new()
    var snm := CylinderMesh.new()
    snm.top_radius = 0.045
    snm.bottom_radius = 0.11
    snm.height = 0.28
    snm.radial_segments = 7
    snout.mesh = snm
    snout.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
    snout.position = head_pos + Vector3(0, -0.02, -0.28)
    snout.material_override = mat
    parent.add_child(snout)

    # Sharp shoulder ridges: thin angular wedges tilted up off the shoulders —
    # the first hint (per §8.2) that this creature's shape can hurt you.
    for sx in [-0.16, 0.16]:
        var ridge := MeshInstance3D.new()
        var rm := PrismMesh.new()
        rm.size = Vector3(0.1, 0.22, 0.34)
        ridge.mesh = rm
        ridge.position = Vector3(sx, torso_y + 0.22, -0.16)
        ridge.rotation = Vector3(0.0, 0.0, deg_to_rad(sign(sx) * 24.0))
        ridge.material_override = mat
        parent.add_child(ridge)

    # Triangular alert ears — adapted from the generic rig's predator cone-ear,
    # slightly larger/sharper.
    for ex in [-0.1, 0.1]:
        var ear := MeshInstance3D.new()
        var earm := CylinderMesh.new()
        earm.top_radius = 0.0
        earm.bottom_radius = 0.085
        earm.height = 0.28
        earm.radial_segments = 6
        ear.mesh = earm
        ear.position = head_pos + Vector3(ex, 0.2, 0.02)
        ear.material_override = mat
        parent.add_child(ear)

    # Tail, matching the generic rig's angle-up treatment.
    var tail := MeshInstance3D.new()
    var tlm := CylinderMesh.new()
    tlm.top_radius = 0.025
    tlm.bottom_radius = 0.055
    tlm.height = 0.46
    tlm.radial_segments = 6
    tail.mesh = tlm
    tail.rotation = Vector3(deg_to_rad(55.0), 0.0, 0.0)
    tail.position = Vector3(0, torso_y + 0.02, 0.54)
    tail.material_override = mat
    parent.add_child(tail)

    # Small amber eye-glow — smaller radius and lower energy than the generic
    # predator eyes; the bestiary calls this "small... rather than full
    # bioluminescence," so it should read as more subtle than a generic
    # predator, not brighter.
    var eye_mat := MaterialLib.glow(Palette.AMBER_EYESHINE, 1.8)
    for sx in [-0.075, 0.075]:
        var eye := MeshInstance3D.new()
        var em := SphereMesh.new()
        em.radius = 0.035
        em.height = 0.07
        em.radial_segments = 6
        em.rings = 3
        eye.mesh = em
        eye.position = head_pos + Vector3(sx, 0.02, -0.16)
        eye.material_override = eye_mat
        parent.add_child(eye)

## --- Gloamstalker Lynx ----------------------------------------------------
## Tier 3 mid predator. Lean, long-limbed big cat — low stalking posture,
## flattened haunches, low head carriage, angular shoulder blades. §8.2 Tier 3:
## GLOW_VIOLET-family bio-glow starts appearing as a creature marking (here,
## per the spec, GLOW_TEAL ruff-flecks specifically), on top of the roster's
## first pack-predator amber eye-glow carried forward from Tier 2.
static func _gloamstalker_lynx(parent: Node3D, mat: StandardMaterial3D, body_height: float) -> void:
    mat.albedo_color = Palette.STONE

    var leg_len: float = body_height * 0.5    # long limbs — the stalking-cat read
    var torso_y: float = leg_len * 0.62        # positioned LOWER than a generic quadruped's torso_y — low to the ground
    var total_h: float = leg_len + 0.4

    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.6, total_h, 1.5)
    col.shape = box
    col.position = Vector3(0, total_h * 0.5, 0)
    parent.add_child(col)

    # Long, low torso.
    var torso := MeshInstance3D.new()
    var tm := CapsuleMesh.new()
    tm.radius = 0.22
    tm.height = 1.2
    tm.radial_segments = 8
    tm.rings = 2
    torso.mesh = tm
    torso.rotation = Vector3(deg_to_rad(90), 0.0, 0.0)
    torso.position = Vector3(0, torso_y, 0)
    torso.material_override = mat
    parent.add_child(torso)

    # Long limbs, proportionally taller than torso height alone would suggest.
    for lx in [-0.2, 0.2]:
        for lz in [-0.4, 0.4]:
            var leg := MeshInstance3D.new()
            var lm := CylinderMesh.new()
            lm.top_radius = 0.075
            lm.bottom_radius = 0.065
            lm.height = leg_len
            lm.radial_segments = 7
            leg.mesh = lm
            leg.position = Vector3(lx, leg_len * 0.5, lz)
            leg.material_override = mat
            parent.add_child(leg)

    # Head positioned low and forward — more level with the torso than up,
    # the "low head carriage" silhouette read.
    var head_pos := Vector3(0, torso_y + 0.04, -0.72)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.24
    hm.height = 0.42
    hm.radial_segments = 8
    hm.rings = 4
    head.mesh = hm
    head.position = head_pos
    head.material_override = mat
    parent.add_child(head)

    # Angular shoulder-blade details — similar wedge technique to Ashjackal's
    # ridges but positioned/angled differently so it reads as "shoulder
    # blades," a tension line even standing still, not "ridges."
    for sx in [-0.19, 0.19]:
        var blade := MeshInstance3D.new()
        var bm := PrismMesh.new()
        bm.size = Vector3(0.09, 0.3, 0.4)
        blade.mesh = bm
        blade.position = Vector3(sx, torso_y + 0.2, -0.28)
        blade.rotation = Vector3(deg_to_rad(-10.0), 0.0, deg_to_rad(sign(sx) * 34.0))
        blade.material_override = mat
        parent.add_child(blade)

    # Flattened haunches — broad low wedges over the rear legs.
    for sx in [-0.2, 0.2]:
        var haunch := MeshInstance3D.new()
        var hpm := PrismMesh.new()
        hpm.size = Vector3(0.16, 0.26, 0.46)
        haunch.mesh = hpm
        haunch.position = Vector3(sx, torso_y + 0.06, 0.36)
        haunch.rotation = Vector3(0.0, 0.0, deg_to_rad(sign(sx) * -16.0))
        haunch.material_override = mat
        parent.add_child(haunch)

    # Low, flat ears — tuned smaller/flatter than the generic predator ear.
    for ex in [-0.1, 0.1]:
        var ear := MeshInstance3D.new()
        var earm := CylinderMesh.new()
        earm.top_radius = 0.0
        earm.bottom_radius = 0.06
        earm.height = 0.16
        earm.radial_segments = 6
        ear.mesh = earm
        ear.position = head_pos + Vector3(ex, 0.16, 0.06)
        ear.rotation = Vector3(deg_to_rad(-14.0), 0.0, 0.0)
        ear.material_override = mat
        parent.add_child(ear)

    # Tail, lower/flatter stance overall.
    var tail := MeshInstance3D.new()
    var tlm := CylinderMesh.new()
    tlm.top_radius = 0.035
    tlm.bottom_radius = 0.07
    tlm.height = 0.5
    tlm.radial_segments = 6
    tail.mesh = tlm
    tail.rotation = Vector3(deg_to_rad(35.0), 0.0, 0.0)
    tail.position = Vector3(0, torso_y + 0.02, 0.66)
    tail.material_override = mat
    parent.add_child(tail)

    # Small CHARCOAL_BLACK patch accents on the body for the mottled two-tone
    # "near-black patches" look — a separate small StandardMaterial3D (not the
    # shared `mat`) since these stay their own colour regardless of tell state.
    var patch_mat := StandardMaterial3D.new()
    patch_mat.albedo_color = Palette.CHARCOAL_BLACK
    patch_mat.roughness = 0.9
    patch_mat.metallic = 0.0
    var patch_specs := [
        [Vector3(0.14, torso_y + 0.16, 0.1), Vector3(0.16, 0.02, 0.22), 12.0],
        [Vector3(-0.15, torso_y + 0.1, -0.14), Vector3(0.14, 0.02, 0.18), -18.0],
        [Vector3(0.02, torso_y + 0.2, 0.44), Vector3(0.18, 0.02, 0.16), 6.0],
    ]
    for spec in patch_specs:
        var patch := MeshInstance3D.new()
        var pm := BoxMesh.new()
        pm.size = spec[1]
        patch.mesh = pm
        patch.position = spec[0]
        patch.rotation = Vector3(0.0, deg_to_rad(spec[2]), 0.0)
        patch.material_override = patch_mat
        parent.add_child(patch)

    # A cluster of small, faint GLOW_TEAL ruff-flecks around the neck/ruff area.
    var ruff_mat := MaterialLib.glow(Palette.GLOW_TEAL, 1.2)
    var rng := RandomNumberGenerator.new()
    rng.seed = hash("gloamstalker_lynx_ruff")
    for i in range(5):
        var fleck := MeshInstance3D.new()
        var fm := SphereMesh.new()
        fm.radius = 0.035
        fm.height = 0.05
        fm.radial_segments = 5
        fm.rings = 3
        fleck.mesh = fm
        var ang := rng.randf_range(-0.6, 0.6)
        fleck.position = head_pos + Vector3(sin(ang) * 0.22, -0.06 + rng.randf_range(-0.05, 0.08), 0.26 + rng.randf_range(0.0, 0.12))
        fleck.material_override = ruff_mat
        parent.add_child(fleck)

    # Predator amber eyes — kept as the roster's existing generic predator eye-
    # glow treatment (the bestiary doesn't call for anything different here).
    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color(1.0, 0.7, 0.2)
    eye_mat.emission_enabled = true
    eye_mat.emission = Palette.AMBER_EYESHINE
    eye_mat.emission_energy_multiplier = 3.0
    for sx in [-0.1, 0.1]:
        var eye := MeshInstance3D.new()
        var em := SphereMesh.new()
        em.radius = 0.05
        em.height = 0.1
        em.radial_segments = 6
        em.rings = 3
        eye.mesh = em
        eye.position = head_pos + Vector3(sx, 0.04, -0.2)
        eye.material_override = eye_mat
        parent.add_child(eye)
