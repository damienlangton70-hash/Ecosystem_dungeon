class_name Structures
extends RefCounted
## Deepforage — landmark architecture: hand-placed environmental set-dressing a
## delver FINDS already standing (docks, shelters, ruins), the same tier as
## Flora's trees or Main.gd's rocky ridge. This is NOT the player-buildable
## shelter/tent/den/magic-circle system from docs/ROADMAP.md's M3 milestone —
## that's a future gameplay/crafting system with its own verb; these are
## static world props with no interaction.
##
## Low-poly primitives + MaterialLib/Palette only, same house style and
## no-binary-asset constraint as everywhere else in the game.

## A weathered dockside hut on stilts, open-fronted (a lean-to shelter, not a
## sealed house), with a hanging lantern on a beam — the one deliberate "warm
## ember" landmark near water, per docs/ART_DIRECTION.md §0's whole thesis
## ("a single warm ember survives in an ocean of cold, glowing dark"). Caller
## positions + rotates the returned root so the open/lantern side faces the
## water it's meant to stand beside.
static func stilt_shelter(stilt_height: float = 2.4) -> Node3D:
    var root := StaticBody3D.new()
    root.name = "StiltShelter"

    var deck_size := Vector3(3.4, 0.2, 3.4)
    var deck_y := stilt_height
    var stilt_mat := MaterialLib.trunk(true)   # shadowed/waterlogged wood, underneath
    var built_mat := MaterialLib.trunk()       # lit wood, the superstructure

    # Collision — deliberately just two shapes, not one giant blocking box:
    # the deck (something to stand on) and the back wall (the one solid wall
    # you'd otherwise walk straight through). The open front/side stay open on
    # purpose, and the space under the platform stays walkable, matching how
    # every other landmark here (trees, the ridge) only approximates its own
    # footprint rather than fully hit-boxing every mesh part.
    var deck_col := CollisionShape3D.new()
    var deck_box := BoxShape3D.new()
    deck_box.size = deck_size
    deck_col.shape = deck_box
    deck_col.position = Vector3(0, deck_y, 0)
    root.add_child(deck_col)

    var wall_col := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(deck_size.x, 1.7, 0.12)
    wall_col.shape = wall_box
    wall_col.position = Vector3(0, deck_y + 0.95, -1.6)
    root.add_child(wall_col)

    # Four corner stilts + two cross-braces — the "built, not floating" read.
    for sx in [-1.4, 1.4]:
        for sz in [-1.4, 1.4]:
            var stilt := MeshInstance3D.new()
            var sm := CylinderMesh.new()
            sm.top_radius = 0.13
            sm.bottom_radius = 0.16
            sm.height = stilt_height
            sm.radial_segments = 6
            stilt.mesh = sm
            stilt.position = Vector3(sx, stilt_height * 0.5, sz)
            stilt.material_override = stilt_mat
            root.add_child(stilt)
    for sx in [-1.4, 1.4]:
        var brace := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.1, 0.12, 3.0)
        brace.mesh = bm
        brace.position = Vector3(sx, stilt_height * 0.62, 0)
        brace.material_override = stilt_mat
        root.add_child(brace)

    # Deck slab (visual; collision already added above).
    var deck := MeshInstance3D.new()
    var dm := BoxMesh.new()
    dm.size = deck_size
    deck.mesh = dm
    deck.position = Vector3(0, deck_y, 0)
    deck.material_override = built_mat
    root.add_child(deck)

    # Back wall + one side wall — a lean-to shelter, open toward the water on
    # the other two sides.
    var back_wall := MeshInstance3D.new()
    var bwm := BoxMesh.new()
    bwm.size = Vector3(deck_size.x, 1.7, 0.12)
    back_wall.mesh = bwm
    back_wall.position = Vector3(0, deck_y + 0.95, -1.6)
    back_wall.material_override = built_mat
    root.add_child(back_wall)

    var side_wall := MeshInstance3D.new()
    var swm := BoxMesh.new()
    swm.size = Vector3(0.12, 1.7, deck_size.z)
    side_wall.mesh = swm
    side_wall.position = Vector3(-1.6, deck_y + 0.95, 0)
    side_wall.material_override = built_mat
    root.add_child(side_wall)

    # Single-slope roof — a tilted slab, the same trick Main._build_descent()
    # already uses for its ramp.
    var roof := MeshInstance3D.new()
    var rm := BoxMesh.new()
    rm.size = Vector3(deck_size.x + 0.5, 0.12, deck_size.z + 0.5)
    roof.mesh = rm
    roof.position = Vector3(0, deck_y + 1.95, -0.3)
    roof.rotation_degrees = Vector3(-16, 0, 0)
    roof.material_override = built_mat
    root.add_child(roof)

    # A beam jutting out over the water, a rope, and the hanging lantern:
    # dark frame + a warm flame core + a real light, the deliberate one warm
    # accent near this pool.
    var beam := MeshInstance3D.new()
    var bem := BoxMesh.new()
    bem.size = Vector3(0.14, 0.14, 1.7)
    beam.mesh = bem
    beam.position = Vector3(1.55, deck_y + 0.25, 1.55)
    beam.rotation_degrees = Vector3(0, -45, 0)
    beam.material_override = stilt_mat
    root.add_child(beam)

    var lantern_pos := Vector3(2.6, deck_y - 0.35, 2.6)
    var rope := MeshInstance3D.new()
    var ropm := CylinderMesh.new()
    ropm.top_radius = 0.015
    ropm.bottom_radius = 0.015
    ropm.height = 0.6
    ropm.radial_segments = 5
    rope.mesh = ropm
    rope.position = lantern_pos + Vector3(0, 0.3, 0)
    rope.material_override = stilt_mat
    root.add_child(rope)

    var frame := MeshInstance3D.new()
    var fm := BoxMesh.new()
    fm.size = Vector3(0.26, 0.32, 0.26)
    frame.mesh = fm
    frame.position = lantern_pos
    var frame_mat := StandardMaterial3D.new()
    frame_mat.albedo_color = Palette.CHARCOAL_BLACK
    frame_mat.roughness = 0.6
    frame.material_override = frame_mat
    root.add_child(frame)

    var flame_core := MeshInstance3D.new()
    var fcm := SphereMesh.new()
    fcm.radius = 0.12
    fcm.height = 0.2
    fcm.radial_segments = 6
    fcm.rings = 3
    flame_core.mesh = fcm
    flame_core.position = lantern_pos
    flame_core.material_override = MaterialLib.flame()
    root.add_child(flame_core)

    var lantern_light := OmniLight3D.new()
    lantern_light.position = lantern_pos
    lantern_light.light_color = Palette.FLAME
    lantern_light.light_energy = 1.4
    lantern_light.omni_range = 9.0
    root.add_child(lantern_light)

    # Access ramp from ground to deck — same tilted-slab trick as the roof.
    var ramp := MeshInstance3D.new()
    var rpm := BoxMesh.new()
    rpm.size = Vector3(0.7, 0.1, stilt_height * 1.35)
    ramp.mesh = rpm
    ramp.position = Vector3(1.3, deck_y * 0.42, 1.75)
    ramp.rotation_degrees = Vector3(-34, 0, 0)
    ramp.material_override = built_mat
    root.add_child(ramp)

    return root
