# The Delver's Cook-Journal — Items & Flora

*The second half of the journal — what things actually ARE, before I decide what to do
with them. Every flora entry here is something I picked myself; every cut of meat is
something I earned. Descriptions are short on purpose — I write these by firelight, not
by lamplight in a library.*

> **Design status:** short journal-voice flavor text + mechanical tags for implementation.
> All effects echo `docs/FOOD_WEB.md` exactly. Numbers reference `RECIPES.md` Part 1 for the
> systemic rules (spoilage, toxicity, cut quality) these items plug into.

---

## Part 1 — Flora

### Trees (3)

| Item | Flavor line | Mechanical effect | Found |
|------|-------------|--------------------|-------|
| **Glowcap Pillar-tree** (cap) | *"A whole tree that glows like it swallowed a lantern. The caps look like dinner and, cooked, they are."* | Passive light source while standing/growing nearby; caps harvestable — **edible when cooked** (raw caps: minor Hunger only, no buff). Cooked cap can fill a fruit-adjacent flavor slot in flora-only dishes. | Floor 1 (Fungal Shallows), scattered through Floor 2 |
| **Ironbark Deeproot** (timber) | *"Heavier than it looks, and it should be — this is what the Gorehorn eat instead of turning around."* | Not eaten. Harvest **timber** for shelter builds and **weapon hafts** (ties into butchery-quality cut chain, see RECIPES.md 1.3); young **shoots** are Stonehide Gorehorn forage, not player food. | Floor 2 (The Rootways) dominant, present Floor 1 |
| **Weeping Palewillow** (withes/bark) | *"Grows only where there's still water to weep over. The withes bend instead of breaking — perfect for a tent pole that has to survive me."* | **Withes** are the craft input for the Tent (see Part 3). **Bark** is brewed into a restorative tea (see Part 3, Palewillow-Bark Restorative Tea). Not itself a food item. | Floor 1–2, waterside/marsh biomes; more common Floor 3 (Sunless Marsh) |

### Fruit / berries (10)

| Item | Flavor line | Mechanical effect | Found |
|------|-------------|--------------------|-------|
| **Emberberry** | *"Warm just to hold. Eat one cold morning and you'll swear the deep got a few degrees kinder."* | Warming — raises Body Temperature / warmth buff. Raw: weak tick. Cooked in a dish: full warmth magnitude. | Floor 1–2, near warm vents/fungal light |
| **Frostplum** | *"Bites back with cold the second it touches your tongue — which is exactly why it's good for the fire-scorched floors below."* | Cooling / heat-resistance. Raw: weak tick. Cooked: full heat-resist buff. | Floor 2–3, damp/cool hollows |
| **Gloomgrape** | *"Sour enough to wake you up. My legs feel it before my tongue does."* | Stamina restore. Raw: small immediate Stamina tick. Cooked: full Stamina-regen buff duration. | Floor 1–2, shaded root-tangles |
| **Cavern Currant** | *"Not exciting. Never has been. Also never once let me go hungry."* | Common filler calories — flat Hunger restore, no buff of its own; the "always available" fruit slot for Rough Stew fallback (see RECIPES.md 1.6). | Floor 1 onward, everywhere, dense clusters |
| **Sourlantern** | *"Citrus-bright and mean about it. Keep a few dried in the pack — you'll want them the day something toxic gets past your guard."* | Cleanses toxins; player-status tool for shortening an active Poisoned debuff (see RECIPES.md 1.2). Also prevents nutritional deficiency over long stretches without variety. | Floor 1–2, lit fungal patches |
| **Mossmelon** | *"Cut it open and it's mostly water — good water, the kind that doesn't taste like the cave around it."* | Water-rich; hydration restore (Thirst stat, M3). | Floor 1–2, near still water |
| **Bleedberry** | *"Named for the color, not the effect — though the first time I ate one I did check my knife hand out of habit."* | Rich; minor healing. Small flat heal on eating raw or cooked; larger flat heal when it's the fruit-slot in a completed dish. | Floor 2–3, marsh edges |
| **Duskfig** | *"Dense enough to feel like a real meal on its own. This is the one I ration for the long stretches between kills."* | Calorie-dense — big Hunger restore, no buff of its own. The "I need to survive, not optimize" fruit. | Floor 2, Rootways undergrowth |
| **Goldcap Gooseberry** | *"Gold-skinned, rare, and everyone in this line of work who's found one has told someone about it. I'm telling you."* | Rare; strong all-round buff (small heal + Hunger + minor resistance boost) when used as the fruit-slot in a completed dish. | Rare, Floor 2–4, isolated patches |
| **Thornapple** | *"Every part of this plant is trying to tell you not to eat it. It's right, until you add Sulfur Chive — then it's one of the best things down here."* | **Toxic raw** — do not eat uncooked (see RECIPES.md 1.2). Cooked *with Sulfur Chive*: potent all-round buff. Cooked *without* Sulfur Chive: still edible but capped low buff, residual Queasy chance. | Floor 2–3, dry rocky ledges |

