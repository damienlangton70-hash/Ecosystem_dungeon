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

var _hp_fill: ColorRect
var _st_fill: ColorRect
var _hu_fill: ColorRect
var _depth_label: Label
var _info_label: Label
var _lock_label: Label

func _ready() -> void:
    _setup_environment()
    _setup_light()
    _build_ecosystem()
    _build_floor1()
    _spawn_player()
    _spawn_creatures()
    _build_hud()

func _setup_environment() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.02, 0.025, 0.04)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.16, 0.20, 0.28)
    env.ambient_light_energy = 0.4
    env.fog_enabled = true
    env.fog_light_color = Color(0.05, 0.08, 0.12)
    env.fog_density = 0.02
    we.environment = env
    add_child(we)

func _setup_light() -> void:
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-60, -40, 0)
    key.light_energy = 0.25
    key.light_color = Color(0.5, 0.6, 0.8)
    add_child(key)

func _build_ecosystem() -> void:
    _ecosystem = Ecosystem.new()
    _ecosystem.name = "Ecosystem"
    add_child(_ecosystem)
    _ecosystem.add_to_group("ecosystem")
    _register("mosslamb", "Mosslamb", 1, 80)
    _register("ashjackal", "Ashjackal", 2, 30)

func _register(id: String, dn: String, tier: int, cap: int) -> void:
    var s := Species.new()
    s.id = id
    s.display_name = dn
    s.tier = tier
    s.population = cap
    s.carrying_capacity = cap
    _ecosystem.register_species(s)

func _add_box(pos: Vector3, size: Vector3, color: Color, rough := 0.95) -> StaticBody3D:
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
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mesh.material_override = mat
    body.add_child(mesh)
    add_child(body)
    return body

func _add_glowcap(pos: Vector3, height: float, glow: Color) -> void:
    var trunk := StaticBody3D.new()
    trunk.position = pos
    var col := CollisionShape3D.new()
    var cyl := CylinderShape3D.new()
    cyl.height = height
    cyl.radius = 0.5
    col.shape = cyl
    col.position = Vector3(0, height * 0.5, 0)
    trunk.add_child(col)
    var tm := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.height = height
    cm.top_radius = 0.35
    cm.bottom_radius = 0.6
    tm.mesh = cm
    tm.position = Vector3(0, height * 0.5, 0)
    var tmat := StandardMaterial3D.new()
    tmat.albedo_color = Color(0.20, 0.22, 0.20)
    tm.material_override = tmat
    trunk.add_child(tm)
    add_child(trunk)

    var cap := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 1.6
    sm.height = 2.2
    cap.mesh = sm
    cap.position = pos + Vector3(0, height + 0.4, 0)
    var capmat := StandardMaterial3D.new()
    capmat.albedo_color = glow
    capmat.emission_enabled = true
    capmat.emission = glow
    capmat.emission_energy_multiplier = 2.5
    cap.material_override = capmat
    add_child(cap)

    var light := OmniLight3D.new()
    light.position = pos + Vector3(0, height + 0.4, 0)
    light.light_color = glow
    light.light_energy = 2.2
    light.omni_range = 16.0
    add_child(light)

func _add_glow_spot(pos: Vector3, glow: Color) -> void:
    var m := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.4
    sm.height = 0.8
    m.mesh = sm
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = glow
    mat.emission_enabled = true
    mat.emission = glow
    mat.emission_energy_multiplier = 2.0
    m.material_override = mat
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
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.10, 0.25, 0.35, 0.55)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness = 0.1
    mat.metallic = 0.2
    mat.emission_enabled = true
    mat.emission = Color(0.05, 0.15, 0.22)
    mat.emission_energy_multiplier = 0.5
    plane.material_override = mat
    add_child(plane)

func _build_floor1() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    # Main floor (top surface at y=0, spans z -24..36).
    _add_box(Vector3(0, -0.5, 6), Vector3(64, 1, 60), Color(0.13, 0.13, 0.15))
    # Perimeter walls.
    _add_box(Vector3(0, 3, -34), Vector3(64, 8, 1), Color(0.10, 0.10, 0.12))
    _add_box(Vector3(0, 3, 36), Vector3(64, 8, 1), Color(0.10, 0.10, 0.12))
    _add_box(Vector3(-32, 3, 6), Vector3(1, 8, 60), Color(0.10, 0.10, 0.12))
    _add_box(Vector3(32, 3, 6), Vector3(1, 8, 60), Color(0.10, 0.10, 0.12))
    # Entrance lip near spawn.
    _add_box(Vector3(0, 0.6, 33), Vector3(12, 1.2, 2), Color(0.16, 0.15, 0.15))
    # Fungal grove.
    _add_glowcap(Vector3(-6, 0, 2), 5.0, Color(0.25, 0.75, 0.85))
    _add_glowcap(Vector3(5, 0, -3), 6.0, Color(0.35, 0.55, 0.95))
    _add_glowcap(Vector3(-2, 0, -10), 4.5, Color(0.55, 0.35, 0.90))
    _add_glowcap(Vector3(9, 0, 8), 5.5, Color(0.25, 0.80, 0.70))
    # Water pool (west).
    _add_water(Vector3(-20, 0.08, 10), Vector2(13, 13))
    # Cover rocks.
    for i in range(12):
        var px := rng.randf_range(-28, 28)
        var pz := rng.randf_range(-22, 30)
        var h := rng.randf_range(1.2, 3.0)
        _add_box(Vector3(px, h * 0.5, pz), Vector3(rng.randf_range(1.0, 2.5), h, rng.randf_range(1.0, 2.5)), Color(0.14, 0.13, 0.14))
    # Glow fungus scatter.
    for i in range(10):
        _add_glow_spot(Vector3(rng.randf_range(-28, 28), 0.3, rng.randf_range(-22, 30)), Color(0.30, 0.80, 0.60))
    # Descent shaft (far -z, reachable off the floor edge).
    _build_descent()

