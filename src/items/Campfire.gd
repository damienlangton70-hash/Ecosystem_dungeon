class_name Campfire
extends Node3D
## A buildable cook-point. Gives light + warmth (temperature hook for later) and
## acts as a cooking station: the player cooks raw food into cooked food while
## standing within range. The magic-circle variant will subclass/reuse this.

var _light: OmniLight3D
var _flame: MeshInstance3D
var _t := 0.0

func _ready() -> void:
    add_to_group("campfires")
    _build()

func _build() -> void:
    # Ring of hearth stones.
    for i in range(6):
        var ang := TAU * float(i) / 6.0
        var stone := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.35, 0.3, 0.35)
        stone.mesh = bm
        stone.position = Vector3(cos(ang) * 0.7, 0.12, sin(ang) * 0.7)
        var smat := StandardMaterial3D.new()
        smat.albedo_color = Color(0.18, 0.17, 0.17)
        stone.material_override = smat
        add_child(stone)
    # Crossed logs.
    for j in range(2):
        var log_mesh := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.height = 1.1
        cm.top_radius = 0.12
        cm.bottom_radius = 0.12
        log_mesh.mesh = cm
        log_mesh.rotation = Vector3(deg_to_rad(90), deg_to_rad(40 + j * 80), 0)
        log_mesh.position = Vector3(0, 0.18, 0)
        var lmat := StandardMaterial3D.new()
        lmat.albedo_color = Color(0.26, 0.16, 0.09)
        log_mesh.material_override = lmat
        add_child(log_mesh)
    # Flame.
    _flame = MeshInstance3D.new()
    var fm := SphereMesh.new()
    fm.radius = 0.35
    fm.height = 0.9
    _flame.mesh = fm
    _flame.position = Vector3(0, 0.5, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(1.0, 0.55, 0.15)
    fmat.emission_enabled = true
    fmat.emission = Color(1.0, 0.5, 0.12)
    fmat.emission_energy_multiplier = 3.0
    _flame.material_override = fmat
    add_child(_flame)
    # Warm light.
    _light = OmniLight3D.new()
    _light.position = Vector3(0, 0.8, 0)
    _light.light_color = Color(1.0, 0.6, 0.25)
    _light.light_energy = 3.0
    _light.omni_range = 12.0
    add_child(_light)
    var a := AudioStreamPlayer3D.new()
    a.stream = Audio.get_stream("fire")
    a.unit_size = 5.0
    a.volume_db = -5.0
    add_child(a)
    a.play()

func _process(delta: float) -> void:
    _t += delta
    var flick := 1.0 + sin(_t * 12.0) * 0.12 + sin(_t * 27.0) * 0.06
    if _light != null:
        _light.light_energy = 3.0 * flick
    if _flame != null:
        _flame.scale = Vector3.ONE * (1.0 + sin(_t * 15.0) * 0.08)
