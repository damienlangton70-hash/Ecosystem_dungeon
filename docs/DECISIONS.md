# Deepforage — Design Decisions (binding)

Approved calls from Damien (owner). **Treat these as canon — do not re-litigate.**
When a system is built, follow the decision here; if a decision conflicts with an
older doc, this file wins and the older doc should be synced.

_Decided 2026-07-09._

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

## Internal cleanup (studio directives, not design calls)
- Migrate hardcoded `Color(...)` literals in `Main.gd`, `Player.gd`, `Pickup.gd`,
  `Forageable.gd`, `Campfire.gd`, `Creature.gd` to `Palette` tokens.
- Graphics agent to write `MaterialLib.gd` (shared toon-ramp + rim shader, headless-safe).
- Keep `data/lore.json` the single machine-readable source; systems should load from it
  rather than re-hardcoding values.
