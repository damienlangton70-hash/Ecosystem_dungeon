# 2026-07-10 — Combat/animation Increment 2, A3: defence + reactions

**Run type:** interactive (owner-directed). Damien selected A3. Goal: player poise/stagger +
parry, and extend the reaction layer to creatures (hit-react + death), tying in D6 (Ashjackal
tell) and D5 (1-2 pack attackers).

## Shipped

### Player (defence)
- **Poise + stagger** (`Player.gd`): the player has poise (`POISE_MAX` 60, regen after a delay).
  Enemy hits deal poise damage; a break plays a new **Stagger** clip with a real loss of control
  (`PLAYER_STAGGER_TIME` 0.7). A hit that doesn't break poise plays the short **Hit** flinch.
- **Parry** on **key R** (`Player.gd`): a short active window (`PARRY_WINDOW` 0.24 of a
  `PARRY_TOTAL` 0.5 move, `PARRY_STAMINA` 10). `receive_attack(amount, attacker)` — which enemies
  now call — deflects a blow landing in the window while facing the attacker: **no damage, and the
  attacker is staggered** (riposte opening), with a teal parry burst + chime. Whiffing leaves
  recovery (punishable). `take_damage` also blocks damage if parrying even without an attacker ref.
- **PlayerRig**: two new clips/states, **Parry** and **Stagger** (added to ONE_SHOTS + transitions).

### Creatures (reactions)
- **Hit-react** (`Creature.gd`): a non-breaking hit now gives a knockback nudge + a quick recoil
  nod (`rotation.x` tween) on top of the player's existing impact burst.
- **Death animation**: creatures no longer pop out — they **topple** (`rotation.z`) and **sink**
  (`position.y`) over ~0.8s, then free. `record_kill` + meat drop fire immediately; the corpse
  leaves the `creatures` group so it can't be re-hit/targeted.
- **D6 — Ashjackal tell:** the generic predator red wind-up already existed; tightened
  `WINDUP_TIME` 0.55 → **0.50** to sit in D6's 0.4–0.5s band.
- **D5 — pack attackers:** a `_committing` flag + `_pack_can_commit()` cap **only 2 same-species
  predators** committing at once; held pack-mates **circle/feint** (tangential move) instead.
- **Parry hook:** `Creature` gained a public **`stagger()`** and routes its strike through
  `Player.receive_attack(...)` (falls back to `take_damage`).

## Honesty / scope

- **Creatures use the static-mesh `CreatureModels` system, not skeletal rigs** — so their hit-react
  and death are **procedural whole-body animation** (tween flinch/topple), which ships the reaction
  animations now. Giving each of the 30 species a true Skeleton3D/AnimationTree rig (like the
  player) is a **larger separate track** I can take next if that's wanted specifically.
- No Godot in the build sandbox — authored to the 4.3 API + structural/consistency checks (brackets,
  every clip/state resolves, self-test poise-break→STAGGER path preserved, no banned IP names).
  **Editor/CI is authoritative.** Poise/parry/stagger/pack numbers are **provisional** (playtest).
- **Parry has no HUD hint yet** (avoided editing the hot `Main.gd`): the key is **R**. A HUD line
  can be added in a small follow-up.
- Commits: `de5ec09` (rig), `71eb680` (player), `9862719` (creature). Player files were unchanged
  since A2; `Creature.gd` re-fetched fresh (hottest file) and unchanged before the rewrite. No 409s.

## Next up (combat/animation track)

- **A4 — Death & recovery loop:** a Souls-style "rest point" at campfires / magic circles + a
  drop-and-recover-on-death resource (coin an ORIGINAL name — IP-check per DECISIONS).
- Polish: creature skeletal rigs (true AnimationTree per species); a parry HUD hint; riposte damage
  bonus vs. staggered foes.
