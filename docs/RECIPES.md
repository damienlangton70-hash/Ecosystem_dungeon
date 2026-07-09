# The Delver's Cook-Journal — Recipes

*Stained pages, grease-thumbed, smelling faintly of woodsmoke and something with too many legs.
Every dish below I've either cooked myself or watched go badly wrong. Numbers in brackets are
my best guess at "how much" and "how long" — the camp cook after me should feel free to season
to taste.*

> **Design status:** starting values for tuning. All numbers are placeholders labeled `[tune]`.
> This document is the implementation spec for the M1→M2 cooking-depth pass (recipes, buffs,
> spoilage) described in the roadmap. Matches `docs/FOOD_WEB.md` and `docs/DESIGN_BIBLE.md`
> exactly — ingredient names, creature names, and effects are canon and must not drift.

---

## Part 1 — Cooking Rules

These are the systemic rules a recipe *runs on*. Individual dishes in Part 2 are just data
that plugs into this frame.

### 1.1 Raw vs. Cooked

- **Raw meat is always inferior.** Eating raw meat restores some Hunger but at a steep
  discount `[tune: 40% of cooked value]`, grants **no buffs**, and carries a flat risk of a
  **Bellyache** debuff (see 1.6) `[tune: 25% chance]` — even from non-toxic species. This is
  the "why bother, just cook it" lever, not a punishment mechanic.