### Herbs / spices (10)

| Item | Flavor line | Mechanical effect | Found |
|------|-------------|--------------------|-------|
| **Deeproot Ginger** | *"My most-used pouch. Warms you, and — this took me too long to learn — makes a rough cut of meat sit right in your stomach anyway."* | Warmth buff contributor; halves Bellyache chance from Botched cut quality / Turning freshness when present in the dish (see RECIPES.md 1.7). | Floor 1–2, root systems near Ironbark |
| **Palethyme** | *"Chew a leaf raw before a long run and you'll feel the difference by the second hill."* | Stamina-regen buff contributor. | Floor 1–2, open mossy ground |
| **Cave Saffron** | *"Three threads of this cost me a fight I didn't want to have. Worth it, once, for the right meal."* | Rare; amplifies any buff already present in a dish by magnitude and duration (see RECIPES.md 1.7). Does not grant its own effect — pure amplifier. | Rare, Floor 2–4, deep alcoves |
| **Emberpepper** | *"One pinch and the whole pot changes temperament. Fire-resistant food should taste like it's daring you a little."* | Fire-resistance / heat buff contributor. | Floor 1–3, near warm vents |
| **Gloomsage** | *"Rub it between your palms before a hunt and even the hyenas seem to lose interest in you."* | Calming; lowers player detection scent (reduces awareness/detection radius, ties into FOOD_WEB awareness mechanics) when eaten in a dish. | Floor 1–2, shaded undergrowth |
| **Marrow Mint** | *"Cold on the tongue, and it does something to fish I can't explain except to say: try it once."* | Cold-resistance buff contributor; specifically "freshens" fish dishes (canon pairing with Palefish) — reduces spoilage-adjacent quality loss on fish specifically. | Floor 1–3, waterside |
| **Stoneleaf Rosemary** | *"Tastes like standing your ground. My knees believe it even when my head doesn't."* | Poise / defense buff contributor. | Floor 2–3, rocky slopes |
| **Bittersalt Crystal** | *"Not a flavor, a favor. This is the one I pack when I know I won't be back at a fire for days."* | Preservative — multiplies freshness timer on the dish/raw meat it's added to (see RECIPES.md 1.5). Contributes no buff of its own. | Floor 1–2, mineral veins/crystal seams |
| **Sulfur Chive** | *"Smells like a struck match. Also the only thing standing between me and a very bad night after a Cockatril kill."* | Neutralizes toxins — **required** ingredient for safely/fully cooking Cinder Cockatril, Dire Basilisk, and Thornapple (see RECIPES.md 1.2). | Floor 1–2, near sulfurous seeps |
| **Dreamdill** | *"Drink it in and the ceiling stops feeling so close overhead. First full night's sleep I had down here had this in it."* | Improves rest quality at camp (stronger, longer recovery / buff-refresh on waking). | Floor 2, quiet Rootways clearings |

---

## Part 2 — Meat & Cuts

Every hunted creature yields a raw meat item tagged with **Cut Quality** (Botched / Clean /
Precise — see RECIPES.md 1.3) at the kill, and a **hazard tag** where relevant. Grouped by
canon cooking-note category.

