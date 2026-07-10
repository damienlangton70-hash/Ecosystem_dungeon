class_name Creature
extends CharacterBody3D
## Animalistic creature with a simple AI state machine, poise, and telegraphed
## attacks. Prey flee; predators chase, WIND UP (a red tell, D6) then strike —
## giving the player a window to dodge or parry. Heavy hits break poise and
## stagger them; lesser hits flinch. On death they topple and sink rather than
## popping out. Pack hunters commit only 1-2 attackers at once (D5); the rest
## circle. A successful player parry calls stagger() on the attacker. Deaths
## report to the Ecosystem.

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
@export var form: Dictionary = {}  # per-species silhouette params (see Main.FORMS)
@export var ambush := false          # stalk slowly, then pounce when close
@export var chase_speed_mult := 1.0  # speed burst while chasing

const WINDUP_TIME := 0.50            # D6: attack tell sits in the 0.4-0.5s band
const STRIKE_REACH := 2.4
const STAGGER_TIME := 0.9
const POISE_REGEN := 8.0
const ATTACK_COOLDOWN := 1.4
const POUNCE_SPEED := 9.0
const PACK_ATTACK_LIMIT := 2         # D5: only 1-2 of a species commit at once
const FLINCH_KNOCKBACK := 2.5

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
var _committing := false             # this creature currently holds a pack attack slot
var _stagger_timer := 0.0
var _pounce_timer := 0.0
var _pounce_dir := Vector3.ZERO
var _home := Vector3.ZERO
var _body_mat: StandardMaterial3D
var _sfx: AudioStreamPlayer3D
var _flinch_tween: Tween
var _death_started := false

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
    _body_mat = StandardMaterial3D.new()
    _body_mat.albedo_color = body_color
    _body_mat.roughness = 0.9
    _body_mat.rim_enabled = true
    _body_mat.rim = 0.5
    _body_mat.rim_tint = 0.3

    # Bespoke per-species silhouette (docs/ART_DIRECTION.md §8.3) takes precedence
    # over the form-driven generic rig below. CreatureModels overrides _body_mat's
    # albedo_color to the correct species tone itself.
    if CreatureModels.has_model(species_id):
        CreatureModels.build(species_id, self, _body_mat, body_height)
        _sfx = AudioStreamPlayer3D.new()
        _sfx.unit_size = 6.0
        add_child(_sfx)
        return

    # --- form-driven generic rig (gfx: form-driven per-species silhouettes), unchanged below ---
    var lean := is_predator                 # predators lower + leaner
    var torso_len: float = float(form.get("torso_len", 1.05))
    var torso_radius: float = float(form.get("torso_radius", 0.24 if lean else 0.30))
    var leg_len: float = body_height * 0.42 * float(form.get("leg_len", 1.0))
    var leg_radius: float = float(form.get("leg_radius", 0.085))
    var head_radius: float = float(form.get("head_radius", 0.26))
    var ears: String = str(form.get("ears", "pointed" if lean else "round"))
    var tail_style: String = str(form.get("tail", "short"))
    var biped: bool = bool(form.get("biped", false))

    var torso_y := 0.0
    var head_pos := Vector3.ZERO
    var total_h := 1.0

    if biped:
        # Upright hopper/bird: two big hind legs, near-vertical body, head on top.
        var body_h := maxf(body_height * 0.7, torso_radius * 2.0 + 0.05)
        torso_y = leg_len + body_h * 0.4
        for bx in [-0.15, 0.15]:
            var bleg := MeshInstance3D.new()
            var blm := CylinderMesh.new()
            blm.top_radius = leg_radius * 1.2
            blm.bottom_radius = leg_radius * 1.3
            blm.height = leg_len * 1.3
            bleg.mesh = blm
            bleg.position = Vector3(bx, leg_len * 0.65, 0.06)
            bleg.material_override = _body_mat
            add_child(bleg)
        var btorso := MeshInstance3D.new()
        var btcap := CapsuleMesh.new()
        btcap.radius = torso_radius
        btcap.height = body_h
        btorso.mesh = btcap
        btorso.rotation = Vector3(deg_to_rad(12), 0.0, 0.0)
        btorso.position = Vector3(0, torso_y, 0)
        btorso.material_override = _body_mat
        add_child(btorso)
        head_pos = Vector3(0, torso_y + body_h * 0.5 + head_radius * 0.4, -0.12)
        total_h = head_pos.y + head_radius + 0.1
    else:
        # Quadruped: horizontal torso + four legs.
        torso_y = leg_len + torso_radius * 0.6
        var qtorso := MeshInstance3D.new()
        var qtm := CapsuleMesh.new()
        qtm.radius = torso_radius
        qtm.height = maxf(torso_len, torso_radius * 2.0 + 0.05)
        qtorso.mesh = qtm
        qtorso.rotation = Vector3(deg_to_rad(90), 0.0, 0.0)
        qtorso.position = Vector3(0, torso_y, 0)
        qtorso.material_override = _body_mat
        add_child(qtorso)
        var lx_off := torso_radius * 0.75
        var lz_off := torso_len * 0.32
        for lx in [-lx_off, lx_off]:
            for lz in [-lz_off, lz_off]:
                var qleg := MeshInstance3D.new()
                var qlm := CylinderMesh.new()
                qlm.top_radius = leg_radius
                qlm.bottom_radius = leg_radius * 0.9
                qlm.height = leg_len
                qleg.mesh = qlm
                qleg.position = Vector3(lx, leg_len * 0.5, lz)
                qleg.material_override = _body_mat
                add_child(qleg)
        head_pos = Vector3(0, torso_y + head_radius * 0.4, -(torso_len * 0.5 + 0.12))
        total_h = torso_y + torso_radius + 0.3
        if tail_style != "none":
            var qtail := MeshInstance3D.new()
            var qtlm := CylinderMesh.new()
            qtlm.top_radius = 0.03
            qtlm.bottom_radius = 0.07
            qtlm.height = 0.6 if tail_style == "long" else 0.32
            qtail.mesh = qtlm
            qtail.rotation = Vector3(deg_to_rad(55), 0.0, 0.0)
            qtail.position = Vector3(0, torso_y + 0.05, torso_len * 0.5 + 0.06)
            qtail.material_override = _body_mat
            add_child(qtail)

    # Head (shared).
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = head_radius
    hm.height = head_radius * 1.7
    head.mesh = hm
    head.position = head_pos
    head.material_override = _body_mat
    add_child(head)

    # Ears (style-driven).
    if ears != "none":
        for ex in [-0.12, 0.12]:
            var ear := MeshInstance3D.new()
            var earm := CylinderMesh.new()
            match ears:
                "pointed":
                    earm.top_radius = 0.0
                    earm.bottom_radius = 0.08
                    earm.height = 0.24
                "long":
                    earm.top_radius = 0.04
                    earm.bottom_radius = 0.06
                    earm.height = 0.42
                _:
                    earm.top_radius = 0.06
                    earm.bottom_radius = 0.07
                    earm.height = 0.14
            ear.mesh = earm
            ear.position = head_pos + Vector3(ex, 0.2, 0.02)
            ear.material_override = _body_mat
            add_child(ear)

    # Collision box (feet at y=0).
    var col := CollisionShape3D.new()
    var box := BoxShape3D.new()
    var depth := 0.7 if biped else 1.3
    box.size = Vector3(0.75, total_h, depth)
    col.shape = box
    col.position = Vector3(0, total_h * 0.5, 0)
    add_child(col)

    # Glowing eyes for predators.
    if lean:
        var emat := StandardMaterial3D.new()
        emat.albedo_color = Color(1.0, 0.7, 0.2)
        emat.emission_enabled = true
        emat.emission = Color(1.0, 0.55, 0.15)
        emat.emission_energy_multiplier = 3.0
        for sx in [-0.1, 0.1]:
            var eye := MeshInstance3D.new()
            var em := SphereMesh.new()
            em.radius = 0.05
            em.height = 0.1
            eye.mesh = em
            eye.position = head_pos + Vector3(sx, 0.02, -0.2)
            eye.material_override = emat
            add_child(eye)
    _sfx = AudioStreamPlayer3D.new()
    _sfx.unit_size = 6.0
    add_child(_sfx)

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
        desired = _wander_dir * (move_speed * (0.25 if ambush else 0.5))
    elif state == State.FLEE and has_player:
        var away := global_position - _player.global_position
        away.y = 0.0
        desired = away.normalized() * move_speed
    elif state == State.CHASE and has_player:
        var to := _player.global_position - global_position
        to.y = 0.0
        desired = to.normalized() * (move_speed * chase_speed_mult)
        if dist < 1.8:
            state = State.ATTACK
            if ambush and to.length() > 0.1:
                _pounce_timer = 0.28
                _pounce_dir = to.normalized()
    elif state == State.ATTACK and has_player:
        if _pounce_timer > 0.0:
            _pounce_timer -= delta
            desired = _pounce_dir * POUNCE_SPEED
        elif dist > 2.8:
            _glow(Color.BLACK, false)
            _telegraph = false
            _committing = false
            state = State.CHASE
        elif _telegraph:
            _windup -= delta
            if _windup <= 0.0:
                _telegraph = false
                _committing = false
                _glow(Color.BLACK, false)
                _attack_cd = ATTACK_COOLDOWN
                if dist <= STRIKE_REACH:
                    if _player.has_method("receive_attack"):
                        _player.receive_attack(attack_damage, self)
                    elif _player.has_method("take_damage"):
                        _player.take_damage(attack_damage)
        elif _attack_cd <= 0.0:
            if _pack_can_commit():
                _telegraph = true
                _committing = true
                _windup = WINDUP_TIME
                _glow(Color(1.0, 0.25, 0.15), true)  # red wind-up tell (D6)
                if _sfx != null:
                    _sfx.stream = Audio.get_stream("growl")
                    _sfx.play()
            else:
                # D5: pack is full — circle/feint around the player instead of committing.
                var toc := _player.global_position - global_position
                toc.y = 0.0
                if toc.length() > 0.1:
                    var tangent := Vector3(-toc.z, 0.0, toc.x).normalized()
                    desired = tangent * move_speed * 0.7

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

