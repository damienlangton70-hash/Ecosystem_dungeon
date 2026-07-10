class_name CreatureRig
extends Node3D
## Deepforage — procedural QUADRUPED skeletal rig for creatures, driven by an
## AnimationTree, the creature counterpart to the player's PlayerRig. Built
## entirely in GDScript (house convention: no scene-file merges) and headless-safe.
##
## This is the start of the creature-rig track: instead of the static bespoke
## meshes in CreatureModels, a species with an entry in _PARAMS gets a real
## Skeleton3D (Body/Chest/Neck/Head/Rear/Tail + four two-segment legs) with rigid
## BoneAttachment3D box limbs, plus code-authored clips (idle / walk / run /
## attack / hit / death) blended by an AnimationTree state machine. One parametric
## skeleton serves every quadruped; per-species proportions (leg length, girth,
## neck, head, ears, tail, predator eyes) come from _PARAMS, so Mosslamb reads
## bulky, Ashjackal lean-and-tall, and the Gloamstalker Lynx long-and-low.
##
## Creature.gd sets species_id + body_mat + body_height, adds this as a child, and
## drives it: set_locomotion(speed01) each frame, play_state("Attack"/"Hit"/
## "Death") from its AI state machine. The body shares Creature's material, so the
## existing telegraph (red) and stagger (blue) _glow still tint the rigged body.
##
## Greybox: proportions and gait arcs are first-pass and will refine in playtest;
## Graphics can later swap the box limbs for sculpted meshes on the same skeleton.

const _AX_X := Vector3(1.0, 0.0, 0.0)   # forward/back swing (legs, pitch)
const _AX_Y := Vector3(0.0, 1.0, 0.0)   # yaw/twist (tail sway)
const _AX_Z := Vector3(0.0, 0.0, 1.0)   # roll (death collapse)

# Per-species proportions. legs/torso are metres before body_height scaling.
const _PARAMS := {
    "mosslamb": {"legs": 0.60, "torso_len": 1.15, "torso_r": 0.36, "neck": 0.20, "head": 0.27, "tail": "short", "ears": "round", "predator": false},
    "ashjackal": {"legs": 0.80, "torso_len": 1.05, "torso_r": 0.22, "neck": 0.26, "head": 0.20, "tail": "long", "ears": "pointed", "predator": true},
    "gloamstalker_lynx": {"legs": 0.66, "torso_len": 1.28, "torso_r": 0.20, "neck": 0.22, "head": 0.19, "tail": "long", "ears": "pointed", "predator": true},
}

# Set by Creature before add_child.
var species_id := "mosslamb"
var body_mat: Material
var body_height := 1.2

var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _body_y := 0.6   # rest height of the Body root bone (feet at y=0)

static func has_rig(sid: String) -> bool:
    return _PARAMS.has(sid)

func _ready() -> void:
    _build_skeleton()
    _build_animations()
    _build_tree()

# ---------------------------------------------------------------- public API --

## 0 = idle, ~0.5 = walk, 1 = run.
func set_locomotion(speed01: float) -> void:
    if anim_tree == null:
        return
    anim_tree.set("parameters/Locomotion/blend_position", clampf(speed01, 0.0, 1.0))

## Travel to a one-shot: "Attack", "Hit", or "Death" (Death is terminal).
func play_state(state: String) -> void:
    if _playback == null:
        return
    _playback.travel(state)

# ---------------------------------------------------------------- skeleton ----

