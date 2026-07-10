# Deepforage — Roadmap & Living Plan

The Studio Director reads this first every morning. Keep it current: check off what
shipped, and always leave a concrete **Next up** list for the following run.

> **Approved decisions are binding — read `docs/DECISIONS.md` and follow it.** If a decision
> there conflicts with an older doc, DECISIONS.md wins.

## Guiding scope

A complete game matching every spec is many weeks of small daily increments — the same
as it would be for a human indie team. We build a **playable vertical slice first**, then
widen it floor-by-floor and system-by-system. Every commit leaves the game runnable.

---

## Milestones

### M0 — Foundation ✅ (done)
- [x] Godot 4.3 project that opens and runs.
- [x] Third-person player controller (move/sprint/jump/mouse-look).
- [x] Descending procedural cavern (three terraces) proving the "deeper and deeper" pillar.
- [x] Survival stat skeleton (hunger/stamina) + HUD depth read-out.
- [x] Ecosystem + Species code skeletons with over-hunting hostility model.
- [x] CI + `tools/validate.sh` QA gate.
- [x] Design bible, food web, team charter.

### M1 — Vertical Slice: "Floor 1, alive"
The first genuinely fun 10 minutes.
- [x] **World:** Floor 1 (Fungal Shallows) as a real environment — entrance, glowing fungal
      grove (glowcap pillar-trees + lights), water pool, cover rocks, and a descent shaft to
      Floor 2 (trigger stub). Still low-poly/procedural.
- [x] **Combat (core):** stamina-gated light attack, dodge-roll with i-frames, right-click
      lock-on, front-arc melee hitscan, health + hitstun + respawn. (Heavy attack, real
      weapons and parries still to come.)
- [x] **Creatures:** Mosslamb (prey: wander/flee) and Ashjackal (predator: chase/attack) with
      an AI state machine; deaths report to the Ecosystem.
- [x] **Survival:** hunger + stamina + death/respawn, **starvation drains HP**, butcher downed
      creatures for **raw meat**, and a buildable **campfire** cook-point.
- [x] **Cooking & foraging:** forage regrowing berry bushes + herbs; cook meat + herb/fruit into
      **meals** that restore hunger, heal, and grant timed buffs (regen / stamina / defense / warmth).
- [x] **Feel:** readable combat HUD + procedural cave-ambience bed, campfire crackle, and
      combat/creature SFX (whoosh/thud/growl/hurt/chime).
- [x] **Look & feel:** a studio colour contract (`Palette.gd`) + shared material language
      (`MaterialLib.gd`, now with real 64×64 tileable textures) + a low-poly flora library
      (`Flora.gd`) — silhouette-distinct trees and per-ingredient forageables; Floor 1 rewired
      off the palette. Full art bible in `docs/ART_DIRECTION.md`, including a §8 art-requirements
      table for the whole 30-creature/10-insect/23-flora roster.
- [x] **Creature identity:** the 3 currently-spawned species (Mosslamb, Ashjackal, Gloamstalker
      Lynx) get real bespoke low-poly silhouettes instead of one shared generic rig — see "Done
      recently" below for detail.

### M2 — The Ecosystem Reacts
- [ ] Populations per species; predators hunt prey; day/rest cycle ticks the sim.
- [ ] Over-hunting consequence: deplete a species → global hostility rises → animals notice
      you sooner and hit harder (wire `Ecosystem.aggression/awareness_multiplier`).
      *(Design ready: per-species awareness/aggression scaling + over-hunting cascade rules in
      `docs/CREATURE_BEHAVIOUR.md` and `data/lore.json`.)*
- [ ] On-screen/diegetic feedback that the dungeon is "stirred up".

### M3 — Survival & Shelter Depth
- [ ] Thirst + body temperature; cold deeper down.
- [ ] Shelter building: tent, den, and **magic circle** cook-point; rest to recover.
      *(Design ready: shelter/craft items in `docs/ITEMS.md`.)*
- [ ] Cooked-food buffs; spoilage; a simple crafting/inventory pass.
      *(Design ready: buff + spoilage rules in `docs/RECIPES.md` + `data/lore.json`.)*