| Category | Creature(s) | Cut item & butchery note | Raw vs. cooked / hazard tags |
|---|---|---|---|
| **Tender roast** | Mosslamb | *Mosslamb Cutlet* — "the reliable roast"; forgiving to butcher, low Botched-chance even with a rough weapon. | Raw: edible, weak, no buff. Cooked: full recipe access (#1). |
| **Lean/fast game** | Grotto Springhare, Deep Quail | *Springhare Loin* / *Quail Breast* — lean meat; fast animals reward Precise cuts more than most (harder to land a clean kill on something that fast, bigger payoff when you do). Deep Quail also drops **Quail Eggs** as a separate forage-adjacent item (found at nests, not from the kill). | Raw: edible, weak. Cooked: recipes #2 (Springhare), #6 (Quail Egg). |
| **Rich-if-cleaned** | Capglow Snail | *Capglow Snail Meat* — slow, easy kill, but tagged **needs-de-slime**: unusable in a completed recipe without Sulfur Chive in the pot (not a toxin per se, a prep-quality gate). | Raw: edible but unpleasant (Bellyache risk higher than usual). Cooked without Sulfur Chive: Rough Stew only. Cooked with: recipe #3. |
| **Stock meat** | Blind Vole | *Blind Vole Meat* — small yield, low individual value; shines as a stock/base ingredient rather than a centerpiece. | Raw: edible, weak. Cooked: recipes #4, #16. |
| **Delicate fish** | Palefish | *Palefish Fillet* — delicate, spoils a touch faster than land meat by default (before Marrow Mint's freshening or Bittersalt); pairs with Marrow Mint. | Raw: edible, weak, slightly higher Bellyache risk if not fresh. Cooked: recipe #5. |
| **Gamey pack-predator** | Gloomferret, Ashjackal, Marrow Hyena, Rackjaw | *Gloomferret Haunch*, *Ashjackal Cut*, *Marrow Hyena Shank*, *Rackjaw Loin* — "better braised" as a category-wide note; these punish being eaten simply cooked (edible, but noticeably worse than the braise/stew treatment) more than gentler meats do. | Raw: edible, weak, elevated Bellyache risk (gamey = less forgiving raw). Cooked: recipes #7, #8, #15, #22. |
| **Fatty & excellent** | Rockback Boar | *Rockback Boar Belly* — dangerous to harvest (charge attack means botched cuts are more common if you fight it carelessly), but the reward is the game's benchmark "excellent" meat. | Raw: edible, weak. Cooked: recipe #9; also the default meat slot for celebration dish #30. |
| **Fine poultry (de-spined)** | Spinefowl | *Spinefowl Breast* — hazard tag **spines-must-be-removed** at butchery; skipping this step caps the cut at Botched quality regardless of kill skill (the spines, not the kill, are the problem). | Raw: edible if de-spined, weak. Cooked: recipe #10. |
| **Oily & warming** | Grave Otter, Deepwater Leviathan-eel | *Grave Otter Cut*, *Leviathan-eel Steak* — oily meat that specifically shines in warming stews/grills; the eel especially needs sustained high heat (Campfire, longer cook time) to render properly. | Raw: edible, weak, mildly higher Bellyache risk (oily). Cooked: recipes #11, #23. |
| **Toxic-until-treated** | Cinder Cockatril, Dire Basilisk | *Cockatril Cut*, *Basilisk Steak* — hazard tag **toxic-raw**; hard Sulfur Chive requirement to cook safely (see RECIPES.md 1.2). | Raw: **Poisoned** debuff, no Hunger benefit worth it. Cooked without Sulfur Chive: capped low, Queasy risk. Cooked with: recipes #12, #17. |
| **Prime tail** | Bog Saurian | *Saurian Tail Cut* — the tail specifically is the prime cut per canon; rest of the beast still butchers into lesser filler meat, but the journal treats the tail as its own named item. | Raw: edible, weak. Cooked: recipe #13. |
| **Lean stealth-cuts (mid-predator)** | Gloamstalker Lynx, Hookbeak Ridgehawk | *Lynx Ambush-Loin*, *Ridgehawk Breast* — both lean, hard-to-reach kills (stealthy ambusher; aerial, hard to reach per canon); the difficulty is in the hunt, not the butchery — Cut Quality here mostly reflects how clean the takedown was. | Raw: edible, weak. Cooked: recipes #20 (Lynx), #21 (Ridgehawk). |
| **Huge yield / snake fillet** | Tunnel Constrictor | *Constrictor Fillet* — one kill yields multiple cook-sessions' worth; ambush predator, so Precise cuts are common if you spot the ambush coming and respond cleanly. | Raw: edible, weak. Cooked: recipe #14; also feeds the Preserved Rations item well (see Part 3) given the yield size. |
| **Big-game cuts** | Chasm Drake, Gravemaw Ursine, Pale Sabertooth, Stonehide Gorehorn | *Drake Sear-Cut* (hazard tag **requires-searing**, Campfire-only), *Ursine Feast-Cut*, *Sabertooth Prized Loin* (also drops a separate **Prized Hide** crafting item, not eaten), *Gorehorn Charge-Cut* (extremely dangerous to harvest — narrative weight per FOOD_WEB "adults untouchable"). | Raw: edible, weak, high Bellyache risk (big meat, easy to botch). Cooked: recipes #24, #25, #26, #27. |
| **Apex meat** | Rare, deep-floor apex species (Gloom Tyrant, Elder Marrowmother, Cavern Roc, Sunless Wyrm, Titan Molebeast) | *Apex Marrow-Cut* — generic rare-tier item name; specific apex source noted in the item's origin tag but shares one mechanical slot to keep the celebration-tier recipe (#29) simple to implement. | Raw: not advisable — extreme Bellyache risk, essentially never worth it narratively or mechanically. Cooked: recipe #29. |
| **Marrow / bone** | Byproduct of most large kills (Marrow Hyena, Ursine, Gorehorn, etc.) | *Bone & Marrow* — a butchery byproduct, not a primary cut; used as a filler/base in broth-style dishes (#22) and implied stock-building rather than a standalone eaten item. | Not eaten raw or alone. Contributes "filler Hunger" weighting to broth dishes it's added to. |

**Do not hunt / no cut exists:** **The Hollow Stag.** Keystone species — no meat item, no
recipe, no butchery entry. This is a deliberate absence, matching FOOD_WEB.md's standing
rule that killing it is catastrophic to the ecosystem. If it ever needs an item entry (e.g.
for a scripted narrative-consequence beat), that is a design call, not a data-completeness
gap — flagged in the summary to Damien.

---

## Part 3 — Craft, Tool & Shelter Items

| Item | Flavor line | Function |
|------|-------------|----------|
| **Tent** | *"Palewillow withes bent into something that keeps the ceiling-feeling out for a few hours. Packs down smaller than it has any right to."* | Quick, portable shelter (Design Bible 5.4: "quick, portable; light rest, minor warmth"). Crafted from **Weeping Palewillow withes**. Grants light rest + minor warmth; no attention cost, no cooking. |
| **Timber & weapon hafts** | *"Ironbark doesn't ask to be shaped so much as tolerate it. Every haft I've carried down here started as a plank of this."* | Crafted from **Ironbark Deeproot** timber. Feeds shelter construction (Den-tier and up) and weapon hafts — the haft quality is part of what determines Cut Quality outcomes at the kill (see RECIPES.md 1.3), tying foraging directly back into the cooking-quality chain. |
| **Campfire** | *"Lights the dark, warms the bones, and tells every hungry thing on the floor exactly where I am. Worth it, usually."* | Primary cook-point. Cook + warmth + light. Raises local attention/hostility exposure via smoke and noise (see RECIPES.md 1.4). Requires Ironbark timber as fuel to stay lit. |
| **Magic Circle** | *"No flame, no smoke, and the cold doesn't care that I'm cooking. Arcane and a little unsettling the first time you use one."* | Secondary cook-point, unlocked later. Identical recipe access to the Campfire (see RECIPES.md 1.4) but no warmth/light and negligible attention cost. No fuel required once placed. |
| **Weeping Palewillow-Bark Restorative Tea** | *"Bitter on its own — the bark alone tastes like the inside of the tree wanted nothing to do with me. Worth brewing anyway."* | Brewed from **Palewillow bark**. Mild restorative (small heal / stamina-adjacent recovery tick) — a non-meal camp drink, distinct from a full cooked dish; see RECIPES.md #19 for the upgraded Deeproot Ginger Trail Tea variant. |
| **Waterskin** | *"Fill it at anything that isn't standing still and green. The deep has a way of making 'water' a generous word."* | Hydration-storage item (Thirst stat, M3). Refills at water sources; Mossmelon supplements but doesn't replace it for sustained hydration. |
| **Preserved Rations** | *"Bittersalt-packed and boring on purpose. This is what I eat three days from the nearest fire, not what I dream about."* | Cooked dish (or raw meat) treated with **Bittersalt Crystal**, tripling its freshness timer (see RECIPES.md 1.5). No buff bonus — pure logistics item for long stretches between camps, especially valuable off huge-yield kills (Tunnel Constrictor, big-game). |

---

## Cross-reference note for implementation

- Every mechanical effect above is a **restatement**, not a reinterpretation, of the
  corresponding line in `docs/FOOD_WEB.md`. If FOOD_WEB.md is ever revised, this table's
  "Mechanical effect" / cooking-note columns should be the first thing re-synced.
- Item **names** here (e.g. "Mosslamb Cutlet," "Basilisk Steak") are original journal/UI
  flavor labels for the *cut of meat* — the underlying creature name driving diet/ecosystem
  logic in `src/systems/ecosystem/Species.gd` remains the canon creature name (Mosslamb,
  Dire Basilisk, etc.) exactly as written in FOOD_WEB.md. Don't rename the species; only the
  butchered item wraps it in flavor text.
