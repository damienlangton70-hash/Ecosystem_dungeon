class_name PlayerRig
extends Node3D
## Deepforage — procedural low-poly humanoid rig for the player, driven by an
## AnimationTree state machine. Built entirely in GDScript (house convention: no
## scene-file merges) so it stays headless-safe and merge-friendly.
##
## Why this exists: the combat *logic* (stamina, i-frame dodge, light/heavy
## attacks, lock-on, hitstun) already lives in Player.gd — what was missing was a
## body that moves with WEIGHT. This node is the visual/animation layer.
##
## Locomotion (Increment 2 / A1): a 2D BlendSpace keyed on LOCAL velocity —
## X = strafe (right +), Y = forward (+) / backpedal (-), magnitude = walk..run —
## so strafing and backpedalling animate correctly (the Souls-like locked-on
## feel), not a forward run cycle played sideways. A separate Turn state handles
## turn-in-place when the delver stands still and rotates. Player.gd drives it via
## update_locomotion(local_dir, turn_amount); one-shots (roll/attack/hit) go
## through play_state(name) and are never interrupted by locomotion.
##
## Rigging style: rigid "boxes bolted to bones" (one BoneAttachment3D + one box
## MeshInstance per bone). The Graphics agent can later swap the box limbs for
## sculpted low-poly meshes on the SAME skeleton without touching this code.
##
## First-pass greybox: joint proportions and swing arcs are tuned by eye and will
## refine over later combat increments. Everything degrades gracefully — if any
## step fails the character still renders (movement is driven by Player physics,
## not by this rig), so a visual glitch never blocks play or the headless gates.

# Bone layout: [name, parent_name, local_position]. Basis is identity at rest;
# limb meshes are offset within each BoneAttachment to span joint -> child, and
# the "hang" (arms down) pose is applied in the animation clips, not the rest.
const _SKEL := [
    ["Hips", "", Vector3(0.0, 0.98, 0.0)],
    ["Spine", "Hips", Vector3(0.0, 0.18, 0.0)],
    ["Chest", "Spine", Vector3(0.0, 0.20, 0.0)],
    ["Head", "Chest", Vector3(0.0, 0.34, 0.0)],
    ["UpperArm_L", "Chest", Vector3(0.22, 0.16, 0.0)],
    ["LowerArm_L", "UpperArm_L", Vector3(0.27, 0.0, 0.0)],
    ["Hand_L", "LowerArm_L", Vector3(0.24, 0.0, 0.0)],
    ["UpperArm_R", "Chest", Vector3(-0.22, 0.16, 0.0)],
    ["LowerArm_R", "UpperArm_R", Vector3(-0.27, 0.0, 0.0)],
    ["Hand_R", "LowerArm_R", Vector3(-0.24, 0.0, 0.0)],
    ["UpperLeg_L", "Hips", Vector3(0.11, -0.02, 0.0)],
    ["LowerLeg_L", "UpperLeg_L", Vector3(0.0, -0.42, 0.0)],
    ["Foot_L", "LowerLeg_L", Vector3(0.0, -0.42, 0.08)],
    ["UpperLeg_R", "Hips", Vector3(-0.11, -0.02, 0.0)],
    ["LowerLeg_R", "UpperLeg_R", Vector3(0.0, -0.42, 0.0)],
    ["Foot_R", "LowerLeg_R", Vector3(0.0, -0.42, 0.08)],
]

# Rotation axes (all unit vectors, so Quaternion(axis, angle) never errors).
const _AXIS_X := Vector3(1.0, 0.0, 0.0)   # left/right — the forward/back swing axis
const _AXIS_Y := Vector3(0.0, 1.0, 0.0)   # up — the twist axis
const _AXIS_Z := Vector3(0.0, 0.0, 1.0)   # roll — hang the arms down / strafe lean

# Locomotion thresholds (normalised units; local_dir is velocity / SPRINT_SPEED).
const MOVE_DEADZONE := 0.12   # below this speed the delver is "standing"
const TURN_DEADZONE := 0.18   # below this |turn| there's no turn-in-place
const ONE_SHOTS := ["Roll", "AttackLight", "AttackHeavy", "Hit"]

var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree

var _playback: AnimationNodeStateMachinePlayback
var _hand_r_att: BoneAttachment3D
var _hang_l: Quaternion
var _hang_r: Quaternion

