class_name Player
extends CharacterBody3D
## Third-person controller: skill-combat core + survival/cooking loop.
## Combat: LMB light attack, RMB heavy attack (slower, committed, big poise
## damage -> staggers foes), Ctrl dodge-roll with i-frames, Q lock-on. A visible
## blade swings on attack. Survival: hunt/butcher/forage/campfire/cook/eat with
## timed buffs; starvation drains HP.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const JUMP_VELOCITY := 5.0
const MOUSE_SENS := 0.0025
const ACCEL := 10.0

# Attack profiles: stamina, damage, total swing time, hit delay, poise damage, reach.
const LIGHT := {"stamina": 16.0, "damage": 14.0, "time": 0.40, "hit": 0.12, "poise": 10.0, "range": 2.6}
const HEAVY := {"stamina": 34.0, "damage": 32.0, "time": 0.75, "hit": 0.40, "poise": 45.0, "range": 3.0}

const DODGE_STAMINA := 22.0
const DODGE_SPEED := 11.0
const DODGE_TIME := 0.45
const IFRAME_TIME := 0.35

const INTERACT_RANGE := 2.8
const COOK_RANGE := 3.6
const STARVE_DPS := 4.0
const FOOD_RAW := 12.0

var max_health := 100.0
var health := 100.0

var inventory := {"raw_meat": 0}
var meals: Array = []
var active_buffs: Array = []
var status_text := ""
var _status_timer := 0.0

var _yaw := 0.0
var _pitch := -0.26
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _pivot: Node3D
var _camera: Camera3D
var _weapon_pivot: Node3D
var _sfx: AudioStreamPlayer
var survival

var _attack_timer := 0.0
var _attack_total := 0.0
var _attack_type := ""
var _hit_done := true
var _dodge_timer := 0.0
var _iframe_timer := 0.0
var _dodge_dir := Vector3.ZERO
var _hitstun := 0.0
var _spawn_point := Vector3.ZERO
var lock_target = null

func _ready() -> void:
    _spawn_point = global_position
    _build_body()
    _build_camera()
    _build_weapon()
    _build_survival()
    _sfx = AudioStreamPlayer.new()
    _sfx.volume_db = -6.0
    add_child(_sfx)
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
    mat.rim_enabled = true
    mat.rim = 0.5
    mesh.material_override = mat
    add_child(mesh)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.28
    hm.height = 0.5
    head.mesh = hm
    head.position = Vector3(0, 1.72, 0)
    head.material_override = mat
    add_child(head)

func _build_camera() -> void:
    _pivot = Node3D.new()
    _pivot.position = Vector3(0, 1.6, 0)
    _pivot.rotation.x = _pitch
    add_child(_pivot)
    _camera = Camera3D.new()
    _camera.position = Vector3(0, 0.2, 4.0)
    _camera.current = true
    _pivot.add_child(_camera)

func _build_weapon() -> void:
    _weapon_pivot = Node3D.new()
    _weapon_pivot.position = Vector3(0.0, 1.1, 0.0)
    add_child(_weapon_pivot)
    var blade := MeshInstance3D.new()
    var bmesh := BoxMesh.new()
    bmesh.size = Vector3(0.08, 0.08, 1.15)
    blade.mesh = bmesh
    blade.position = Vector3(0.36, 0.0, -0.55)
    var bmat := StandardMaterial3D.new()
    bmat.albedo_color = Color(0.76, 0.79, 0.84)
    bmat.metallic = 0.7
    bmat.roughness = 0.3
    blade.material_override = bmat
    _weapon_pivot.add_child(blade)
    var hilt := MeshInstance3D.new()
    var hmesh := BoxMesh.new()
    hmesh.size = Vector3(0.30, 0.09, 0.09)
    hilt.mesh = hmesh
    hilt.position = Vector3(0.36, 0.0, -0.02)
    var hmat := StandardMaterial3D.new()
    hmat.albedo_color = Color(0.30, 0.22, 0.14)
    hilt.material_override = hmat
    _weapon_pivot.add_child(hilt)

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