### M4 — Descend: Floors 2–5
- [ ] Floors 2–5 as distinct full environments, each deeper, darker, deadlier.
- [ ] Full 30-monster / 5-tier food web populated across floors (see `FOOD_WEB.md`).
      *(Design ready: per-species floors, stats & behaviour in `docs/BESTIARY.md`,
      `docs/CREATURE_BEHAVIOUR.md`, `data/lore.json`.)*
- [ ] 3 trees, 10 fruit bushes, 10 herb/spice types, 10 hostile insects placed per biome.
      *(Design ready: flora effects/placement + insect hazards in `docs/ITEMS.md`,
      `docs/BESTIARY.md`, `data/lore.json`.)*
- [ ] Tier-appropriate apex encounters gating the descent.

### M5 — Content, Polish & Ship
- [ ] Recipe breadth; bestiary/journal UI; save/load.
      *(Content ready: 30 dishes in `docs/RECIPES.md`; full bestiary text in `docs/BESTIARY.md` —
      UI still to build.)*
- [ ] Audio & music pass; options menu; controller support.
- [ ] Reliable Windows/Linux/macOS installers via CI releases.

---

## Next up (for the very next run)

**⚠ Sync note (2026-07-10 pm):** `docs/DECISIONS.md` **D16** (decided today) makes completing
Floor 1 in full — sections S1–S5 — the current TOP PRIORITY, ahead of the combat/animation A4 item
and creature-rig polish below. This list hasn't been fully re-sequenced around D16 yet; treat
DECISIONS.md as authoritative on ordering. Status as of this run: **S1 (scale/enclosure) and S3
(groves/water/ridge/flora) already look substantially shipped** in the current `Main.gd` — a big
160×150 fully-enclosed cavern, 12 glowcaps, 4 ironbarks, 2 water pools, 3 palewillows, an 8-piece
rock ridge, 36 cover rocks, 22 glow spots, 24 forageables. **S2 (populate): ✅ SHIPPED (2026-07-10
pm)** — see "Done recently" below; all 10 species D16 names for Floor 1 now spawn. Two floor-1
species from `lore.json` that D16's own list didn't name — Capglow Snail (`capglow_snail`,
detritivore, needs a de-slime prep hazard) and Palefish (`palefish`, aquatic) — are still absent;
flagging as a small remaining gap, not blocking. **S4 (integration/perf) and S5 (CI delivery)
status still unverified** — S4 is the natural next D16 item: confirm combat/rigs/audio/cooking/
ecosystem all hold up with the floor now carrying ~44 creatures at once.

**Also image-inspired: ✅ SHIPPED (2026-07-10 pm).** Damien shared a concept-art reference
(painterly isometric dungeon scene) and asked to "match the look." Rather than chase photoreal
rendering (against house style — stylized low-poly stays canon), this became three honest,
low-poly-appropriate translations, all now shipped: a real styled **HUD**, a **stilt shelter +
hanging lantern** landmark, and **mushroom-cluster** flora variety — see "Done recently" below
for all three.

The Lore team has now shipped the full design layer **ahead of production** (`docs/BESTIARY.md`,
`docs/CREATURE_BEHAVIOUR.md`, `docs/RECIPES.md`, `docs/ITEMS.md`, `data/lore.json`) — every item
below is backed by concrete spec + loadable data, so implementation isn't blocked on design.

**★ Owner priority (2026-07-10) — Combat / animation track.** Damien asked to make combat
Souls-like and to work on animations; the approved plan sequences the build starting with the core.
Increments 1 (rig + AnimationTree), 2/A1 (2D locomotion + turn-in-place), 2/A2 (attack game-feel)
and 2/A3 (defence + reactions) have shipped — **A4 is now the lead item**:

- **A1 — Directional locomotion: ✅ SHIPPED (2026-07-10).** 2D `BlendSpace2D` (strafe/backpedal,
  walk→run) + a turn-in-place state, driven by `PlayerRig.update_locomotion()`.
- **A2 — Attack game-feel: ✅ SHIPPED (2026-07-10).** 3-hit light combo chain with recovery-cancel
  windows + input buffering, hitstop on connect, and slash/impact VFX (`src/systems/combat/CombatFX.gd`).
