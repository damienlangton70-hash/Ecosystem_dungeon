# 2026-07-10 — Combat/animation Increment 2, A1: 2D locomotion + turn-in-place

**Run type:** interactive (owner-directed follow-on to Increment 1). Damien selected
A1 from the combat/animation Next-up track.

## Shipped

- **`src/player/PlayerRig.gd`**
  - Locomotion `Move` state upgraded from a 1D speed `BlendSpace1D` to a **2D
    `BlendSpace2D`** keyed on LOCAL velocity: X = strafe (right +), Y = forward (+) /
    backpedal (−), magnitude = walk→run. Strafing and backpedalling now animate
    correctly instead of playing a forward run cycle sideways — the key locked-on feel.
  - New **`Turn` state** (`BlendSpace1D`, idle at centre, turn clips at the extremes)
    for **turn-in-place** when the delver stands still and rotates.
  - Five new code-authored clips: `walk_back`, `strafe_left`, `strafe_right`,
    `turn_left`, `turn_right`.
  - New API: `update_locomotion(local_dir, turn_amount)` — sets both blends and
    switches Move⇄Turn, and **never interrupts** an active roll/attack/hit one-shot
    (it early-outs while a one-shot is current). Plus `set_move(Vector2)` /
    `set_turn(float)`. Kept a `set_locomotion(float)` shim (forward-only) so the
    intermediate commit stayed runnable.
  - Transitions extended: Move⇄Turn, and one-shots reachable from both Move and Turn.

- **`src/player/Player.gd`**
  - Feeds the rig each physics frame: local-space velocity (relative to facing) →
    2D blend, and per-frame yaw change → turn amount (`TURN_FULL_RATE` = 2.4 rad/s
    maps to a full-speed turn clip). Tracks `_prev_yaw`.

## Notes / honesty

- Still no Godot in the build sandbox — authored against the Godot 4.3 API +
  structural/consistency checks (bracket balance, every tree-referenced clip exists
  in the library, API wiring). **Editor/CI is the authoritative compile.**
- Greybox: strafe/turn clips are approximate (leg abduction + body lean read as
  sideways/turn); left/right sign and swing arcs will refine with playtest. The
  turn-in-place only triggers when standing (moving takes priority), so circling a
  locked target uses the strafe blend, as intended.

## Next up (combat/animation track)

- **A2 — Attack game-feel:** light/heavy combo strings with recovery-cancel windows;
  land-on-hit feedback (brief hitstop + a slash VFX).
- A3 — player poise/stagger + parry; extend the rig approach to creature hit-react/death.
- A4 — death & recovery loop at campfire / magic-circle checkpoints.