func _ready() -> void:
    # Arms rest pointing sideways (+/-X); "hang" rotates them to hang down. Baked
    # into every arm keyframe (rotation tracks set absolute local rotation).
    _hang_l = Quaternion(_AXIS_Z, deg_to_rad(-78.0))
    _hang_r = Quaternion(_AXIS_Z, deg_to_rad(78.0))
    _build_skeleton()
    _build_limbs()
    _build_animations()
    _build_tree()

# ---------------------------------------------------------------- public API --

## Drive locomotion each physics frame. local_dir is velocity in the body's local
## frame divided by sprint speed (x = strafe right, y = forward); turn_amount is
## the normalised yaw change (-1 left .. +1 right) for turn-in-place. Manages the
## Move/Turn states and NEVER interrupts an active roll/attack/hit one-shot.
func update_locomotion(local_dir: Vector2, turn_amount: float) -> void:
    if _playback == null:
        return
    set_move(local_dir)
    set_turn(turn_amount)
    var cur := String(_playback.get_current_node())
    if cur in ONE_SHOTS:
        return
    var moving := local_dir.length() > MOVE_DEADZONE
    if moving or absf(turn_amount) <= TURN_DEADZONE:
        if cur != "Move":
            _playback.travel("Move")
    else:
        if cur != "Turn":
            _playback.travel("Turn")

## Set the 2D locomotion blend directly (x = strafe right, y = forward).
func set_move(local_dir: Vector2) -> void:
    if anim_tree == null:
        return
    anim_tree.set("parameters/Move/blend_position",
        Vector2(clampf(local_dir.x, -1.0, 1.0), clampf(local_dir.y, -1.0, 1.0)))

## Set the turn-in-place blend (-1 left .. +1 right).
func set_turn(turn_amount: float) -> void:
    if anim_tree == null:
        return
    anim_tree.set("parameters/Turn/blend_position", clampf(turn_amount, -1.0, 1.0))

## Back-compat shim (Increment 1 API): forward-only speed blend. Kept so any
## caller mid-migration still animates; prefer update_locomotion / set_move.
func set_locomotion(speed01: float) -> void:
    set_move(Vector2(0.0, clampf(speed01, 0.0, 1.0)))

## Travel to a one-shot state: "Roll", "AttackLight", "AttackHeavy", "Hit".
func play_state(state: String) -> void:
    if _playback == null:
        return
    _playback.travel(state)

## The right-hand BoneAttachment — Player.gd parents the weapon here so the sword
## follows the arm animation instead of floating in front of the body.
func get_hand_attachment() -> Node3D:
    return _hand_r_att

# ---------------------------------------------------------------- skeleton ----

func _build_skeleton() -> void:
    skeleton = Skeleton3D.new()
    skeleton.name = "Skeleton3D"
    add_child(skeleton)
    # Pass 1: create every bone so parents exist before we wire hierarchy.
    for spec in _SKEL:
        skeleton.add_bone(spec[0])
    # Pass 2: parent + rest transform.
    for spec in _SKEL:
        var idx := skeleton.find_bone(spec[0])
        var parent_name: String = spec[1]
        if parent_name != "":
            skeleton.set_bone_parent(idx, skeleton.find_bone(parent_name))
        skeleton.set_bone_rest(idx, Transform3D(Basis(), spec[2]))
    skeleton.reset_bone_poses()

