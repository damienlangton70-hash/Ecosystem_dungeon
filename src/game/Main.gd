extends Node3D
## Deepforage — Floor 1: The Fungal Shallows (M1 vertical-slice environment).
##
## Assembles the first real floor procedurally (still low-poly): an entrance, a
## glowing fungal grove, a water pool, scattered cover, and a descent shaft to
## Floor 2. Spawns prey + predators wired to the Ecosystem, and a combat HUD.
## The World Building / Graphics agents replace these procedural stubs with
## authored, textured environments in later builds.

var _player: Player
var _ecosystem: Ecosystem
var _hud: HUD

# Combat tuning by trophic tier (lore.json holds ecology/identity, not combat numbers).
const TIER_TUNING := {
    1: {"hp": 26.0, "poise": 20.0, "speed": 3.0, "dmg": 0.0, "height": 1.10, "color": Color(0.82, 0.80, 0.72)},
    2: {"hp": 42.0, "poise": 30.0, "speed": 4.2, "dmg": 9.0, "height": 1.20, "color": Color(0.26, 0.24, 0.22)},
    3: {"hp": 58.0, "poise": 40.0, "speed": 3.4, "dmg": 16.0, "height": 1.05, "color": Color(0.17, 0.16, 0.20)},
    4: {"hp": 110.0, "poise": 60.0, "speed": 3.2, "dmg": 26.0, "height": 1.60, "color": Color(0.20, 0.18, 0.20)},
    5: {"hp": 200.0, "poise": 90.0, "speed": 3.4, "dmg": 34.0, "height": 2.00, "color": Color(0.10, 0.10, 0.14)},
}

func _ready() -> void:
    _setup_environment()
    _setup_light()
    _build_ecosystem()
    _build_floor1()
    _spawn_player()
    _spawn_creatures()
    _spawn_forageables()
    _hud = HUD.new()
    add_child(_hud)
    _hud.bind(_player, _ecosystem)
    _build_audio()

func _build_audio() -> void:
    var amb := AudioStreamPlayer.new()
    amb.stream = Audio.get_stream("ambience")
    amb.volume_db = -14.0
    add_child(amb)
    amb.play()

func _setup_environment() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Palette.AMBIENT
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    # Ambient is a floor, not a source — the glow flora/water/fire cast the real
    # light; ambient just keeps unlit surfaces from reading as pure black (ART_DIRECTION §3.1).
    env.ambient_light_color = Palette.AMBIENT
    env.ambient_light_energy = 0.5
    # Filmic tonemap for contrast + controlled highlights.
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.05
    # Bloom — the bioluminescence, water and firelight should glow.
    env.glow_enabled = true
    env.glow_intensity = 0.9
    env.glow_strength = 1.1
    env.glow_bloom = 0.25
    env.glow_hdr_threshold = 0.95
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    # Contact darkening for depth/grounding.
    env.ssao_enabled = true
    env.ssao_radius = 2.0
    env.ssao_intensity = 2.5
    # Subtle grade.
    env.adjustment_enabled = true
    env.adjustment_contrast = 1.06
    env.adjustment_saturation = 1.12
    # Depth fog.
    env.fog_enabled = true
    env.fog_light_color = Color(Palette.FOG.r, Palette.FOG.g, Palette.FOG.b)
    env.fog_density = 0.018
    env.fog_sun_scatter = 0.0
    we.environment = env
    add_child(we)

func _setup_light() -> void:
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-60, -40, 0)
    key.light_energy = 0.18
    key.light_color = Palette.GLOW_DIM
    add_child(key)

func _build_ecosystem() -> void:
    _ecosystem = Ecosystem.new()
    _ecosystem.name = "Ecosystem"
    add_child(_ecosystem)
    _ecosystem.add_to_group("ecosystem")
    # D16-S2: the full Floor-1 roster per data/lore.json, not just the 3 that
    # happen to have bespoke bodies/rigs yet — the other 7 use the generic
    # form-driven rig below until they're rigged (see docs/ROADMAP.md).
    for id in ["mosslamb", "grotto_springhare", "blind_vole", "deep_quail", "gloomferret",
               "ashjackal", "rockback_boar", "spinefowl", "cinder_cockatril", "gloamstalker_lynx"]:
        _register_from_lore(id, 1)