func _build_descent() -> void:
    # Lower landing beyond the floor edge (floor ends at z=-24).
    _add_box(Vector3(0, -3.0, -30), Vector3(16, 1, 9), Color(0.05, 0.05, 0.06))
    # Ramp bridging floor edge (z=-24, y=0) down to the landing.
    var ramp := _add_box(Vector3(0, -1.4, -25.5), Vector3(8, 0.6, 6), Color(0.10, 0.09, 0.10))
    ramp.rotation.x = deg_to_rad(24)
    # Warning-glow markers at the lip.
    _add_glow_spot(Vector3(-4, 0.3, -23), Color(0.90, 0.40, 0.30))
    _add_glow_spot(Vector3(4, 0.3, -23), Color(0.90, 0.40, 0.30))
    # Trigger.
    var area := Area3D.new()
    area.position = Vector3(0, -2.0, -31)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(16, 5, 9)
    cs.shape = bs
    area.add_child(cs)
    add_child(area)
    area.body_entered.connect(_on_descent_entered)

func _on_descent_entered(body: Node) -> void:
    if body is Player:
        print("[Deepforage] The descent to Floor 2 yawns below — coming in a future build.")

func _spawn_player() -> void:
    _player = Player.new()
    _player.position = Vector3(0, 2, 30)
    add_child(_player)

func _spawn_creatures() -> void:
    var prey := [Vector3(-5, 1, 0), Vector3(4, 1, -2), Vector3(-1, 1, -7), Vector3(10, 1, 6)]
    for p in prey:
        _spawn_creature(p, "mosslamb", "Mosslamb", false, 26.0, 3.0, 0.0, 9.0, Color(0.82, 0.80, 0.72), 1.1)
    _spawn_creature(Vector3(-18, 1, -14), "ashjackal", "Ashjackal", true, 42.0, 4.3, 9.0, 12.0, Color(0.26, 0.24, 0.22), 1.2)
    _spawn_creature(Vector3(16, 1, -16), "ashjackal", "Ashjackal", true, 42.0, 4.3, 9.0, 12.0, Color(0.26, 0.24, 0.22), 1.2)

func _spawn_creature(pos: Vector3, id: String, dn: String, predator: bool, hp: float, spd: float, dmg: float, det: float, col: Color, hgt: float) -> void:
    var c := Creature.new()
    c.species_id = id
    c.display_name = dn
    c.is_predator = predator
    c.max_health = hp
    c.move_speed = spd
    c.attack_damage = dmg
    c.detect_radius = det
    c.body_color = col
    c.body_height = hgt
    c.position = pos
    add_child(c)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "DEEPFORAGE — Floor 1: The Fungal Shallows"
    title.position = Vector2(16, 10)
    layer.add_child(title)
    _hp_fill = _make_bar(layer, Vector2(16, 40), Color(0.80, 0.20, 0.20), "HP")
    _st_fill = _make_bar(layer, Vector2(16, 64), Color(0.20, 0.70, 0.90), "STA")
    _hu_fill = _make_bar(layer, Vector2(16, 88), Color(0.85, 0.60, 0.20), "FOOD")
    _depth_label = Label.new()
    _depth_label.position = Vector2(16, 114)
    layer.add_child(_depth_label)
    _info_label = Label.new()
    _info_label.position = Vector2(16, 138)
    layer.add_child(_info_label)
    _lock_label = Label.new()
    _lock_label.position = Vector2(16, 162)
    layer.add_child(_lock_label)
    var help := Label.new()
    help.text = "WASD move · Shift sprint · Space jump · LMB attack · RMB lock-on · Ctrl dodge · Esc cursor"
    help.position = Vector2(16, 194)
    layer.add_child(help)

func _make_bar(layer: CanvasLayer, pos: Vector2, color: Color, label: String) -> ColorRect:
    var lab := Label.new()
    lab.text = label
    lab.position = pos + Vector2(0, -3)
    layer.add_child(lab)
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.5)
    bg.position = pos + Vector2(54, 0)
    bg.size = Vector2(200, 16)
    layer.add_child(bg)
    var fill := ColorRect.new()
    fill.color = color
    fill.position = pos + Vector2(54, 0)
    fill.size = Vector2(200, 16)
    layer.add_child(fill)
    return fill

func _process(_delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    if _hp_fill != null:
        _hp_fill.size.x = 200.0 * clampf(_player.health / _player.max_health, 0.0, 1.0)
    if _player.survival != null:
        if _st_fill != null:
            _st_fill.size.x = 200.0 * clampf(_player.survival.stamina / _player.survival.max_stamina, 0.0, 1.0)
        if _hu_fill != null:
            _hu_fill.size.x = 200.0 * clampf(_player.survival.hunger / _player.survival.max_hunger, 0.0, 1.0)
    if _depth_label != null:
        _depth_label.text = "Depth: %.1f m" % maxf(-_player.global_position.y, 0.0)
    if _info_label != null and _ecosystem != null:
        var n := get_tree().get_nodes_in_group("creatures").size()
        _info_label.text = "Hostility: %d%%    Creatures: %d" % [int(_ecosystem.global_hostility * 100.0), n]
    if _lock_label != null:
        if _player.lock_target != null and is_instance_valid(_player.lock_target):
            _lock_label.text = "[ lock-on: %s ]" % str(_player.lock_target.display_name)
        else:
            _lock_label.text = ""
