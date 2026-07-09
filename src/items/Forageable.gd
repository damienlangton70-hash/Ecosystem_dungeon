class_name Forageable
extends Node3D
## A harvestable plant (berry bush or herb). The player gathers it with the
## interact key; it regrows after a delay, so foraging is sustainable — over-
## harvesting just means waiting (a gentle echo of the ecosystem theme).

@export var item_id := "emberberry"
@export var display_name := "Emberberry"
@export var yield_amount := 1
@export var color := Color(0.75, 0.25, 0.30)
@export var regrow_time := 25.0

var harvested := false
var _timer := 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
    add_to_group("forageables")
    _mesh = MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.5
    sm.height = 0.9
    _mesh.mesh = sm
    _mesh.position = Vector3(0, 0.5, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color * 0.4
    mat.emission_energy_multiplier = 0.5
    _mesh.material_override = mat
    add_child(_mesh)

func harvest() -> int:
    if harvested:
        return 0
    harvested = true
    _timer = regrow_time
    if _mesh != null:
        _mesh.visible = false
    return yield_amount

func _process(delta: float) -> void:
    if harvested:
        _timer -= delta
        if _timer <= 0.0:
            harvested = false
            if _mesh != null:
                _mesh.visible = true