func _build_skeleton() -> void:
    var p: Dictionary = _PARAMS.get(species_id, _PARAMS["mosslamb"])
    var sc: float = maxf(body_height, 0.6) / 1.2
    var legs: float = float(p["legs"]) * sc
    var tl: float = float(p["torso_len"]) * sc
    var tr: float = float(p["torso_r"]) * sc
    var neck: float = float(p["neck"]) * sc
    var head: float = float(p["head"]) * sc
    _body_y = legs
    var half_leg := legs * 0.5
    var xoff := tr * 0.85

    # [name, parent, local_position]
    var layout := [
        ["Body", "", Vector3(0.0, _body_y, 0.0)],
        ["Chest", "Body", Vector3(0.0, 0.0, -tl * 0.30)],
        ["Neck", "Chest", Vector3(0.0, tr * 0.55, -tl * 0.12)],
        ["Head", "Neck", Vector3(0.0, tr * 0.35, -neck * 1.1)],
        ["Rear", "Body", Vector3(0.0, 0.0, tl * 0.32)],
        ["Tail", "Rear", Vector3(0.0, tr * 0.45, tl * 0.10)],
        ["LegFL_U", "Chest", Vector3(xoff, 0.0, 0.0)],
        ["LegFL_L", "LegFL_U", Vector3(0.0, -half_leg, 0.0)],
        ["LegFR_U", "Chest", Vector3(-xoff, 0.0, 0.0)],
        ["LegFR_L", "LegFR_U", Vector3(0.0, -half_leg, 0.0)],
        ["LegHL_U", "Rear", Vector3(xoff, 0.0, 0.0)],
        ["LegHL_L", "LegHL_U", Vector3(0.0, -half_leg, 0.0)],
        ["LegHR_U", "Rear", Vector3(-xoff, 0.0, 0.0)],
        ["LegHR_L", "LegHR_U", Vector3(0.0, -half_leg, 0.0)],
    ]

    skeleton = Skeleton3D.new()
    skeleton.name = "Skeleton3D"
    add_child(skeleton)
    for spec in layout:
        skeleton.add_bone(spec[0])
    for spec in layout:
        var idx := skeleton.find_bone(spec[0])
        if String(spec[1]) != "":
            skeleton.set_bone_parent(idx, skeleton.find_bone(spec[1]))
        skeleton.set_bone_rest(idx, Transform3D(Basis(), spec[2]))
    skeleton.reset_bone_poses()

    _build_limbs(p, tl, tr, neck, head, half_leg)

func _build_limbs(p: Dictionary, tl: float, tr: float, neck: float, head: float, half_leg: float) -> void:
    var tail_len: float = (0.6 if str(p["tail"]) == "long" else 0.32) * (maxf(body_height, 0.6) / 1.2)
    _limb("Body", Vector3(tr * 1.7, tr * 1.5, tl * 0.95), Vector3(0.0, 0.0, 0.0))
    _limb("Neck", Vector3(tr * 0.75, tr * 0.75, neck * 1.1), Vector3(0.0, 0.0, -neck * 0.5))
    _limb("Head", Vector3(head * 1.3, head * 1.1, head * 1.5), Vector3(0.0, 0.0, -head * 0.5))
    _limb("Tail", Vector3(tr * 0.35, tr * 0.35, tail_len), Vector3(0.0, 0.0, tail_len * 0.5))
    for leg in ["LegFL", "LegFR", "LegHL", "LegHR"]:
        _limb(leg + "_U", Vector3(tr * 0.5, half_leg, tr * 0.5), Vector3(0.0, -half_leg * 0.5, 0.0))
        _limb(leg + "_L", Vector3(tr * 0.42, half_leg, tr * 0.42), Vector3(0.0, -half_leg * 0.5, 0.0))
    _build_head_features(p, tr, head)

func _limb(bone: String, box: Vector3, offset: Vector3) -> void:
    if skeleton.find_bone(bone) < 0:
        return
    var att := BoneAttachment3D.new()
    att.name = "att_" + bone
    skeleton.add_child(att)
    att.bone_name = bone
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = box
    mi.mesh = bm
    mi.position = offset
    if body_mat != null:
        mi.material_override = body_mat
    att.add_child(mi)

func _build_head_features(p: Dictionary, tr: float, head: float) -> void:
    var head_idx := skeleton.find_bone("Head")
    if head_idx < 0:
        return
    var att := BoneAttachment3D.new()
    att.name = "att_HeadFeatures"
    skeleton.add_child(att)
    att.bone_name = "Head"
    # Ears.
    var ears := str(p["ears"])
    for ex in [-1.0, 1.0]:
        var ear := MeshInstance3D.new()
        var em := CylinderMesh.new()
        if ears == "pointed":
            em.top_radius = 0.0
            em.bottom_radius = head * 0.28
            em.height = head * 0.9
        else:
            em.top_radius = head * 0.22
            em.bottom_radius = head * 0.26
            em.height = head * 0.4
        ear.mesh = em
        ear.position = Vector3(ex * head * 0.5, head * 0.7, -head * 0.3)
        if body_mat != null:
            ear.material_override = body_mat
        att.add_child(ear)
    # Predator eye-shine.
    if bool(p["predator"]):
        var emat := StandardMaterial3D.new()
        emat.albedo_color = Palette.AMBER_EYESHINE
        emat.emission_enabled = true
        emat.emission = Palette.AMBER_EYESHINE
        emat.emission_energy_multiplier = 3.0
        for sx in [-1.0, 1.0]:
            var eye := MeshInstance3D.new()
            var sm := SphereMesh.new()
            sm.radius = head * 0.16
            sm.height = head * 0.32
            eye.mesh = sm
            eye.position = Vector3(sx * head * 0.42, head * 0.2, -head * 1.0)
            eye.material_override = emat
            att.add_child(eye)

