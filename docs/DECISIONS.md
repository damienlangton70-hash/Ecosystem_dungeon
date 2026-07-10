# Deepforage — Design Decisions (binding)

Approved calls from Damien (owner). **Treat these as canon — do not re-litigate.**
When a system is built, follow the decision here; if a decision conflicts with an
older doc, this file wins and the older doc should be synced.

_Decided 2026-07-09._

---

## Current milestone — TOP PRIORITY

_Decided 2026-07-10 (owner-directed: "build in sections to complete full Floor 1")._

**D16 — Complete FULL FLOOR 1, in sections. This is the current TOP PRIORITY — do it before the
creature-rig / animation polish tracks; resume those once Floor 1 is complete.**
Build one section per run; each must pass `tools/validate.sh`, stay runnable, and not regress
existing systems (combat, animation, creature rigs, audio, cooking, ecosystem, graphics).
- **S1 — Scale & enclosure (fixes "world falling"):** enlarge Floor 1 to ~10× today's size
  (~500×500). Guarantee no falling: ONE solid ground collider across the whole area (no gaps),
  tall/thick perimeter walls fully enclosing it, the player spawns on solid ground, the descent
  shaft has a solid landing (no infinite void), AND a safety kill-plane (~y −60) that respawns
  the player at the entrance if anything slips through.
- **S2 — Populate:** spawn the full Floor-1 ecosystem from `data/lore.json` (every creature whose
  `floors` includes 1: Mosslamb, Grotto Springhare, Blind Vole, Deep Quail, Gloomferret,
  Ashjackal, Rockback Boar, Spinefowl, Cinder Cockatril, Gloamstalker Lynx) in believable numbers
  across the space — prey common, predators rarer, Lynxes guarding the descent.
- **S3 — Environment:** fill the larger space — multiple glowcap groves, water pool(s), a rocky
  ridge / landmarks, and forageable flora (trees / berry bushes / herbs) distributed widely.
- **S4 — Integrate & performance:** confirm combat, creature rigs/animation, audio,
  cooking/foraging and the ecosystem all work together on the big floor; light performance pass
  for the larger scene.
- **S5 — Deliver:** a validated build; once the **Workflows permission** is granted, CI
  auto-builds the Windows/Linux installers (workflow already staged at `ci/build.yml`).

---

## Systems & scope

**D1 — Butchery-quality tiers: APPROVED (as a system).**
Three tiers — Botched / Clean / Precise → **×0.60 / ×1.00 / ×1.25** buff magnitude.
Keep it simple (no further sub-tiers). This is now canon; add a one-line reference to
`FOOD_WEB.md` so it isn't treated as undocumented.

**D2 — Insects: HYBRID implementation.**
- **Swarm/cloud types** → a single lightweight "swarm emitter" entity (NOT individual
  `Creature.gd` instances): Razorwing Wasp, Glowmite Swarm, Deathcap Gnat Cloud,
  Corpsefly Cloud, Bloodtick Crawler.
- **Individually-pathed `Creature.gd` instances** for the large solo bugs: Gravel Mantis,
  Venomfang Centipede, Chitin Scuttler, Spinneret Lurker, Cinder Beetle.

**D3 — Aerial flight: DEFERRED to Floor 3+.**
Floor 2 (The Rootways) ships **ground-based** so it lands sooner. Aerial predators
(Hookbeak Ridgehawk, later Cavern Roc) arrive with the flight system on Floor 3, or use a
perched/ground stand-in until then. Do not build a flight-volume system for Floor 2.

**D4 — Ecosystem API: keep it small.**
Add `population_ratio()`. Do **not** add a separate `record_keystone_kill()` — fold it into
`record_kill(species_id, amount := 1, is_keystone := false)`.

## Combat & fairness

**D5 — Pack attackers: 1–2 commit at a time.**
For pack hunters (Ashjackal, Marrow Hyena) only **one or two** members attack at once; the
rest circle/feint. Exact count to be tuned in playtest.

**D6 — Ashjackal telegraph retrofit: APPROVED.**
Give the already-shipped Ashjackal an attack wind-up tell (**0.4–0.5s**, red glow like the
Lynx) for consistency/fairness.

**D7 — Pinned numbers (were "recommended"):**
- Stonehide Gorehorn charge damage → **cap at 30% of player max HP** (not 40%).
- Hollow Stag keystone-kill hostility floor → **0.75**.

## Content

**D8 — The Hollow Stag stays uncookable.**
No recipe, no meat/cut item. Killing it fires the keystone hostility spike (D7). A narrative
"consequence" beat may be added later — but never a dish.

**D9 — Accept Lore's provisional placements/values.**
Floor placements for the Hollow Stag (Floor 4–5) and all 10 insects, the "Apex Marrow-Cut"
shared apex-meat slot, Tier-5 aggression/awareness numbers, and Elder Marrowmother stats are
**accepted as provisional** — build to them, tune in playtest. No sign-off needed to proceed.

**D10 — Recipe numbers are provisional.**
All `[tune]` buff magnitudes/durations across the 30 dishes are accepted as starting values;
tune once the cooking loop is playable. Don't block on them.

## Art

**D11 — ART_DIRECTION.md is the visual canon** and supersedes DESIGN_BIBLE §7. Do the sync pass.

## Combat feel & animation

_Decided 2026-07-10 (owner-directed: "make combat souls-like" + "work on animations"). Starting values — tune in playtest._

**D12 — Animation pipeline: procedural Skeleton3D + AnimationTree.**
The player is a code-built `Skeleton3D` humanoid with rigid `BoneAttachment3D` box limbs
(`src/player/PlayerRig.gd`), driven by an `AnimationTree` state machine: a `BlendSpace1D`
locomotion node (idle→walk→run) plus one-shot Roll / AttackLight / AttackHeavy / Hit states.
Clips are authored in GDScript (no scene-file merges). Graphics may later swap the box limbs
for sculpted low-poly meshes **on the same skeleton** without touching animation/state code.

**D13 — Souls-like commitment + dodge-cancel.**
Attacks and the dodge are committed (no free movement-cancel), EXCEPT a dodge may cancel an
attack or a flinch — the i-frame roll is the primary defensive tool. Confirmed constants
(already in `Player.gd`): dodge = 0.45s roll with a 0.35s i-frame window, stamina cost 22;
light attack 16 / heavy 34 stamina; sprint drains stamina (`SurvivalStats`). Actions are
blocked at empty stamina. Attack-clip lengths/strike timing mirror `LIGHT/HEAVY.time/.hit`
so the visible swing lands with the hitscan.

**D14 — Healing is the cooking loop (no separate Estus-style flask).**
Cooked meals restore HP + timed buffs; campfires and magic circles are the checkpoint layer.
Souls-like risk/reward maps onto Deepforage's existing survival systems rather than a bolted-on
heal item.

**D15 — Lock-on is a soft-lock toggle (Q).**
Targets the nearest creature in range; the player orients to it; it drops when the target
leaves range/validity. This is the confirmed model to build combat around.

## Internal cleanup (studio directives, not design calls)
- Migrate hardcoded `Color(...)` literals in `Main.gd`, `Player.gd`, `Pickup.gd`,
  `Forageable.gd`, `Campfire.gd`, `Creature.gd` to `Palette` tokens.
- Graphics agent to write `MaterialLib.gd` (shared toon-ramp + rim shader, headless-safe).
- Keep `data/lore.json` the single machine-readable source; systems should load from it
  rather than re-hardcoding values.
