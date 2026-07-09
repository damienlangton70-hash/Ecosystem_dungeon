extends Node3D
## Deepforage — bootstrap for the vertical-slice foundation.
##
## Builds a small descending cavern, spawns the player, and shows a minimal HUD.
## Everything here is intentionally procedural and simple: the specialist agents
## (World Building, Graphics, Mechanics...) replace these stubs with authored
## content over successive daily builds. This file just guarantees that cloning
## the repo and pressing Play gives you something you can walk around in.

var _player: Player
var _depth_label: Label
var _stat_label: Label

func _ready() -> void:
    _setup_environment()
    _setup_light()
    _build_cavern()
    _spawn_player()
    _build_hud()

func _setup_environment() -> void:
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.02, 0.02, 0.035)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.20, 0.22, 0.30)
    env.ambient_light_energy = 0.5
    env.fog_enabled = true
    env.fog_light_color = Color(0.04, 0.05, 0.08)
    env.fog_density = 0.03
    we.environment = env
    add_child(we)

func _setup_light() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -35, 0)
    sun.light_energy = 0.6
    sun.light_color = Color(0.72, 0.76, 0.9)
    sun.shadow_enabled = true
    add_child(sun)

func _build_cavern() -> void:
    # Three descending terraces convey the "deeper and deeper" descent pillar.
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var terrace_size := Vector3(40, 1, 40)
    for i in range(3):
        var y := -float(i) * 6.0
        var z := -float(i) * 34.0
        _add_block(Vector3(0, y, z), terrace_size, Color(0.16, 0.14, 0.15))
        if i < 2:
            var ramp := _add_block(Vector3(0, y - 3.0, z - 20.0), Vector3(8, 1, 16), Color(0.14, 0.12, 0.13))
            ramp.rotation.x = deg_to_rad(20)
        for j in range(8):
            var px := rng.randf_range(-16, 16)
            var pz := rng.randf_range(-16, 16)
            var h := rng.randf_range(2.0, 6.0)
            var s := Vector3(rng.randf_range(1.5, 3.0), h, rng.randf_range(1.5, 3.0))
            _add_block(Vector3(px, y + h * 0.5, z + pz), s, Color(0.12, 0.11, 0.12))

func _add_block(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
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
    mat.roughness = 0.95
    mesh.material_override = mat
    body.add_child(mesh)
    add_child(body)
    return body

func _spawn_player() -> void:
    _player = Player.new()
    _player.position = Vector3(0, 3, 12)
    add_child(_player)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "DEEPFORAGE  —  vertical slice"
    title.position = Vector2(16, 12)
    layer.add_child(title)
    _depth_label = Label.new()
    _depth_label.position = Vector2(16, 36)
    layer.add_child(_depth_label)
    _stat_label = Label.new()
    _stat_label.position = Vector2(16, 60)
    layer.add_child(_stat_label)
    var help := Label.new()
    help.text = "WASD move  ·  Shift sprint  ·  Space jump  ·  Mouse look  ·  Esc release cursor"
    help.position = Vector2(16, 84)
    layer.add_child(help)

func _process(_delta: float) -> void:
    if _player == null:
        return
    var depth := -_player.global_position.y
    _depth_label.text = "Depth: %.1f m" % depth
    if _player.survival != null:
        _stat_label.text = "Hunger: %d    Stamina: %d" % [int(_player.survival.hunger), int(_player.survival.stamina)]