# --------------------------------------------------------------- animation ----

func _build_animations() -> void:
    anim_player = AnimationPlayer.new()
    anim_player.name = "AnimationPlayer"
    add_child(anim_player)
    anim_player.root_node = NodePath("..")
    var lib := AnimationLibrary.new()
    lib.add_animation("idle", _make_idle())
    lib.add_animation("walk", _make_gait(0.7, 0.5, 0.03))
    lib.add_animation("run", _make_gait(0.45, 0.95, 0.06))
    lib.add_animation("attack", _make_attack())
    lib.add_animation("hit", _make_hit())
    lib.add_animation("death", _make_death())
    anim_player.add_animation_library("", lib)

func _rot(anim: Animation, bone: String, keys: Array) -> void:
    var t := anim.add_track(Animation.TYPE_ROTATION_3D)
    anim.track_set_path(t, NodePath("Skeleton3D:%s" % bone))
    for k in keys:
        anim.rotation_track_insert_key(t, k[0], k[1])

func _pos(anim: Animation, bone: String, keys: Array) -> void:
    var t := anim.add_track(Animation.TYPE_POSITION_3D)
    anim.track_set_path(t, NodePath("Skeleton3D:%s" % bone))
    for k in keys:
        anim.position_track_insert_key(t, k[0], k[1])

func _sw(a: float) -> Quaternion:
    return Quaternion(_AX_X, a)

func _ty(a: float) -> Quaternion:
    return Quaternion(_AX_Y, a)

func _rz(a: float) -> Quaternion:
    return Quaternion(_AX_Z, a)

func _make_idle() -> Animation:
    var a := Animation.new()
    a.length = 2.5
    a.loop_mode = Animation.LOOP_LINEAR
    _pos(a, "Body", [[0.0, Vector3(0, _body_y, 0)], [1.25, Vector3(0, _body_y + 0.012, 0)], [2.5, Vector3(0, _body_y, 0)]])
    _rot(a, "Neck", [[0.0, _sw(0.0)], [1.25, _sw(0.05)], [2.5, _sw(0.0)]])
    _rot(a, "Tail", [[0.0, _ty(-0.12)], [1.25, _ty(0.12)], [2.5, _ty(-0.12)]])
    return a

func _make_gait(length: float, amp: float, bob: float) -> Animation:
    var a := Animation.new()
    a.length = length
    a.loop_mode = Animation.LOOP_LINEAR
    var q := length * 0.25
    var h := length * 0.5
    var tq := length * 0.75
    # Diagonal gait: FL + HR together, FR + HL opposite.
    var pair_a := [[0.0, _sw(0.0)], [q, _sw(amp)], [h, _sw(0.0)], [tq, _sw(-amp)], [length, _sw(0.0)]]
    var pair_b := [[0.0, _sw(0.0)], [q, _sw(-amp)], [h, _sw(0.0)], [tq, _sw(amp)], [length, _sw(0.0)]]
    _rot(a, "LegFL_U", pair_a)
    _rot(a, "LegHR_U", pair_a)
    _rot(a, "LegFR_U", pair_b)
    _rot(a, "LegHL_U", pair_b)
    # Lower legs trail with a small bend.
    _rot(a, "LegFL_L", [[0.0, _sw(0.15)], [q, _sw(0.4)], [length, _sw(0.15)]])
    _rot(a, "LegHR_L", [[0.0, _sw(0.15)], [q, _sw(0.4)], [length, _sw(0.15)]])
    _rot(a, "LegFR_L", [[0.0, _sw(0.15)], [tq, _sw(0.4)], [length, _sw(0.15)]])
    _rot(a, "LegHL_L", [[0.0, _sw(0.15)], [tq, _sw(0.4)], [length, _sw(0.15)]])
    _pos(a, "Body", [[0.0, Vector3(0, _body_y, 0)], [q, Vector3(0, _body_y + bob, 0)], [h, Vector3(0, _body_y, 0)], [tq, Vector3(0, _body_y + bob, 0)], [length, Vector3(0, _body_y, 0)]])
    _rot(a, "Neck", [[0.0, _sw(0.0)], [h, _sw(0.08)], [length, _sw(0.0)]])
    _rot(a, "Tail", [[0.0, _ty(-0.15)], [h, _ty(0.15)], [length, _ty(-0.15)]])
    return a