## Count how many same-species pack-mates are already committed to an attack; a
## creature may commit only if fewer than PACK_ATTACK_LIMIT are (D5).
func _pack_can_commit() -> bool:
    if _committing:
        return true
    var committed := 0
    for c in get_tree().get_nodes_in_group("creatures"):
        if c == self or not is_instance_valid(c):
            continue
        if c is Creature and c.species_id == species_id and c._committing:
            committed += 1
            if committed >= PACK_ATTACK_LIMIT:
                return false
    return true

func take_damage(amount: float, poise_damage: float = 0.0) -> void:
    if state == State.DEAD:
        return
    health -= amount
    poise -= poise_damage
    if health <= 0.0:
        _die()
        return
    if poise <= 0.0:
        _committing = false
        _enter_stagger()
    else:
        _flinch()
        if not is_predator:
            state = State.FLEE

## A non-breaking hit: small knockback + a quick recoil nod so it reads even when
## poise holds. (The player's impact burst already flashes at the body.)
func _flinch() -> void:
    if _player != null and is_instance_valid(_player):
        var kb := global_position - _player.global_position
        kb.y = 0.0
        if kb.length() > 0.1:
            velocity += kb.normalized() * FLINCH_KNOCKBACK
    if _flinch_tween != null and _flinch_tween.is_valid():
        _flinch_tween.kill()
    rotation.x = 0.0
    _flinch_tween = create_tween()
    _flinch_tween.tween_property(self, "rotation:x", -0.18, 0.06)
    _flinch_tween.tween_property(self, "rotation:x", 0.0, 0.12)

