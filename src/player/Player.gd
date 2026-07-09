class_name Player
extends CharacterBody3D
## Third-person player controller for the vertical slice.
##
## Deliberately compact. The Mechanics agent grows this into skill-based,
## Dark Souls-style combat (stamina-gated attacks, dodge-rolls, lock-on,
## hitboxes/hurtboxes) and wires in survival, shelter and cooking.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const JUMP_VELOCITY := 5.0
const MOUSE_SENS := 0.0025
const ACCEL := 10.0

var _yaw := 0.0
var _pitch := -0.26
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _pivot: Node3D
var _camera: Camera3D
var survival  # SurvivalStats instance (see src/systems/survival)

func _ready() -> void:
    _build_body()
    _build_camera()
    _build_survival()
    add_to_group("player")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
    var col := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    col.shape = capsule
    col.position = Vector3(0, 0.9, 0)
    add_child(col)
    var mesh := MeshInstance3D.new()
    var cap := CapsuleMesh.new()
    cap.radius = 0.4
    cap.height = 1.8
    mesh.mesh = cap
    mesh.position = Vector3(0, 0.9, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.86, 0.79, 0.62)
    mesh.material_override = mat
    add_child(mesh)

func _build_camera() -> void:
    _pivot = Node3D.new()
    _pivot.position = Vector3(0, 1.6, 0)
    _pivot.rotation.x = _pitch
    add_child(_pivot)
    _camera = Camera3D.new()
    _camera.position = Vector3(0, 0.2, 4.0)
    _camera.current = true
    _pivot.add_child(_camera)

func _build_survival() -> void:
    var script := load("res://src/systems/survival/SurvivalStats.gd")
    survival = script.new()
    survival.name = "SurvivalStats"
    add_child(survival)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _yaw -= event.relative.x * MOUSE_SENS
        _pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.2, 0.4)
        rotation.y = _yaw
        _pivot.rotation.x = _pitch
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif Input.is_physical_key_pressed(KEY_SPACE):
        velocity.y = JUMP_VELOCITY

    var input_dir := Vector3.ZERO
    if Input.is_physical_key_pressed(KEY_W):
        input_dir.z -= 1.0
    if Input.is_physical_key_pressed(KEY_S):
        input_dir.z += 1.0
    if Input.is_physical_key_pressed(KEY_A):
        input_dir.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        input_dir.x += 1.0

    var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)
    var speed := SPRINT_SPEED if sprinting else WALK_SPEED

    var dir := transform.basis * input_dir
    dir.y = 0.0
    if dir.length() > 0.001:
        dir = dir.normalized()
    else:
        dir = Vector3.ZERO

    var target := dir * speed
    var horiz := Vector3(velocity.x, 0.0, velocity.z)
    horiz = horiz.move_toward(target, ACCEL * delta)
    velocity.x = horiz.x
    velocity.z = horiz.z
    move_and_slide()