func _build_limbs() -> void:
    var garb := MaterialLib.hide(Palette.TRUNK_DARK)   # dark leather delver's garb
    var skin := MaterialLib.hide(Palette.PALEWILLOW)   # pale head / hands
    # torso mass
    _limb("Hips", Vector3(0.30, 0.20, 0.20), Vector3(0.0, 0.05, 0.0), garb)
    _limb("Chest", Vector3(0.36, 0.34, 0.22), Vector3(0.0, 0.12, 0.0), garb)
    _limb("Head", Vector3(0.26, 0.26, 0.26), Vector3(0.0, 0.14, 0.0), skin)
    # left arm (long axis +X)
    _limb("UpperArm_L", Vector3(0.27, 0.10, 0.10), Vector3(0.135, 0.0, 0.0), garb)
    _limb("LowerArm_L", Vector3(0.24, 0.09, 0.09), Vector3(0.12, 0.0, 0.0), garb)
    _limb("Hand_L", Vector3(0.10, 0.08, 0.08), Vector3(0.05, 0.0, 0.0), skin)
    # right arm (long axis -X)
    _limb("UpperArm_R", Vector3(0.27, 0.10, 0.10), Vector3(-0.135, 0.0, 0.0), garb)
    _limb("LowerArm_R", Vector3(0.24, 0.09, 0.09), Vector3(-0.12, 0.0, 0.0), garb)
    _limb("Hand_R", Vector3(0.10, 0.08, 0.08), Vector3(-0.05, 0.0, 0.0), skin)
    # legs (long axis -Y)
    _limb("UpperLeg_L", Vector3(0.13, 0.42, 0.13), Vector3(0.0, -0.21, 0.0), garb)
    _limb("LowerLeg_L", Vector3(0.11, 0.42, 0.11), Vector3(0.0, -0.21, 0.0), garb)
    _limb("Foot_L", Vector3(0.12, 0.08, 0.24), Vector3(0.0, -0.04, 0.06), garb)
    _limb("UpperLeg_R", Vector3(0.13, 0.42, 0.13), Vector3(0.0, -0.21, 0.0), garb)
    _limb("LowerLeg_R", Vector3(0.11, 0.42, 0.11), Vector3(0.0, -0.21, 0.0), garb)
    _limb("Foot_R", Vector3(0.12, 0.08, 0.24), Vector3(0.0, -0.04, 0.06), garb)

func _limb(bone: String, box: Vector3, offset: Vector3, mat: Material) -> void:
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
    if mat != null:
        mi.material_override = mat
    att.add_child(mi)
    if bone == "Hand_R":
        _hand_r_att = att

# --------------------------------------------------------------- animation ----

func _build_animations() -> void:
    anim_player = AnimationPlayer.new()
    anim_player.name = "AnimationPlayer"
    add_child(anim_player)
    anim_player.root_node = NodePath("..")   # resolve "Skeleton3D:Bone" from the rig root
    var lib := AnimationLibrary.new()
    lib.add_animation("idle", _make_idle())
    lib.add_animation("walk", _make_locomotion(0.9, 0.5, 0.4, 0.05))
    lib.add_animation("run", _make_locomotion(0.55, 0.95, 0.75, 0.16))
    lib.add_animation("walk_back", _make_walk_back())
    lib.add_animation("strafe_left", _make_strafe(-1.0))
    lib.add_animation("strafe_right", _make_strafe(1.0))
    lib.add_animation("turn_left", _make_turn(-1.0))
    lib.add_animation("turn_right", _make_turn(1.0))
    lib.add_animation("roll", _make_roll())
    lib.add_animation("attack_light", _make_attack_light())
    lib.add_animation("attack_heavy", _make_attack_heavy())
    lib.add_animation("hit", _make_hit())
    anim_player.add_animation_library("", lib)

## Add a bone rotation track; keys is Array[[time, Quaternion]].
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

## Forward/back swing about X for a limb; arms pre-multiply the hang pose.
func _swing(angle: float) -> Quaternion:
    return Quaternion(_AXIS_X, angle)

func _arm_l(angle: float) -> Quaternion:
    return Quaternion(_AXIS_X, angle) * _hang_l

func _arm_r(angle: float) -> Quaternion:
    return Quaternion(_AXIS_X, angle) * _hang_r

func _make_idle() -> Animation:
    var a := Animation.new()
    a.length = 3.0
    a.loop_mode = Animation.LOOP_LINEAR
    # Arms hang, with a slow breathing sway.
    _rot(a, "UpperArm_L", [[0.0, _arm_l(0.05)], [1.5, _arm_l(0.12)], [3.0, _arm_l(0.05)]])
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.05)], [1.5, _arm_r(0.12)], [3.0, _arm_r(0.05)]])
    # Subtle chest breathe + head settle.
    _rot(a, "Chest", [[0.0, _swing(0.0)], [1.5, _swing(0.03)], [3.0, _swing(0.0)]])
    _rot(a, "Head", [[0.0, _swing(0.0)], [1.5, _swing(-0.03)], [3.0, _swing(0.0)]])
    return a