## Public: a successful player parry staggers the attacker outright.
func stagger() -> void:
    if state == State.DEAD:
        return
    poise = 0.0
    _committing = false
    _enter_stagger()

func _enter_stagger() -> void:
    state = State.STAGGER
    _stagger_timer = STAGGER_TIME
    _telegraph = false
    _committing = false
    if _flinch_tween != null and _flinch_tween.is_valid():
        _flinch_tween.kill()
    rotation.x = 0.0
    _glow(Color(0.5, 0.7, 1.0), true)  # blue-white stagger flash
    if _player != null and is_instance_valid(_player):
        var kb := global_position - _player.global_position
        kb.y = 0.0
        if kb.length() > 0.1:
            velocity = kb.normalized() * 6.0

func _die() -> void:
    if _death_started:
        return
    _death_started = true
    state = State.DEAD
    _telegraph = false
    _committing = false
    if _flinch_tween != null and _flinch_tween.is_valid():
        _flinch_tween.kill()
    remove_from_group("creatures")   # corpse can't be targeted/hit again
    _glow(Color.BLACK, false)
    if _ecosystem != null and _ecosystem.has_method("record_kill"):
        _ecosystem.record_kill(species_id, 1)
    _drop_meat()
    # Topple + sink, then remove — a death beat instead of a pop-out.
    var fall := 1.0 if randf() < 0.5 else -1.0
    var t := create_tween()
    t.tween_property(self, "rotation:z", fall * (PI * 0.5), 0.55)
    t.parallel().tween_property(self, "position:y", position.y - 0.6, 0.8)
    t.tween_callback(queue_free)

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
