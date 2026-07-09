# Deepforage — Creature Behaviour Spec

**Author:** Cogg (Ecology/Behaviour, Lore team)
**Status:** Production-ready draft for Mechanics. Numbers are starting values for
tuning — flagged as such throughout, never guess a value not labelled.
**Canon sources:** `docs/FOOD_WEB.md`, `docs/DESIGN_BIBLE.md` (names, tiers, diets,
`base_aggression`/`awareness`, over-hunting rules — matched exactly, not reinterpreted).
**Code sources:** `src/creatures/Creature.gd`, `src/systems/ecosystem/Species.gd`,
`src/systems/ecosystem/Ecosystem.gd`, `src/game/Main.gd`, `src/player/Player.gd`,
`src/systems/survival/SurvivalStats.gd` — all read directly, current as of this draft.

---

## 1. How this maps onto the existing code

### 1.1 The state machine that already exists (do not reinvent it)

`src/creatures/Creature.gd` is a single shared script driving **every** creature today
(Mosslamb and Ashjackal are just two configurations of it, spawned from
`Main.gd::_spawn_creature()` with different exported values). Its state enum:

```gdscript
enum State { WANDER, FLEE, CHASE, ATTACK, DEAD }
```

Current transition logic (paraphrased from `_physics_process`):
- `aware = detect_radius * Ecosystem.awareness_multiplier()` (recomputed every frame).
- If player is within `aware`: predators (`is_predator == true`) → `CHASE`; non-predators → `FLEE`.
- If in `CHASE`/`FLEE` and player exits `aware * 1.4` (a hysteresis band so creatures don't
  flicker state at the detection boundary): → `WANDER`.
- `CHASE` → `ATTACK` when `dist < 1.8`. `ATTACK` → `CHASE` when `dist > 2.2` (same kind of
  hysteresis band on the melee boundary). `ATTACK` fires damage on a cooldown (`_attack_cd`,
  currently a flat `1.2s`, no wind-up telegraph yet).
- `take_damage()`: non-predators always drop to `FLEE` on being hit; on `health <= 0` → `DEAD`,
  which calls `_ecosystem.record_kill(species_id, 1)` and spawns a `raw_meat` Pickup
  (`_drop_meat()`), then `queue_free()`.
- Per-creature exported tuning knobs already exist: `move_speed`, `attack_damage`,
  `detect_radius`, `max_health`, `is_predator`, plus cosmetic (`body_color`, `body_height`).

**This spec extends that machine — it does not replace it.** Every archetype below is
`WANDER → (new intermediate states) → CHASE/AMBUSH/CHARGE → ATTACK → back to WANDER`,
built by **inserting states between the existing bookends**, and by making the existing
bookends do more (e.g. `FLEE` gaining a distance-based give-up, `ATTACK` gaining a
telegraphed wind-up instead of a flat cooldown). New states are additive to the enum;
nothing here requires touching Mosslamb's or Ashjackal's current behaviour to work as
already shipped, but section 2 recommends refactoring `ATTACK` to carry a windup timer
for every creature that attacks — this is the one change I'd ask Mechanics to apply
retroactively to Ashjackal too, since "no visible tell before damage" contradicts the
Dark-Souls-readability pillar in `DESIGN_BIBLE.md` §5.2 and will feel unfair the moment a
second predator ships.

Combat-adjacent constants I anchored my wind-up/cooldown numbers to, read from
`src/player/Player.gd`: player dodge duration `DODGE_TIME = 0.45s`, i-frame window
`IFRAME_TIME = 0.35s`, attack commit `ATTACK_TIME = 0.35s`, melee range `ATTACK_RANGE = 2.6`,
lock-on range `20.0` (break at `22.0`). **Rule of thumb applied throughout this doc: every
creature attack tell must last ≥ the player's i-frame window (0.35s) with margin, so a
dodge started on tell-read (not tell-start) still lands inside the window.** I target
0.5–0.9s tells for readability at first-encounter pace, tightening only for glass-cannon
apex threats where the design intent is that reaction time itself is the challenge.

### 1.2 The Ecosystem API (unchanged, used as-is)

`src/systems/ecosystem/Ecosystem.gd`:
- `register_species(s: Species)`, `species: Dictionary` (id → `Species`).
- `record_kill(species_id: String, amount: int = 1)` — decrements population, recomputes
  `global_hostility`. **Already wired**: `Creature._die()` calls this. No new hook needed
  for basic kill-tracking; archetypes below only add extra *callers* for archetype-specific
  cases (e.g. insect swarm collateral kills, keystone kill spike).
- `global_hostility: float` (0..1), `aggression_multiplier() = 1 + hostility*2.0`,
  `awareness_multiplier() = 1 + hostility*1.5` — used verbatim, per `FOOD_WEB.md`.
- `_recompute_hostility()` — pressure accrues when a species' `population` falls below
  `carrying_capacity / 3`. This is a **global** scalar today (one hostility value for the
  whole simulation, not per-species/per-floor). Section 2.7 and 4 flag where per-species
  desperation logic (a creature reacting to *its own* prey being scarce, independent of
  global hostility) needs a small new read path — I specify the minimal interface Mechanics
  should add, since it doesn't exist yet.

`src/systems/ecosystem/Species.gd` fields used as the canonical data shape for every
species entry in section 3: `id`, `display_name`, `tier`, `diet: Array[String]`,
`population`, `carrying_capacity`, `base_aggression`, `awareness`, `edible`.

### 1.3 Minimal interface I'm assuming that doesn't exist yet

Two small additions, both additive (no breaking changes to current API):

1. **`Ecosystem.population_ratio(species_id: String) -> float`** — returns
   `population / max(carrying_capacity, 1)` for a given species, clamped `[0,1]`. Needed so
   a predator can check *its own prey's* scarcity (desperation, §2 per-archetype hooks) without
   every `Creature` instance reaching into `species` dictionary internals directly.
2. **`Ecosystem.record_keystone_kill(species_id: String)`** — a thin wrapper Mechanics can
   call instead of (or alongside) `record_kill()` specifically for The Hollow Stag, which
   forces `global_hostility` to a high floor value immediately (see §2.8) rather than letting
   the normal population-ratio pressure math produce it gradually. This keeps the "catastrophic
   spike" from FOOD_WEB.md as a designed discrete event rather than an emergent side-effect of
   a single population decrement — a stag's `carrying_capacity` is tiny (1–3), so a naive
   `record_kill()` might already crater its ratio to zero, but the *spike-and-long-recovery*
   shape (vs. gradual pressure) reads better as an explicit call.

If Mechanics prefers to fold both into the existing `record_kill()` signature (e.g. an
optional `is_keystone: bool` param) rather than adding new methods, that's a fine
implementation choice — the important part is the *behaviour*, not the exact method name.

---

## 2. Behaviour archetypes (9)

Each archetype lists: extended state machine, concrete tunable parameters, and ecosystem
hooks. All speed values are relative to the creature's own `move_speed` export (i.e. "wander
speed = 0.4x move_speed" means `move_speed * 0.4`, consistent with the existing
`WANDER` code using `move_speed * 0.5`). All radii are in meters, matching `detect_radius`'
existing unit. All timings are seconds.

### (a) Grazer / flee prey

**Covers:** Mosslamb, Grotto Springhare, Capglow Snail, Blind Vole, Palefish, Deep Quail
(all Tier 1); also the *prey-side* behaviour baseline that Tier 2 omnivores fall back to
when not the aggressor (e.g. Rockback Boar while foraging).

**States** (extends existing `WANDER`/`FLEE`, adds `ALERT` and `GRAZE`):

```
WANDER → ALERT → FLEE → (RETURN) → GRAZE → WANDER
           ↑________________________|
```

- `GRAZE`: a sub-state of idling near flora (visually distinct — head-down animation) instead
  of open wandering. Not mechanically required for M1/M2 but flagged now so Mechanics can
  gate it behind a "near flora tag" node check whenever World Building starts placing
  bushes — cheap addition, big readability win (tells the player "this is a feeding ground").
- `ALERT` (**new**, inserted before `FLEE`): triggered when the player enters
  `detect_radius * awareness_multiplier() * 1.5` (an outer "notice" ring, larger than the
  existing flee-trigger ring) — creature stops, head/body turns to face the player, plays an
  alert vocalization/animation, **does not move**. Lasts `alert_duration` (0.4–0.6s, tuning).
  This exists purely for readability: right now a Mosslamb snaps straight from grazing to
  fleeing with zero tell, which reads as twitchy/robotic rather than animalistic. If the
  player closes to the *existing* flee-trigger ring (`detect_radius * awareness_multiplier()`)
  before `ALERT` finishes, skip straight to `FLEE` (a rushing player should still spook it
  immediately — `ALERT` softens the *distant* notice, not close encounters).
- `FLEE`: unchanged trigger, but add a **give-up distance**: once `dist > flee_giveup_radius`
  (12–16, tuning) the creature stops sprinting and transitions to `RETURN` rather than
  continuing to flee indefinitely (current code only exits `FLEE`→`WANDER` via the aware*1.4
  hysteresis check, which is fine, but I want `RETURN` as a distinct state so a fleeing
  Mosslamb visibly settles/looks-back before resuming wander, instead of instantly resuming
  a random wander direction).
- `RETURN`: brief pause (0.5–1.0s) facing back toward the threat's last-seen position, then
  → `WANDER`.

