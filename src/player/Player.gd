class_name Player
extends CharacterBody3D
## Third-person player controller with a Dark Souls-style skill-combat core:
## stamina-gated light attack, dodge-roll with invulnerability frames, and
## right-click lock-on. Health + hunger + stamina drive the survival loop.
## The Mechanics agent extends this (heavy attacks, weapons, poise, parries).

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const JUMP_VELOCITY := 5.0
const MOUSE_SENS := 0.0025
const ACCEL := 10.0

const ATTACK_STAMINA := 18.0
const ATTACK_DAMAGE := 14.0
const ATTACK_RANGE := 2.6
const ATTACK_TIME := 0.35
const DODGE_STAMINA := 22.0
const DODGE_SPEED := 11.0
const DODGE_TIME := 0.45
const IFRAME_TIME := 0.35

var max_health := 100.0
var health := 100.0

var _yaw := 0.0
var _pitch := -0.26
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _pivot: Node3D
var _camera: Camera3D
var survival  # SurvivalStats instance

var _attack_timer := 0.0
var _dodge_timer := 0.0
var _iframe_timer := 0.0
var _dodge_dir := Vector3.ZERO
var _hitstun := 0.0
var _spawn_point := Vector3.ZERO
var lock_target = null  # a Creature, or null

func _ready() -> void:
    _spawn_point = global_position
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

func is_attacking() -> bool:
    return _attack_timer > 0.0

func is_dodging() -> bool:
    return _dodge_timer > 0.0

func is_invulnerable() -> bool:
    return _iframe_timer > 0.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _yaw -= event.relative.x * MOUSE_SENS
        _pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.2, 0.4)
        if lock_target == null:
            rotation.y = _yaw
        _pivot.rotation.x = _pitch
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _try_attack()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _toggle_lock()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_CTRL:
            _try_dodge()
        elif event.keycode == KEY_ESCAPE:
            if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            else:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _try_attack() -> void:
    if is_attacking() or is_dodging():
        return
    if survival == null or not survival.use_stamina(ATTACK_STAMINA):
        return
    _attack_timer = ATTACK_TIME
    var origin := global_position
    var fwd := -global_transform.basis.z
    for c in get_tree().get_nodes_in_group("creatures"):
        if not (c is Node3D):
            continue
        var to: Vector3 = c.global_position - origin
        to.y = 0.0
        if to.length() <= ATTACK_RANGE and fwd.dot(to.normalized()) > 0.35:
            if c.has_method("take_damage"):
                c.take_damage(ATTACK_DAMAGE)

func _try_dodge() -> void:
    if is_dodging():
        return
    if survival == null or not survival.use_stamina(DODGE_STAMINA):
        return
    var dir := _input_dir()
    dir.y = 0.0
    if dir.length() < 0.1:
        dir = -global_transform.basis.z
    _dodge_dir = dir.normalized()
    _dodge_timer = DODGE_TIME
    _iframe_timer = IFRAME_TIME

func _toggle_lock() -> void:
    if lock_target != null:
        lock_target = null
        return
    var best = null
    var best_d := 20.0
    for c in get_tree().get_nodes_in_group("creatures"):
        if not (c is Node3D):
            continue
        var d := global_position.distance_to(c.global_position)
        if d < best_d:
            best_d = d
            best = c
    lock_target = best

func _input_dir() -> Vector3:
    var v := Vector3.ZERO
    if Input.is_physical_key_pressed(KEY_W):
        v.z -= 1.0
    if Input.is_physical_key_pressed(KEY_S):
        v.z += 1.0
    if Input.is_physical_key_pressed(KEY_A):
        v.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        v.x += 1.0
    return transform.basis * v

func take_damage(amount: float) -> void:
    if is_invulnerable():
        return
    health -= amount
    _hitstun = 0.2
    if health <= 0.0:
        _respawn()

func _respawn() -> void:
    health = max_health
    global_position = _spawn_point
    velocity = Vector3.ZERO
    lock_target = null
    if survival != null:
        survival.hunger = survival.max_hunger

func _physics_process(delta: float) -> void:
    _attack_timer = maxf(_attack_timer - delta, 0.0)
    _dodge_timer = maxf(_dodge_timer - delta, 0.0)
    _iframe_timer = maxf(_iframe_timer - delta, 0.0)
    _hitstun = maxf(_hitstun - delta, 0.0)

    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif Input.is_physical_key_pressed(KEY_SPACE) and not is_dodging():
        velocity.y = JUMP_VELOCITY

    # Lock-on keeps the player facing the target.
    if lock_target != null and is_instance_valid(lock_target):
        var ft := Vector3(lock_target.global_position.x, global_position.y, lock_target.global_position.z)
        if global_position.distance_to(ft) > 0.4:
            look_at(ft, Vector3.UP)
            _yaw = rotation.y
        if global_position.distance_to(lock_target.global_position) > 22.0:
            lock_target = null
    elif lock_target != null:
        lock_target = null

    if is_dodging():
        velocity.x = _dodge_dir.x * DODGE_SPEED
        velocity.z = _dodge_dir.z * DODGE_SPEED
        move_and_slide()
        return

    var target := Vector3.ZERO
    if _hitstun <= 0.0 and not is_attacking():
        var dir := _input_dir()
        dir.y = 0.0
        if dir.length() > 0.1:
            dir = dir.normalized()
        else:
            dir = Vector3.ZERO
        var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)
        var speed := SPRINT_SPEED if sprinting else WALK_SPEED
        target = dir * speed

    var horiz := Vector3(velocity.x, 0.0, velocity.z)
    horiz = horiz.move_toward(target, ACCEL * delta)
    velocity.x = horiz.x
    velocity.z = horiz.z
    move_and_slide()
