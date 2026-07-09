# Deepforage — Roadmap & Living Plan

The Studio Director reads this first every morning. Keep it current: check off what
shipped, and always leave a concrete **Next up** list for the following run.

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
- [~] **Feel:** readable combat HUD (HP/STA/FOOD bars, depth, hostility, lock-on) done; cave
      ambience audio still to come.

### M2 — The Ecosystem Reacts
- [ ] Populations per species; predators hunt prey; day/rest cycle ticks the sim.
- [ ] Over-hunting consequence: deplete a species → global hostility rises → animals notice
      you sooner and hit harder (wire `Ecosystem.aggression/awareness_multiplier`).
- [ ] On-screen/diegetic feedback that the dungeon is "stirred up".

### M3 — Survival & Shelter Depth
- [ ] Thirst + body temperature; cold deeper down.
- [ ] Shelter building: tent, den, and **magic circle** cook-point; rest to recover.
- [ ] Cooked-food buffs; spoilage; a simple crafting/inventory pass.

### M4 — Descend: Floors 2–5
- [ ] Floors 2–5 as distinct full environments, each deeper, darker, deadlier.
- [ ] Full 30-monster / 5-tier food web populated across floors (see `FOOD_WEB.md`).
- [ ] 3 trees, 10 fruit bushes, 10 herb/spice types, 10 hostile insects placed per biome.
- [ ] Tier-appropriate apex encounters gating the descent.

### M5 — Content, Polish & Ship
- [ ] Recipe breadth; bestiary/journal UI; save/load.
- [ ] Audio & music pass; options menu; controller support.
- [ ] Reliable Windows/Linux/macOS installers via CI releases.

---

## Next up (for the very next run)
1. **Combat depth:** heavy attack + a first real weapon; enemy attack tells/telegraphs; poise.
2. **Content:** more of the food web on Floor 1 (a Tier-2/3 predator) + more flora variety.
3. **Cooking depth:** food spoilage; a few signature recipes with stronger combined buffs.
4. **Audio:** a low cave-ambience bed and basic combat / creature / fire SFX.
5. **Descend:** make the shaft load Floor 2 (The Rootways) as a second environment.

## Done recently
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