**Parameters (starting values):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius (base) | per-species, §3 (8–12 typical T1) | `× awareness_multiplier()` |
| alert outer ring | `detect_radius × awareness_multiplier() × 1.5` | derived |
| alert_duration | 0.4–0.6s | flat (not scaled — a spooked animal doesn't hesitate longer when the world is calm) |
| flee speed | `move_speed × 1.0` (full/current) | unaffected by aggression_multiplier (fleeing is not an attack stat) |
| flee_giveup_radius | 12–16m | shrinks slightly as hostility rises: `giveup × (1 - hostility×0.3)` — a stressed prey animal in a hostile floor flees *further* before feeling safe. Equivalently, tune as `giveup / awareness_multiplier()` if that's simpler to wire since the multiplier already exists. |
| flee-health-threshold | N/A (prey don't fight back) | — |
| attack wind-up | N/A — no attack state | — |
| pack size | 1 (solitary) except Deep Quail may spawn in coveys of 3–5 (cosmetic clustering only, not coordinated — see §3 note) | — |

**Ecosystem hooks:**
- `record_kill()` already fires on death via existing `Creature._die()` — no change needed.
- **Over-hunting cascade (the important one for this archetype):** when a Tier 1 species'
  `population_ratio()` (new helper, §1.3) drops below ~0.5, its Tier 2 predators should read
  that directly (not just via global `hostility`) and enter **DESPERATE** behaviour — see
  archetype (b)/(c) hooks. Grazers themselves have no desperation state (they don't hunt), but
  a depleted grazer population should reduce *spawn density* on floor reset/regrowth ticks
  (a Mechanics population-simulation concern, flagged not specified here — FOOD_WEB.md's
  "Recovery" section already covers the regrowth-over-time intent).
- Global hostility still raises `awareness_multiplier()` for these creatures like everything
  else — a stirred-up floor makes even Mosslambs spookier (bigger alert ring, faster to flee),
  which is emergent from existing math, no new code required.

---

### (b) Pack hunter

**Covers:** Ashjackal (existing, Tier 2), Marrow Hyena (Tier 3), Antler Warg (Tier 3),
Elder Marrowmother's hyena packs (Tier 5 command-layer, see note below).

**States** (extends existing `WANDER`/`CHASE`/`ATTACK`, adds `ALERT`, `STALK`, `CIRCLE`,
`FLEE`(pack-relative), `DESPERATE`):

```
WANDER → ALERT → STALK → CIRCLE ⇄ ATTACK → (CHASE if target flees) → CIRCLE
                    ↓                                  ↓
                  FLEE (if pack member count drops / player too strong)
                    ↓
                 DESPERATE (own prey scarce) → wider WANDER radius, lower ALERT threshold
```

- `ALERT`: as (a), but on alert a pack member **broadcasts** to nearby same-species pack-mates
  within `pack_coordination_radius` (10–14m) — this is the one genuinely new *systemic* piece:
  packs need a lightweight shared-target mechanism. Minimal implementation: each `Creature`
  instance in `is_predator` + `pack` mode checks `get_tree().get_nodes_in_group(species_id)`
  within radius and, if any pack-mate is already in `CHASE`/`CIRCLE`/`ATTACK` against the same
  player target, skips its own `ALERT`→`STALK` progression and jumps straight to `CIRCLE`,
  taking a pre-assigned flanking slot (simplest: alternate left/right offset from the target
  by pack-join-order, recomputed each time pack size at the target changes). This avoids a
  full blackboard/squad-manager system for M1–M2 scope while still producing "the pack
  converges" behaviour.
- `STALK`: replaces jumping straight to `CHASE`. Pack closes distance at **reduced speed**
  (`move_speed × 0.7`) stalking rather than running, staying just outside the player's
  peripheral/lock-on comfort range, until either (i) close enough to commit (`stalk_commit_
  radius`, 6–8m) → `CIRCLE`, or (ii) player attacks/notices (closes to melee range) →
  `CIRCLE` immediately (skip remaining stalk).
- `CIRCLE`: **this is the core pack-identity state** — instead of all pack members
  converging straight at the player (current `CHASE` behaviour, fine for a lone Ashjackal but
  wrong for 3+), members orbit at `circle_radius` (3.5–4.5m, just outside melee) at
  `move_speed × 0.8`, offset evenly around the player, until each one's individual "commit
  window" timer (staggered per-member, 1.5–3.5s random per member) elapses — then that member
  breaks inward to `ATTACK`. This produces the classic "one lunges while the others circle"
  read instead of a clump. Only **one pack member attacks at a time** by default (a second
  member's commit-window firing while another is already mid-`ATTACK` gets its timer reset
  +0.8–1.2s) — this is a **fairness knob for solo-play combat balance**, flagged for playtest
  in §4.
- `ATTACK`: telegraphed wind-up (see table). On landing OR on being hit hard enough to flinch
  (poise-break, if/when poise exists — for now: any hit while `ATTACK` wind-up is active
  cancels the attack and returns the attacker to `CIRCLE` with a `1.0s` stagger before it can
  re-commit) → back to `CIRCLE`.
- `FLEE` (pack-relative): if the pack's headcount actively engaged drops below
  `flee_pack_threshold` (roughly half, so a 4-pack falling to 2 alive) **and** no member has
  landed a hit in `pack_morale_window` (8–10s), the remaining members break off to `FLEE` at
  full speed toward `_home`/den, same mechanics as archetype (a)'s flee-with-giveup. This is
  what makes packs feel like animals with self-preservation rather than a suicidal zerg —
  important given Dark-Souls-style stamina combat means a lone player *can* wear down a pack,
  and a pack that never breaks becomes a stamina-attrition slog rather than a tense fight.
- `DESPERATE`: entered when the pack's primary prey species' `population_ratio()` (§1.3) is
  below ~0.35. Effects: `ALERT` outer ring expands ×1.3, `WANDER` roams a much larger radius
  (pack ranges further from den), and `flee_pack_threshold` is *relaxed* (packs fight harder/
  longer before breaking — hunger overrides self-preservation). This directly implements
  FOOD_WEB.md's "predators that lose their prey grow hungrier and roam wider" and gives
  the player a legible in-fiction signal that they've over-hunted this pack's food source.

**Parameters (starting values, generic pack hunter — Ashjackal-specific in §3):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius (base) | 10–14 (T2) up to 16–20 (T3) | `× awareness_multiplier()` |
| pack_coordination_radius | 10–14m | flat |
| stalk speed | `move_speed × 0.7` | `× aggression_multiplier()` cap ×1.3 (packs shouldn't out-speed player sprint by too much even hostile) |
| stalk_commit_radius | 6–8m | shrinks slightly with aggression_multiplier (bolder packs commit from further, i.e. radius grows — tune direction by feel; default: `radius × aggression_multiplier()` capped at 1.4× so hostile packs commit from further out, giving player less warning, which is the intended "world feels more dangerous" read) |
| circle_radius | 3.5–4.5m | flat |
| per-member commit window | random 1.5–3.5s | shortens with aggression_multiplier: `window / aggression_multiplier()` |
| attack wind-up (tell) | 0.55–0.7s | flat (wind-up is a physical animation read, not a "mood" stat — keep it consistent so players can learn it) |
| attack recovery (post-swing, vulnerable) | 0.5–0.8s | flat |
| attack cooldown per member | 1.4–1.8s | `/ aggression_multiplier()` (hostile packs attack more often) |
| pack size | 3–5 (Ashjackal), 4–6 (Marrow Hyena), 4–6 (Antler Warg) | see §3 |
| flee-health-threshold (individual) | below 20% of `max_health` AND pack morale broken (see FLEE state) → individual also breaks even if pack hasn't collectively | — |
| flee_pack_threshold | ~50% of engaged pack headcount | — |

**Ecosystem hooks:**
- `record_kill()` per member death, unchanged (existing `_die()` call).
- **This is the primary archetype for over-hunting cascade demonstration**: kill too many of
  a pack predator's prey (e.g. hunt Grotto Springhare to <1/3 capacity) → Ashjackal packs go
  `DESPERATE` → wider roam + relaxed flee threshold → player encounters them further from
  their usual territory and finds them harder to rout, which is the direct, readable
  consequence FOOD_WEB.md promises ("the floor stirs up").
- Waste/attention note from FOOD_WEB.md ("leaving unbutchered carcasses attracts... Marrow
  Hyenas") applies here directly for Marrow Hyena: give it an additional passive check —
  periodically (every 3–5s while in `WANDER`) scan for `Pickup` nodes with `item_id ==
  "raw_meat"` within a "scavenger sense" radius (larger than `detect_radius`, ~1.5×) that
  aren't yet collected; if found, path toward it (a `SCAVENGE` sub-state of `WANDER`, not a
  combat state) and, on arrival, "consume" it (despawn the pickup, no player interaction
  needed) — this is what makes leaving meat around feel consequential rather than free loot,
  per FOOD_WEB.md's waste-and-attention rule. Flagging as a **light M2+ addition**, not
  required to ship the base pack-hunter archetype.
- **Elder Marrowmother** (Tier 5) is a command-layer variant of this archetype rather than a
  new one: mechanically she IS a pack-hunter (same states) but her presence in a Marrow Hyena
  pack raises that pack's `aggression_multiplier`-equivalent locally (multiply the pack's
  effective aggression by an additional flat ×1.2–1.3 while she's alive and nearby) and
  prevents `FLEE` morale-break while she's present and un-fled herself (packs rally around
  her). If she dies, the pack she was leading immediately re-checks `FLEE` conditions. Full
  detail in §3; this is a light layer on (b), not archetype (g)/(h).

---

### (c) Solo ambush predator

**Covers:** Gloomferret (T2, more opportunist-scavenger than true ambusher but shares the
shape — see note in §3), Gloamstalker Lynx (T3), Tunnel Constrictor (T3, wall/floor ambush
specifically), Pale Sabertooth (T4), Dire Basilisk (T4, toxin variant), Spinneret Lurker
(insect, web-immobilise variant — cross-referenced in archetype (i) too since it's also an
insect hazard).

**States** (extends existing `WANDER`/`CHASE`/`ATTACK`, adds `STALK`(solo variant, lower
profile than pack version), `AMBUSH`, `FLEE`):

```
WANDER → STALK → AMBUSH → ATTACK → CHASE (if target escapes/flees) → back to STALK or WANDER
                              ↓
                            FLEE (low health)
```

- Key structural difference from pack hunter: **no `CIRCLE`** (solo, no coordination needed)
  and **no broadcast** — but a genuinely distinct `AMBUSH` state that pack hunters don't get,
  because solo ambushers are specced to commit to a *hidden, stationary lie-in-wait* rather
  than a visible stalk.
- `STALK`: on alert, moves to within `ambush_range` (species-specific, e.g. Lynx ~8–10m,
  Constrictor is different — see below) using terrain/cover if a nav-mesh cover query exists
  (Mechanics call — if not available yet, a simpler placeholder: move to a point *behind* the
  player's current facing, using `-player.forward` as a bias direction, so the creature at
  least tries to flank rather than approach head-on) at reduced speed (`move_speed × 0.6`) and
  **does not enter the player's existing `detect_radius`-based state check early** — i.e. this
  creature's *effective* detect_radius for triggering `CHASE` should be treated as smaller
  than its stated `detect_radius` while in `STALK` specifically, because the intent is the
  creature is *hunting the player*, not yet detected reactively. Simplest implementation:
  give ambush predators a second, smaller field, `commit_radius`, and gate the `STALK→AMBUSH`
  transition on `commit_radius` rather than the shared `detect_radius`-based aware check;
  `detect_radius` still governs the normal reactive WANDER→CHASE fallback for when the player
  blunders in from outside a deliberate stalk.
- `AMBUSH`: creature goes fully idle/hidden (Tunnel Constrictor: pressed into a wall/floor
  recess node; Lynx/Sabertooth: crouched behind cover or in tall terrain) and **waits** until
  the player closes to `ambush_trigger_radius` (tight — 2.5–4m, deliberately close so the
  strike feels sudden) OR a timeout (8–12s) elapses with no player approach, in which case it
  gives up and returns to `STALK` with a new position. On trigger: **lunge** — a fast,
  short-wind-up burst attack (see table) that covers `ambush_lunge_distance` in one motion.
  Because this is the "sudden" moment, the *tell* still needs to exist (design pillar: no
  unreadable damage) but can be shorter than a normal attack wind-up **provided** it's
  visually loud (a distinct pre-lunge crouch/coil pose, audio cue) rather than long — see
  timing table, and note the floor: even the fastest ambush tell must clear 0.35s (player
  i-frame) with the margin described in §1.1.
- `ATTACK`/`CHASE`/`FLEE`: standard, as existing code, with wind-up added to `ATTACK` and a
  `flee-health-threshold` (this archetype, unlike a straight predator, DOES flee — ambush
  predators are stealth-reliant and risk-averse once spotted/hurt, matching the "stealthy
  ambusher, lean cuts" / "huge yield, ambush from walls" character notes in FOOD_WEB.md).

**Parameters (starting values, generic solo ambusher):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius (reactive fallback) | 10–14 (T2–3) | `× awareness_multiplier()` |
| commit_radius (deliberate stalk trigger) | detect_radius × 0.6–0.7 | `× awareness_multiplier()` |
| ambush_trigger_radius | 2.5–4m | shrinks slightly with awareness_multiplier is wrong-feeling (a more alert predator should trigger from FURTHER, not closer) — use `radius × awareness_multiplier()` so hostile-floor ambushers strike sooner/further, giving the player less time |
| ambush lie-in-wait timeout | 8–12s | flat |
| ambush lunge wind-up (tell) | 0.4–0.55s (tight but ≥ i-frame floor) | flat — kept tight and non-scaling since this is the archetype's signature "sudden" beat; readability comes from a strong visual/audio cue, not from a long timer |
| ambush lunge distance | 4–7m burst | flat |
| standard attack wind-up | 0.5–0.65s | flat |
| attack recovery | 0.5–0.7s | flat |
| attack cooldown | 1.3–1.6s | `/ aggression_multiplier()` |
| flee-health-threshold | 25–35% of `max_health` | threshold rises with hostility is wrong direction — a hostile floor's predators flee LESS readily: `threshold × (1 - hostility×0.4)`, i.e. they hold on longer before breaking off, consistent with aggression_multiplier's "fewer flees" intent from FOOD_WEB.md |
| pack size | 1 (solitary by definition) | — |

**Ecosystem hooks:**
- Standard `record_kill()` on death.
- **Desperation**: when this predator's own prey (`diet` array, per FOOD_WEB.md) drops in
  `population_ratio()` below ~0.35–0.4, ambush predators should *shorten* their lie-in-wait
  timeout (more impatient, more opportunistic strikes on marginal targets) and *widen*
  `commit_radius` (ranging further from usual territory to find prey) — same directional
  intent as pack-hunter desperation, tuned per-archetype because ambushers don't have a pack
  morale mechanic to relax instead.
- Dire Basilisk's toxin and Cinder Cockatril's toxin (T2, technically archetype (a)/(b)
  adjacent but sharing the "handle with care" cooking-note) are a **combat/cooking property**,
  not a behaviour-state difference — same state machine, but their `ATTACK` hitbox should
  apply a poison/DoT status rather than (or in addition to) flat damage. Flagging this as a
  status-effect system dependency Mechanics likely already has planned for M3 survival
  expansion (body temperature etc.) — behaviourally these creatures are ordinary ambushers/
  mid-predators, no new state needed.

---

### (d) Aerial predator

**Covers:** Hookbeak Ridgehawk (T3), Chasm Drake (T4, "wingless wyvern" per FOOD_WEB.md —
see note below), Cavern Roc (T5).

**States** (a genuinely new movement layer on top of the existing machine — adds `PERCH`,
`SOAR`, `DIVE`, keeps `ATTACK`/`FLEE`):

```
PERCH → SOAR → DIVE → ATTACK → (RETREAT) → SOAR → PERCH
   ↑_____________________________________________|
```

- **Design note before the states**: aerial creatures need a 3D flight volume, not the
  ground-plane `move_and_slide()` the current `Creature.gd` uses (gravity applied, floor-
  relative). This is the one archetype that most clearly needs a **second base script** or a
  significant branch inside `Creature.gd` (e.g. an `is_flying` export that swaps the movement
  block to fly freely in Y within a floor/ceiling band, ignoring `is_on_floor()`/gravity while
  `state != DEAD`). I'm specifying behaviour; the flight-volume implementation is a Mechanics
  call, but flagging it now since it's not a small delta on the existing physics path — it's
  the first archetype requiring one, and worth budgeting time for before Floor 2 (Rootways,
  still no aerial per FOOD_WEB.md tier table) — genuinely first needed for Floor 3 (Sunless
  Marsh, T2-4, Ridgehawk's territory)? No — checking FOOD_WEB.md tiers again: Ridgehawk is T3,
  and DESIGN_BIBLE's floor table puts T1-3 on Floor 2 (Rootways) already. **So aerial flight
  is needed starting Floor 2, not Floor 3** — earlier than M4's "floors 2-5" framing might
  suggest at a glance. Calling this out explicitly since it affects Mechanics' scheduling.
- `PERCH`: idle state, stationary on a raised point (cliff ledge, tall glowcap canopy —
  World Building placement dependency). Functions like `WANDER`'s rest but doesn't patrol on
  foot. Transitions to `SOAR` on a timer (patrol cycle, 4–8s) or immediately if player enters
  `detect_radius × awareness_multiplier()`.
- `SOAR`: circles at altitude within a patrol radius around a perch/territory center,
  scanning. This is the aerial analogue of `WANDER`, at `move_speed × 0.8` (SOAR is
  deliberately unhurried — the threat is the dive, not the cruise). On spotting the player
  (same aware-radius check) → `DIVE`.
- `DIVE`: **this is the attack wind-up, spatialized** — the creature banks and commits to a
  descending line toward the player's position (predicted lead point, or simplest:
  position-at-dive-start, accept some miss chance if player moves — good enough for M1-M2
  fidelity) at high speed (`move_speed × 1.6–1.8`), audibly/visually telegraphed (a distinct
  screech + visible bank-and-dive posture) for `dive_telegraph` duration before impact-capable
  — telegraph starts the moment `DIVE` is entered, so total time-to-impact IS the tell;
  target 0.7–1.0s for total dive duration (longer than ground melee tells because the whole
  dive arc is visible, giving the player more total warning even if the "committed" moment is
  late in the arc).
- `ATTACK`: on reaching melee range mid-dive, applies damage (talon strike / bite), then the
  creature does NOT loiter — it continues through into `RETREAT` (can't hover-facetank like a
  ground predator; the whole point of an aerial threat is hit-and-run).
- `RETREAT`: climbs back to altitude over 1.5–2.5s, invulnerable-to-ground-melee in practice
  since it's out of `ATTACK_RANGE` (2.6, from Player.gd) almost immediately — this is
  intentional: aerial predators are meant to be *annoying/dangerous via chip damage and
  positioning pressure*, not stand-and-fight targets, until they choose to `PERCH` again
  (which is the punish window — a perched Roc/Ridgehawk is vulnerable to ranged/ambush).
- `FLEE`: on low health, breaks off patrol entirely and flies to a distant perch outside
  `detect_radius`, not returning to `SOAR` for an extended cooldown (60s+, or simplest: never
  returns to this encounter, despawn-and-respawn-elsewhere on a long timer — implementation
  detail for Mechanics, behavioural intent is "wounded fliers disengage hard").

**Parameters (starting values):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius | 14–18 (T3) up to 22–26 (T5 Roc) | `× awareness_multiplier()` |
| patrol radius (SOAR) | 15–25m around perch | flat |
| soar speed | `move_speed × 0.8` | flat |
| dive speed | `move_speed × 1.6–1.8` | `× aggression_multiplier()` capped ×1.2 additional (hostile-floor divers are noticeably faster/bolder, but capped so they don't become unreadable) |
| dive telegraph / total dive time | 0.7–1.0s | flat (this is the tell; don't compress it under hostility — getting harder should mean MORE frequent dives, not less readable ones) |
| dive cooldown (time perched/soaring before next dive attempt) | 3–5s | `/ aggression_multiplier()` |
| retreat climb time | 1.5–2.5s | flat |
| flee-health-threshold | 20–30% of `max_health` | as archetype (c): `threshold × (1 - hostility×0.4)` |
| pack size | 1 (Ridgehawk, Roc solitary/territorial) | — |

**Ecosystem hooks:**
- Standard `record_kill()`.
- Chasm Drake ("wingless wyvern... searing required" per cooking note) is specced here as an
  **aerial predator that cannot fly** — a deliberate FOOD_WEB.md naming/flavor choice
  (wyvern-shaped but grounded). Mechanically it should use archetype (c) (solo ambush) or (g)
  (apex stalker) shape instead, NOT this one — flagging so nobody wires it to the flight
  branch by name-association alone. Full note in §3.

---

### (e) Aquatic / semi-aquatic

**Covers:** Palefish (T1, aquatic — archetype (a) shape but confined to water, noted here for
the movement-volume constraint), Grave Otter (T2, aquatic), Bog Saurian (T3, semi-aquatic),
Deepwater Leviathan-eel (T4, aquatic apex-of-the-water).

**States** (extends `WANDER`(confined)/`FLEE`/`CHASE`/`ATTACK`, adds `SUBMERGE`, `SURFACE`,
`LUNGE`):

```
[fully aquatic, e.g. Palefish, Leviathan-eel]
SUBMERGE-WANDER → ALERT → FLEE/CHASE (all underwater) → ATTACK
   (never leaves water volume)

[semi-aquatic, e.g. Bog Saurian]
SURFACE-WANDER (on land/shallows) → SUBMERGE (on threat/hunt) → LUNGE → ATTACK → SUBMERGE (retreat)
```

- Fully-aquatic creatures use the existing state shape but their `WANDER`/movement is
  constrained to a water-volume (an `Area3D` boundary the World Building agent places per
  water feature — `Main.gd::_add_water()` already creates visual water planes; those need a
  matching collision/logic volume for aquatic creatures to be confined to, which doesn't
  exist yet — flagging as a placement/volume dependency, not a behaviour-spec concern).
  Movement in water can otherwise reuse ground-plane logic (swim on X/Z, minor Y bob) rather
  than needing the full 3D flight volume of archetype (d) — much cheaper to implement.
- Semi-aquatic (Bog Saurian) is the interesting case: it patrols land/shallow edges in a
  normal `WANDER`, but on detecting prey or being threatened, transitions to `SUBMERGE`
  (visually: sinks to eyes-only or fully underwater, becomes hard to track — this IS the tell
  reduction relative to ground predators, intentionally, matching "reptile... ambush" flavor)
  then `LUNGE` — a fast, short burst from the water onto the bank (or within-water lunge if
  target is also in shallows), functionally identical in timing shape to archetype (c)'s
  ambush lunge but originating from a water-edge rather than terrestrial cover.
- Leviathan-eel (T4, "marsh terror... enormous") is specced as fully-aquatic apex-of-the-pool:
  never leaves its water volume, so the player must either avoid its water or fight at a
  disadvantage in/near it — the water volume itself becomes the "territory" the way a lair
  does for archetype (g).

**Parameters (starting values):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius (in-water, generally lower than surface — murky water logic) | 6–9 (T1 Palefish) up to 16–20 (T4 Leviathan-eel) | `× awareness_multiplier()` |
| swim speed | comparable to land `move_speed` equivalent for tier, ~3–3.5 (T1) up to 5.5–6.5 (T4) | as ground creatures |
| submerge transition time | 0.4–0.6s (visual sink) | flat |
| lunge wind-up (semi-aquatic) | 0.4–0.55s (matches archetype c ambush tell floor) | flat |
| lunge distance | 4–6m (Bog Saurian) up to 8–10m (Leviathan-eel from open water to bank) | flat |
| attack cooldown | 1.4–1.8s | `/ aggression_multiplier()` |
| flee-health-threshold (prey only: Palefish; predators here mostly hold ground in their water like archetype g) | Palefish: 100% (any damage → flee/submerge-and-hide, it's T1 grazer-equivalent) | — |
| pack size | 1, except Grave Otter may raft in small family groups of 2–3 (cosmetic, non-coordinated, like Deep Quail coveys in (a)) | — |

**Ecosystem hooks:**
- Standard `record_kill()`.
- Note for Mechanics: because aquatic creatures are volume-confined, over-hunting cascades
  for them are naturally *localized per water feature* rather than floor-wide — if Floor 3
  (Sunless Marsh) has multiple pools, each could sensibly track its own local Palefish
  population separate from a global `species` entry, OR (simpler, matches current single-
  dictionary-per-id `Ecosystem.species` shape) just treat all Palefish across the floor as one
  population regardless of which pool they're in — recommend the simpler global approach for
  M2–M4 scope and only split per-pool if playtesting shows it matters. Flagging the fork, not
  mandating the harder path.

---

### (f) Mega-herbivore (defensive charge)

**Covers:** Stonehide Rhinox (T4). This is a **single-species archetype** by roster (no other
creature shares this exact shape), but specced fully as its own category per the brief's
9-archetype structure since its behaviour is qualitatively distinct from every predator type.

**States** (extends `WANDER`/`FLEE`(the trigger is being attacked, not being noticed), adds
`GRAZE`, `THREATENED`, `CHARGE`, `RECOVER`):

```
GRAZE/WANDER → THREATENED → CHARGE → RECOVER → GRAZE/WANDER
      ↑_____________________________________________|
                    (never initiates — only reacts)
```

- **Core identity: base_aggression is low (0.5, per FOOD_WEB.md, and note that's HIGH for a
  "grazer" but reflects danger, not initiation — Rhinox does not hunt or chase unprompted).**
  It never transitions to `CHASE` the way a predator does — it has no analogue of the existing
  `CHASE` state at all. It grazes/wanders like archetype (a) but does NOT flee when merely
  approached — it's "not a predator, but lethal charge; adults untouchable" per FOOD_WEB.md,
  meaning the intended player experience is *respect its space, don't provoke it*.
- `THREATENED`: triggered specifically by (i) the player attacking it (`take_damage()` called
  while not already charging), OR (ii) the player remaining within a **very tight**
  `provoke_radius` (much smaller than a predator's detect_radius — 3–5m, i.e. you have to
  really crowd it) for longer than `provoke_dwell` (2–3s). This state is a brief
  (0.5–0.8s) rear-back/bellow tell — the loudest, most obvious wind-up in the whole roster,
  because the charge that follows is meant to be avoidable by ANY attentive player, punishing
  only carelessness, not skill.
- `CHARGE`: commits to a straight-line charge along the vector to the threatening position
  (locked at charge-start, does not re-track — this is important for player counterplay: side-
  step and the charge misses, full stop, matching real animal charge behaviour and giving
  skilled players a clean dodge window that doesn't rely on frame-perfect i-frames) at very
  high speed (`move_speed × 2.2–2.5` — this should be the single fastest sustained ground
  speed of any creature in the game, faster than the player's sprint) for `charge_distance`
  (10–14m) or until it hits something (player, or a wall/rock — collision should stagger it,
  see RECOVER). Charge deals heavy damage (flagged as a distinct, larger number than normal
  `attack_damage` — this is a "you got hit by a rhino" event, should be able to take a large
  chunk of player health, e.g. 30–40% of a fresh player's max_health as a strong tuning
  starting point given `Player.max_health = 100.0`).
- `RECOVER`: after a charge (hit or miss), the Rhinox is stationary and vulnerable for
  `recover_duration` (1.5–2.5s, a real punish window — "adults untouchable" refers to
  head-on/mid-charge, not this opening) before returning to `GRAZE`/`WANDER`. If it hit a
  wall/rock during `CHARGE`, extend `recover_duration` further (it stumbled harder) — a nice
  emergent reward for baiting a charge into terrain.
- Never enters `FLEE` — a Rhinox this large doesn't run from the player; if its health drops
  low it should stay in the GRAZE/THREATENED/CHARGE loop rather than despawn-fleeing, though
  design intent is this creature is meant to be *skipped*, not farmed, for most players (see
  §4 tuning note on whether it should even reliably die to sustained melee at intended player
  power, or whether it's meant to be effectively a hazard to route around at this stage of
  gear).

**Parameters (starting values):**

| Param | Value | Scaling |
|---|---|---|
| provoke_radius | 3–5m | `× awareness_multiplier()` (a stirred-up floor's Rhinox is touchier) |
| provoke_dwell | 2–3s | `/ awareness_multiplier()` (shorter fuse when hostile) |
| threatened tell duration | 0.5–0.8s (deliberately loud/obvious) | flat |
| charge speed | `move_speed × 2.2–2.5` | `× aggression_multiplier()` capped ×1.15 (should stay dodgeable even hostile — this is a "skill check" creature, not a "grind" one) |
| charge distance | 10–14m | flat |
| charge damage | 30–40% of a baseline 100 HP player pool (i.e. large, tune against actual player max_health) | flat — do not scale charge damage by aggression_multiplier; scaling detection/frequency is enough, a one-shot-adjacent hit getting worse with hostility risks feeling unfair rather than "the world reacting" |
| recover_duration | 1.5–2.5s (longer if charge hit terrain) | flat |
| pack size | 1 (solitary adult); FOOD_WEB.md implies calves exist (Elder Marrowmother's diet includes "Rhinox calf") — calves, if implemented, would be archetype (a) shape, small and fleeing, not this archetype | — |

**Ecosystem hooks:**
- Standard `record_kill()` if the player does manage to kill one — but per "adults
  untouchable" flavor, expect this to be rare; that's fine, `carrying_capacity` for this
  species should be set low regardless (few individuals per floor) since it's meant to be
  encountered, not farmed.
- Rhinox is prey for Titan Molebeast (T5) per FOOD_WEB.md diet list — no special hook, that's
  a predator-prey relationship the ecosystem simulation (population math) already models
  generically; behaviourally the Molebeast is archetype (g)/(c)-adjacent (burrower ambush,
  see §3), not something this archetype needs to react to directly.

---

### (g) Apex stalker

**Covers:** The Gloom Tyrant (T5), Pale Sabertooth (T4 — cross-referenced from (c), see note),
Titan Molebeast (T5), and functionally Chasm Drake (T4, "wingless wyvern," reassigned here
from where its name might suggest archetype (d) — see §2.4/(d) note above).

**States** (this is the "solo ambush predator" archetype (c) made bigger, slower to commit,
and territorial — extends (c)'s shape with `PATROL`(territory-bound wander), `INTIMIDATE`,
and a harder-hitting `ATTACK`/finishing move):

```
PATROL(territory) → STALK → INTIMIDATE → AMBUSH/CHARGE → ATTACK → CHASE(short) → back to PATROL
                        ↓
                      FLEE (rare — only apex predators that DO flee; some may never flee, see per-species)
```

- `PATROL`: like `WANDER` but bounded to a defined **territory** (a den/lair region, larger
  than a normal wander leash — the existing code already has a `_home`-based leash pulling
  wander back within 18.0 units; apex territory should simply use a larger leash radius, e.g.
  30–50m, same mechanism, no new code pattern needed).
  Aggression at the population/behaviour design intent: apex predators do NOT chase the player
  across the whole floor — they defend/patrol a territory and disengage past its edge (unlike
  a pack hunter which can range further while `DESPERATE`). This creates identifiable "boss
  territory" zones the player learns to read, matching the roguelike-dungeon-crawl-with-real-
  ecology fantasy: you don't get chased off the floor by the apex, you get chased out of ITS
  patch.
- `STALK`/`AMBUSH` or `CHARGE`: reuse archetype (c)'s stalk/ambush shape for stealthier apexes
  (Sabertooth, Gloom Tyrant), or archetype (f)'s charge shape for the burrower (Titan
  Molebeast surfaces via a "burst from ground" variant of charge/ambush — see per-species note
  below) or Chasm Drake (grounded, wingless — charges/lunges rather than flies, per the (d)
  note).
- `INTIMIDATE` (**new, apex-specific**): before the FIRST engagement in an encounter (once per
  fight, not every attack cycle), an apex predator gets a distinct roar/pose beat (1.0–1.5s,
  can be longer than a combat tell since it's not itself the strike — it's a "boss intro"
  beat) that also has a mechanical effect: while it plays, the predator's `detect_radius`
  read for THIS encounter is treated as if awareness_multiplier were momentarily higher
  (say +0.3 flat for the duration) — narratively "it's noticed you and everything about this
  encounter just got more serious," and it doubles as a fair warning that a serious fight is
  starting (the player has 1+ seconds to decide whether to engage or disengage before the
  first `STALK`/`AMBUSH` cycle begins). This is squarely a "human tuning call" item (§4).
- `ATTACK`: higher damage, longer wind-ups than mid-tier predators are fine here (apex fights
  are meant to be slower, more deliberate reads — per DESIGN_BIBLE §5.2 "positioning and
  patience beat button-mashing," this is where that pillar matters MOST), 0.7–1.0s tells
  acceptable/desired, with correspondingly longer recovery windows (real punish opportunities)
  so the fight has rhythm rather than being pure DPS-race.
- `FLEE`: apex predators generally should NOT flee, or only at extremely low health thresholds
  (5-10%, effectively "nearly already dead" rather than a normal predator's 25-35% archetype-c
  threshold) — an apex fleeing readily undercuts the "apex" fantasy. Titan Molebeast is the
  exception: as a burrower, its "flee" is functionally "burrow away and reposition," which
  looks like a disengage but is actually just its `RETREAT`-into-ground state before
  resurfacing elsewhere — not a morale break, a repositioning tool, closer to archetype (d)'s
  RETREAT-and-reperch than a scared flee.

**Parameters (starting values, generic apex):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius | 18–24 (T4-adjacent apex like Sabertooth) up to 26–32 (T5) | `× awareness_multiplier()` |
| territory/patrol leash radius | 30–50m (reuse existing `_home` leash mechanism at larger radius) | flat |
| intimidate duration (once per encounter) | 1.0–1.5s | flat |
| stalk/charge speed | `move_speed × 0.7` (stalk) / `× 1.8–2.2` (charge/lunge burst) | `× aggression_multiplier()` capped ×1.2 |
| attack wind-up (tell) | 0.7–1.0s | flat — deliberately long/readable per apex design intent above |
| attack recovery | 0.8–1.2s (real punish window) | flat |
| attack cooldown | 1.8–2.4s | `/ aggression_multiplier()` |
| flee-health-threshold | 5–10% (most apex) — see per-species for exceptions | mostly flat; not meaningfully affected by hostility since it's already near-zero |
| pack size | 1 (all apex in this archetype are solitary — Elder Marrowmother leads a PACK per archetype (b), not solitary, hence she's specced under (b) not (g) despite T5) | — |

**Ecosystem hooks:**
- Standard `record_kill()` — apex `carrying_capacity` should be very low (1-3 per floor, per
  FOOD_WEB.md's T5 population guidance), so a single kill can meaningfully affect that
  species' local pressure; but per FOOD_WEB.md's cascade rules this SHOULD ripple (removing
  an apex predator lets its prey boom, which then stresses THEIR food, etc.) — that's the
  generic cascade math already, no special-casing needed except for the one true exception:
- **The Hollow Stag is explicitly NOT in this archetype** — despite being T5, it gets its own
  archetype (h) below precisely because it inverts the apex-stalker shape entirely (passive,
  non-predator, catastrophic-if-killed rather than "another big fight"). Flagging clearly here
  so nobody accidentally specs the Stag with apex-stalker states by tier-proximity.

---

### (h) Keystone (The Hollow Stag)

**Covers:** The Hollow Stag only. Deliberately its own archetype — mechanically almost the
inverse of every predator archetype above.

**States** (minimal — this creature does not hunt, flee reactively in the normal sense, or
fight; extends only `WANDER`, adds `WARY` and a death-special-case, no `ATTACK` state at all):

```
WANDER(wide-roam, unbothered) → WARY(player very close) → WANDER
                                      ↓ (if attacked)
                                 [death → Ecosystem.record_keystone_kill(), see §1.3]
```

- `is_predator = false`, and unlike normal prey it does **not** `FLEE` readily — FOOD_WEB.md
  frames it as calm/unbothered ("its presence stabilises the web"), so its detect/reaction
  profile should read as serene rather than skittish. Recommend: does not flee from mere
  proximity at all (no `FLEE` state reachable via detection) — only reacts if actually
  attacked, and even then its reaction is closer to a startled retreat-a-short-distance than a
  full panicked sprint (a brief `WARY` withdrawal of 4-6m, then resumes `WANDER`), because
  narratively you generally get exactly one hit on it before either it's dead (small
  `max_health`, deliberately — killing it should be TRIVIAL mechanically, the cost is entirely
  ecological, not a combat gate) or it's gone.
- No `ATTACK` state, no `attack_damage`, ever. It is never a threat. This matters for the
  design read: the game should never accidentally make the Stag scary to approach (which
  would undercut "you did something wrong by choosing to kill it" — the choice must be clearly
  the player's, not the game defending it like a boss).
- **Death is the entire point of this archetype.** On `health <= 0`: instead of (or in
  addition to) the standard `_die()` → `record_kill()` path, call the new
  `Ecosystem.record_keystone_kill(species_id)` (§1.3) which should set `global_hostility` to a
  high floor value immediately (recommend 0.7–0.85 as a starting value — enough that the
  awareness/aggression multipliers spike hard and unmistakably) rather than letting it emerge
  from the normal population-ratio pressure formula (which, given the Stag's tiny
  `carrying_capacity` of 1–3, might already zero out ITS OWN pressure term but wouldn't
  necessarily produce a dungeon-wide spike on its own under the current per-species-averaged
  `_recompute_hostility()` math — a single species among ~30+ hitting max pressure barely
  moves a 30-way average). This is the one place I'm asking for a genuine special case rather
  than emergent behaviour, because FOOD_WEB.md is explicit that this should be catastrophic
  and immediate, not a rounding error in an average.
- Recovery from a Stag-kill spike should still use the existing "recovery during rest/time-
  passage" decay mechanism (FOOD_WEB.md's Recovery section) — just starting from a much higher
  floor and, narratively, taking noticeably longer (a slower decay RATE specifically after a
  keystone-triggered spike is a nice-to-have; flat is acceptable for M1-M4 if Mechanics wants
  to avoid adding a second decay-rate variable — flagging as optional refinement, not required).

**Parameters (starting values):**

| Param | Value | Scaling |
|---|---|---|
| detect_radius (WARY trigger, not flee) | 6–8m, and only relevant for the wary-withdrawal, not any hunt/flee logic | not scaled by awareness_multiplier — the Stag's calm shouldn't erode just because the floor is hostile; if anything that's thematically backwards |
| max_health | low (20-30, comparable to or below Mosslamb's 30) | flat — killing it should never be the hard part |
| wary withdrawal distance | 4–6m | flat |
| carrying_capacity | 1–3 per floor it appears on (likely just Floor 4-5 per tier table, though FOOD_WEB.md doesn't explicitly floor-place it — recommend Bonefields/Maw, T3-4+apex / T4-5, consistent with its T5 listing) | — |
| keystone_kill hostility floor | 0.7–0.85 (immediate set, not additive) | this IS the effect, not a scaled parameter |
| pack size | 1 (always solitary — a "the" name, singular by design) | — |

**Ecosystem hooks:**
- `Ecosystem.record_keystone_kill()` (new, §1.3) instead of relying purely on generic
  `record_kill()` math for the hostility effect — though `record_kill()` should presumably
  still be called too for population bookkeeping consistency (or `record_keystone_kill()`
  simply calls `record_kill()` internally and then does the extra hostility-floor-set on top
  — implementation detail for Mechanics, either order works as long as both effects land).
- No desperation logic (it doesn't hunt), no pack logic, no cascade-trigger role beyond the
  one specific death event. This is the simplest state machine of any archetype by design —
  the WEIGHT is narrative/systemic, not mechanical complexity.

---

### (i) Insect swarm / hazard

**Covers:** Razorwing Wasp, Glowmite Swarm, Bloodtick Crawler, Cinder Beetle, Chitin Scuttler,
Venomfang Centipede, Gravel Mantis, Deathcap Gnat Cloud, Spinneret Lurker, Corpsefly Cloud
(all 10 hostile insects, per FOOD_WEB.md — "pervasive hazards, not part of the trophic tiers,"
so treated as environmental threats layered separately from the 30-creature food web itself,
though they DO get eaten by Tier 1-2 animals per the same doc).

**States** (deliberately the lightest-weight archetype — insects are hazards, not
individually-tracked "creatures" with the full population/ecosystem machinery in most cases;
extends minimal `WANDER`/`ATTACK`, adds `SWARM`(cluster-move) and `LATCH`(for the
drain/immobilize variants)):

```
[most swarm/flying insects: Wasp, Gnat Cloud, Corpsefly, Glowmite]
SWARM(cluster idle/drift) → ALERT → SWARM-CHASE → ATTACK(repeated, low individual damage) → SWARM(disperse after player leaves)

[ground skirmisher/ambush insects: Mantis, Centipede, Scuttler, Beetle]
WANDER → (ALERT →) AMBUSH or CHASE → ATTACK → WANDER
  (essentially a miniature archetype (c), scaled down)

[latch/immobilize specialists: Bloodtick Crawler, Spinneret Lurker]
WANDER/AMBUSH → LATCH(on contact, damage-over-time or immobilize) → (shaken off by player action or timer) → WANDER
```

- **Design simplification specific to this archetype**: most insects should NOT be full
  `CharacterBody3D` `Creature.gd` instances individually simulated with the full state machine
  if they're meant to appear in genuine swarms (Wasp, Gnat Cloud, Corpsefly, Glowmite,
  Bloodtick as a "latches on" hazard) — recommend a lightweight **swarm emitter** pattern
  instead: a single logical hazard entity (with a hitbox/damage-zone and a particle-driven
  visual swarm) rather than N individual pathfinding creatures, which would be needlessly
  expensive and hard to make read well at low-poly scale anyway. The ground skirmishers
  (Mantis, Centipede, Scuttler, Beetle) and the two ambush specialists (Bloodtick as a single
  attacher, Spinneret Lurker as a spider) ARE reasonably individual `Creature.gd`-style
  instances since they're solo/small-group threats, not true swarms. This split is a
  significant implementation-shape recommendation — flagging clearly for Mechanics buy-in
  before insects are built, since building all 10 as individual pathing creatures would be
  substantial wasted effort if half of them are meant to read as clouds/swarms.
- `SWARM` (cluster-move variant): the swarm entity drifts/loiters in a bounded region (similar
  to archetype (a)'s WANDER-leash) until player enters its aggro radius → `SWARM-CHASE`
  (moves as a cluster toward player, no individual-member pathing) → `ATTACK` is a persistent
  damage-over-time or repeated-low-tick contact effect while player remains inside the swarm's
  volume, rather than discrete wind-up/attack cycles — the "tell" for these is the swarm's
  VISIBILITY and audio (buzzing gets louder near it) rather than a combat wind-up animation,
  since there's no single attack to read; player counterplay is positioning/avoidance and
  clearing the volume, not dodge-timing. This is a deliberately different combat-readability
  contract than every other archetype, and worth calling out explicitly: **insects are the one
  category where "avoid the area" replaces "read the tell" as the core counterplay.**
- `LATCH` (Bloodtick, Spinneret Lurker): on player contact (Bloodtick) or successful web-shot
  (Lurker, presumably a short-range projectile/web attack with its own brief tell, 0.4-0.5s),
  applies a status (drain-over-time for Bloodtick; immobilize/webbed for Lurker) that requires
  a player action to clear (e.g. an interact-button "shake off" or a few seconds of forced
  struggle) rather than being cleared by normal combat — this is a status-effect system
  dependency (Mechanics/systems call on exact clear mechanism), specced here only at the
  behavioural level: what triggers the latch and what it does, not how the player input for
  clearing it is implemented.
- Ground skirmishers (Mantis, Centipede, Scuttler, Beetle): treat as a miniature version of
  archetype (c) (solo ambush) — same state shape, much lower `max_health`/`attack_damage`,
  much shorter ranges, and Cinder Beetle gets a unique death-special-case: **on death, instead
  of (or in addition to) dropping meat, it detonates** — a small AoE burn effect centered on
  its death position, meaning killing one at melee range punishes the player exactly like a
  standard "exploding enemy" trope; tell for this should be a brief (0.3-0.4s) visual fuse/
  glow-brightening on death-trigger before the explosion actually applies damage, so a player
  who just landed the killing blow still has a beat to back off.

**Parameters (starting values, deliberately lighter detail than main archetypes per insects
being a hazard layer, not core food-web content — per the brief's floor-priority guidance,
Floor 1-2 insects listed in §3 get a bit more, but even those are lighter than main creatures):**

| Param | Value | Scaling |
|---|---|---|
| swarm aggro radius | 5–8m (short — you have to get close before a swarm reacts, but then it's very committed) | `× awareness_multiplier()` |
| swarm per-tick damage (contact DoT) | low, 1-3 per tick at ~0.5s ticks while inside volume | `× aggression_multiplier()` on tick rate (ticks faster, not harder, when hostile — keeps it avoidable rather than suddenly lethal) |
| ground-skirmisher detect_radius | 4–7m (short-range hazards, easy to avoid if attentive) | `× awareness_multiplier()` |
| ground-skirmisher attack wind-up | 0.35–0.45s (still must clear the i-frame floor even at this small scale) | flat |
| latch trigger range | Bloodtick: melee contact (~1m); Lurker: 5-7m web-shot range | flat |
| latch DoT/immobilize duration | 3-5s or until player clears it | flat |
| Cinder Beetle death-fuse | 0.3-0.4s before AoE | flat |
| pack size | true swarms: effectively "1 hazard entity" per encounter, visually many; ground skirmishers: 1-2 (Mantis solitary; Centipede/Scuttler may appear in small loose clusters of 2-3, non-coordinated) | — |

**Ecosystem hooks:**
- Per FOOD_WEB.md, insects sit OUTSIDE the 5-tier trophic structure and are eaten BY Tier 1-2
  animals rather than participating in the main predator-prey population math as
  predators/prey themselves in the same sense. Recommend: insects generally do NOT need
  `Species.gd` entries / `Ecosystem.register_species()` calls at all for M1-M4 scope — they're
  environmental hazards, not simulated populations. The one possible exception: if Mechanics
  wants insect density itself to respond to hostility (more swarms/hazards on a stirred-up
  floor, matching FOOD_WEB.md's "more wandering, ambushes... on your trail" language), that's
  cleanly achievable by scaling **spawn frequency/density** off `global_hostility` directly at
  the floor-population level (a spawner concern) rather than giving insects individual
  `Species` population tracking. Corpsefly Cloud specifically ties into the waste/attention
  rule (FOOD_WEB.md: "unbutchered carcasses attract... Corpsefly Clouds") — same mechanism as
  Marrow Hyena's scavenge-sense in archetype (b), just spawning/attracting a Corpsefly hazard
  entity instead of a full creature.

---

## 3. Per-species table

Legend: **Arch.** = archetype letter from §2. **Floors** per DESIGN_BIBLE §6 tier-availability
(Floor 1 T1-2, Floor 2 T1-3, Floor 3 T2-4, Floor 4 T3-4+apex, Floor 5 T4-5) — a species appears
on any floor whose tier range includes its tier; exact per-floor density is a spawn-table
concern for World Building/Mechanics, not restated as a full matrix here, but I list the
floor(s) each species is first eligible on and note where it persists. **Aggr./Aware.** are
FOOD_WEB.md's exact `base_aggression`/`awareness` values — matched exactly, not reinterpreted.
Carrying capacity values are **starting tuning values**, following FOOD_WEB.md's guidance
("Tier 1 high, e.g. 80-120; Tier 5 tiny, e.g. 1-3") scaled down proportionally for Floor 1's
already-shipped numbers (Mosslamb 80, Ashjackal 30, per `Main.gd`) as the calibration anchor.

### Tier 1 — Grazers (Floor 1-2 priority: FULL detail)

| Species | Arch. | Tier | Floors | Cap. (per floor, starting) | Aggr. | Aware. | Pack | Edible | Signature moves (tell) |
|---|---|---|---|---|---|---|---|---|---|
| **Mosslamb** | (a) | 1 | 1,2 | 80 (shipped value, `Main.gd`) | 0.05 | 0.3 | 1 | yes | *(shipped, existing)* Startle-turn (ALERT, 0.4-0.5s head-up freeze) → Bolt-flee (full `move_speed`, zig-zag direction changes every 1-1.5s while fleeing, distinct from a straight-line flee — cheap, high-value polish: makes fleeing prey feel alive rather than gliding away in a line). |
| **Grotto Springhare** | (a) | 1 | 1,2 | 90-100 (fast/skittish — set cap slightly higher than Mosslamb since FOOD_WEB.md notes "hard to catch," implying higher population sustains hunting pressure) | 0.05 | 0.5 | 1 | yes | Double-hop flee-start: a single vertical hop-in-place (0.2s, reads as a startle) immediately before bolting — telegraphs the flee direction change a beat early, rewarding players who are already tracking it. Faster flee speed than Mosslamb (`move_speed × 1.15` relative to its own base) reflecting FOOD_WEB.md's "hard to catch." |
| **Capglow Snail** | (a) | 1 | 1,2 | 100-120 (slow, resilient population per "slow" flavor + detritivore niche) | 0.02 | 0.2 | 1 | yes | No real flee — "slow" per flavor text, so on ALERT it withdraws into its shell (a `RETREAT`-into-defense micro-state: briefly invulnerable/reduced-damage for 1-1.5s, then resumes GRAZE) rather than fleeing distance. Tell: visible shell-tuck animation. This is a nice small variant worth flagging: the ONE Tier 1 grazer that doesn't run, giving players an easy, low-risk hunt target early — good onboarding creature. |
| **Blind Vole** | (a) | 1 | 1,2 | 90-100 | 0.05 | 0.4 | 1 | yes | Standard ALERT→FLEE per archetype baseline; being "blind" (flavor) suggests its detection should lean on a different sense than sight — recommend awareness_multiplier still applies normally to its `detect_radius` (matches FOOD_WEB.md's flat 0.4 value, no special-casing needed), but if World Building adds scent/vibration mechanics later, Blind Vole is the natural first candidate to react to those instead of line-of-sight. Flagging as a future hook, not required now. |
| **Palefish** | (a)/(e) | 1 | 1,2 | 70-90 (aquatic, water-feature-confined so effective local density is what matters, not floor-wide headcount) | 0.02 | 0.3 | 1 | yes | Confined to water volume (see archetype e). On ALERT, darts to deeper water / cover rather than a long-distance flee (it has nowhere far to go within a bounded pool) — a short, quick dart (`move_speed × 1.3`, 1-2s burst) then holds still (fish "freeze" behaviour) rather than continuous fleeing. |
| **Deep Quail** | (a) | 1 | 1,2 | 90-100, may cluster in coveys of 3-5 (cosmetic) | 0.05 | 0.5 | 1 (cosmetic covey 3-5) | yes | Burst flight-flee: a sudden upward/outward scatter-hop (reads as small-bird panic-flush, 0.3s) then low fast flee (`move_speed × 1.2`) — if implemented as a covey, EACH member flees independently on its own ALERT trigger rather than coordinating (no pack logic needed, just simultaneous individual archetype-a instances placed near each other). |

### Tier 2 — Small hunters/omnivores (Floor 1-2 priority: FULL detail; Ashjackal already shipped)

| Species | Arch. | Tier | Floors | Cap. (starting) | Aggr. | Aware. | Pack | Edible | Signature moves (tell) |
|---|---|---|---|---|---|---|---|---|---|
| **Gloomferret** | (c) | 2 | 1,2 | 35-40 | 0.35 | 0.6 | 1 | yes | Low-profile stalk (crouched gait, visually distinct from upright wander) → short lunge-bite (0.5s wind-up, 3-4m lunge distance) at prey-scale targets; against the player specifically, treat as a cautious opportunist: `flee-health-threshold` on the higher end (35-40%, it's "gamey" not tough per flavor, and a genuine risk-averse skirmisher) — good early "sometimes flees, sometimes commits" variety creature for Floor 1. |
| **Ashjackal** | (b) | 2 | 1,2 | 30 (shipped value, `Main.gd`) | 0.45 | 0.6 | 3-5 | yes | *(shipped baseline to extend, not replace)* Pack howl-alert (broadcasts pack-coordination per archetype b, audible cue for the player too — a howl is a fair warning that more are coming) → Circle-and-flank (archetype b CIRCLE state) → Snapping bite (0.55-0.7s wind-up, per archetype-b table) → pack breaks and flees if headcount drops below half with no landed hits in 8-10s. THIS is the archetype-b reference implementation — build it here first, then reuse the shape for Marrow Hyena/Antler Warg. |
| **Rockback Boar** | (b)-lite/(f)-lite | 2 | 1,2 | 35-40 | 0.4 | 0.4 | 1 (solitary omnivore, not a true pack hunter despite sharing some charge-DNA with (f)) | yes | Foraging WANDER (roots/carrion, per omnivore diet) → on threat, a SHORT telegraphed charge (smaller-scale version of archetype (f)'s charge: `move_speed × 1.6-1.8`, 6-8m distance, 0.5-0.6s rear-back tell — noticeably shorter/weaker than Rhinox's full mega-herbivore charge, this is "dangerous charge" per flavor, not "untouchable") → RECOVER (1-1.5s) → resumes foraging. Doesn't flee readily (aggression 0.4 is mid-range) but isn't a relentless hunter either — a genuine omnivore-opportunist read. |
| **Spinefowl** | (a)-lite/(c)-lite | 2 | 1,2 | 45-50 | 0.3 | 0.5 | 1, loose flock 2-4 (cosmetic) | yes (spines removed first, per flavor — a butchery-quality note for Mechanics/cooking, not a behaviour note) | Mostly grazer-shaped (archetype a ALERT→FLEE) since it preys on insects/small fish rather than chasing large targets, but will peck-attack (short 0.4s jab, low damage) if directly cornered rather than only fleeing — a mild archetype-c flavor at the very low end of aggression. |
| **Grave Otter** | (e) | 2 | 1,2 | 30-35 (aquatic, water-confined) | 0.25 | 0.5 | 2-3 (cosmetic family raft) | yes | Aquatic archetype-e baseline: submerge-and-dart on ALERT; low aggression (0.25) means it's much closer to prey-behaviour than predator-behaviour despite Tier 2 status — mostly flees, rarely fights, matches "oily... good for warming stews" as a low-drama harvest target. |
| **Cinder Cockatril** | (a)/(c)-lite | 2 | 1,2 | 35-40 | 0.4 | 0.5 | 1 | mildly toxic RAW (edible cooked, per Sulfur Chive note — cooking-system flag, not a behaviour-state difference, see archetype (c) toxin note) | Ground-bird predator of small prey (Deep Quail, Blind Vole per diet) — archetype (a)/(c) hybrid: normally skittish/fleeing around the player (moderate aggression 0.4, closer to Rockback Boar's profile than Ashjackal's), but a quick peck-lunge (0.45-0.5s tell, short range 2-3m) if cornered. ATTACK hitbox should flag a toxin-on-hit status per archetype-c's toxin note, resolved by the cooking/status system, not a new behaviour state. |

### Tier 3 — Mid predators (Floor 2 introduces these; Floor 3 continues — moderate-full detail, these are "next after Floor 1-2" per production priority)

| Species | Arch. | Tier | Floors | Cap. (starting) | Aggr. | Aware. | Pack | Edible | Signature moves (tell) |
|---|---|---|---|---|---|---|---|---|---|
| **Gloamstalker Lynx** | (c) | 3 | 2,3 | 15-20 | 0.6 | 0.7 | 1 | yes | Stealth stalk using cover (archetype c STALK, `commit_radius` tuned tight since it's a dedicated ambusher) → crouched AMBUSH lie-in-wait → pounce lunge (0.45-0.5s tell, fast lunge burst 5-6m). Flees at moderate health threshold (~30%) — a genuine hit-and-vanish predator, good "makes you check corners" Floor 2 addition. |
| **Hookbeak Ridgehawk** | (d) | 3 | 2,3 | 12-16 | 0.55 | 0.8 | 1 | yes | Perch-soar-dive per archetype (d) baseline — this is the FIRST aerial creature, build the flight-volume support for this one (flagged in §2(d) as needed starting Floor 2, not later). Dive telegraph 0.8-1.0s (toward the longer end given it's the introductory flier, give players generous first-encounter readability), talon-strike on dive contact, hard disengage-climb after. |
| **Marrow Hyena** | (b) | 3 | 2,3,4 (drawn to carrion floor-wide per scavenger flavor) | 20-25 | 0.65 | 0.7 | 4-6 | yes | Direct reuse of Ashjackal's archetype-b shape at larger pack size and higher aggression/awareness (bigger circle_radius to match bigger pack, shorter per-member commit windows since aggression 0.65 > Ashjackal's 0.45). Unique addition: passive SCAVENGE sub-state (§2b hook) — periodically checks for unbutchered `raw_meat` pickups within an extended sense radius and paths to consume them; this is the concrete mechanical expression of FOOD_WEB.md's "drawn to wasted carcasses" flavor line, and the clearest in-game teaching moment for the waste/attention rule. |
| **Bog Saurian** | (e) | 3 | 3 (Sunless Marsh is its home per "reptile" + aquatic diet skew) | 15-18 | 0.6 | 0.5 | 1 | yes (tail is prime meat, per flavor — a butchery-quality/yield note) | Semi-aquatic archetype-e: patrols shallow/bank WANDER, SUBMERGE on alert (visual read reduction, intentional per flavor), LUNGE from water (0.5s tell, 5-6m burst) onto bank targets. Moderate awareness (0.5, lower than most T3) fits "ambush from the murk" rather than "sees you coming." |
| **Tunnel Constrictor** | (c) | 3 | 2,3 | 10-14 | 0.5 | 0.4 | 1 | yes ("huge yield" per flavor) | The purest archetype-c AMBUSH specialist in the roster — low awareness (0.4, lowest T3 value) but devastating commit: lies in wait IN a wall/floor recess (visually hidden, not just crouched) with an unusually tight `ambush_trigger_radius` (2-3m, tightest in the roster) and a correspondingly strong, sudden lunge (0.4s tell — right at the archetype's floor, since the whole point is "sudden ambush from walls" per flavor — but paired with a loud audio/visual cue the instant it breaks cover so the short timer stays fair). Big single-target grab-and-constrict attack rather than a fast bite — recommend a longer `attack recovery` (0.8-1.0s) than a typical ambusher to compensate for the very short wind-up, keeping overall fairness balanced across the whole attack cycle even though the initial tell is brief. |
| **Antler Warg** | (b) | 3 | 2,3 | 18-22 | 0.6 | 0.7 | 4-6 | yes | Second archetype-b pack reuse (after Ashjackal, alongside Marrow Hyena) — "fast pack hunter of the Rootways" per flavor: higher stalk/circle speed than Ashjackal or Hyena (`move_speed × 0.8` stalk instead of the archetype baseline 0.7) to express "fast," otherwise standard pack-hunter shape. Good candidate for the Floor 2 "second pack predator" so players learn packs generalize rather than being an Ashjackal-only quirk. |

### Tier 4 — Large predators (Floor 3-4; lighter-but-complete detail per production priority — these arrive well after Floor 1-2)

| Species | Arch. | Tier | Floors | Cap. (starting) | Aggr. | Aware. | Pack | Edible | Signature moves (tell) |
|---|---|---|---|---|---|---|---|---|---|
| **Chasm Drake** | (c)/(g) | 4 | 3,4 | 6-9 | 0.75 | 0.7 | 1 | yes (searing required — toxin-adjacent handling note, resolves in cooking system) | Grounded "wingless wyvern" — do NOT build flight logic for this one (see §2d note); use solo-ambush/apex-stalker shape instead: territorial PATROL, STALK, a strong ground lunge/bite-and-tail-swipe combo (two-hit attack pattern: 0.6s wind-up bite, then a follow-up tail-swipe with its own separate 0.5s tell if the player doesn't retreat after the bite lands) — the two-tell combo is a good "this one's tougher than a single-hit ambusher" signal appropriate to T4. |
| **Gravemaw Ursine** | (g)-lite/(c) | 4 | 3,4 | 5-8 | 0.7 | 0.6 | 1 | yes ("a feast, a nightmare to fight" — high risk/reward, reflect in high damage + long recovery windows so skilled play is rewarded) | Territorial cave-bear behaviour: PATROL a den area, heavy stand-and-fight ATTACK (0.7-0.8s wind-up, high damage, but LONG recovery 1.0-1.3s — a real punish opportunity) rather than a hit-and-run ambusher; doesn't flee readily (aggression 0.7) and holds ground even at moderate damage, only breaking at low health (~15-20%). |
| **Pale Sabertooth** | (g) | 4 | 3,4 | 4-7 | 0.8 | 0.7 | 1 | yes (prized hide — a crafting/yield hook, not behavioural) | "Glass-cannon predator" per flavor — this is the one T4 that should hit VERY hard but also be relatively fragile itself (lower `max_health` than Ursine despite being a full apex-stalker archetype) and highly committed once it engages (short cooldowns, aggressive re-engagement) rather than territorial-patient like Ursine — a fast, dangerous burst-damage fight rather than a slow attrition one. |
| **Dire Basilisk** | (c) | 4 | 3,4 | 5-8 | 0.7 | 0.5 | 1 | yes (toxin glands — must be Sulfur-Chive-handled, cooking-system flag) | Solo ambush with a toxin-on-hit ATTACK (per archetype-c toxin note) — moderate awareness (0.5, on the low side for T4) rewards careful approach/avoidance; the toxin makes even a single landed hit meaningfully costly (DoT), so the fair-tell requirement matters MORE here than for a pure-damage predator — do not shorten this creature's wind-up below the archetype-c standard (0.5-0.65s) even under high aggression_multiplier, given the stacked risk of a toxin hit. |
| **Deepwater Leviathan-eel** | (e) | 4 | 3 (Sunless Marsh's deep pools specifically) | 3-5 (aquatic apex-of-the-water, very low pop per flavor "enormous") | 0.65 | 0.5 | 1 | yes ("enormous, oily meat" — big single-carcass yield) | Fully water-confined per archetype (e) — the water feature itself is effectively this creature's whole territory (see archetype-e note on treating water volumes like lair territory); long-range lunge from open water onto bank/shallow targets (8-10m burst, longer than Bog Saurian's, reflecting size) with a correspondingly longer, very visible tell (a surface disturbance/wake cue building for ~0.6-0.7s before the lunge breaks water) since it's meant to be a "the pool itself is dangerous" set-piece threat rather than a fast-twitch ambush. |
| **Stonehide Rhinox** | (f) | 4 | 3,4 | 4-6 (few individuals, "adults untouchable" per flavor) | 0.5 | 0.3 | 1 | not really hunted in practice per flavor, but not flagged non-edible in canon either — treat `edible = true` structurally, expect rare use | Full archetype-f mega-herbivore charge, exactly as specced in §2(f) — this IS the reference implementation for that archetype, only entry in the roster that needs it. |

### Tier 5 — Apex (Floor 4-5; lighter-but-complete detail — furthest from current production)

| Species | Arch. | Tier | Floors | Cap. (starting) | Aggr./Aware. (FOOD_WEB.md gives role, not explicit numeric T5 values — recommend numeric extension below) | Pack | Edible | Signature moves (tell) |
|---|---|---|---|---|---|---|---|---|
| **The Gloom Tyrant** | (g) | 5 | 4,5 | 1-2 | Aggr. 0.85 / Aware. 0.75 (recommended — FOOD_WEB.md's T5 table lists role only, not numbers; these are Cogg's proposed starting values, please confirm/adjust) | 1 | yes | Full apex-stalker per §2(g): INTIMIDATE roar on first engagement, long deliberate wind-ups (0.8-1.0s) but heavy damage and a genuinely large territory leash (40-50m) — "apex predator of the deep" should feel like entering its domain, not just meeting a tough mob. |
| **Elder Marrowmother** | (b)+command-layer | 5 | 4 (commands Marrow Hyena packs — co-locate spawns) | 1 | Aggr. 0.75 / Aware. 0.75 (recommended) | leads a hyena pack (4-6, per Marrow Hyena's own pack size) rather than having her own separate pack | yes | Per §2(b) command-layer note: mechanically a beefed-up archetype-b pack-hunter herself, PLUS while alive raises her escorting pack's effective aggression (+×1.2-1.3 local multiplier) and suppresses their FLEE morale-break. Killing her first (if the player can isolate her) should visibly embolden-then-demoralize the escorted pack — recommend the pack immediately re-runs its FLEE check the instant she dies, since her death removes the morale-suppression. |
| **Cavern Roc** | (d) | 5 | 5 (giant raptor "of the vaults" — Maw-tier) | 1-2 | Aggr. 0.75 / Aware. 0.85 (recommended) | 1 | yes | Full aerial archetype-d at the largest scale in the roster — longest dive distance, highest dive speed multiplier (still capped per the archetype's aggression_multiplier ceiling so it stays dodgeable), largest detect_radius in the game (26-32m) befitting "giant raptor." |
| **The Sunless Wyrm** | (g) | 5 | 5 only (explicitly Floor 5 apex per flavor) | 1 | Aggr. 0.9 / Aware. 0.8 (recommended — this is THE floor-5 capstone, should be the single hardest numeric profile in the roster) | 1 | yes | Apex-stalker archetype at its most extreme: "eats everything" per diet note (functionally: no diet restriction, preys on anything including other apex, which the population math should reflect by giving it a broad/wildcard `diet` array covering all tiers rather than a specific short list) — longest wind-ups (0.9-1.0s, giving max readability to compensate for it being the single most dangerous fight in the game), largest territory, and the one creature where INTIMIDATE should arguably be extended (1.5-2.0s) as a true "final encounter" beat. |
| **Titan Molebeast** | (g)+(f)-ish burrow variant | 5 | 4,5 | 1-2 | Aggr. 0.7 / Aware. 0.5 (recommended — lower awareness than other T5 fits "burrower," it senses differently/less broadly at range but is dangerous up close) | 1 | yes | Distinct traversal gimmick: spends baseline time BURROWED (invisible/untargetable, a variant of archetype (d)'s RETREAT applied to going underground instead of up) and surfaces to attack — recommend a clear pre-surface tell (ground-shudder/cracking visual+audio for 0.6-0.8s at the surfacing point) before it erupts into an archetype-f-style short charge/slam, then re-burrows. "Reshapes terrain" per flavor suggests its surfacing could also be a light environmental-hazard beat (e.g. temporarily cratering the ground at the burst point) — flagging as a nice-to-have, not required for the base behaviour to function. |
| **The Hollow Stag** | (h) | 5 (but see archetype-h floor note) | likely 4,5 (Bonefields/Maw — not explicitly floor-placed in FOOD_WEB.md; recommend confirming placement, this is a content-placement gap not a behaviour gap) | 1-3 | Aggr. ~0 / Aware. low (it doesn't hunt, and per §2h shouldn't erode its calm under hostility) | 1 | technically edible per FOOD_WEB.md structure, but killing it is the entire catastrophic event — see §2(h) | Passive WANDER, brief WARY withdrawal if crowded, no attack ever. The single most mechanically simple entry in the entire roster — all its weight is in the `record_keystone_kill()` consequence, not its combat behaviour. |

### Insects (10 hazards — Floor 1-2 relevant ones get slightly fuller detail per production priority; all are lighter than main-roster creatures per §2(i))

| Insect | Arch. | Likely floors (recommended — FOOD_WEB.md doesn't tier-place insects explicitly; flagging as a placement gap) | Pack/swarm shape | Edible | Signature hazard (tell) |
|---|---|---|---|---|---|
| **Razorwing Wasp** | (i) swarm | 1,2 (early, common hazard) | true swarm entity | no (hazard insects generally non-cooking-relevant unless Lore later decides otherwise — flagging, not deciding here) | Buzzing audible cue at range (the tell IS the sound getting louder) → contact-DoT bleed while inside swarm volume; disperses briefly if player exits volume and re-forms after a short delay if they linger nearby. |
| **Glowmite Swarm** | (i) swarm | 1,2 | true swarm entity | no | Visually bright/attention-grabbing (bioluminescent) which is itself fair warning; contact applies a "dazzle" (brief reduced-visibility or aim-wobble effect for the player, systems-dependent) rather than pure damage — a debuff swarm, distinct in feel from Wasp's bleed. |
| **Bloodtick Crawler** | (i) latch | 1,2 | solitary attacher | no | Near-invisible until contact (low profile per "crawler" + "latches on") — the fair-tell compromise here is a SHORT detection window before contact (a small audible/visual cue at ~1-1.5m, giving a half-second to react) rather than a long-range tell, since its whole design is "the sneaky one." Drains health-over-time once latched until shaken off. |
| **Cinder Beetle** | (i) ground-skirmisher + death-special | 1,2 | solitary/loose pairs | no | Ordinary weak ground-skirmisher in life; on death, 0.3-0.4s fuse-glow tell before an AoE burn detonation (see §2i) — teaches players to finish it at range or back off immediately after the killing blow. |
| **Chitin Scuttler** | (i) ground-skirmisher | 2,3 | loose clusters 2-3 | no | "Armored, tanky, slow" per flavor — high effective HP-for-its-size and slow attack cadence rather than a dangerous tell; mostly a stamina-attrition nuisance rather than a burst threat, good contrast piece against faster insects. |
| **Venomfang Centipede** | (i) ground-skirmisher | 2,3 | loose clusters 2-3 | no | Fast ground-skirmisher with a toxin-on-hit bite (short 0.35-0.4s tell, per the archetype floor) — "fast" per flavor means keep its `move_speed` noticeably higher than Scuttler's to contrast directly. |
| **Gravel Mantis** | (i) ground-skirmisher/ambush | 3,4 | solitary | no | "Camouflaged ambush; high burst" — closest insect analogue to archetype (c) proper rather than (i)'s lighter ground-skirmisher shape; deserves a real AMBUSH lie-in-wait (not just a shortened detect radius) given "high burst" implies a serious punish for walking into one. Recommend treating this as a small-scale full archetype-c instance rather than the lightweight ground-skirmisher template used for Scuttler/Centipede. |
| **Deathcap Gnat Cloud** | (i) swarm | 3,4 | true swarm entity | no | Spore-cloud DoT (poison rather than Wasp's bleed or Glowmite's dazzle) — visually a drifting particulate cloud, slower-moving swarm than Wasp (matches "cloud" over "wasp" framing) but the poison lingers briefly after the player exits the volume (a short residual-DoT tail), making "just walk out" slightly less of a full escape than with the other swarms — a nice differentiator. |
| **Spinneret Lurker** | (i) latch/(c) cross-reference | 3,4 | solitary | no | Web-shot ranged latch (5-7m, 0.4-0.5s tell on the shot itself) applies immobilize rather than Bloodtick's drain — pairs naturally with ground-skirmisher or small ambush ground predators nearby (a Lurker webbing the player right before a Mantis or Centipede closes in is a good designed "combo" encounter for World Building to place deliberately on Floor 3+). |
| **Corpsefly Cloud** | (i) swarm + waste-attention hook | any floor (spawns reactively at unbutchered carcasses rather than being floor-placed like the others) | true swarm entity, spawned reactively | no | Doesn't need a home territory at all — spawns/attracted specifically to un-collected `raw_meat` pickups per the waste/attention rule (§2i hook), lingers around the carcass, disperses once it's gone (collected or fully decayed/despawned). Mechanically the clearest, most direct expression of "clean, purposeful hunting is safest" from FOOD_WEB.md — recommend this be one of the FIRST insects implemented despite being T-agnostic, since it's a direct teaching tool for the core over-hunting/waste theme, not just a combat hazard. |

---

## 4. Tuning knobs — the values I most want a human call on before locking

These are the parameters where I made a reasonable starting guess but genuinely expect
playtesting (Damien + Mechanics) to move them, roughly in priority order:

1. **Pack-hunter single-attacker-at-a-time rule (archetype b)** — I specced only one pack
   member committing to `ATTACK` at once as a solo-play fairness knob. This could make packs
   feel too tame/scripted if it's too strict, or the fight could feel unfair/overwhelming if
   loosened. Needs actual multi-Ashjackal playtesting once pack coordination ships — this is
   the single biggest "feel" unknown in the whole doc.
2. **Attack wind-up durations across the board, especially the archetype-c ambush lunge floor
   (0.4-0.55s) and ground-skirmisher insect wind-ups (0.35-0.45s)** — I anchored everything to
   "must clear the player's 0.35s i-frame window with margin," but where exactly the margin
   should sit (bare-minimum-clears-it vs. comfortably-readable) is a feel call that depends on
   actual combat-camera framing and animation clarity, which I can't evaluate from a doc.
3. **Rhinox charge damage as 30-40% of player max_health** — this is a big, opinionated
   number (an "avoid, don't fight" design intent for a Tier 4 creature). Confirm this is the
   intended power-curve position before Floor 2-3 content locks around it, since it implies
   Rhinox is meant to be a hazard-to-route-around rather than a normal kill target at that
   point in player progression.
4. **The keystone hostility-floor value (0.7-0.85) on Hollow Stag death** — this is the
   headline "catastrophic" number in the whole spec and I picked it somewhat arbitrarily to be
   "unmistakably severe." Damien should sanity-check this against however global_hostility
   decay/recovery pacing actually plays once M2 ships, since too high + too slow a decay could
   read as a soft-lock rather than a consequence.
5. **INTIMIDATE duration and effect on apex encounters (archetype g)** — a "boss intro" beat
   is a strong feel decision (some players love it, some find it padding) and I gave it a
   mechanical effect (temporary awareness bump) that's easy to cut if playtesting says it's
   unnecessary friction.
6. **Aerial flight-volume timing** — flagged that Floor 2 (not Floor 3) is when the first
   flying creature (Hookbeak Ridgehawk) is actually needed, which is earlier than the "more
   creatures for Floor 1-2" framing might suggest at a glance. Worth Damien/Mechanics
   confirming this doesn't blindside the schedule, since flight is a new movement-volume
   system, not just new tuning values on the existing ground machine.
7. **Insect implementation split (true swarm-entity vs. individual Creature.gd instances)** —
   a structural recommendation, not just a number, but it changes how much work 10 insects
   actually are. Worth explicit sign-off before anyone starts building insects, since building
   all 10 as individually-simulated pathing creatures (if that's what happens by default
   without this doc) would be significantly more expensive than the swarm/skirmisher split
   recommends.
