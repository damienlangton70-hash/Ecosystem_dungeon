# Deepforage — The Food Web & Ecology

The living heart of Deepforage. This is the Lore agent's canonical first draft of the
**30-monster / 5-tier food chain**, the **10 hostile insects**, and the **flora** (3 trees,
10 fruit bushes, 10 herb/spice types), plus the **over-hunting rules** the Ecosystem
simulation enforces. All creatures are **animalistic** so the web behaves like a real
ecology. Numbers are starting values for tuning.

> Data shape: each species maps to `src/systems/ecosystem/Species.gd`
> (`tier`, `diet`, `population`, `carrying_capacity`, `base_aggression`, `awareness`, `edible`).

---

## Trophic tiers at a glance

```
Tier 5  APEX            Gloom Tyrant · Elder Marrowmother · Cavern Roc · Sunless Wyrm · Titan Molebeast · Hollow Stag(keystone)
Tier 4  LARGE PREDATORS Chasm Drake · Gravemaw Ursine · Pale Sabertooth · Dire Basilisk · Leviathan-eel · Stonehide Rhinox
Tier 3  MID PREDATORS   Gloamstalker Lynx · Hookbeak Ridgehawk · Marrow Hyena · Bog Saurian · Tunnel Constrictor · Antler Warg
Tier 2  SMALL HUNTERS   Gloomferret · Ashjackal · Rockback Boar · Spinefowl · Grave Otter · Cinder Cockatril
Tier 1  GRAZERS         Mosslamb · Grotto Springhare · Capglow Snail · Blind Vole · Palefish · Deep Quail
                        (Tier 1 eats FLORA & detritus — the base of the web)
```

---

## Tier 1 — Grazers & Foragers (prey base)

| # | Species | Eats | Aggr. | Aware. | Cooking note |
|---|---------|------|:-----:|:------:|--------------|
| 1 | **Mosslamb** | cave moss, lichen | 0.05 | 0.3 | Tender; the reliable roast. |
| 2 | **Grotto Springhare** | fungus, fallen fruit | 0.05 | 0.5 | Lean; fast, hard to catch. |
| 3 | **Capglow Snail** | moss, decay (detritivore) | 0.02 | 0.2 | Slow; rich if de-slimed (needs Sulfur Chive). |
| 4 | **Blind Vole** | roots, tubers, herbs | 0.05 | 0.4 | Small; good stock meat. |
| 5 | **Palefish** | algae, larvae *(aquatic)* | 0.02 | 0.3 | Delicate; pairs with Marrow Mint. |
| 6 | **Deep Quail** | seeds, insects | 0.05 | 0.5 | Eggs are a foraging prize. |

## Tier 2 — Small Hunters & Omnivores

| # | Species | Eats | Aggr. | Aware. | Cooking note |
|---|---------|------|:-----:|:------:|--------------|
| 7 | **Gloomferret** | Capglow Snail, Blind Vole, Deep Quail | 0.35 | 0.6 | Gamey; better braised. |
| 8 | **Ashjackal** *(pack)* | Springhare, Deep Quail | 0.45 | 0.6 | Tough; pack aggro scales with hostility. |
| 9 | **Rockback Boar** *(omnivore)* | roots, Capglow Snail, carrion | 0.4 | 0.4 | Fatty, excellent; dangerous charge. |
| 10 | **Spinefowl** | insects, Palefish, eggs | 0.3 | 0.5 | Spines must be removed; fine poultry. |
| 11 | **Grave Otter** *(aquatic)* | Palefish, Capglow Snail | 0.25 | 0.5 | Oily; good for warming stews. |
| 12 | **Cinder Cockatril** | Deep Quail, Blind Vole | 0.4 | 0.5 | Mildly toxic raw; safe cooked (Sulfur Chive). |

## Tier 3 — Mid Predators

