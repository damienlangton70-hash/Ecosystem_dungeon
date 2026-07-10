# 2026-07-10 — Combat/animation Increment 2, A2: attack game-feel

**Run type:** interactive (owner-directed). Damien selected A2 from the combat/animation track.
Goal: make attacks feel like they connect — combo strings, recovery-cancel windows, and
land-on-hit feedback.

## Shipped

- **`src/systems/combat/CombatFX.gd` (new)** — self-contained, fire-and-forget combat FX built
  in code (no shaders/binaries): `slash(parent, xform, color)` spawns a bright blade streak along
  the swing; `impact(parent, pos, color)` spawns a burst where a blow lands. Each fades + frees
  itself via a `Tween`. Colours from `Palette` (pale steel streak, ember connect). Reusable by
  creatures later.

- **`src/player/PlayerRig.gd`** — three distinct **light-attack combo clips**
  (`attack_light1` R→L chop, `attack_light2` backhand, `attack_light3` overhead finisher) with
  matching `AttackLight1/2/3` states (replacing the single AttackLight); clip lengths/strike
  timing mirror the `LIGHT_CHAIN` data. New **`set_frozen(bool)`** (toggles `AnimationTree.active`)
  for a hitstop freeze-frame. ONE_SHOTS + transitions updated.

- **`src/player/Player.gd`** — attacks are now **data-driven** (`LIGHT_CHAIN` + reshaped `HEAVY`,
  each carrying a `cancel` window time + `anim` state):
  - **Combo strings:** pressing light again walks the 3-hit chain (heavy resets it).
  - **Recovery-cancel + input buffering:** `_can_cancel_attack()` opens the window after the hit;
    pressing inside it chains immediately, pressing earlier **buffers** and fires the instant the
    window opens. `_tick_attack()` runs the timeline.
  - **Hitstop:** a landed blow freezes the attack timeline **and** the rig for `HITSTOP` (0.06s) —
    the core "it connected" punch — plus a `thud`, a slash arc, and an impact burst.
  - Dodging or taking a hit **breaks the combo** (and clears hitstop). Locomotion feed is skipped
    during the freeze.

## Notes / honesty

- Still no Godot in the build sandbox — authored to the Godot 4.3 API + structural/consistency
  checks (bracket balance; every AnimationTree clip resolves; every `play_state` target is a real
  state node; no bare `LIGHT` left). **Editor/CI is the authoritative compile.**
- Combo damage/stamina/cancel numbers and `HITSTOP` are **provisional tuning** — expect one
  playtest pass. The slash arc is a greybox streak (a proper swept trail can come with polish).
- Commit order CombatFX → PlayerRig → Player (each runnable); SHA-fresh, no 409s.
  Commits `f53af06`, `0b70828`, `f8838a8`.

## Next up (combat/animation track)

- **A3 — Defence + reactions:** player poise/stagger + a parry; extend the rig approach to
  creature **hit-react + death** animations (dovetails with the Ashjackal tell D6 / pack rule D5).
- A4 — death & recovery loop at campfire / magic-circle checkpoints.
