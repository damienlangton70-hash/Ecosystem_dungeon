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
- [ ] **World:** hand-shaped Floor 1 (Fungal Shallows) as a real environment with a descent
      exit to Floor 2, water pool, and landmark caverns.
- [ ] **Combat:** Dark Souls-style basics — stamina-gated light/heavy attack, dodge-roll with
      i-frames, lock-on, one melee weapon, hit/hurtboxes, hitstun.
- [ ] **Creatures:** 3–5 Tier-1/2 animals with basic AI (wander, flee, aggro) that fight back.
- [ ] **Survival:** hunger with real consequences; gather 2–3 foods; **campfire** you can light.
- [ ] **Cooking:** cook raw meat/fruit at a campfire → edible item that restores hunger.
- [ ] **Feel:** cave ambience audio bed; readable HUD.

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

## Next up (for the very next run) → START OF M1
1. **World Building:** replace the three placeholder terraces with a proper Floor 1 layout
   (entrance hall → fungal grove → water pool → descent shaft), still low-poly.
2. **Mechanics:** stand up the combat core (stamina, light attack, dodge-roll i-frames,
   lock-on) on the existing `Player`.
3. **QA:** extend `tools/validate.sh` with a headless combat smoke-test.

## Known risks / notes
- **CI export** presets/platform names are a best-effort starting point; Assembly+QA must
  confirm them against Godot 4.3 on the first CI run (Linux preset may be `Linux` vs `Linux/X11`).
- **Headless noise:** `Parameter "m" is null` from the dummy renderer is expected and ignored
  by `validate.sh`; never treat it as a failure.
- **3D art ceiling:** AI can't hand-sculpt high-poly models — commit to stylized low-poly.