## Register a species in the ecosystem using stats from the Lore layer (lore.json).
func _register_from_lore(id: String, floor: int) -> void:
    var L := LoreData.creature(id)
    var s := Species.new()
    s.id = id
    s.display_name = str(L.get("name", id))
    s.tier = int(L.get("tier", 1))
    var caps: Dictionary = L.get("carrying_capacity_by_floor", {})
    var cap := int(caps.get(str(floor), 30))
    if cap <= 0:
        cap = 30
    s.carrying_capacity = cap
    s.population = cap
    s.base_aggression = float(L.get("base_aggression", 0.2))
    s.awareness = float(L.get("awareness", 0.3))
    s.edible = bool(L.get("edible", true))
    var diet: Array[String] = []
    for d in L.get("diet", []):
        diet.append(str(d))
    s.diet = diet
    _ecosystem.register_species(s)

func _add_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    col.shape = box
    body.add_child(col)
    var mesh := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mesh.mesh = bm
    mesh.material_override = mat
    body.add_child(mesh)
    add_child(body)
    return body

func _add_glow_spot(pos: Vector3, glow: Color) -> void:
    var m := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.4
    sm.height = 0.8
    m.mesh = sm
    m.position = pos
    m.material_override = MaterialLib.glow(glow, 2.8)
    add_child(m)
    var l := OmniLight3D.new()
    l.position = pos
    l.light_color = glow
    l.light_energy = 1.0
    l.omni_range = 7.0
    add_child(l)

func _add_water(center: Vector3, size: Vector2) -> void:
    var plane := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = size
    plane.mesh = pm
    plane.position = center
    plane.material_override = MaterialLib.water()
    add_child(plane)

func _build_floor1() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    # Large main cavern floor. Top surface at y=0, spans x[-80,80], z[-60,90].
    _add_box(Vector3(0, -0.5, 15), Vector3(160, 1, 150), MaterialLib.ground())
    # Perimeter walls (tall, to read as a cavern).
    _add_box(Vector3(0, 5, 90), Vector3(160, 12, 1), MaterialLib.wall())     # front
    _add_box(Vector3(0, 5, -74), Vector3(160, 12, 1), MaterialLib.wall())    # back (behind descent)
    _add_box(Vector3(-80, 5, 8), Vector3(1, 12, 164), MaterialLib.wall())    # left
    _add_box(Vector3(80, 5, 8), Vector3(1, 12, 164), MaterialLib.wall())     # right
    # Entrance lip near spawn.
    _add_box(Vector3(0, 0.6, 84), Vector3(18, 1.2, 2), MaterialLib.entrance())

    # Glowcap pillar-trees spread across the whole cavern (position, height, glow),
    # cycling the three cold bioluminescence hues across the ring.
    var glow_cycle := [Palette.GLOW_TEAL, Palette.GLOW_BLUE, Palette.GLOW_VIOLET]
    var cap_specs := [
        [Vector3(-12, 0, 55), 6.0],
        [Vector3(14, 0, 48), 5.0],
        [Vector3(-4, 0, 30), 7.5],
        [Vector3(24, 0, 22), 5.5],
        [Vector3(-26, 0, 12), 6.5],
        [Vector3(6, 0, 2), 5.0],
        [Vector3(-36, 0, -8), 6.0],
        [Vector3(32, 0, -6), 5.5],
        [Vector3(-10, 0, -26), 7.5],
        [Vector3(22, 0, -36), 6.0],
        [Vector3(-44, 0, -42), 5.0],
        [Vector3(48, 0, 34), 6.5],
    ]
    for i in range(cap_specs.size()):
        var spec = cap_specs[i]
        var tree := Flora.glowcap_tree(spec[1], glow_cycle[i % glow_cycle.size()])
        tree.position = spec[0]
        add_child(tree)

    # Ironbark Deeproot landmarks — squat, dark hardwood mass, no glow.
    for p in [Vector3(-58, 0, -18), Vector3(56, 0, 6), Vector3(-20, 0, 70), Vector3(38, 0, 62)]:
        var ironbark := Flora.ironbark_tree(rng.randf_range(4.0, 5.0))
        ironbark.position = p
        add_child(ironbark)

    # Two water pools.
    _add_water(Vector3(-52, 0.08, 32), Vector2(30, 30))
    _add_water(Vector3(40, 0.08, -32), Vector2(22, 22))

    # Weeping Palewillows near the water pools — the soft, curved-line flora note.
    for p in [Vector3(-64, 0, 20), Vector3(-40, 0, 44), Vector3(50, 0, -20)]:
        var willow := Flora.palewillow_tree(3.2)
        willow.position = p
        add_child(willow)

    # A dockside stilt shelter at the edge of the larger pool, with a hanging
    # lantern — the one deliberate "warm ember" landmark near water, inspired
    # by a concept-art reference Damien shared. Static world landmark (like
    # the ridge or the trees) — NOT the player-buildable tent/den/magic-circle
    # system from docs/ROADMAP.md's M3 milestone; see src/world/Structures.gd.
    var shelter := Structures.stilt_shelter(2.4)
    shelter.position = Vector3(-38, 0, 26)
    shelter.rotation_degrees.y = 180.0
    add_child(shelter)

    # A little more mushroom/flora variety at ground level near both pools —
    # small glowing clusters, a different scale/register from the Glowcap
    # Pillar-trees, cycling the cold-bioluminescence family.
    var cluster_specs := [
        [Vector3(-58, 0, 50), Palette.GLOW_TEAL],
        [Vector3(-48, 0, 14), Palette.GLOW_VIOLET],
        [Vector3(-34, 0, 30), Palette.GLOW_BLUE],
        [Vector3(24, 0, -20), Palette.GLOW_FUNGUS],
        [Vector3(56, 0, -30), Palette.GLOW_TEAL],
    ]
    for spec in cluster_specs:
        var cluster := Flora.mushroom_cluster(spec[1])
        cluster.position = spec[0]
        add_child(cluster)

    # A rocky ridge along the east wall — a landmark to navigate by.
    for i in range(8):
        var rz := -52.0 + float(i) * 13.0
        var rh := rng.randf_range(3.0, 7.5)
        _add_box(Vector3(64.0 + rng.randf_range(-4, 4), rh * 0.5, rz), Vector3(rng.randf_range(3, 6), rh, rng.randf_range(3, 6)), MaterialLib.ridge())

    # Cover rocks scattered widely (a safe-ish clearing kept near the entrance).
    for i in range(36):
        var px := rng.randf_range(-74, 74)
        var pz := rng.randf_range(-56, 78)
        if Vector2(px, pz).distance_to(Vector2(0, 82)) < 10.0:
            continue
        var h := rng.randf_range(1.2, 3.6)
        _add_box(Vector3(px, h * 0.5, pz), Vector3(rng.randf_range(1.0, 3.0), h, rng.randf_range(1.0, 3.0)), MaterialLib.stone())

    # Glow fungus scatter (emissive + light).
    for i in range(22):
        _add_glow_spot(Vector3(rng.randf_range(-74, 74), 0.3, rng.randf_range(-56, 80)), Palette.GLOW_FUNGUS)

    _build_descent()