| # | Species | Eats | Aggr. | Aware. | Cooking note |
|---|---------|------|:-----:|:------:|--------------|
| 13 | **Gloamstalker Lynx** | Gloomferret, Ashjackal pup, Deep Quail | 0.6 | 0.7 | Stealthy ambusher; lean cuts. |
| 14 | **Hookbeak Ridgehawk** | Springhare, Spinefowl | 0.55 | 0.8 | Aerial; hard to reach. |
| 15 | **Marrow Hyena** *(pack)* | Rockback Boar, Ashjackal, carrion | 0.65 | 0.7 | Bone-cracker; drawn to wasted carcasses. |
| 16 | **Bog Saurian** *(semi-aquatic)* | Grave Otter, Palefish, Rockback Boar | 0.6 | 0.5 | Reptile; tail is prime meat. |
| 17 | **Tunnel Constrictor** | Blind Vole, Gloomferret, Springhare | 0.5 | 0.4 | Ambush from walls; huge yield. |
| 18 | **Antler Warg** | Springhare, Deep Quail, Lynx cub | 0.6 | 0.7 | Fast pack hunter of the Rootways. |

## Tier 4 — Large Predators

| # | Species | Eats | Aggr. | Aware. | Cooking note |
|---|---------|------|:-----:|:------:|--------------|
| 19 | **Chasm Drake** | Ridgehawk, Lynx, Marrow Hyena | 0.75 | 0.7 | Wingless wyvern; searing required. |
| 20 | **Gravemaw Ursine** | Marrow Hyena, Boar, Bog Saurian | 0.7 | 0.6 | Cave bear; a feast, a nightmare to fight. |
| 21 | **Pale Sabertooth** | Antler Warg, Ursine cub, Drake young | 0.8 | 0.7 | Glass-cannon predator; prized hide. |
| 22 | **Dire Basilisk** | Bog Saurian, Antler Warg, Constrictor | 0.7 | 0.5 | Toxin glands; must be handled with Sulfur Chive. |
| 23 | **Deepwater Leviathan-eel** | Bog Saurian, Grave Otter, aquatic all | 0.65 | 0.5 | Marsh terror; enormous, oily meat. |
| 24 | **Stonehide Rhinox** *(mega-herbivore)* | Ironbark shoots, heavy flora | 0.5 | 0.3 | Not a predator, but lethal charge; adults untouchable. |

## Tier 5 — Apex

| # | Species | Eats | Role |
|---|---------|------|------|
| 25 | **The Gloom Tyrant** | Chasm Drake, Gravemaw Ursine, Pale Sabertooth | Apex predator of the deep. |
| 26 | **Elder Marrowmother** | Antler Warg, Rhinox calf, rival hyenas | Matriarch; commands Marrow Hyena packs. |
| 27 | **Cavern Roc** | Chasm Drake, Sabertooth, Antler Warg | Giant raptor of the vaults. |
| 28 | **The Sunless Wyrm** | *everything* | Floor 5 apex; serpent-dragon; the Maw's dread. |
| 29 | **Titan Molebeast** | Stonehide Rhinox, Gravemaw Ursine | Burrower; reshapes terrain. |
| 30 | **The Hollow Stag** *(keystone)* | high flora only | **Not a predator.** Its presence stabilises the web; killing it is catastrophic (see rules). |

---

## The 10 hostile insects

Insects are pervasive hazards, not part of the trophic tiers above (though Tier 1–2 animals eat them).

| # | Insect | Threat |
|---|--------|--------|
| 1 | **Razorwing Wasp** | Flying swarm; bleed. |
| 2 | **Glowmite Swarm** | Bioluminescent biters; blind/dazzle. |
| 3 | **Bloodtick Crawler** | Latches on, drains over time. |
| 4 | **Cinder Beetle** | Explodes on death — area burn. |
| 5 | **Chitin Scuttler** | Armored, tanky; slow. |
| 6 | **Venomfang Centipede** | Poison; fast. |
| 7 | **Gravel Mantis** | Camouflaged ambush; high burst. |
| 8 | **Deathcap Gnat Cloud** | Spore cloud; poison-over-time. |
| 9 | **Spinneret Lurker** | Spider; webs immobilise. |
| 10 | **Corpsefly Cloud** | Swarms carrion; spreads rot, raises attention. |