func _flash(msg: String) -> void:
    status_text = msg
    _status_timer = 3.0

func _play_sfx(name: String) -> void:
    if _sfx == null:
        return
    _sfx.stream = Audio.get_stream(name)
    _sfx.play()

func count_category(cat: String) -> int:
    var n := 0
    for id in inventory:
        if Recipes.INGREDIENTS.has(id) and Recipes.INGREDIENTS[id]["category"] == cat:
            n += int(inventory[id])
    return n

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _yaw -= event.relative.x * MOUSE_SENS
        _pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.2, 0.4)
        if lock_target == null:
            rotation.y = _yaw
        _pivot.rotation.x = _pitch
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _try_attack("light")
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _try_attack("heavy")
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_CTRL:
                _try_dodge()
            KEY_Q:
                _toggle_lock()
            KEY_E:
                _collect()
            KEY_B:
                _build_campfire()
            KEY_C:
                _cook()
            KEY_F:
                _eat()
            KEY_ESCAPE:
                if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
                else:
                    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _nearest_in_group(group: String, rng: float):
    var best = null
    var best_d := rng
    for n in get_tree().get_nodes_in_group(group):
        if not (n is Node3D):
            continue
        var d := global_position.distance_to(n.global_position)
        if d < best_d:
            best_d = d
            best = n
    return best

# ---------- combat ----------
func _try_attack(kind: String) -> void:
    if is_attacking() or is_dodging():
        return
    var a: Dictionary = HEAVY if kind == "heavy" else LIGHT
    if survival == null or not survival.use_stamina(a["stamina"]):
        return
    _attack_type = kind
    _attack_total = a["time"]
    _attack_timer = a["time"]
    _hit_done = false
    _play_sfx("whoosh")

func _do_hit() -> void:
    var a: Dictionary = HEAVY if _attack_type == "heavy" else LIGHT
    var origin := global_position
    var fwd := -global_transform.basis.z
    var landed := false
    for c in get_tree().get_nodes_in_group("creatures"):
        if not (c is Node3D):
            continue
        var to: Vector3 = c.global_position - origin
        to.y = 0.0
        if to.length() <= a["range"] and fwd.dot(to.normalized()) > 0.30:
            if c.has_method("take_damage"):
                c.take_damage(a["damage"], a["poise"])
                landed = true
    if landed:
        _play_sfx("thud")

func _update_weapon() -> void:
    if _weapon_pivot == null:
        return
    if is_attacking() and _attack_total > 0.0:
        var prog := 1.0 - (_attack_timer / _attack_total)
        if _attack_type == "heavy":
            _weapon_pivot.rotation = Vector3(lerpf(-2.0, 1.1, prog), 0.0, 0.0)
        else:
            _weapon_pivot.rotation = Vector3(0.0, lerpf(1.1, -1.1, prog), 0.0)
    else:
        _weapon_pivot.rotation = _weapon_pivot.rotation.lerp(Vector3(0.15, 0.25, 0.0), 0.2)

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
    lock_target = _nearest_in_group("creatures", 20.0)

# ---------- survival / cooking loop ----------
func _collect() -> void:
    var p = _nearest_in_group("pickups", INTERACT_RANGE)
    if p != null:
        var id: String = p.item_id
        inventory[id] = int(inventory.get(id, 0)) + int(p.amount)
        _flash("Butchered: +%d %s" % [int(p.amount), p.display_name])
        p.queue_free()
        return
    var f = _nearest_in_group("forageables", INTERACT_RANGE)
    if f != null and not f.harvested:
        var amt: int = f.harvest()
        if amt > 0:
            inventory[f.item_id] = int(inventory.get(f.item_id, 0)) + amt
            _flash("Foraged: +%d %s" % [amt, f.display_name])
        return
    _flash("Nothing to gather nearby")

func _build_campfire() -> void:
    var parent := get_parent()
    if parent == null:
        return
    var fire := Campfire.new()
    parent.add_child(fire)
    var fwd := -global_transform.basis.z
    fire.global_position = global_position + fwd * 1.6
    fire.global_position.y = 0.0
    _flash("Built a campfire")
    _play_sfx("chime")

