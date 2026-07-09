class_name Pickup
extends Node3D
## A dropped, collectable item (e.g. raw meat butchered from a downed creature).
## The player collects the nearest pickup within range with the interact key.

@export var item_id := "raw_meat"
@export var display_name := "Raw Meat"
@export var amount := 1
@export var color := Color(0.60, 0.15, 0.15)

func _ready() -> void:
    add_to_group("pickups")
    var m := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.4, 0.28, 0.4)
    m.mesh = bm
    m.position = Vector3(0, 0.2, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color * 0.5
    mat.emission_energy_multiplier = 0.5
    m.material_override = mat
    add_child(m)

func _process(delta: float) -> void:
    rotate_y(delta * 1.5)  # gentle spin so pickups read as interactable