- **Raw fruit/herbs are mostly fine to snack on** (they're forage food, not meat) — they
  restore a little Hunger and can even apply a *weak* version of their effect raw
  (e.g., a raw Gloomgrape gives a token Stamina tick). Cooking them into a proper dish is what
  unlocks their **full magnitude and duration.**
- **Cooking always requires a cook-point** (Campfire or Magic Circle — see 1.3). Standing
  over a fire with a skewer *is* the minigame/interaction; there's no cooking without a fire
  lit or circle active.

### 1.2 Toxicity & Sulfur Chive Detox

Three ingredients are flagged `toxic_raw = true` per canon:

| Ingredient | Toxicity source |
|---|---|
| **Cinder Cockatril** meat | "Mildly toxic raw; safe cooked (Sulfur Chive)." |
| **Dire Basilisk** meat | "Toxin glands; must be handled with Sulfur Chive." |
| **Thornapple** (fruit) | "Toxic raw; potent buff when cooked with Sulfur Chive." |

Rules:
- Eating any of these **raw** applies **Poisoned** (damage-over-time + nausea debuff,
  `[tune: 3 HP/sec for 8s]`), full stop — no partial Hunger restore, this is a hard "don't."
- Cooking them **without Sulfur Chive present in the recipe** still leaves them
  **Undetoxified**: heat kills the worst of it, but the dish is capped at a **low buff ceiling**
  and has a `[tune: 15%]` residual chance of a *mild* Queasy debuff (short Stamina-regen
  penalty) — cooking alone helps, but it isn't a substitute for the herb.
- Cooking them **with Sulfur Chive** fully neutralizes the toxin and unlocks the dish's real
  buff magnitude. This is why Sulfur Chive shows up as a hard *ingredient requirement*
  (not just a flavor pairing) on every Cockatril/Basilisk/Thornapple recipe below.
- **Sourlantern** (fruit, "cleanses toxins") is the *player-status* answer to poisoning that
  already landed — eating one while Poisoned shortens the debuff duration
  `[tune: cuts remaining duration by 60%]`. It doesn't retroactively fix a bad meal; it treats
  the symptom after the fact.

### 1.3 Butchery Quality → Meal Quality

Per Design Bible 5.2: *"some weapons harvest cleaner meat (butchery quality → better food)."*
Every hunt yields a **Cut Quality** tag on the raw meat item, set at the kill:

| Cut Quality | How it happens | Cooking effect |
|---|---|---|
| **Botched** | Killed with a messy/overkill hit, or looted from a corpse that sat too long | Recipe buffs at `[tune: 60%]` magnitude; higher Bellyache chance |
| **Clean** | A solid, skillful kill with an appropriate weapon | Recipe buffs at **100%** magnitude — the baseline this whole doc is written against |
| **Precise** | A clean kill with a bonus (headshot/finisher/high-poise weapon, or a butchery-specialized blade) | Recipe buffs at `[tune: 125%]` magnitude, and a small chance `[tune: 10%]` to yield a bonus **Prime Cut** sub-item usable in the same recipe slot for an extra flat buff tick |

Cut Quality is a property of the *raw meat item*, carried into the pot — it's what makes
"which weapon you hunt with" matter at the dinner table, not just in the fight. Snails
(Capglow Snail) and toxic-until-treated creatures (Cockatril, Basilisk) still need their
canon herb regardless of Cut Quality — quality scales the buff, it doesn't skip the prep step.

### 1.4 Campfire vs. Magic Circle

Both are valid cook-points and **produce the same dishes** — the difference is entirely in
*cost*, not *menu*:

| | **Campfire** | **Magic Circle** |
|---|---|---|
| Unlocked | From the start | Later (per Design Bible 5.4 — unlocked mid-game) |
| Warmth/light | Yes — also warms Body Temperature and lights the area | No ambient warmth or light |
| Smoke & noise | Yes — visibly smokes, audibly crackles | None |
| Attention/hostility cost | Raises local **attention** (per FOOD_WEB "Waste & attention" — smoke reads like carrion-fire to wandering predators) `[tune: +attention while active, decays after]` | Negligible attention cost |
| Fuel | Needs wood (Ironbark timber) to stay lit | No fuel; arcane, always ready once placed |
| Best used | When you want the warmth too, or don't have a Circle yet | When you're stalked, over-hunted-hostile, or just don't need the heat |

Some **Gloomsage** dishes (which lower detection scent) pair thematically with the Magic
Circle's quiet cooking — cooking a Gloomsage dish at a smoky Campfire is a small in-fiction
joke (you're masking your scent while announcing your location), mechanically harmless but
worth a flavor note in the journal (see dish entries).

### 1.5 Spoilage & Bittersalt Crystal

Every raw or cooked food item carries a **freshness timer**, `[tune: raw meat spoils in
~48 in-game hours; cooked dishes in ~24h; fruit/herbs in ~72h]`:

- **Fresh** → full effect as designed.
- **Turning** (past ~60% of timer) → buffs at `[tune: 75%]` magnitude, small Bellyache risk.
- **Spoiled** (timer expired) → **do not eat.** Forces the raw-food-safety debuff (nausea DoT,
  same family as raw-toxic) if eaten anyway; no Hunger restore worth the risk.

**Bittersalt Crystal** ("preservative; slows spoilage") is the answer: adding it to a
cooked dish, or rubbing it into raw meat before storage, **multiplies the freshness timer**
`[tune: x3]`. It contributes no buff of its own — it's pure shelf-life, which makes it the
one herb you use *instead of* a flavor herb when you're stocking up for a long push between
camps rather than min-maxing a single meal (see **Preserved Rations** in ITEMS.md).

### 1.6 Over-eating & Bad-Combo Penalties

- **Over-eating:** Hunger has a soft cap. Eating past ~90% Hunger still works but the
  *buff* portion of the meal is wasted `[tune: buffs don't apply if Hunger > 90% pre-meal]` —
  a nudge to eat with intent (before a hunt/descent) rather than snack-spam at full belly.
- **Bad combos:** a recipe needs its ingredients to be thematically coherent (the game only
  "completes" a dish into its named form when meat + the *correct* herb/spice + the *correct*
  fruit are all present, per the recipe table). Cooking meat with a **mismatched** herb/fruit
  (e.g., oily Grave Otter with Frostplum, a warming-with-cooling clash) still yields an edible
  **"Rough Stew"** fallback — full Hunger restore, only **50%** of any buff either ingredient
  would normally grant, and no journal discovery credit. This keeps every raw ingredient
  edible in a pinch (nobody starves because they lack the "right" herb) while making the
  *named, discovered* recipes clearly better.
- **Bellyache** (referenced above): a short debuff — reduced Stamina regen and a slow Hunger
  drain tick `[tune: 90s]` — the game's soft slap on the wrist for raw meat, botched cuts, and
  turning food. Never lethal on its own.

### 1.7 Buff Stacking, Duration & Expiry

- A single meal grants **at most one buff from the herb slot and one from the fruit slot**
  (a dish is meat + herb/spice + fruit; each contributes its own tagged effect). These two
  effects **stack together** freely (e.g., warmth + minor heal at once).
- Eating a **second** meal before the first's buffs expire **refreshes duration but does not
  stack magnitude** — buffs of the same type don't multiply, they top up. This stops
  buff-hoarding via meal-spam while still rewarding "eat before the hunt."
- Buffs are timed, not permanent `[tune: most buffs 4–8 in-game minutes; see per-dish
  Duration column]`. Resistances and regen buffs are meant to be pre-fight/pre-descent prep,
  not always-on stat sticks.
- **Cave Saffron** ("rare; amplifies any buff") is the wildcard: added into *any* recipe
  (it doesn't replace the herb slot — treat it as an optional bonus 4th ingredient), it
  boosts whatever buff(s) that dish already grants by `[tune: +50% magnitude and +50%
  duration]`, without changing what the buff *is*. It never invents a new effect — it just
  makes an existing plate hit harder. Rare, so it's the "I'm about to do something dangerous"
  ingredient, not a daily staple.
- **Deeproot Ginger** ("warmth; settles bad meat") does two jobs and both matter here: it's a
  normal warmth-herb slot filler, **and** whenever it's present in a dish, it halves the
  Bellyache chance contributed by Botched cut quality or Turning freshness on that same dish
  `[tune: -50% Bellyache chance]`. It doesn't fix raw-toxic poisoning — that's Sulfur Chive's
  job — it fixes "this cut wasn't great but I don't want to waste it."

---

## Part 2 — Discovery Model

Kept deliberately simple to implement against the current M1 cook-point stub:

1. **Experimentation first.** Any meat + any herb/spice + any fruit can be thrown on the
   fire at any time — the system always resolves *something* (a named Recipe if the exact
   canon trio matches, otherwise the **Rough Stew** fallback from 1.6). Nothing is ever
   locked out of being cooked; only the *good result* is locked behind the right combo.
2. **First successful cook = journal entry.** The moment a player cooks the exact ingredient
   trio for a named dish for the first time, the Cook-Journal (diegetic recipe book, per
   Design Bible's "delver's journal aesthetic for the bestiary/recipes") auto-fills that
   page: dish name, a sketch/icon, the flavor line, and the buff(s) it grants. This is the
   entire "unlock" — no separate skill tree, no recipe-scroll loot items needed for the
   Floor 1–2 tier.
3. **Hints nudge without spoiling.** Two light-touch, easy-to-implement hint sources:
   - **Creature cooking notes** (the short "Cooking note" column already in `FOOD_WEB.md`
     per species) surface in the **bestiary** entry for that creature once it's been
     hunted/examined once — e.g. Palefish's page literally says "pairs with Marrow Mint,"
     which is a direct pointer at **Cold-Cellar Chowder** below.
   - **Failed-but-close attempts leave a journal note.** If a player cooks a meat with the
     *correct herb* but *wrong fruit* (or vice versa), the Rough Stew result still adds a
     small scribbled hint line to that meat's journal page ("...the ginger helped. Something
     sweet might finish it?") rather than silently giving nothing. This rewards near-misses
     without giving the answer outright.
4. **Rare ingredients gate rare dishes naturally.** Cave Saffron, Goldcap Gooseberry, and
   deep-floor meats are simply *hard to have on hand* — no separate unlock flag needed; scarcity
   of the ingredient itself paces when a player can realistically complete those pages.
5. **No fail states.** A player who never "discovers" anything and only ever eats Rough Stew
   can still survive indefinitely (full Hunger restore always applies) — discovery is upside,
   never a gate on basic survival. This matters given Hunger is the master clock.

---

## Part 3 — Recipe Table

Cook-point key: **CF** = Campfire · **MC** = Magic Circle · **Either** = both work identically
(see 1.4). All dishes assume **Clean** cut quality and **Fresh** ingredients as the baseline
numbers; see 1.3/1.5 for how quality and spoilage scale them. Duration is in-game minutes
unless noted. Ordered roughly Floor 1 → Floor 2 → deeper → celebration.

### Floor 1–2 staples (Tier 1–2 meat)

| # | Dish | Ingredients (meat · herb/spice · fruit) | Cook-point | Buff(s) | Duration / Magnitude `[tune]` | Journal flavor note |
|---|------|------------------------------------------|:----------:|---------|-------------------------------|----------------------|
| 1 | **Moss-Lamb Hearth Roast** | Mosslamb · Deeproot Ginger · Cavern Currant | Either | Warmth +, small Hunger restore | Warmth: 6 min, +15%; Hunger: +40% | *"The first thing I ever cooked down here that didn't fight back. Tastes like being forgiven."* |
| 2 | **Springhare Quickstew** | Grotto Springhare · Palethyme · Cavern Currant | Either | Stamina-regen + | 5 min, +20% regen rate | *"Springhare's too fast to catch tired — eat this before, not after, or you're cooking dust again tomorrow."* |
| 3 | **De-Slimed Snail Skewers** | Capglow Snail · Sulfur Chive · Sourlantern | Either | Minor toxin-resist + tiny heal | 4 min resist buffer; heal +8 HP once | *"Sulfur Chive first, always. Skip it and you'll taste why the snail was slow."* |
| 4 | **Blind Vole Stock Pot** | Blind Vole · Gloomsage · Mossmelon | Either | Detection-scent lowered, hydration | Scent: 6 min, -20% detection radius; Hydration: +30% Thirst | *"Voles are barely a meal on their own, but this stock is why I've walked past three Ashjackals that never turned their heads."* |
| 5 | **Cold-Cellar Chowder** | Palefish · Marrow Mint · Mossmelon | Either | Cold-resist +, hydration | Cold-resist: 6 min, +20%; Hydration +30% | *"The bestiary note wasn't lying — mint and Palefish were made for each other. First recipe I ever 'discovered' instead of stumbled into."* |
| 6 | **Quail Egg Custard-Cake** | Deep Quail Egg · Deeproot Ginger · Duskfig | Either | Warmth +, big Hunger restore | Warmth: 5 min, +15%; Hunger +70% | *"Not meat at all — a forager's dish. One nest of eggs feeds better than the bird ever would have."* |
| 7 | **Gloomferret Brasier Braise** | Gloomferret · Stoneleaf Rosemary · Bleedberry | CF | Poise/defense +, minor heal | Poise: 6 min, +15% stagger-resist; heal +10 HP | *"Braised, always braised. Gloomferret straight off the fire is a chewing exercise, not a meal."* |
| 8 | **Ashjackal Pack-Hunter's Chili** | Ashjackal · Emberpepper · Emberberry | CF | Fire-resist + warmth (stacks, see 1.7) | 6 min, Fire-resist +20%, Warmth +15% | *"Fought off three of them to earn this pot. Feels right that it burns a little going down."* |
| 9 | **Rockback Boar Belly** | Rockback Boar · Deeproot Ginger · Goldcap Gooseberry | Either | Warmth +, all-round buff (small heal + Hunger) | 7 min, Warmth +20%; heal +12 HP; Hunger +60% | *"Fatty, excellent, the note said. It undersold it. Save the Gooseberry for this one — the boar earns it."* |
| 10 | **Spinefowl Clean-Pluck Confit** | Spinefowl · Palethyme · Bleedberry | Either | Stamina-regen +, minor heal | Stamina: 6 min, +20% regen; heal +10 HP | *"Pull every spine before it touches the pan or you'll be picking them out of your gums for a week."* |
| 11 | **Grave Otter Warming Stew** | Grave Otter · Emberpepper · Emberberry | CF | Warmth ++ (strong, oily meat) | 8 min, Warmth +30% | *"Oily meat, hot pepper, a fire that won't quit — this is the dish I make when the floor gets cold and I don't care who smells the smoke."* |
| 12 | **Ashen Cockatril Confit** | Cinder Cockatril · Sulfur Chive · Sourlantern | Either | Toxin-resist +, cleanses lingering toxin | Resist: 6 min, +25%; instantly clears any active Poisoned debuff | *"Cook it wrong and it's the last mistake you make twice. Cook it right and it's genuinely one of my favorites."* |

### Floor 2 additions (Tier 2–3 edge, Rootways)

| # | Dish | Ingredients (meat · herb/spice · fruit) | Cook-point | Buff(s) | Duration / Magnitude `[tune]` | Journal flavor note |
|---|------|------------------------------------------|:----------:|---------|-------------------------------|----------------------|
| 13 | **Bog Saurian Tail Confit** | Bog Saurian · Marrow Mint · Frostplum | CF | Cold-resist ++, heat-resist | 8 min, Cold-resist +25%, Heat-resist +15% | *"The note says the tail's the prime cut and it isn't wrong — it's the one part of the beast worth the fight."* |
| 14 | **Constrictor Coil Sausage** | Tunnel Constrictor · Stoneleaf Rosemary · Cavern Currant | Either | Poise/defense +, big Hunger restore (huge yield) | Poise: 6 min, +15%; Hunger +70%, feeds multiple sittings | *"One kill, a week of sausage. The ecosystem rules say don't waste a carcass — this is how you don't."* |
| 15 | **Antler Warg Rootways Ragout** | Antler Warg · Palethyme · Gloomgrape | CF | Stamina-regen ++ (stacked herb+fruit, see 1.7) | 7 min, Stamina-regen +35% total | *"Pack hunters run you ragged before you ever land a killing blow. This is the dish that pays that debt back."* |
| 16 | **Gloomsage Vole-and-Root Hotpot** | Blind Vole · Gloomsage · Duskfig | Either | Detection-scent lowered, big Hunger restore | Scent: 6 min, -20% detection; Hunger +70% | *"Cook this one over the Circle if you can — smoking it over an open flame while trying to smell like nothing is the funniest kind of hypocrisy."* |
| 17 | **Sulfur-Cleansed Basilisk Steak** | Dire Basilisk · Sulfur Chive · Sourlantern | Either | Toxin-resist ++, minor heal | Resist: 8 min, +30%; heal +12 HP | *"Glands out, chive in, twice-checked. I am not exaggerating when I say I triple-check this one."* |
| 18 | **Thornapple Sear** | *(no meat — flora dish)* Thornapple · Sulfur Chive · — | Either | Potent all-round buff (per canon "potent buff cooked with Sulfur Chive") | 8 min, Hunger +30%, small heal +15 HP, +10% to all active resistances | *"The only fruit on this floor that's actively trying to kill you raw. Treated right, it's the best thing that grows here."* |
| 19 | **Deeproot Ginger Trail Tea** | *(no meat — flora dish)* Weeping Palewillow bark · Deeproot Ginger · — | Either | Warmth +, rest-quality improved slightly | Warmth: 6 min, +10%; small camp-rest bonus | *"Not a meal — a mug you drink between meals. The bark alone would just be bitter; the ginger's what makes it worth brewing."* |

### Floor 3–4 (Sunless Marsh / Bonefields — Tier 3–4)

| # | Dish | Ingredients (meat · herb/spice · fruit) | Cook-point | Buff(s) | Duration / Magnitude `[tune]` | Journal flavor note |
|---|------|------------------------------------------|:----------:|---------|-------------------------------|----------------------|
| 20 | **Gloamstalker Ambush Loin** | Gloamstalker Lynx · Palethyme · Bleedberry | Either | Stamina-regen +, minor heal | 7 min, +25% regen; heal +12 HP | *"Lean cuts off a lean killer. It ambushed three things smaller than me to earn this plate; feels only fair I return the favor."* |
| 21 | **Ridgehawk High-Roast** | Hookbeak Ridgehawk · Emberpepper · Frostplum | CF | Fire-resist +, heat-resist (aerial game, cooked hot and fast) | 6 min, Fire-resist +20%, Heat-resist +15% | *"Hardest thing on this floor to actually reach. I owe whoever taught me to throw a hook-line."* |
| 22 | **Marrow Hyena Bone-Broth** | Marrow Hyena · Stoneleaf Rosemary · Cavern Currant | CF | Poise/defense ++, filler Hunger | Poise: 8 min, +20%; Hunger +50% | *"Bone-cracker's own bones make the best stock. There's a joke in there I haven't found yet."* |
| 23 | **Leviathan-Eel Ember Grill** | Deepwater Leviathan-eel · Emberpepper · Emberberry | CF | Warmth +++, fire-resist (oily, enormous, needs a hot fire) | 9 min, Warmth +35%, Fire-resist +15% | *"One eel, a feast for a week, and a fire I had to feed all night to render it properly. Worth every log."* |
| 24 | **Sabertooth Prized-Hide Chops** | Pale Sabertooth · Stoneleaf Rosemary · Goldcap Gooseberry | Either | Poise/defense ++, all-round buff | Poise: 8 min, +25%; heal +15 HP, Hunger +60% | *"Glass-cannon in life, feast in death. Keep the hide separate from the meat — one goes on the wall, one goes in the pot."* |
| 25 | **Rhinox Charge-Breaker Stew** | Stonehide Rhinox · Deeproot Ginger · Duskfig | CF | Warmth ++, huge Hunger restore | Warmth: 8 min, +25%; Hunger +90% | *"You do not hunt a Rhinox for sport. You hunt it because the ecosystem note says adults are untouchable and you have decided, against all sense, otherwise. Cook it with respect."* |

### Deep / apex & celebration dishes (Floor 4–5, rare ingredients)

| # | Dish | Ingredients (meat · herb/spice · fruit) | Cook-point | Buff(s) | Duration / Magnitude `[tune]` | Journal flavor note |
|---|------|------------------------------------------|:----------:|---------|-------------------------------|----------------------|
| 26 | **Chasm Drake Sear-Feast** | Chasm Drake · Emberpepper · Emberberry | CF | Warmth +++, fire-resist ++ (needs a proper sear — CF only) | Warmth: 10 min, +30%; Fire-resist +25% | *"Wingless it may be, but it still breathes like a forge. Searing it is not optional — the note wasn't kidding."* |
| 27 | **Gravemaw Ursine Winter Feast** | Gravemaw Ursine · Marrow Mint · Frostplum | CF | Cold-resist +++, huge Hunger restore, minor heal | Cold-resist: 10 min, +35%; Hunger +90%; heal +15 HP | *"A cave bear is a nightmare to fight and a feast to eat, in that exact order. Nobody warns you how much it actually feeds."* |
| 28 | **Saffron-Gilded Gooseberry Crown** | Any prime meat (celebration slot) · Cave Saffron · Goldcap Gooseberry | MC | Amplifies whatever meat's normal buff(s) +50% magnitude/duration (per 1.7); all-round buff from the Gooseberry itself | Base buff: +50% magnitude & duration; Hunger +50%, heal +15 HP | *"Two rare things on one plate. I don't cook this to survive — I cook it because I made it to the Circle with both ingredients still in my pack, and that's worth celebrating on its own."* |
| 29 | **Apex Marrow Feast** | Apex-tier meat (deep-floor, rare) · Stoneleaf Rosemary · Goldcap Gooseberry | MC | Poise/defense +++, all-round buff, big heal | Poise: 12 min, +35%; heal +25 HP; Hunger +90% | *"There are maybe five things down here that could end up on this plate, and every one of them could have ended me first. I write this note a little shaky."* |
| 30 | **Dreamdill Descent-Eve Supper** | Rockback Boar (or best-available Floor 1–2 meat) · Dreamdill · Bleedberry | Either | Rest-quality improved (strong), minor heal, small Hunger restore | Rest bonus: full camp cycle; heal +10 HP; Hunger +40% | *"Not for buffs before a fight — for the night before a descent, when you want to wake up actually rested instead of just stopped moving. Dreamdill's worth foraging for on its own."* |

**Notably absent by design:** there is **no** recipe using **The Hollow Stag**. Per canon it is
a keystone, not prey — see Part 1 header note and the standing lore rule that hunting it is
catastrophic. If a future design pass wants a *narrative* consequence dish (something a player
could theoretically cook if they made that terrible choice), that's a deliberate design call,
not an oversight here — flagged for Damien below.

---

## Part 4 — Quick-reference: effect → dishes

For designers/QA sanity-checking buff coverage at a glance:

- **Warmth:** #1, #8, #9, #11, #19, #23, #25, #26
- **Stamina-regen:** #2, #10, #15, #20
- **Cold-resist:** #5, #13, #27
- **Fire/heat-resist:** #8, #13, #21, #23, #26
- **Toxin-resist / detox:** #3, #12, #17, #18
- **Healing:** #3 (tiny), #7, #9, #10, #12, #17, #18, #20, #24, #26, #27, #28, #29, #30
- **Detection-scent lowered:** #4, #16
- **Poise/defense:** #7, #14, #22, #24, #29
- **Rest quality:** #19 (small), #30 (strong)
- **Hunger restore (large, "filler" role):** #6, #9, #14, #16, #22, #25, #27, #28, #29

*(Cross-check against Part 3 before implementing — this section is a coverage map, not a
second source of truth; if a number ever conflicts, Part 3 wins.)*