func _first_of_category(cat: String) -> String:
    for id in inventory:
        if int(inventory[id]) > 0 and Recipes.INGREDIENTS.has(id) and Recipes.INGREDIENTS[id]["category"] == cat:
            return id
    return ""

func _cook() -> void:
    var fire = _nearest_in_group("campfires", COOK_RANGE)
    if fire == null:
        _flash("Need a campfire to cook (press B to build)")
        return
    if int(inventory.get("raw_meat", 0)) <= 0:
        _flash("No raw meat to cook")
        return
    var herb := _first_of_category("herb")
    var fruit := _first_of_category("fruit")
    inventory["raw_meat"] -= 1
    if herb != "":
        inventory[herb] -= 1
    if fruit != "":
        inventory[fruit] -= 1
    var meal := Recipes.make_meal(herb, fruit)
    meals.append(meal)
    _flash("Cooked %s" % meal["name"])
    _play_sfx("chime")

func _eat() -> void:
    if meals.size() > 0:
        var m: Dictionary = meals.pop_back()
        if survival != null:
            survival.feed(m["food"])
        health = minf(max_health, health + m["heal"])
        for b in m["buffs"]:
            active_buffs.append({"type": b["type"], "mag": b["mag"], "rem": b["dur"]})
        _flash("Ate %s" % m["name"])
        _play_sfx("chime")
    elif int(inventory.get("raw_meat", 0)) > 0:
        inventory["raw_meat"] -= 1
        if survival != null:
            survival.feed(FOOD_RAW)
        _flash("Ate raw meat (+%d food — better cooked)" % int(FOOD_RAW))
    else:
        _flash("Nothing to eat")

func _defense() -> float:
    var d := 0.0
    for b in active_buffs:
        if b["type"] == "defense":
            d += b["mag"]
    return clampf(d, 0.0, 0.8)

func _tick_buffs(delta: float) -> void:
    var i := active_buffs.size() - 1
    while i >= 0:
        var b: Dictionary = active_buffs[i]
        b["rem"] -= delta
        match b["type"]:
            "regen":
                health = minf(max_health, health + b["mag"] * delta)
            "stamina":
                if survival != null:
                    survival.stamina = minf(survival.max_stamina, survival.stamina + b["mag"] * delta)
            "warm":
                if survival != null:
                    survival.temperature = move_toward(survival.temperature, 32.0, 6.0 * delta)
        if b["rem"] <= 0.0:
            active_buffs.remove_at(i)
        i -= 1

# ---------- damage / life ----------
func take_damage(amount: float) -> void:
    if is_invulnerable():
        return
    health -= amount * (1.0 - _defense())
    _hitstun = 0.2
    _play_sfx("hurt")
    if health <= 0.0:
        _respawn()

func _respawn() -> void:
    health = max_health
    global_position = _spawn_point
    velocity = Vector3.ZERO
    lock_target = null
    active_buffs.clear()
    if survival != null:
        survival.hunger = survival.max_hunger
    _flash("You black out... and wake at the entrance")

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

func _physics_process(delta: float) -> void:
    _attack_timer = maxf(_attack_timer - delta, 0.0)
    _dodge_timer = maxf(_dodge_timer - delta, 0.0)
    _iframe_timer = maxf(_iframe_timer - delta, 0.0)
    _hitstun = maxf(_hitstun - delta, 0.0)
    _tick_buffs(delta)

    if is_attacking() and not _hit_done:
        var a: Dictionary = HEAVY if _attack_type == "heavy" else LIGHT
        if _attack_total - _attack_timer >= a["hit"]:
            _do_hit()
            _hit_done = true
    _update_weapon()

    if _status_timer > 0.0:
        _status_timer -= delta
        if _status_timer <= 0.0:
            status_text = ""

    if survival != null and survival.hunger <= 0.0:
        health -= STARVE_DPS * delta
        if health <= 0.0:
            _respawn()

    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif Input.is_physical_key_pressed(KEY_SPACE) and not is_dodging():
        velocity.y = JUMP_VELOCITY

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
