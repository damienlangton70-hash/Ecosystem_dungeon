class_name Creature
extends CharacterBody3D
## Animalistic creature with a simple AI state machine, poise, and telegraphed
## attacks. Prey flee; predators chase, WIND UP (a red tell) then strike — giving
## the player a window to dodge. Heavy hits break poise and stagger them. Deaths
## report to the Ecosystem. The Lore/Mechanics agents deepen behaviours later.

enum State { WANDER, FLEE, CHASE, ATTACK, STAGGER, DEAD }

@export var species_id := "mosslamb"
@export var display_name := "Mosslamb"
@export var is_predator := false
@export var max_health := 30.0
@export var max_poise := 30.0
@export var move_speed := 3.0
@export var attack_damage := 8.0
@export var detect_radius := 10.0
@export var body_color := Color(0.8, 0.8, 0.75)
@export var body_height := 1.2

const WINDUP_TIME := 0.55
const STRIKE_REACH := 2.4
const STAGGER_TIME := 0.9
const POISE_REGEN := 8.0
const ATTACK_COOLDOWN := 1.4

var health := 30.0
var poise := 30.0
var state: int = State.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _player: Node3D
var _ecosystem: Node
var _wander_dir := Vector3.ZERO
var _wander_timer := 0.0
var _attack_cd := 0.0
var _windup := 0.0
var _telegraph := false
var _stagger_timer := 0.0
var _home := Vector3.ZERO
var _body_mat: StandardMaterial3D

func _ready() -> void:
    health = max_health
    poise = max_poise
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
    _body_mat = StandardMaterial3D.new()
    _body_mat.albedo_color = body_color
    _body_mat.roughness = 0.9
    mesh.material_override = _body_mat
    add_child(mesh)

func _glow(color: Color, on: bool) -> void:
    if _body_mat == null:
        return
    _body_mat.emission_enabled = on
    if on:
        _body_mat.emission = color
        _body_mat.emission_energy_multiplier = 1.9

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
    if poise < max_poise:
        poise = minf(max_poise, poise + POISE_REGEN * delta)

    # Staggered: can't act, slides to a stop, recovers.
    if state == State.STAGGER:
        _stagger_timer -= delta
        velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
        if _stagger_timer <= 0.0:
            poise = max_poise
            _glow(Color.BLACK, false)
            state = State.WANDER
        move_and_slide()
        return

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
        if global_position.distance_to(_home) > 22.0:
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
        if dist > 2.8:
            _glow(Color.BLACK, false)
            _telegraph = false
            state = State.CHASE
        elif _telegraph:
            _windup -= delta
            if _windup <= 0.0:
                _telegraph = false
                _glow(Color.BLACK, false)
                _attack_cd = ATTACK_COOLDOWN
                if dist <= STRIKE_REACH and _player.has_method("take_damage"):
                    _player.take_damage(attack_damage)
        elif _attack_cd <= 0.0:
            _telegraph = true
            _windup = WINDUP_TIME
            _glow(Color(1.0, 0.25, 0.15), true)  # red wind-up tell

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

func take_damage(amount: float, poise_damage: float = 0.0) -> void:
    if state == State.DEAD:
        return
    health -= amount
    poise -= poise_damage
    if health <= 0.0:
        _die()
        return
    if poise <= 0.0:
        _enter_stagger()
    elif not is_predator:
        state = State.FLEE

func _enter_stagger() -> void:
    state = State.STAGGER
    _stagger_timer = STAGGER_TIME
    _telegraph = false
    _glow(Color(0.5, 0.7, 1.0), true)  # blue-white stagger flash
    if _player != null and is_instance_valid(_player):
        var kb := global_position - _player.global_position
        kb.y = 0.0
        if kb.length() > 0.1:
            velocity = kb.normalized() * 6.0

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