- **A3 — Defence + reactions: ✅ SHIPPED (2026-07-10).** Player poise + stagger and a parry (key R)
  that staggers the attacker; creature hit-react flinch + topple/sink death; D6 wind-up 0.5s; D5 caps 2 pack attackers.
- **A4 — Death & recovery loop (NEXT):** a Souls-style "rest point" at campfires / magic circles + a
  drop-and-recover-on-death resource (coin an ORIGINAL name — not "souls"; IP-check per DECISIONS).
- **Creature rigs — parallel track, STARTED (2026-07-10):** the 3 spawned species (Mosslamb,
  Ashjackal, Gloamstalker Lynx) now use a true `CreatureRig` (Skeleton3D + AnimationTree:
  walk/run/attack/hit/death), like the player. Next on this track: rig species as they're added +
  gait polish (4-beat gaits, foot-plant, a dedicated stagger clip).

Then the broader backlog:

1. **Descend:** make the shaft load Floor 2 (The Rootways) as a second, deeper environment.
   Per **D3**, Floor 2 is **ground-based** (aerial deferred to Floor 3).
   *(Ready: all Floor 2 / Tier 1–3 species + Rootways ecology in the bestiary + behaviour spec.)*
2. **Content:** a second prey species + more flora variety; balance the new Lynx encounter.
   *(Ready: Grotto Springhare / Blind Vole / Deep Quail prey stats + behaviour, Lynx tuning values,
   and flora effects/placement in `CREATURE_BEHAVIOUR.md`, `ITEMS.md`, `data/lore.json`.)*
3. **Cooking depth:** food spoilage; signature recipes with stronger combined buffs; butchery
   quality (D1: ×0.60 / ×1.00 / ×1.25).
   *(Ready: spoilage + Bittersalt preservation, Cave Saffron amplification, and 30 dishes in
   `docs/RECIPES.md` + `data/lore.json`.)*
4. **Combat polish:** player poise/stagger, a parry, hit VFX/juice; retrofit the Ashjackal tell (D6);
   packs commit 1–2 attackers (D5).
   *(Ready: per-archetype attack wind-up/recovery/tell timings in `CREATURE_BEHAVIOUR.md`.)*
5. **Audio depth:** a warm music sting at camp; distinct per-creature calls.
6. **More creature identity:** wire real `form` dicts (torso/leg/head proportions, ear/tail style,
   biped support — see `Creature.gd`'s new parametric rig, `Main.FORMS` referenced but not yet
   created) or bespoke `CreatureModels` entries for the next species up, e.g. Grotto Springhare
   (biped hopper — a good first test of the new `biped` rig path) or Rockback Boar.