func _make_locomotion(length: float, leg_amp: float, arm_amp: float, lean: float) -> Animation:
    var a := Animation.new()
    a.length = length
    a.loop_mode = Animation.LOOP_LINEAR
    var q := length * 0.25
    var h := length * 0.5
    var tq := length * 0.75
    # Contralateral gait: left leg with right arm.
    _rot(a, "UpperLeg_L", [[0.0, _swing(0.0)], [q, _swing(leg_amp)], [h, _swing(0.0)], [tq, _swing(-leg_amp)], [length, _swing(0.0)]])
    _rot(a, "UpperLeg_R", [[0.0, _swing(0.0)], [q, _swing(-leg_amp)], [h, _swing(0.0)], [tq, _swing(leg_amp)], [length, _swing(0.0)]])
    _rot(a, "LowerLeg_L", [[0.0, _swing(0.1)], [q, _swing(0.5)], [h, _swing(0.1)], [tq, _swing(0.2)], [length, _swing(0.1)]])
    _rot(a, "LowerLeg_R", [[0.0, _swing(0.1)], [q, _swing(0.2)], [h, _swing(0.1)], [tq, _swing(0.5)], [length, _swing(0.1)]])
    _rot(a, "UpperArm_L", [[0.0, _arm_l(0.0)], [q, _arm_l(-arm_amp)], [h, _arm_l(0.0)], [tq, _arm_l(arm_amp)], [length, _arm_l(0.0)]])
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.0)], [q, _arm_r(arm_amp)], [h, _arm_r(0.0)], [tq, _arm_r(-arm_amp)], [length, _arm_r(0.0)]])
    # Forward lean + a little vertical bob on the hips.
    _rot(a, "Chest", [[0.0, _swing(lean)], [length, _swing(lean)]])
    _pos(a, "Hips", [[0.0, Vector3(0.0, 0.98, 0.0)], [q, Vector3(0.0, 1.0, 0.0)], [h, Vector3(0.0, 0.98, 0.0)], [tq, Vector3(0.0, 1.0, 0.0)], [length, Vector3(0.0, 0.98, 0.0)]])
    return a

func _make_walk_back() -> Animation:
    # Backpedal: shorter strides, a slight backward lean so it doesn't read as a
    # reversed forward walk.
    var a := Animation.new()
    a.length = 0.95
    a.loop_mode = Animation.LOOP_LINEAR
    var q := 0.2375
    var h := 0.475
    var tq := 0.7125
    var length := 0.95
    var amp := 0.34
    var aamp := 0.26
    _rot(a, "UpperLeg_L", [[0.0, _swing(0.0)], [q, _swing(-amp)], [h, _swing(0.0)], [tq, _swing(amp)], [length, _swing(0.0)]])
    _rot(a, "UpperLeg_R", [[0.0, _swing(0.0)], [q, _swing(amp)], [h, _swing(0.0)], [tq, _swing(-amp)], [length, _swing(0.0)]])
    _rot(a, "UpperArm_L", [[0.0, _arm_l(0.0)], [q, _arm_l(aamp)], [h, _arm_l(0.0)], [tq, _arm_l(-aamp)], [length, _arm_l(0.0)]])
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.0)], [q, _arm_r(-aamp)], [h, _arm_r(0.0)], [tq, _arm_r(aamp)], [length, _arm_r(0.0)]])
    _rot(a, "Chest", [[0.0, _swing(-0.10)], [length, _swing(-0.10)]])   # lean back
    return a

func _make_strafe(sign: float) -> Animation:
    # Side-step shuffle: lean into the strafe (roll about Z), legs abduct/adduct
    # alternately so it reads as sideways travel rather than a forward cycle.
    var a := Animation.new()
    a.length = 0.7
    a.loop_mode = Animation.LOOP_LINEAR
    var h := 0.35
    var length := 0.7
    var lean := Quaternion(_AXIS_Z, sign * -0.14)
    _rot(a, "Chest", [[0.0, lean], [length, lean]])
    _rot(a, "Hips", [[0.0, Quaternion(_AXIS_Z, sign * -0.06)], [length, Quaternion(_AXIS_Z, sign * -0.06)]])
    _rot(a, "UpperLeg_L", [[0.0, Quaternion(_AXIS_Z, 0.0)], [h, Quaternion(_AXIS_Z, sign * 0.34)], [length, Quaternion(_AXIS_Z, 0.0)]])
    _rot(a, "UpperLeg_R", [[0.0, Quaternion(_AXIS_Z, sign * 0.34)], [h, Quaternion(_AXIS_Z, 0.0)], [length, Quaternion(_AXIS_Z, sign * 0.34)]])
    _rot(a, "UpperArm_L", [[0.0, _arm_l(0.0)], [h, _arm_l(0.14)], [length, _arm_l(0.0)]])
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.0)], [h, _arm_r(-0.14)], [length, _arm_r(0.0)]])
    return a