func _build_descent() -> void:
    # Lower landing beyond the floor's back edge (floor ends at z=-60).
    _add_box(Vector3(0, -3.0, -67), Vector3(26, 1, 16), MaterialLib.stone_dark())
    # Ramp bridging floor edge (z=-60, y=0) down to the landing.
    var ramp := _add_box(Vector3(0, -1.5, -61), Vector3(12, 0.6, 9), MaterialLib.stone())
    ramp.rotation.x = deg_to_rad(24)
    # Warning-glow markers at the lip.
    _add_glow_spot(Vector3(-6, 0.3, -58), Palette.WARN)
    _add_glow_spot(Vector3(6, 0.3, -58), Palette.WARN)
    # Trigger.
    var area := Area3D.new()
    area.position = Vector3(0, -2.0, -68)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(26, 5, 16)
    cs.shape = bs
    area.add_child(cs)
    add_child(area)
    area.body_entered.connect(_on_descent_entered)

func _on_descent_entered(body: Node) -> void:
    if body is Player:
        print("[Deepforage] The descent to Floor 2 yawns below — coming in a future build.")

func _spawn_player() -> void:
    _player = Player.new()
    _player.position = Vector3(0, 2, 82)
    add_child(_player)

## D16-S2: populate the FULL Floor-1 roster from data/lore.json (was just 3 of
## the 10 species listed for this floor). Prey common, small hunters rarer,
## Lynx guarding the descent — same "believable numbers across the space"
## shape the original 3 already followed, just extended to the rest of the
## roster. None of the 7 new species have a bespoke CreatureModels/CreatureRig
## body yet, so they render via Creature.gd's generic form-driven rig — the
## same safe, already-proven fallback Mosslamb/Ashjackal used before they were
## rigged (colour + predator/prey silhouette cues still apply via body_color/
## is_predator, just not a bespoke shape yet).
func _spawn_creatures() -> void:
    # --- Tier 1 grazers (common prey) ---
    for p in [Vector3(-15, 1, 52), Vector3(12, 1, 44), Vector3(-6, 1, 30), Vector3(24, 1, 24),
              Vector3(-30, 1, 12), Vector3(34, 1, 18), Vector3(4, 1, -6), Vector3(-20, 1, -22)]:
        _spawn_from_lore("mosslamb", p)
    for p in [Vector3(-60, 1, 58), Vector3(-40, 1, 66), Vector3(10, 1, 70),
              Vector3(40, 1, 50), Vector3(60, 1, 20), Vector3(-16, 1, -8)]:
        _spawn_from_lore("grotto_springhare", p)
    for p in [Vector3(-70, 1, 44), Vector3(-24, 1, 60), Vector3(30, 1, 64),
              Vector3(55, 1, 42), Vector3(-40, 1, -4), Vector3(50, 1, 8)]:
        _spawn_from_lore("blind_vole", p)
    for p in [Vector3(-50, 1, 70), Vector3(-4, 1, 58), Vector3(26, 1, 74),
              Vector3(64, 1, 56), Vector3(-64, 1, -6), Vector3(16, 1, 14)]:
        _spawn_from_lore("deep_quail", p)

    # --- Tier 2 small hunters (rarer) ---
    for p in [Vector3(-46, 1, -34), Vector3(46, 1, -38), Vector3(0, 1, -48), Vector3(-54, 1, 38)]:
        _spawn_from_lore("ashjackal", p)
    for p in [Vector3(-34, 1, 26), Vector3(46, 1, 40), Vector3(-56, 1, -30)]:
        _spawn_from_lore("gloomferret", p)
    for p in [Vector3(20, 1, 46), Vector3(-66, 1, 4), Vector3(58, 1, -18)]:
        _spawn_from_lore("rockback_boar", p)
    for p in [Vector3(-14, 1, 44), Vector3(38, 1, -2), Vector3(-44, 1, -40)]:
        _spawn_from_lore("spinefowl", p)
    for p in [Vector3(8, 1, 20), Vector3(-70, 1, -26), Vector3(48, 1, -48)]:
        _spawn_from_lore("cinder_cockatril", p)

    # --- Tier 3 ambush stalkers guarding the descent ---
    _spawn_from_lore("gloamstalker_lynx", Vector3(-8, 1, -50))
    _spawn_from_lore("gloamstalker_lynx", Vector3(12, 1, -46))

