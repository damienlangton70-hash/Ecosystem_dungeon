# 2026-07-10 — Creature skeletal-rig track: START (Mosslamb, Ashjackal, Gloamstalker Lynx)

**Run type:** interactive (owner-directed). Damien opened the separate track: give creatures true
Skeleton3D + AnimationTree rigs like the player, beginning with the 3 spawned species.

## Shipped

- **`src/creatures/CreatureRig.gd` (new)** — the creature counterpart to `PlayerRig`: a **parametric
  quadruped** Skeleton3D (Body / Chest / Neck / Head / Rear / Tail + four two-segment legs) with
  rigid `BoneAttachment3D` box limbs, driven by an **AnimationTree** state machine. One skeleton
  serves every quadruped; per-species proportions come from `_PARAMS` (leg length, girth, neck,
  head, ears, tail, predator eye-shine) so the three read distinctly:
  - **Mosslamb** — short-legged, bulky, round ears, short tail, no eye-shine.
  - **Ashjackal** — tall, lean, pointed ears, long tail, amber predator eyes.
  - **Gloamstalker Lynx** — long, low, pointed ears, long tail, amber predator eyes.
  - Code clips: **idle, walk, run** (diagonal-gait leg swing + body bob + tail sway), **attack**
    (wind-up coil → lunge, timed to the 0.5s tell), **hit** (recoil), **death** (legs buckle, body
    drops + rolls; terminal). AnimationTree: Locomotion `BlendSpace1D` (idle/walk/run) + Attack /
    Hit / Death one-shots. API: `set_locomotion(speed01)`, `play_state(name)`, `has_rig(species_id)`.
  - Uses the **creature's shared material**, so the existing telegraph-red / stagger-blue `_glow`
    still tints the rigged body.

- **`src/creatures/Creature.gd`** — for a species with a rig, builds a `CreatureRig` (with its own
  collision box) instead of the static `CreatureModels`/generic body, and **drives it from the AI
  state machine**: feeds `set_locomotion` each frame from ground speed; plays **Attack** on the
  telegraph, **Hit** on flinch/stagger, **Death** on death (then frees after the collapse clip).
  Non-rigged species keep the A3 procedural fallback (rotation flinch + topple/sink).

## Honesty / scope

- This is the **start** of the track: the 3 currently-spawned species are rigged. The other 27
  documented species keep the static/parametric static body until rigged in later runs (the same
  `CreatureRig` + a `_PARAMS` entry each). The bespoke `CreatureModels` silhouettes remain in the
  file as reference/fallback.
- Box-limb greybox: proportions and gait arcs are first-pass (diagonal walk is approximate; a true
  4-phase gait + foot IK is future polish). Graphics can swap box limbs for sculpted meshes on the
  same skeleton without touching animation code.
- No Godot in the build sandbox — authored to the Godot 4.3 API + structural/consistency checks
  (every clip resolves, every animated bone exists, brackets, no banned IP names, self-test
  poise-break→STAGGER path preserved). **Editor/CI is the authoritative compile.** ~15 AnimationTrees
  now build on Floor 1 (player + 14 creatures) — worth a perf glance in the editor.
- Commits: `f596545` (CreatureRig), `ccf1b9e` (Creature). Creature.gd re-fetched fresh (hottest
  file) and unchanged before the edit. No 409s.

## Next up (creature-rig track)

- Rig the next species as they're added (Floor 2 prey/predators) via new `_PARAMS` entries.
- Gait polish: proper 4-beat walk vs. 2-beat trot/gallop, foot-plant timing, head/tail secondary
  motion; a dedicated creature **stagger** clip (currently reuses Hit).
- Optionally fold the bespoke `CreatureModels` silhouette details onto the rigged skeleton.
