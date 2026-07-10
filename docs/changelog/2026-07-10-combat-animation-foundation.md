# 2026-07-10 — Combat/animation foundation: skeletal player rig + AnimationTree

**Run type:** interactive (owner-directed). Damien asked to make combat Souls-like
and to work on animations. Approved plan: skeletal rig + AnimationTree; sequence
the combat build starting with the core. This is **Combat Increment 1 — the
movement/animation foundation.**

## Shipped

- **New `src/player/PlayerRig.gd`** — a procedural low-poly humanoid built entirely
  in GDScript (house convention: no scene-file merges):
  - A real **Skeleton3D** (16-bone humanoid: hips/spine/chest/head, arms, legs).
  - Rigid **BoneAttachment3D box limbs** (stylised low-poly; the Graphics agent can
    later swap the boxes for sculpted meshes on the same skeleton without touching
    animation code). Materials come from `MaterialLib.hide()` + `Palette` tokens.
  - **Code-authored animation clips**: idle, walk, run, roll, attack_light,
    attack_heavy, hit — clip lengths/strike timing mirror `Player.LIGHT/HEAVY` and
    `DODGE_TIME`/hitstun so the visible swing lands with the existing hitscan.
  - An **AnimationTree state machine**: a `BlendSpace1D` locomotion node
    (idle→walk→run on a 0..1 speed axis) plus one-shot Roll / AttackLight /
    AttackHeavy / Hit states. Manual `travel()` in, auto-return at clip end; a dodge
    can cancel an attack or a flinch (i-frames remain the primary defence).
  - Tiny public API: `set_locomotion(speed01)`, `play_state(name)`,
    `get_hand_attachment()`.

- **`src/player/Player.gd`** — wired the existing combat/movement state to the rig:
  - Replaced the capsule+sphere visual with the rig (physics capsule unchanged).
  - The **sword now rides the right-hand bone**, so it swings with the arm
    animation instead of being lerped independently (old `_update_weapon()` removed).
  - `_try_attack` / `_try_dodge` / `take_damage` now drive the matching animation
    state; ground speed feeds the locomotion blend each physics frame.

- **`src/systems/visual/Palette.gd`** — removed a duplicate `class_name Palette`
  that collided with the canonical `src/systems/style/Palette.gd` (Godot 4:
  "hides a global script class"). Constants preserved; canonical palette unchanged.

## Design decisions recorded (docs/DECISIONS.md D12–D15)

Animation pipeline (procedural Skeleton3D + BoneAttachment + AnimationTree),
Souls-like commitment + dodge-cancel rule, healing via the cooking/campfire loop
(no separate Estus), and soft-lock lock-on. All as starting values, tune in playtest.

## Notes / honesty

- No Godot binary in the build sandbox, so this was authored against the Godot 4.3
  API and structurally checked; the **editor/CI is the authoritative compile**. The
  rig is greybox: bone proportions and swing arcs are first-pass and will refine.
  It degrades gracefully — movement is physics-driven, so a rig glitch never blocks
  play or the headless self-test.
- Repo write-concurrency was live during this run (HEAD moved twice mid-audit);
  commits were made SHA-fresh and one file at a time.

## Next up (combat/animation track)

1. 2D directional locomotion blend (strafe/backpedal while locked on) + turn-in-place.
2. Attack combo strings + recovery-cancel windows; land-on-hit feedback (hitstop/VFX).
3. Player poise/stagger + a parry; extend the same rig approach to creature hit-react
   and death animations (ties to D5/D6 enemy tells).
4. Death & recovery loop at campfire / magic-circle checkpoints (Souls "bonfire"
   analog) — coin an original name for any recoverable resource.
