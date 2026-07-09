class_name Creature
extends CharacterBody3D
## Animalistic creature with a simple AI state machine, configured per species.
## Prey flee; predators chase and attack. Deaths report to the Ecosystem so the
## over-hunting/hostility model responds. The Lore + Mechanics agents deepen the
## behaviours (herding, diets, fear memory) over later builds.

enum State { WANDER, FLEE, CHASE, ATTACK, DEAD }

@export var species_id := "mosslamb"
@export var display_name := "Mosslamb"
@export var is_predator := false
@export var max_health := 30.0
@export var move_speed := 3.0
@export var attack_damage := 8.0
@export var detect_radius := 10.0
@export var body_color := Color(0.8, 0.8, 0.75)
@export var body_height := 1.2

var health := 30.0
var state: int = State.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _player: Node3D
var _ecosystem: Node
var _wander_dir := Vector3.ZERO
var _wander_timer := 0.0
var _attack_cd := 0.0
var _home := Vector3.ZERO

func _ready() -> void:
    health = max_health
    _home = global_position
    add_to_group("creatures")
    _build_body()
    _player = get_tree().get_first_node_in_group("player")
    _ecosystem = get_tree().get_first_node_in_group("ecosystem")
    _pick_wander()

func _build_body() -> void:
    var col := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = body_height
    col.shape = cap
    col.position = Vector3(0, body_height * 0.5, 0)
    add_child(col)
    var mesh := MeshInstance3D.new()
    var cm := CapsuleMesh.new()
    cm.radius = 0.35
    cm.height = body_height
    mesh.mesh = cm
    mesh.position = Vector3(0, body_height * 0.5, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = body_color
    mat.roughness = 0.9
    mesh.material_override = mat
    add_child(mesh)

func _pick_wander() -> void:
    var ang := randf() * TAU
    _wander_dir = Vector3(cos(ang), 0.0, sin(ang))
    _wander_timer = randf_range(1.5, 4.0)

func _physics_process(delta: float) -> void:
    if state == State.DEAD:
        return
    if not is_on_floor():
        velocity.y -= _gravity * delta
    _attack_cd = maxf(_attack_cd - delta, 0.0)

    var has_player := _player != null and is_instance_valid(_player)
    var dist := 9999.0
    if has_player:
        dist = global_position.distance_to(_player.global_position)

    var aware := detect_radius
    if _ecosystem != null and _ecosystem.has_method("awareness_multiplier"):
        aware *= _ecosystem.awareness_multiplier()

    if has_player and dist < aware:
        state = State.CHASE if is_predator else State.FLEE
    elif (state == State.CHASE or state == State.FLEE) and dist > aware * 1.4:
        state = State.WANDER

    var desired := Vector3.ZERO
    if state == State.WANDER:
        _wander_timer -= delta
        if _wander_timer <= 0.0:
            _pick_wander()
        if global_position.distance_to(_home) > 18.0:
            _wander_dir = (_home - global_position).normalized()
            _wander_dir.y = 0.0
        desired = _wander_dir * (move_speed * 0.5)
    elif state == State.FLEE and has_player:
        var away := global_position - _player.global_position
        away.y = 0.0
        desired = away.normalized() * move_speed
    elif state == State.CHASE and has_player:
        var to := _player.global_position - global_position
        to.y = 0.0
        desired = to.normalized() * move_speed
        if dist < 1.8:
            state = State.ATTACK
    elif state == State.ATTACK and has_player:
        if dist > 2.2:
            state = State.CHASE
        elif _attack_cd <= 0.0:
            _attack_cd = 1.2
            if _player.has_method("take_damage"):
                _player.take_damage(attack_damage)

    velocity.x = desired.x
    velocity.z = desired.z

    var face := Vector3.ZERO
    if (state == State.CHASE or state == State.ATTACK) and has_player:
        face = _player.global_position - global_position
    elif desired.length() > 0.1:
        face = desired
    face.y = 0.0
    if face.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), 0.2)

    move_and_slide()

func take_damage(amount: float) -> void:
    if state == State.DEAD:
        return
    health -= amount
    if not is_predator:
        state = State.FLEE
    if health <= 0.0:
        _die()

func _die() -> void:
    state = State.DEAD
    if _ecosystem != null and _ecosystem.has_method("record_kill"):
        _ecosystem.record_kill(species_id, 1)
    _drop_meat()
    queue_free()

func _drop_meat() -> void:
    var parent := get_parent()
    if parent == null:
        return
    var pk := Pickup.new()
    pk.item_id = "raw_meat"
    pk.display_name = "Raw Meat"
    pk.amount = 2 if is_predator else 1
    parent.add_child(pk)
    pk.global_position = global_position + Vector3(0, 0.1, 0)