func _make_turn(sign: float) -> Animation:
    # Turn-in-place: small alternating foot lifts (stepping around) + the chest
    # leading the turn. The actual yaw is done by the controller; this just keeps
    # the feet from looking like they slide.
    var a := Animation.new()
    a.length = 0.8
    a.loop_mode = Animation.LOOP_LINEAR
    var h := 0.4
    var length := 0.8
    _rot(a, "UpperLeg_L", [[0.0, _swing(0.0)], [h, _swing(0.28)], [length, _swing(0.0)]])
    _rot(a, "UpperLeg_R", [[0.0, _swing(0.28)], [h, _swing(0.0)], [length, _swing(0.28)]])
    _rot(a, "Chest", [[0.0, Quaternion(_AXIS_Y, 0.0)], [h, Quaternion(_AXIS_Y, sign * 0.18)], [length, Quaternion(_AXIS_Y, 0.0)]])
    _rot(a, "UpperArm_L", [[0.0, _arm_l(0.05)], [h, _arm_l(0.12)], [length, _arm_l(0.05)]])
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.05)], [h, _arm_r(0.12)], [length, _arm_r(0.05)]])
    return a

func _make_roll() -> Animation:
    # Matches Player DODGE_TIME (0.45): a forward somersault over the hips.
    var a := Animation.new()
    a.length = 0.45
    a.loop_mode = Animation.LOOP_NONE
    var full := TAU
    _rot(a, "Hips", [
        [0.0, Quaternion(_AXIS_X, 0.0)],
        [0.1125, Quaternion(_AXIS_X, -full * 0.25)],
        [0.225, Quaternion(_AXIS_X, -full * 0.5)],
        [0.3375, Quaternion(_AXIS_X, -full * 0.75)],
        [0.45, Quaternion(_AXIS_X, -full)],
    ])
    # Tuck: drop and gather the body through the roll.
    _pos(a, "Hips", [[0.0, Vector3(0.0, 0.98, 0.0)], [0.225, Vector3(0.0, 0.62, 0.0)], [0.45, Vector3(0.0, 0.98, 0.0)]])
    _rot(a, "UpperLeg_L", [[0.0, _swing(0.0)], [0.225, _swing(1.4)], [0.45, _swing(0.0)]])
    _rot(a, "UpperLeg_R", [[0.0, _swing(0.0)], [0.225, _swing(1.4)], [0.45, _swing(0.0)]])
    _rot(a, "Chest", [[0.0, _swing(0.0)], [0.225, _swing(0.8)], [0.45, _swing(0.0)]])
    return a

func _make_attack_light() -> Animation:
    # Matches LIGHT.time (0.40); blade lands ~LIGHT.hit (0.12). A fast diagonal chop.
    var a := Animation.new()
    a.length = 0.40
    a.loop_mode = Animation.LOOP_NONE
    _rot(a, "UpperArm_R", [[0.0, _arm_r(-0.7)], [0.12, _arm_r(1.5)], [0.24, _arm_r(1.2)], [0.40, _arm_r(0.1)]])
    _rot(a, "LowerArm_R", [[0.0, _swing(-0.3)], [0.12, _swing(0.2)], [0.40, _swing(0.0)]])
    _rot(a, "Chest", [[0.0, Quaternion(_AXIS_Y, 0.35)], [0.12, Quaternion(_AXIS_Y, -0.35)], [0.40, Quaternion(_AXIS_Y, 0.0)]])
    return a

func _make_attack_heavy() -> Animation:
    # Matches HEAVY.time (0.75); blade lands ~HEAVY.hit (0.40). Overhead wind-up -> slam.
    var a := Animation.new()
    a.length = 0.75
    a.loop_mode = Animation.LOOP_NONE
    _rot(a, "UpperArm_R", [[0.0, _arm_r(0.0)], [0.30, _arm_r(-1.9)], [0.40, _arm_r(1.7)], [0.55, _arm_r(1.4)], [0.75, _arm_r(0.0)]])
    _rot(a, "Chest", [[0.0, _swing(0.0)], [0.30, _swing(-0.25)], [0.40, _swing(0.45)], [0.75, _swing(0.0)]])
    _rot(a, "UpperLeg_L", [[0.0, _swing(0.0)], [0.40, _swing(-0.3)], [0.75, _swing(0.0)]])
    return a