## Spawn a creature whose identity/ecology comes from lore.json; combat numbers
## are derived from its tier (TIER_TUNING) since lore holds no combat values.
func _spawn_from_lore(id: String, pos: Vector3) -> void:
    var L := LoreData.creature(id)
    var tier := int(L.get("tier", 1))
    var tune: Dictionary = TIER_TUNING.get(tier, TIER_TUNING[1])
    var arche := str(L.get("behaviour_archetype", ""))
    var aggr := float(L.get("base_aggression", 0.2))
    var aware := float(L.get("awareness", 0.3))
    var c := Creature.new()
    c.species_id = id
    c.display_name = str(L.get("name", id))
    c.is_predator = aggr >= 0.3
    c.ambush = arche == "ambush_predator"
    c.chase_speed_mult = 1.9 if c.ambush else 1.0
    var cs := LoreData.combat(id)
    c.max_health = float(cs.get("hp", tune["hp"]))
    c.max_poise = float(cs.get("poise", tune["poise"]))
    c.move_speed = float(cs.get("speed", tune["speed"]))
    c.attack_damage = float(cs.get("damage", tune["dmg"]))
    c.detect_radius = 6.0 + aware * 14.0
    c.body_color = tune["color"]
    c.body_height = float(tune["height"])
    c.position = pos
    add_child(c)

func _spawn_forageables() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var flora := [
        ["emberberry", "Emberberry", Color(0.85, 0.35, 0.25)],
        ["gloomgrape", "Gloomgrape", Color(0.45, 0.30, 0.70)],
        ["bleedberry", "Bleedberry", Color(0.75, 0.15, 0.25)],
        ["duskfig", "Duskfig", Color(0.42, 0.28, 0.36)],
        ["palethyme", "Palethyme", Color(0.55, 0.80, 0.45)],
        ["stoneleaf", "Stoneleaf Rosemary", Color(0.45, 0.65, 0.50)],
        ["deeprootginger", "Deeproot Ginger", Color(0.80, 0.75, 0.40)],
        ["marrowmint", "Marrow Mint", Color(0.50, 0.85, 0.70)],
    ]
    for entry in flora:
        for k in range(3):
            var f := Forageable.new()
            f.item_id = entry[0]
            f.display_name = str(LoreData.flora(entry[0]).get("name", entry[1]))
            f.color = entry[2]
            f.yield_amount = 1
            f.position = Vector3(rng.randf_range(-70, 70), 0.0, rng.randf_range(-52, 74))
            add_child(f)