---

## Flora

### 3 trees
| Tree | Use |
|------|-----|
| **Glowcap Pillar-tree** | Giant luminescent fungal tree; light source; caps edible when cooked. |
| **Ironbark Deeproot** | Hardwood — timber for shelter & weapon hafts; shoots feed the Rhinox. |
| **Weeping Palewillow** | Waterside; flexible withes for **tents**; bark brews a restorative tea. |

### 10 fruit / berry bushes
| Fruit | Effect (cooked or raw) |
|-------|------------------------|
| **Emberberry** | Warming (body temperature). |
| **Frostplum** | Cooling / heat resistance. |
| **Gloomgrape** | Stamina restore. |
| **Cavern Currant** | Common filler calories. |
| **Sourlantern** | Citrus; cleanses toxins, prevents deficiency. |
| **Mossmelon** | Water-rich; hydration. |
| **Bleedberry** | Rich; minor healing. |
| **Duskfig** | Calorie-dense; big hunger restore. |
| **Goldcap Gooseberry** | Rare; strong all-round buff. |
| **Thornapple** | **Toxic raw**; potent buff when cooked with Sulfur Chive. |

### 10 herb / spice types
| Herb/Spice | Culinary role |
|------------|---------------|
| **Deeproot Ginger** | Warmth; settles bad meat. |
| **Palethyme** | Stamina-regen buff. |
| **Cave Saffron** | Rare; amplifies any buff. |
| **Emberpepper** | Fire resistance / heat. |
| **Gloomsage** | Calming; lowers your detection scent. |
| **Marrow Mint** | Cold resistance; freshens fish. |
| **Stoneleaf Rosemary** | Poise / defense buff. |
| **Bittersalt Crystal** | Preservative; slows spoilage. |
| **Sulfur Chive** | Neutralises toxins (Cockatril, Basilisk, Thornapple). |
| **Dreamdill** | Improves rest quality at camp. |

---

## Over-hunting & ecosystem rules

Enforced by `src/systems/ecosystem/Ecosystem.gd` (first pass in place; Mechanics expands).

**Populations.** Each species has a per-floor `carrying_capacity` (Tier 1 high, e.g. 80–120;
Tier 5 tiny, e.g. 1–3). `population` starts at capacity and changes via hunting, predation,
starvation, and slow regrowth.

**Pressure → hostility.** When a species drops **below one-third** of its capacity it adds
*pressure*. `global_hostility` (0..1) is the average pressure across species. As it rises:
- **Awareness** scales by `1 + hostility * 1.5` — animals detect you from further.
- **Aggression** scales by `1 + hostility * 2.0` — more attacks, fewer flees; packs form.
- The floor visibly "stirs up": more wandering, ambushes, scavengers on your trail.

**Cascades.** Wipe out a prey species and its predators starve — their population falls too,
then *their* predators, rippling up the tiers. Kill too many predators and prey boom, then
crash their own food (flora), starving everything. The system rewards **balance**.

**The keystone.** Killing **The Hollow Stag** triggers an immediate large hostility spike and
a long, hard recovery — the deep does not forgive it. Strongly discouraged in-fiction.

**Waste & attention.** Leaving unbutchered carcasses attracts **Corpsefly Clouds** and
**Marrow Hyenas** and raises local attention. Clean, purposeful hunting is safest.

**Recovery.** During rest/time-passage, populations regrow toward capacity and hostility
decays — the world can heal if you ease off.

**Design goal:** make *sustainable hunting* and *avoiding unnecessary fights* the smart play,
communicated through the world's mood rather than a scolding UI.