func _make_hit() -> Animation:
    # Matches Player hitstun (0.2): a quick recoil flinch.
    var a := Animation.new()
    a.length = 0.20
    a.loop_mode = Animation.LOOP_NONE
    _rot(a, "Chest", [[0.0, _swing(0.0)], [0.08, _swing(-0.4)], [0.20, _swing(0.0)]])
    _rot(a, "Head", [[0.0, _swing(0.0)], [0.08, _swing(-0.3)], [0.20, _swing(0.0)]])
    _rot(a, "Spine", [[0.0, _swing(0.0)], [0.08, _swing(-0.2)], [0.20, _swing(0.0)]])
    return a

# ------------------------------------------------------------- AnimationTree --

func _build_tree() -> void:
    var sm := AnimationNodeStateMachine.new()

    # 2D locomotion: X = strafe right, Y = forward; magnitude = walk..run.
    var move := AnimationNodeBlendSpace2D.new()
    move.min_space = Vector2(-1.0, -1.0)
    move.max_space = Vector2(1.0, 1.0)
    move.add_blend_point(_anim_node("idle"), Vector2(0.0, 0.0))
    move.add_blend_point(_anim_node("walk"), Vector2(0.0, 0.5))
    move.add_blend_point(_anim_node("run"), Vector2(0.0, 1.0))
    move.add_blend_point(_anim_node("walk_back"), Vector2(0.0, -0.8))
    move.add_blend_point(_anim_node("strafe_left"), Vector2(-0.8, 0.0))
    move.add_blend_point(_anim_node("strafe_right"), Vector2(0.8, 0.0))

    # Turn-in-place: idle at centre, turn clips at the extremes.
    var turn := AnimationNodeBlendSpace1D.new()
    turn.min_space = -1.0
    turn.max_space = 1.0
    turn.add_blend_point(_anim_node("turn_left"), -1.0)
    turn.add_blend_point(_anim_node("idle"), 0.0)
    turn.add_blend_point(_anim_node("turn_right"), 1.0)

    sm.add_node("Move", move, Vector2(300, 160))
    sm.add_node("Turn", turn, Vector2(300, 300))
    sm.add_node("Roll", _anim_node("roll"), Vector2(560, 40))
    sm.add_node("AttackLight", _anim_node("attack_light"), Vector2(560, 130))
    sm.add_node("AttackHeavy", _anim_node("attack_heavy"), Vector2(560, 220))
    sm.add_node("Hit", _anim_node("hit"), Vector2(560, 310))

    # Begin in locomotion.
    _trans(sm, "Start", "Move", true, false)
    # Move <-> Turn are code-driven (update_locomotion), immediate both ways.
    _trans(sm, "Move", "Turn", false, false)
    _trans(sm, "Turn", "Move", false, false)
    # Manual travel INTO one-shots from either locomotion state; auto-return to
    # Move when the clip ends.
    for s in ONE_SHOTS:
        _trans(sm, "Move", s, false, false)
        _trans(sm, "Turn", s, false, false)
        _trans(sm, s, "Move", true, true)
    # A dodge can cancel an attack or a flinch (i-frames are the main defence).
    for s in ["AttackLight", "AttackHeavy", "Hit"]:
        _trans(sm, s, "Roll", false, false)

    anim_tree = AnimationTree.new()
    anim_tree.name = "AnimationTree"
    add_child(anim_tree)
    anim_tree.tree_root = sm
    anim_tree.anim_player = anim_tree.get_path_to(anim_player)
    anim_tree.active = true
    _playback = anim_tree.get("parameters/playback")
    if _playback != null:
        _playback.start("Move")

func _anim_node(anim_name: String) -> AnimationNodeAnimation:
    var n := AnimationNodeAnimation.new()
    n.animation = anim_name
    return n

func _trans(sm: AnimationNodeStateMachine, from: String, to: String, auto: bool, at_end: bool) -> void:
    var tr := AnimationNodeStateMachineTransition.new()
    tr.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END if at_end else AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
    tr.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO if auto else AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED
    sm.add_transition(from, to, tr)
