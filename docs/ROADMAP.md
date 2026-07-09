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

The Lore team has now shipped the full design layer **ahead of production** (`docs/BESTIARY.md`,
`docs/CREATURE_BEHAVIOUR.md`, `docs/RECIPES.md`, `docs/ITEMS.md`, `data/lore.json`) — every item
below is backed by concrete spec + loadable data, so implementation isn't blocked on design.
(The Gloamstalker Lynx just added in M1 pt.5 is a good proof: its ambush/pounce behaviour matches
the ambush-predator archetype in `docs/CREATURE_BEHAVIOUR.md`.)

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

## Done recently
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