## Done recently
- **UI: HUD re-skinned to the parchment field-journal vision (owner decision):** the HUD shipped
  a few runs ago (see the "real styled HUD" entry below) followed the reference-image's dark/
  monospace chrome; that surfaced a real conflict with `docs/ART_DIRECTION.md` §6's own written
  spec, which calls for a warm hand-inked field-journal look instead. Asked Damien rather than
  picking a side — he chose §6 as canon, so `src/systems/ui/HUD.gd` is now re-skinned to match:
  warm parchment/cream panel tint + a thin ink border on every side (dropped the old "coloured top
  accent stripe," itself the vector-flat-corporate look §6 warns against — every panel now shares
  one uniform ink-on-parchment frame), a hand-lettered/brush `SystemFont` for headers only
  (`Bradley Hand`/`Segoe Print`/`Noteworthy`/... fallback chain) paired with a clean serif for
  body/stat text, and small diamond-rotated colour swatches (`Control.rotation_degrees` +
  `pivot_offset` — a real Control-level transform, not Node2D) instead of flat square icons.
  Per §6.2 step 1 ("re-skin first, restructure never"): panel positions and every data binding are
  byte-for-byte unchanged from the previous pass — only colour/typography/frame changed. Colour
  stays reserved for meaningful data only, per §6.1: HP/STA/HUNGER bars keep `WARN`/`GLOW_TEAL`/
  `FLAME`, provisions chips keep `Palette.ingredient_color` swatches, and nothing else gets a
  special accent colour anymore. Also used this pass to sync `docs/ART_DIRECTION.md` §8.3's
  creature-status table to reality (was still calling Mosslamb/Ashjackal/Lynx "placeholder
  capsules" post-`CreatureRig`, and the 7 newly-populated species "not yet built") and flagged
  which §8.1-proposed Palette tokens are real vs. still proposals (D11 sync pass). Zero
  gameplay-logic touched; validated headless green. Commits `5b5220e` (HUD), `93a9e45` (art bible
  sync).
- **World: stilt shelter + hanging lantern + mushroom clusters (owner-directed, image-inspired
  S3 richness):** new `src/world/Structures.gd` (landmark architecture — explicitly NOT the M3
  player-buildable shelter/tent/den/magic-circle system; a hand-placed static prop, same tier as
  a tree or the rocky ridge). `Structures.stilt_shelter()` — 4 stilts + cross-braces, a deck you
  can stand on, a lean-to's back+side wall, a tilted-slab roof, and a beam-hung lantern (dark
  frame + `MaterialLib.flame()` core + a real `OmniLight3D` at `Palette.FLAME`) — placed at the
  eastern edge of the larger water pool, the one deliberate "warm ember near cold water" landmark
  per ART_DIRECTION §0's own thesis. Collision is deliberately just 2 shapes (the deck to stand
  on, the back wall so it's not walk-through) rather than one sealed blocking box, so the space
  under the platform stays walkable — matches how every other landmark here only approximates its
  own footprint. Also `Flora.mushroom_cluster()` — small ground-level glowing mushroom clumps (a
  different scale/register from the landmark-sized Glowcap Pillar-trees), 5 scattered near both
  pools cycling the cold-bioluminescence family (GLOW_TEAL/BLUE/VIOLET/GLOW_FUNGUS) for variety.
  All new positions hand-checked against both water pools' exact bounding boxes and existing
  landmarks to avoid literal overlaps. Honest caveat: exact prop orientation/spacing is
  unverifiable without a GPU in this sandbox — reasonable, not pixel-perfect. Zero gameplay-logic
  touched; validated headless green. Commits `1aa70e5`, `0b83f49`, `fc689e9`.