func _make_attack() -> Animation:
    # Wind-up coil (0-0.3) then lunge forward (strike ~0.5), recover to 0.6.
    var a := Animation.new()
    a.length = 0.6
    a.loop_mode = Animation.LOOP_NONE
    _pos(a, "Body", [[0.0, Vector3(0, _body_y, 0)], [0.3, Vector3(0, _body_y - 0.06, 0.12)], [0.5, Vector3(0, _body_y, -0.22)], [0.6, Vector3(0, _body_y, 0)]])
    _rot(a, "Neck", [[0.0, _sw(0.0)], [0.3, _sw(-0.22)], [0.5, _sw(0.4)], [0.6, _sw(0.0)]])
    _rot(a, "Head", [[0.0, _sw(0.0)], [0.5, _sw(0.3)], [0.6, _sw(0.0)]])
    _rot(a, "LegFL_U", [[0.0, _sw(0.0)], [0.5, _sw(0.5)], [0.6, _sw(0.0)]])
    _rot(a, "LegFR_U", [[0.0, _sw(0.0)], [0.5, _sw(0.5)], [0.6, _sw(0.0)]])
    return a

func _make_hit() -> Animation:
    var a := Animation.new()
    a.length = 0.25
    a.loop_mode = Animation.LOOP_NONE
    _pos(a, "Body", [[0.0, Vector3(0, _body_y, 0)], [0.08, Vector3(0, _body_y, 0.14)], [0.25, Vector3(0, _body_y, 0)]])
    _rot(a, "Neck", [[0.0, _sw(0.0)], [0.08, _sw(-0.3)], [0.25, _sw(0.0)]])
    return a

func _make_death() -> Animation:
    # Collapse: legs buckle, body drops and rolls onto its side. Terminal pose.
    var a := Animation.new()
    a.length = 0.7
    a.loop_mode = Animation.LOOP_NONE
    _pos(a, "Body", [[0.0, Vector3(0, _body_y, 0)], [0.5, Vector3(0, _body_y * 0.35, 0)], [0.7, Vector3(0, _body_y * 0.28, 0)]])
    _rot(a, "Body", [[0.0, _rz(0.0)], [0.55, _rz(1.2)], [0.7, _rz(1.3)]])
    _rot(a, "Neck", [[0.0, _sw(0.0)], [0.4, _sw(0.5)], [0.7, _sw(0.5)]])
    for leg in ["LegFL_U", "LegFR_U", "LegHL_U", "LegHR_U"]:
        _rot(a, leg, [[0.0, _sw(0.0)], [0.4, _sw(0.8)], [0.7, _sw(0.6)]])
    return a

# ------------------------------------------------------------- AnimationTree --

func _build_tree() -> void:
    var sm := AnimationNodeStateMachine.new()

    var loco := AnimationNodeBlendSpace1D.new()
    loco.min_space = 0.0
    loco.max_space = 1.0
    loco.add_blend_point(_anim_node("idle"), 0.0)
    loco.add_blend_point(_anim_node("walk"), 0.5)
    loco.add_blend_point(_anim_node("run"), 1.0)

    sm.add_node("Locomotion", loco, Vector2(280, 160))
    sm.add_node("Attack", _anim_node("attack"), Vector2(540, 60))
    sm.add_node("Hit", _anim_node("hit"), Vector2(540, 160))
    sm.add_node("Death", _anim_node("death"), Vector2(540, 260))

    _trans(sm, "Start", "Locomotion", true, false)
    _trans(sm, "Locomotion", "Attack", false, false)
    _trans(sm, "Locomotion", "Hit", false, false)
    _trans(sm, "Locomotion", "Death", false, false)
    _trans(sm, "Attack", "Locomotion", true, true)
    _trans(sm, "Hit", "Locomotion", true, true)
    # A creature can die mid-swing or mid-flinch.
    _trans(sm, "Attack", "Death", false, false)
    _trans(sm, "Hit", "Death", false, false)
    # Death is terminal (no outgoing transitions).

    anim_tree = AnimationTree.new()
    anim_tree.name = "AnimationTree"
    add_child(anim_tree)
    anim_tree.tree_root = sm
    anim_tree.anim_player = anim_tree.get_path_to(anim_player)
    anim_tree.active = true
    _playback = anim_tree.get("parameters/playback")
    if _playback != null:
        _playback.start("Locomotion")

func _anim_node(anim_name: String) -> AnimationNodeAnimation:
    var n := AnimationNodeAnimation.new()
    n.animation = anim_name
    return n

func _trans(sm: AnimationNodeStateMachine, from: String, to: String, auto: bool, at_end: bool) -> void:
    var tr := AnimationNodeStateMachineTransition.new()
    tr.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END if at_end else AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
    tr.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO if auto else AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED
    sm.add_transition(from, to, tr)