- **D16-S2: full Floor-1 roster populated (owner-directed):** `Main.gd` now spawns and registers
  all 10 species `data/lore.json` lists for Floor 1, not just the original 3. Added: **Grotto
  Springhare, Blind Vole, Deep Quail** (Tier 1 grazers, 6 each, spread across open ground — common
  prey, matching Mosslamb's density) and **Gloomferret, Rockback Boar, Spinefowl, Cinder Cockatril**
  (Tier 2 small hunters, 3 each — rarer, matching Ashjackal's density). All hand-placed (no RNG, so
  positions are eyeball-checked against existing landmarks/each other), all registered in
  `_build_ecosystem()` so hostility tracking sees them, all combat-tuned from `data/combat.json`
  (per-creature hp/damage/speed/poise) exactly like the original 3. Floor 1 goes from 14 to 44
  active creatures. None of the 7 have a bespoke `CreatureModels`/`CreatureRig` body yet, so they
  render via `Creature.gd`'s generic form-driven rig — confirmed safe by re-reading the whole
  function before wiring anything up: it has zero dependency on the `Main.FORMS` dict the roadmap
  used to mention (that was only ever a stale doc-comment, not real code) and is the same
  already-proven code that rendered Mosslamb/Ashjackal before they were rigged. Predator/prey read
  (colour, pointed vs. round ears, amber eye-glow) still applies via `is_predator`; bespoke
  silhouettes for these 7 are a clean future Graphics increment, not required for D16-S2. Capglow
  Snail and Palefish (also floor-1 in lore.json, not named in D16's own S2 list) are still
  unspawned — flagged, not blocking. Zero changes to `Creature.gd`/`Player.gd`/combat logic;
  validated headless green (all 6 self-test checks). Commit `4dec481`.
- **UI: real styled HUD (owner-directed — "push the game look to match the image"):** replaced
  the placeholder plain-`Label`/flat-`ColorRect` HUD with a real presentation layer, new
  `src/systems/ui/HUD.gd` (`class_name HUD extends CanvasLayer`, owns all HUD nodes + its own
  `_process()`, `Main.gd` just constructs + `bind()`s it). Rounded `StyleBoxFlat` panel chrome
  (coloured top accent edge, zero image assets), a `SystemFont` monospace look (named system font
  fallback list, zero font files committed), and colour-swatch "icons" — all built from Godot's
  vector/procedural UI primitives, no binary assets. Translates a concept-art reference's
  information design (icon-coded vitals bars, hotbar-style item chips, badge-style keybind legend,
  minimap-corner status panel) into Deepforage's real systems and Palette tokens: HP (`WARN`) / STA
  (`GLOW_TEAL`) / HUNGER (`FLAME`) bars, lock-on + buff-pill + status-text cluster, 4 honest resource
  chips (raw meat/meals/fruit/herbs — the real inventory, no fabricated items), a 3-column controls
  legend covering every real binding, and a depth/hostility/creature-count readout in the screen
  corner the reference reserves for a minimap (we have no level-layout data, so this is the honest
  equivalent, not a fake map). Deliberately does **not** attempt photoreal rendering (against house
  style) and does **not** fabricate cold/wet/tired meters or a quest log (those systems don't exist
  yet — M3 not built). Zero gameplay-logic touched; SelfTest unaffected. Godot 4.3 API, validated
  headless green. Commits `c12da01`, `4127d77`.
- **Creature skeletal-rig track — STARTED (owner-directed):** new `src/creatures/CreatureRig.gd` —
  a parametric **quadruped** Skeleton3D + `AnimationTree` (idle/walk/run/attack/hit/death), the
  creature counterpart to `PlayerRig`. The 3 spawned species (Mosslamb bulky, Ashjackal lean/tall,
  Gloamstalker Lynx long/low — via `_PARAMS`) now build a `CreatureRig` instead of a static body;
  `Creature.gd` drives it from the AI state machine (locomotion by speed; Attack on the telegraph,
  Hit on flinch/stagger, Death on death). Shares the creature material so telegraph/stagger `_glow`
  still tints it. Other 27 species keep the static/procedural body until rigged later. Greybox gaits;
  Godot 4.3 API, editor/CI authoritative. Commits `f596545`, `ccf1b9e`.
- **Combat / animation — A3: defence + reactions (Increment 2, owner-directed):** player **poise +
  stagger** (a break plays a Stagger clip with real loss of control) and a **parry on key R** —
  `Player.receive_attack(amount, attacker)` deflects a blow in the active window and **staggers the
  attacker** (teal parry burst + chime). Creatures gained a **hit-react** flinch and a **topple/sink
  death animation** (no more pop-out; corpse leaves the group). **D6** predator wind-up tightened to
  0.5s; **D5** caps same-species committed attackers at 2 (the rest circle). New PlayerRig Parry +
  Stagger states; `Creature.stagger()` + strike routed through `receive_attack`. Creatures still use
  static meshes, so their reactions are procedural whole-body animation (a true per-species skeletal
  rig is a later track). Provisional numbers; Godot 4.3 API, editor/CI authoritative. Commits
  `de5ec09`, `71eb680`, `9862719`.
- **Combat / animation — A2: attack game-feel (Increment 2, owner-directed):** attacks now feel
  like they connect. A **3-hit light combo chain** (`attack_light1/2/3` in `PlayerRig`) with
  **recovery-cancel windows + input buffering** (`_can_cancel_attack` / `_tick_attack` in
  `Player.gd`), a **hitstop** freeze-frame on connect (`PlayerRig.set_frozen` toggling
  `AnimationTree.active`), and **slash + impact VFX** from a new self-fading
  `src/systems/combat/CombatFX.gd`. Attacks are data-driven (`LIGHT_CHAIN` + `HEAVY`); dodging or
  taking a hit breaks the combo. Numbers provisional (playtest). Greybox; Godot 4.3 API,
  editor/CI authoritative. Commits `f53af06`, `0b70828`, `f8838a8`.
- **Combat / animation — A1: 2D locomotion + turn-in-place (Increment 2, owner-directed):**
  `PlayerRig`'s Move state upgraded from a 1D speed blend to a **`BlendSpace2D`** keyed on local
  velocity (strafe/backpedal, walk→run), plus a new **Turn** state for turn-in-place. Five new
  code clips (walk_back, strafe_left/right, turn_left/right). New
  `update_locomotion(local_dir, turn_amount)` API drives Move⇄Turn and never interrupts a
  roll/attack/hit one-shot; `Player.gd` now feeds local-space velocity + per-frame yaw rate.
  Greybox arcs (left/right sign + swing tuning to refine); Godot 4.3 API, editor/CI authoritative.
  Commits `6ee8524`, `b10dcdf`.
- **Combat / animation — skeletal player rig + AnimationTree (Increment 1, owner-directed):** the
  player is no longer a capsule+sphere — new `src/player/PlayerRig.gd` builds a procedural
  Skeleton3D humanoid with rigid `BoneAttachment3D` box limbs, code-authored clips
  (idle/walk/run/roll/light/heavy/hit) and an `AnimationTree` state machine (locomotion
  `BlendSpace1D` + one-shot roll/attack/hit; a dodge can cancel an attack). `Player.gd`'s existing
  combat states now drive real body animation, the sword rides the right-hand bone, and ground
  speed feeds the locomotion blend. Decisions **D12–D15**. Greybox (bone proportions/swing arcs
  will refine); authored against the Godot 4.3 API — no Godot in the build sandbox, so the
  editor/CI is the authoritative compile; degrades gracefully (movement is physics-driven).
  A duplicate `class_name Palette` (stale `src/systems/visual/Palette.gd`) was removed by a
  concurrent run this morning, resolving the collision.
- **Creature identity:** Mosslamb, Ashjackal, and Gloamstalker Lynx — the 3 currently-spawned
  species — get real bespoke low-poly silhouettes (`src/creatures/CreatureModels.gd`) instead of
  one shared generic rig: Mosslamb's stacked-boulder barrel body + blunt horn-stubs, Ashjackal's
  lean snout + shoulder ridges + small amber eye-glow, Gloamstalker Lynx's low stalking posture +
  angular shoulder blades + teal ruff-flecks. Per `docs/ART_DIRECTION.md` §8.3's art-requirements
  table. Added 3 new `Palette` tokens (`ASH_GREY`, `AMBER_EYESHINE`, `CHARCOAL_BLACK`) per §8.1's
  proposal. Landed alongside (not instead of) a separate same-morning `form`-driven parametric
  rig refactor to the generic body-builder (torso/leg/head proportions, ear/tail style, biped
  support) — the two coexist: bespoke models for these 3 species, the parametric rig as fallback
  for the other 27 documented-but-not-yet-spawned species. Validated headless, self-test green.
- **data-driven wiring:** the game now loads `data/lore.json` (via new `LoreData`) — species
  identity, tier, carrying capacity, aggression, awareness, diet, and flora names come from the
  Lore layer; combat numbers derive from a per-tier tuning table. Exports bundle `data/*.json`.
  Validated headless + the packaged build confirmed to ship and read the data.
- **decisions:** Damien approved the open design calls — recorded in `docs/DECISIONS.md` (butchery
  tiers, hybrid insects, flight deferred to Floor 3, pack fairness, Ashjackal tell, pinned Gorehorn/
  keystone numbers, Hollow Stag stays uncookable). Binding for future builds.
- **lore: originality rename** — Antler Warg -> **Rackjaw** and Stonehide Rhinox -> **Stonehide Gorehorn**, swept across all lore docs + `data/lore.json` + `FOOD_WEB.md`; removes external-IP name collisions (Warg = Tolkien/GoT, Rhinox = Transformers). Docs/data only, not in code yet — no gameplay impact.
- **M1 pt.6:** procedural audio — cave-ambience bed, campfire crackle, and combat/creature SFX
  (whoosh / thud / growl / hurt / chime), synthesized in code (no binary assets).
- **Lore layer — design one step ahead of production:** full **BESTIARY** (30 creatures +
  10 insects; art/silhouette notes for Graphics, danger cues for Mechanics); **CREATURE_BEHAVIOUR**
  (9 implementable behaviour archetypes + a 40-species table mapped onto the real
  `src/creatures/Creature.gd` state machine and the Ecosystem API, with attack tells tuned to the
  player's i-frame/dodge constants — the M1 pt.5 Lynx follows its ambush-predator archetype);
  **RECIPES** (30 original dishes + spoilage/detox/butchery rules + discovery model); **ITEMS**
  (all flora, meat cuts, craft/shelter items); and a validated machine-readable **`data/lore.json`**
  production can load directly. All original / legally clean; canon cross-checked against `FOOD_WEB.md`.
- **M1 pt.5:** added the **Gloamstalker Lynx** (Tier-3) — an ambush predator that stalks then
  pounces, guarding the descent. Creature AI gained ambush/pounce behaviour + per-species poise.
- **M1 pt.4:** combat depth — visible blade + swing, light (LMB) & committed heavy (RMB) attacks,
  enemy red wind-up telegraphs, and poise so heavy hits stagger. Lock-on moved to Q. Self-test
  covers poise-break stagger.
- **M1 pt.3:** enlarged Floor 1 to a big cavern; foraging (regrowing bushes/herbs) + recipe
  cooking (meals granting regen/stamina/defense/warmth buffs). Self-test covers forage→cook→eat.
- **M1 pt.2:** butchering → raw meat, buildable campfire, cook raw→cooked, eat to restore
  hunger, starvation drains HP. Verified by `tools/SelfTest.tscn` (collect/fire/cook/eat PASS).
- **M1 pt.1:** shaped Floor 1, skill-combat core (attack / dodge-iframes / lock-on), two AI
  creatures wired to the ecosystem, combat HUD. Validated headless.

## Known risks / notes
- **CI export** presets/platform names are a best-effort starting point; Assembly+QA must
  confirm them against Godot 4.3 on the first CI run (Linux preset may be `Linux` vs `Linux/X11`).
- **Headless noise:** `Parameter "m" is null` from the dummy renderer is expected and ignored
  by `validate.sh`; never treat it as a failure.
- **3D art ceiling:** AI can't hand-sculpt high-poly models — commit to stylized low-poly.
- **Lore now leads production.** Design/content for M2–M5 is written ahead of the code; when a
  system is implemented it should consume the matching doc + `data/lore.json` rather than
  re-inventing values, and Lore should keep extending the layer so code is never design-blocked.
- **Ecology decisions — RESOLVED (see `docs/DECISIONS.md`):** packs commit 1–2 attackers at a time
  (D5); Ashjackal gets a 0.4–0.5s attack tell (D6); Gorehorn charge caps at 30% player HP (D7);
  Hollow Stag keystone hostility floor = 0.75 (D7); insects are HYBRID — swarm-emitter for clouds,
  individual creatures for large bugs (D2); aerial flight deferred to Floor 3 so Floor 2 ships
  ground-based (D3). Remaining numbers accepted as provisional (tune in playtest).
- **Butchery-quality tiers — RESOLVED (D1):** approved — Botched/Clean/Precise → ×0.60 / ×1.00 /
  ×1.25 buff magnitude. Add a reference line to `FOOD_WEB.md`.
- **Real headless CI still needs the Workflows permission:** grant the GitHub app **Workflows** and
  move `ci/build.yml` → `.github/workflows/build.yml` so `tools/validate.sh` runs on every push.
  (This run's changes are docs + one unreferenced JSON — non-code — so the build is unaffected.)
- **Concurrency note:** multiple same-morning runs have been landing overlapping graphics/creature
  work in quick succession (form-driven rig refactor + bespoke creature models within the same
  few minutes). Both merged cleanly this time, but if you're about to touch `src/creatures/
  Creature.gd` or `src/game/Main.gd`, re-fetch immediately first — these are the hottest files.
- **D16 (2026-07-10, TOP PRIORITY):** complete Floor 1 in full (S1–S5) before resuming
  creature-rig/animation polish. S1, S2, and S3 now look substantially shipped; **S4
  (integration/perf with the fuller floor) is the concrete next gap**, S5 (CI delivery) is still
  blocked on the GitHub Workflows permission. See the sync note atop "Next up".
