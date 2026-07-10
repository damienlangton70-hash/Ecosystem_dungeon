# Deepforage — Art Direction

*Owner: Art Director (Umbra). Expands `DESIGN_BIBLE.md` §7 into the studio's working art
bible. Everyone touching a visual — Graphics, UI, VFX, even Lore's flavour text for how
things are described — aligns to this. Colour tokens live in code at
`src/systems/style/Palette.gd`; this document is the reasoning behind them.*

North-star reference: `docs/keyart/fungal-shallows.jpg.base64` (Floor 1 concept, see
`docs/keyart/README.md` for how to decode and view it).

---

## 0. The thesis, in one sentence

**A single warm ember survives in an ocean of cold, glowing dark** — every frame of
Deepforage should let you find the flame before you find anything else, and everything
around it should be trying to put it out.

The concept art earns its keep because it commits *completely*: towering glowcap
pillar-trees hang teal, cornflower-blue, and violet light down through volumetric haze
onto genuinely black-blue stone; a lone hooded delver stands small against that scale,
holding a lantern whose amber core is the only warm pixel in the entire image. Nothing
else competes with it. That restraint — one warm note, one silhouette for scale, and
patient, confident darkness everywhere else — is the whole job. Awe reads first because
the glow is beautiful and vast; threat reads a half-second later because the delver is
so small and so alone in it.

---

## 1. Palette

Every constant below is defined once, in code, in `src/systems/style/Palette.gd`. Nobody
hand-types a `Color(...)` literal for cavern/glow/flame/flora work — if a colour isn't in
`Palette.gd`, it doesn't exist yet; add it there, don't inline it.

### 1.1 Structure / stone — the dark the glow fights against

| Token | Hex | Use |
|---|---|---|
| `STONE` | `#1A1C24` | Default cavern rock. Cool blue-grey, not neutral grey — stone should always feel slightly underwater. |
| `STONE_DARK` | `#0B0D11` | Deep shadow recesses, tunnel throats, the descent shaft's mouth. Near-black; where the eye should refuse to resolve detail. |
| `STONE_LIT` | `#292E38` | Rock faces catching bounce-light from a nearby glowcap. The *brightest* stone gets, still darker than any glow token. |
| `WALL` | `#1D1A18` | Wall rock with a warmer, drier, brown-black bias — deliberately off-hue from `STONE` so walls and floor/ceiling don't collapse into one grey mass. |
| `RIDGE` | `#33302E` | Chipped ledge edges and rock-ridge highlights; the only stone token allowed near mid-value — used sparingly, on edges only. |
| `GROUND` | `#161413` | Cavern floor, damp earth and silt. Warm-dark, grounding the cold glow above it. |
| `ENTRANCE` | `#4C3D29` | Surface-facing stone at the very top of Floor 1 only — a memory of daylight-warmed rock the player leaves behind at the game's opening and never sees again until (if ever) they climb back out. |

### 1.2 Cold bioluminescence — the light source and the beauty

| Token | Hex | Use |
|---|---|---|
| `GLOW_TEAL` | `#4CF2CC` | Brightest, coldest accent — glowcap cap-rims and gill undersides at their most saturated. This is the "wow" colour; use it at the top of the frame, rarely at eye level. |
| `GLOW_BLUE` | `#5999F2` | Mid-register cap glow; also the water-reflection tint — pools mirror the canopy in this hue. |
| `GLOW_VIOLET` | `#8C66E6` | Deep/distant cap glow and background canopy. Becomes the *dominant* glow hue from Floor 3 down (see §4) — violet reads as older, deeper, stranger than teal. |
| `GLOW_FUNGUS` | `#73E6A6` | Ground-level glow-fungus clusters. Greener and warmer-cool than the cap glows above — a deliberate secondary note so the ground doesn't just echo the canopy. |
| `GLOW_DIM` | `#2E4C52` | Same family, heavily desaturated — background/unlit caps receding into haze. Use for anything more than ~15m from camera so distant glow doesn't compete with foreground glow. |

**Glow hierarchy rule:** teal reads as *closest/newest*, blue as *mid-distance*, violet as
*deepest/oldest*. This isn't just palette variety — it's a depth cue the player learns
without a UI telling them.

### 1.3 Warmth — the one thing fighting the dark

| Token | Hex | Use |
|---|---|---|
| `FLAME` | `#FF9E33` | The lantern and campfire flame core. **This is the only saturated warm light source that should ever exist on screen.** If something else glows amber, it is either the player's own fire or it is wrong. |
| `EMBER` | `#D9591A` | Coals, a dying fire, sear marks on cooked meat. `FLAME`'s tired cousin — used for "the fire is not doing its job right now" beats. |
| `WARN` | `#F2381F` | Descent-lip warning glow at the edge of a drop-shaft. Deliberately close to `EMBER`/`FLAME` in hue but pushed hotter and redder — it should almost, but not quite, look like comfort, then read as danger the instant you're near it. This is the one place warm colour means *threat, not safety*. |

### 1.4 Water

| Token | Hex | Use |
|---|---|---|
| `WATER` | `#1F383D` @ 75% alpha | Still bioluminescent pools. The alpha is load-bearing — pools must show `GROUND` (or silt/debris) through them, never render as an opaque colour block. |
| `WATER_EMISSION` | `#408C8C` | Faint self-glow / canopy-mirror sheen on the surface. Water is the one surface allowed to both reflect *and* faintly emit — it's doing double duty as a mirror for the glow above and a glow of its own. |

### 1.5 Flora

| Token | Hex | Use |
|---|---|---|
| `TRUNK` | `#6B5C4C` | Glowcap pillar-tree stalk / Ironbark bark, lit face. |
| `TRUNK_DARK` | `#332B26` | Trunk shadow side; Ironbark's near-black heartwood — Ironbark should read structurally *darker and heavier* than the Glowcap stalk even in identical light. |
| `FOLIAGE` | `#337361` | Cap underside / canopy foliage, mid-tone — the colour of "living plant matter" independent of its glow overlay. |
| `FOLIAGE_DEEP` | `#1A3838` | Shadowed foliage / cap topside, where the glow doesn't reach — caps should be *dark on top*, glowing from beneath, per the concept art. |
| `PALEWILLOW` | `#B8C7B8` | Weeping Palewillow withes. The one deliberately *soft, pale, low-saturation* flora note in the whole game — everything else is either dark structure or saturated glow; Palewillow is the visual exhale between them. |

### 1.6 Atmosphere

| Token | Hex | Use |
|---|---|---|
| `FOG` | `#141A21` @ 55% alpha | Volumetric haze for depth cueing. Teal-leaning, never neutral grey — fog should feel like it's carrying the glow's colour with it, not just obscuring. |
| `AMBIENT` | `#0D1217` | Baseline ambient / `WorldEnvironment` fill. Deliberately very dark — **the glow flora and the flame are the lights; ambient is a floor, not a source.** If a scene looks fine with ambient alone and no glow/flame lit, ambient is set too high. |

### 1.7 Ingredient accents (`Palette.INGREDIENT`, keyed to `Recipes.INGREDIENTS`)

| Id | Hex | Design note reflected in colour |
|---|---|---|
| `emberberry` | `#E65224` | Warming buff → kin to `FLAME`/`EMBER`, the only fruit allowed to sit in the warm family. |
| `gloomgrape` | `#8557B8` | Stamina buff → kin to `GLOW_VIOLET`, cave-grown and cold-toned. |
| `bleedberry` | `#8C0F24` | Healing → deep crimson, richer and darker than `WARN` so it never reads as a hazard colour. |
| `duskfig` | `#523847` | Big calorie fig → dusky purple-brown, unglamorous and filling. |
| `palethyme` | `#9EC794` | Stamina-regen herb → pale culinary green, the "kitchen herb" register. |
| `stoneleaf` | `#70856B` | Defense buff → grey-green, kin to `STONE` + `FOLIAGE`, reads as tough/armouring. |
| `deeprootginger` | `#CC9442` | Warmth/settling → golden tan, the one ingredient allowed near-amber without being mistaken for `FLAME`. |
| `marrowmint` | `#59B8AD` | Cold-resist, fish-freshening → mint teal-green, kin to `GLOW_TEAL`, the coldest-looking ingredient in the larder. |

Use `Palette.ingredient_color(id)` everywhere an ingredient needs a colour (pickup glow,
inventory icon tint, recipe-book swatch) — never re-derive it.

---

## 2. Material language

Deepforage is **flat-ish stylized low-poly with painterly atmosphere** — think honest,
hand-built PS2-era clarity elevated by colour and light, not photoreal PBR. Materials
should look confident and simple up close and gorgeous from a distance because of what
the *light* is doing, not the material.

### 2.1 Baseline material rules

- **Roughness is high almost everywhere.** Stone, dirt, bark, fungus flesh, cloth, fur —
  all matte-to-satin. Nothing indoors-looking or "clean CG" should read as glossy.
  Target roughness ~0.7–0.95 for `STONE`/`WALL`/`GROUND`/`TRUNK`-family surfaces.
- **Metallic is near-zero except two exceptions:** still water (`WATER`, low metallic +
  low roughness for a soft mirror sheen, not a hard chrome reflection) and forged
  weapon blades. Everything else — including bone, chitin, fungus — is metallic 0.0.
- **Emission is reserved and meaningful.** Only these things emit: glow flora
  (`GLOW_*` tokens), the flame/lantern (`FLAME`/`EMBER`), the descent-lip warning
  (`WARN`), and water's faint surface sheen (`WATER_EMISSION`). If it emits, it is
  either alive-and-luminous, on fire, or dangerous. Nothing emits "for style" — an
  emissive rock or an emissive weapon breaks the one-warm-flame rule and must be a
  design decision, not a shader flourish.
- **Emissive surfaces also cast real light**, not just self-glow. A glowcap cap should
  visibly brighten the stone beneath it and tint nearby fog; the campfire should be a
  real `OmniLight3D`/`SpotLight3D` colored `FLAME`, not just an unlit-glow mesh sitting
  in the dark. Glow-as-decoration-only is a bug, not a style choice — see §3.1.

### 2.2 The shared stylized material (for the Graphics agent's `MaterialLib.gd`)

Everything non-emissive should be able to run through one shared material approach so
the whole world holds together visually without hand-tuning every mesh:

1. **Base albedo** from `Palette` tokens (flat colour per surface, optionally with a
   cheap vertex-colour blend for authored meshes — no texture *required*, textures are
   an enhancement per §7's tileable-texture pipeline, not a dependency).
2. **A subtle toon/gradient ramp on the diffuse term** — 2–3 visible bands rather than a
   smooth photoreal falloff. This is what makes chunky low-poly forms read as
   *intentional* rather than "low-budget realism." Keep the bands soft-edged (a short
   `smoothstep`, not a hard cel-shade line) — Deepforage is painterly, not cel/anime.
3. **A soft rim-light term**, driven by the nearest dominant light colour (usually a
   `GLOW_*` token, occasionally `FLAME`). This is what sells "the glow is touching this
   surface" on rock, trunks, and creature fur even where the base albedo is dark stone —
   it's doing a lot of the "cold bioluminescence against dark stone" contrast work
   cheaply, per-pixel, without needing bespoke lighting per scene.
4. **Fresnel-driven fog/haze tint at grazing angles**, sampling `FOG`, so distant
   geometry naturally desaturates and cools/warms toward the fog colour without a
   separate depth-fog pass fighting the material.

This is deliberately achievable headless (no external DCC bake required, no light-probe
authoring per scene) — it should look right the moment a mesh with the shared material
is dropped under a `Palette.GLOW_TEAL` light and a `Palette.FLAME` light in the same
frame, which is the acid test for the whole look.

---

## 3. Lighting & atmosphere

### 3.1 Glow-as-light philosophy

The rule the concept art teaches: **there is no ambient sun.** Every floor is lit by (a)
glow flora, which is bright, coloured, and localized, and (b) the player's own flame,
which is small, warm, and mobile. `AMBIENT` exists only as a floor so nothing goes
fully unreadable-black — it must never be bright enough to substitute for an actual
light. If a room looks fully lit with no glow flora and no fire nearby, it's wrong;
either add a light source in-fiction (more glow flora, a forgotten campfire) or let it
be dark and make the player bring their own light. Darkness withheld is doing its job;
darkness the player never notices is wasted.

### 3.2 Deep shadow as a design tool, not an oversight

Shadows should be genuinely deep (`STONE_DARK`/`AMBIENT`-level, not a lifted "readable
dark grey"). Shape and silhouette carry information in shadow; colour detail does not
have to. This is what makes the glow pop the way it does in the concept art — the glow
isn't *bright* in absolute terms, it's bright *relative to how dark everything else is
allowed to be*. Resist the instinct to bounce-light-fill every shadow for "clarity" —
clarity comes from readable silhouettes (see §5), not from lifted blacks.

### 3.3 Coloured fog/haze for depth and scale

Volumetric haze (`FOG`) is what turns "a mushroom is lit teal" into "a mushroom is lit
teal and it's forty feet away and there are three more like it fading into blue-black
behind it." Fog should:
- Pick up and carry the local glow colour rather than staying neutral — a Floor 1 scene's
  haze should read faintly teal/blue; a Floor 3 scene's haze should read faintly violet.
- Increase with distance to give scale — the towering glowcap canopy in the key art only
  feels *towering* because the upper caps are hazier/dimmer (`GLOW_DIM`) than the
  lowest, nearest one.
- Never fully obscure — Deepforage is about awe at scale, not a fog-of-war gimmick.

### 3.4 Awe first, threat close behind

The compositional lesson from the key art: put the *beautiful* thing in frame first
(the canopy, the mirrored pool, the scale of the caps against a tiny delver), and let the
*dangerous* thing arrive a beat later — a warning glow at a shaft's lip, a distant
predator vocalization, the sudden awareness that the lantern is the only light for fifty
feet in any direction. Never lead with threat; earn the awe, then let the player notice
they're alone in it. This applies to environment composition, to encounter pacing, and
to UI (§6) alike — nothing should scream for attention before the world has had its
moment.

---

## 4. The descent (5 floors)

Each floor should feel like the *same visual language turned one notch colder, one
notch darker, one notch deadlier, and one notch richer* — never a palette reset. The
player should be able to tell which floor they're on from a single screenshot without
a HUD label.

| Floor | Name | Tonal shift from previous | Accent direction |
|---:|---|---|---|
| 1 | **The Fungal Shallows** | Baseline — the key art. Dim but still gentle; the nearest thing to "welcoming" the game offers. | `GLOW_TEAL` dominant, `GLOW_BLUE` secondary. Warmest stone (`WALL`/`ENTRANCE` still present near the top). First water (`WATER`) appears here, calm and mirror-still. |
| 2 | **The Rootways** | Darker and more enclosed — canopy gives way to root-tangle overhead; sightlines shorten. | `GLOW_BLUE` dominant, `GLOW_TEAL` recedes to accents. `TRUNK_DARK`/Ironbark heartwood becomes the structural material — the world starts to feel *built from* dead-feeling wood, not just stone. |
| 3 | **The Sunless Marsh** | Colder and wetter — fog thickens, ground gives way to standing water everywhere. | `GLOW_VIOLET` becomes dominant for the first time; `WATER`/`WATER_EMISSION` are everywhere rather than a single feature pool. `FOG` density increases noticeably — this is the haziest floor. |
| 4 | **The Bonefields** | Deadlier and drier — a tonal snap after three wet floors. Glow flora thins out; remains (bone-pale, desaturated) become part of the dressing. | `GLOW_VIOLET`/`GLOW_DIM` only — glow becomes scarce and precious rather than ambient, forcing more reliance on the player's own `FLAME`. Palette desaturates further; this is the least "beautiful," most exposed floor — awe gives real ground to threat here. |
| 5 | **The Maw** | Richest and most extreme — vast negative space, the deepest violet, and the single largest warm/cold contrast moment in the game. | `GLOW_VIOLET` at its most saturated and vast (huge, distant glow sources implying scale beyond the playable space) against the darkest `STONE_DARK`/`AMBIENT` in the game. The player's `FLAME` should feel smaller here than anywhere else — the ratio of "warm light" to "cold dark" is the whole point of arriving at the bottom. |

This table is the direct visual expression of pillar 4, "down is the only way": each
floor is recognizably *Deepforage*, just colder, darker, and more precious in its light,
until the ratio of warm-to-cold hits its most extreme at The Maw.

---

## 5. Flora identity

Foraging and hunting both depend on the player reading flora silhouettes at a glance,
often at speed or in low light. Distinct silhouette is not optional polish — it's a
readability requirement.

### 5.1 The three trees

| Tree | Silhouette identity | Colour identity |
|---|---|---|
| **Glowcap Pillar-tree** | Tall, single stalk, one broad umbrella cap dominating the crown — the widest single silhouette element in any scene it's in. This is the tree from the key art; caps should be readable as *circles/ellipses from below*, unmistakable against any background. | `TRUNK` stalk, `FOLIAGE_DEEP` cap topside, `GLOW_TEAL`/`GLOW_BLUE`/`GLOW_VIOLET` glowing from the cap's underside/gill structure — dark on top, glowing from below, per §1.5. |
| **Ironbark Deeproot** | Squat, thick, heavily-branched — reads as *structural and load-bearing* rather than tall and singular. Should look like it could hold a shelter up, because thematically it's the timber tree. Roots visibly grip rock. | `TRUNK_DARK`-dominant — darker and heavier than the Glowcap stalk even before lighting. No glow; Ironbark's identity is *mass and weight*, the counterpoint to Glowcap's *light and height*. |
| **Weeping Palewillow** | Drooping, trailing withes hanging toward water — the only "soft," curved-line silhouette among the three trees, always sited at water's edge. Should read as flexible/bending where the other two read as rigid. | `PALEWILLOW` pale, low-saturation foliage against `TRUNK` bark — the visual exhale of the flora set (see §1.5). |

At a glance: **tall + glowing = Glowcap. Squat + heavy = Ironbark. Drooping + pale +
waterside = Palewillow.** No two should ever be mistakable in a screenshot.

### 5.2 Berry bush vs. herb clump

Foraging speed depends on telling these apart before walking up to them:

- **Berry bushes** (emberberry, gloomgrape, bleedberry, duskfig, and the rest of the
  10-fruit list) — read as **rounded, clustered, and colour-forward**. Silhouette is a
  soft mound shape with small round accent-coloured dots (the fruit itself, tinted via
  `Palette.ingredient_color`) breaking up the mass. The fruit's colour should be visible
  *before* the leaf shape is — bushes are spotted by their colour dots first.
- **Herb clumps** (palethyme, stoneleaf, deeprootginger, marrowmint, and the rest of the
  10-herb list) — read as **low, spiky/frondy, and texture-forward** rather than
  colour-forward. Silhouette is closer to the ground, with thin blade/frond geometry
  rather than a rounded mass. Herb colour tints the whole clump subtly rather than
  showing as discrete dots — herbs are spotted by their *shape* first, colour second.

This shape-vs-colour split gives the player two independent, fast-to-learn read
strategies, and keeps a screen with both bushes and clumps from turning into visual
noise.

---

## 6. UI identity — a delver's journal

HUD and menus should feel like something the delver *carries*, not a game engine's
default overlay. Restrained, diegetic-leaning, and quiet enough to never compete with
the awe-then-threat mood established by the world itself.

### 6.1 Aesthetic direction

- **Frame:** a hand-inked field-journal register — think worn paper, soft ink-brush
  edges, hand-lettered headers (the key art's own title card, "DEEPFORAGE, FLOOR 1: THE
  FUNGAL SHALLOWS," is a good tonal reference for header treatment: cream/parchment
  ground, dark hand-drawn ink, no digital sheen). This should inform bestiary pages,
  recipe cards, and floor-transition title cards specifically.
- **In-play HUD** stays more restrained than the journal pages — thin, minimal linework
  rather than full parchment texture, so it doesn't visually compete with gameplay.
  Icons should look hand-drawn/etched rather than vector-flat corporate.
- **Typography:** a hand-lettered/rough-brush display face for headers and floor names
  (evoking the key art's title card), paired with a clean, high-legibility serif or
  humanist sans for body/stat text — journal marginalia, not a HUD font. Avoid anything
  that reads as "sci-fi" or "fantasy-generic" (no glowing rune fonts, no sharp gothic
  blackletter) — the tone is *naturalist's field notes*, not grimoire.
- **Colour:** warm parchment/cream neutrals for the "paper," ink-dark neutrals (kin to
  `STONE_DARK`/`WALL`, not pure black) for linework and text, and `Palette` tokens used
  *sparingly and meaningfully* as accent — a hunger bar tinted toward `FLAME`/`EMBER`
  as it empties, a stamina bar tinted `GLOW_TEAL`, a recipe card's ingredient swatches
  pulled directly from `Palette.ingredient_color`. The UI should never introduce a new
  colour family the world doesn't already speak.
- **Diegetic lean:** where feasible, treat HUD elements as *things the delver carries* —
  the hunger/stamina readout as a journal margin note, the bestiary as literal
  hand-written entries with a sketch, recipe discovery as a page turning. Full diegesis
  (in-world 3D objects instead of screen-space UI) is a stretch goal, not a requirement —
  the *aesthetic* of a journal matters more than literal diegetic placement for the
  vertical slice.

### 6.2 Evolving the current text HUD

The current HUD is a functional plain-text readout (hunger/stamina numbers, a depth
figure). The evolution path, in order:

1. **Re-skin first, restructure never** — swap the current text HUD's font and colour
   to the journal-ink direction above before touching layout. This alone should make the
   HUD feel intentional rather than debug-console.
2. **Convert bare numbers to bars/dials** tinted with the relevant `Palette` token
   (stamina → `GLOW_TEAL`-family, hunger/warmth → `FLAME`/`EMBER`-family) so the HUD
   itself echoes the cold-glow-vs-warm-flame contrast at a glance.
3. **Add the journal frame treatment** to menus, bestiary, and recipe book — this is
   where the parchment/ink aesthetic pays off most, since these are full-screen,
   lower-urgency moments where the player can appreciate the texture.
4. **Only then** consider diegetic placement experiments (an in-world journal object,
   etc.) — nice-to-have, not required for the vertical slice.

---

## 8. Creature & Flora Art Requirements

*Source of truth for every entry below: `docs/BESTIARY.md` (Lore's Appearance prose and
behavioural tells) cross-checked against `docs/FOOD_WEB.md` and `docs/ITEMS.md` (floor
placement, flavour text) and the current codebase (`src/creatures/Creature.gd`,
`src/world/Flora.gd`, `src/systems/cooking/Recipes.gd`, `src/game/Main.gd`) as of this
writing. This section is a translation layer, not a rewrite of the bestiary — go back to
`BESTIARY.md` for full prose; come here for the buildable spec.*

### 8.0 — How to use this section

This section is the bridge between `docs/BESTIARY.md` (Lore's prose) and buildable
Graphics work: for each of the 30 creatures, 10 insects, and 23 non-tree flora species,
it records the current implementation status, a compressed silhouette identity, and a
concrete `Palette` mapping (existing tokens plus the proposed new ones in §8.1). Building
forty-plus unique creature meshes and a full flora roster is not one run's work — this is
the ordered backlog and the palette groundwork so that when each entry's turn comes, it's
a fast, well-specified build from a shared visual language rather than a fresh design
question asked from scratch. Treat "Status" columns as living — update them in place as
Graphics ships real silhouettes, rather than adding a second tracking document.

### 8.1 — Proposed new Palette tokens

`Palette.gd` currently covers stone/structure, cold bioluminescence (teal/blue/violet/
fungus/dim), warmth (flame/ember/warn), water, flora (trunk/foliage/palewillow), fog/
ambient, and 8 ingredient accents. Scanning every Appearance paragraph in `BESTIARY.md`
surfaces recurring hue-language that doesn't map cleanly onto any of those — mottled
stone-greys and near-blacks that aren't quite `STONE`, bone-white and marrow-yellow
blotching, ash-grey sooty smudging, sickly toxin yellow-green, ember-veins-on-black,
rust/dun ground-bird plumage, and a warm amber eye-glow that is explicitly *not* `FLAME`
(creature eye-shine is a hunting tell, not the game's one sacred warm light source — see
§2.1's emission rule). Clustering that language into a tight, non-redundant set below —
aiming for coverage, not one token per creature. Each hex was chosen to sit comfortably
alongside the existing palette (cross-checked against every current token so nothing
here silently duplicates e.g. `GLOW_VIOLET` or `TRUNK_DARK` under a new name).

This is a proposal only — `Palette.gd` itself is not edited by this document. The table
below is written to be trivial to transcribe directly into `Palette.gd` as new `const`
lines when the Graphics agent picks this up.

| Token | Hex | Rationale | Example creatures |
|---|---|---|---|
| `BONE` | `#D8D0C0` | Bone/ivory-white fur, antler, and hide — the palest warm-neutral in the roster, distinct from `PALEWILLOW`'s cooler pale-green-grey. Reused across the roster's most "marked by rank or age" creatures. | Marrow Hyena (blotching), Rackjaw (antlers), Elder Marrowmother (mane), The Hollow Stag (hide), Spinefowl (spine-ridge) |
| `MARROW_YELLOW` | `#C9A227` | The dull yellow half of "bone-white and marrow-yellow blotching" — a desaturated, unglamorous yellow-ochre, warmer and duller than `deeprootginger`'s golden tan so it never competes with ingredient accents. | Marrow Hyena, Elder Marrowmother |
| `ASH_GREY` | `#4A4B4E` | Sooty, smudged mid-grey coat colour — cooler and flatter than `RIDGE`, warmer and less blue than `STONE_LIT`. The "pack canid" base fur tone. | Ashjackal, Gloomferret (base fur before its violet stripe), Deep Quail (slate half of its plumage) |
| `CHARCOAL_BLACK` | `#111013` | Near-black fur/scale/hide base for the roster's darkest non-`STONE_DARK` creatures — warmer and slightly less blue than `STONE_DARK` so creature silhouettes don't optically fuse with cavern shadow at a glance. | Gloomferret, Gravemaw Ursine, Chasm Drake, Deepwater Leviathan-eel, The Gloom Tyrant |
| `TOXIN_GREEN` | `#A8C438` | Flat, sickly yellow-green — the roster's one deliberately *unappealing* colour, reserved for "do not touch" reads. Distinct from `GLOW_FUNGUS`'s healthy cool green and from any ingredient accent. | Dire Basilisk (frilled crest), Cinder Cockatril (secondary toxicity read alongside its own ember-crest) |
| `TOXIN_TEAL_GLOW` | `#3ECBA0` | The learnable "about to strike" bio-glow — venomous teal-green, pulsing at a throat or tail rather than lighting a scene. Close kin to `GLOW_TEAL` but pulled slightly greener/duller so it reads as a *creature tell*, not flora/environment light. | Dire Basilisk (throat-pulse), Bog Saurian (tail glow-stripe) |
| `EMBER_VEIN` | `#E0641F` | "Banked-ember orange glowing along ribs/jaw" against black plating — a creature-body application of the ember family, kept distinct from `EMBER` (dying campfire) and `FLAME` (the one sacred light) by being a *vein pattern on dark scale*, never a light source in its own right. | Chasm Drake |
| `AMBER_EYESHINE` | `#F2A63D` | Warm amber eye-glow / hunting stare — explicitly a small emissive *tell*, not a light source, and intentionally close to `FLAME` in hue (it's the one place a warm glow that ISN'T the player's fire is allowed, because it signals "predator is watching you," a threat read, not a comfort one). Use sparingly, on eyes only, never as body-wide emission. | Ashjackal, Hookbeak Ridgehawk, Gravemaw Ursine, Elder Marrowmother, Cavern Roc, Grotto Springhare (non-predator exception — its eyes are simply bright, not a glow-tell) |
| `RIDGE_BROWN` | `#8A5A3D` | Dusty ridge/rust-brown for ground and cliff birds — warmer and more saturated than `WALL`, so feathered creatures read as organic rather than as an extension of the rock they perch on. | Hookbeak Ridgehawk, Spinefowl, Deep Quail (rust half), Cavern Roc |
| `SWAMP_MUD` | `#3E4A32` | Mottled swamp-green/mud-brown reptile camouflage — a muddy, desaturated olive distinct from both `TOXIN_GREEN` (which must stay "unappealing/warning-only") and `GLOW_FUNGUS` (healthy plant-green). | Bog Saurian, Tunnel Constrictor (root-brown mimicry half) |
| `FROST_HIDE` | `#C7CDD6` | Near-white to pale bone-grey coat carrying cold-violet striping — the "ghostly against the dark" register for Bonefields apex fauna. Cooler and blue-er than `BONE` so the two don't collapse into one "pale creature" bucket. | Pale Sabertooth, Titan Molebeast (base hide before its amber dust-flecks) |
| `RUST_DUN` | `#6E5A3E` | Warm brown-black hide/plating base for armoured ground mammals — a dun-brown workhorse tone sitting between `WALL` and `TRUNK`, reused wherever a creature needs to read as solid, armoured, and unglamorous rather than glowing or ghostly. | Rockback Boar, Marrow Hyena (base coat under its bone/marrow blotching), Stonehide Gorehorn (weathered-stone half already covered by `STONE_LIT`; this token covers its warmer seam-staining) |

Note on reuse, not duplication: creature-body cold bio-glow (Grave Otter's whisker rim,
Tunnel Constrictor's eye-points, Pale Sabertooth's striping, The Gloom Tyrant's crown,
The Sunless Wyrm's veins, The Hollow Stag's antler-glow) should draw directly on the
existing `GLOW_TEAL` / `GLOW_VIOLET` family rather than a new token — that reuse is
deliberate and reinforces §1.2's depth-cue rule (teal = nearer/younger, violet =
deeper/older) at the creature level, not just the flora level. Rackjaw's "cold slate-grey
coat" likewise reuses `STONE_LIT` rather than needing its own token.

### 8.2 — Tier-based scale & visual escalation

Extending §1.2's glow hierarchy (teal = near/new, violet = deep/old) to the creature
roster: **scale and silhouette complexity should escalate with trophic tier, in lockstep
with the existing glow-hierarchy colour language**, so a delver reads danger from size
AND colour together, not either alone.

- **Tier 1 (Grazers):** Small, rounded, soft silhouettes — barrel bodies, big harmless
  eyes, no aggressive geometry (no horns-that-gore, no crests, no visible teeth). Where
  bio-glow appears at all (Capglow Snail, Palefish) it should sit in the `GLOW_TEAL`/
  `GLOW_FUNGUS` family — the "newest/nearest" hues — reinforcing "this is not a threat."
- **Tier 2 (Small Hunters):** Still small, but silhouettes gain a first angular note —
  sharp shoulder ridges, a spine-ridge, plate armour — the first hint that shape can
  hurt you. Eye-glow (where present) shifts to `AMBER_EYESHINE`, the roster's first
  "predator is watching" tell.
- **Tier 3 (Mid Predators):** Clearly predator-shaped — low stalking postures, visible
  fangs/antlers/talons, pack-signalling silhouettes (Rackjaw's antler-rack readable at a
  pack's silhouette-distance before individual detail resolves). This is where
  `GLOW_VIOLET`-family bio-glow starts appearing as a creature marking (Gloamstalker
  Lynx's ruff-flecks, Tunnel Constrictor's eye-points) rather than only `GLOW_TEAL`.
- **Tier 4 (Large Predators):** Genuinely large, blocky, architectural mass — Gravemaw
  Ursine and Stonehide Gorehorn are explicitly "largest ground silhouette" claims in the
  bestiary; meshes should read as too big to casually fight even in silhouette alone.
  Bio-glow, where present, is fully in the `GLOW_VIOLET`/`EMBER_VEIN` family — old,
  deep, dangerous hues only.
- **Tier 5 (Apex):** Towering, near-architectural silhouettes that dwarf Tier 4 (The
  Gloom Tyrant "dwarfs even Gravemaw Ursine"; Cavern Roc's wings "wider than most
  chambers feel comfortable with"). Colour is at its most saturated and vast
  `GLOW_VIOLET`/near-total-black — this is where the palette's coldest, deepest hue and
  the roster's largest scale converge on purpose. The Hollow Stag is the deliberate
  exception: Tier 5 scale-and-stillness with a *calm* glow (bone-white + violet-white,
  no aggressive geometry at all) — its danger is entirely behavioural/ecological, not
  visual, and the art should not editorialize threat onto it.

Per-floor colour context from §4 still applies on top of this — a Tier 3 predator
encountered on Floor 2 (violet not yet dominant) should still read slightly "younger/
nearer" than the same tier encountered on Floor 4 (violet-dominant, glow scarce), even
though its base tier-glow family doesn't change.

### 8.3 — Creature art requirements (30 species, grouped by tier)

**Status as of this sync pass (2026-07-10, per D11 — keep this doc synced to reality):**
Mosslamb, Ashjackal, and Gloamstalker Lynx now build a real animated `CreatureRig`
(Skeleton3D + AnimationTree — tapered/rounded limb primitives, correct Palette colour,
hide texture) instead of a static placeholder; see "Done recently" in `docs/ROADMAP.md`.
The full Floor-1 roster from `data/lore.json` (10 species) is now spawned in-game — the 7
without a bespoke `CreatureModels`/`CreatureRig` entry (Grotto Springhare, Blind Vole,
Deep Quail, Gloomferret, Rockback Boar, Spinefowl, Cinder Cockatril) render via
`Creature.gd`'s generic form-driven rig: correct stats/colour and predator-vs-prey
silhouette cues (ear shape, eye-glow) apply, but no bespoke per-species shape yet. The
other 20 species remain fully documented in Lore with no code presence at all.
**Token caveat:** of §8.1's 12 proposed new tokens, only `ASH_GREY`, `AMBER_EYESHINE`,
and `CHARCOAL_BLACK` actually exist in `Palette.gd` today — every other token named in
the tables below (`BONE`, `RIDGE_BROWN`, `RUST_DUN`, `EMBER_VEIN`, `MARROW_YELLOW`,
`TOXIN_GREEN`, `TOXIN_TEAL_GLOW`, `FROST_HIDE`, `SWAMP_MUD`) is still a proposal, not
real code — check `Palette.gd` before assuming a token exists.

#### Tier 1 — Grazers & Foragers

| Creature | Tier | Silhouette identity | Palette tokens | Status |
|---|---|---|---|---|
| Mosslamb | 1 | Barrel-bodied quadruped, stacked rounded boulders, mossy felted coat | `STONE_LIT`/`STONE` (chalky grey-green base), `GLOW_TEAL` (dim, back-lichen fleck) | **Built — animated CreatureRig** (tapered capsule torso/limbs, correct `STONE_LIT` tint + hide texture; lichen-fleck accent not yet ported) |
| Grotto Springhare | 1 | Long-legged, big-eared, coiled-spring haunches | `STONE_LIT` (pale limestone fading to cream belly), `CHARCOAL_BLACK` (ink ear-tips), `AMBER_EYESHINE` (bright, non-predator exception) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |
| Capglow Snail | 1 | Slow broad foot beneath a spiral glowing shell | `STONE` (basalt-grey foot), `GLOW_TEAL`/`GLOW_VIOLET` (shell ridge glow) | Not yet built (not spawned) |
| Blind Vole | 1 | Small featureless ovoid, stub limbs, no eyes, blunt snout — deliberately the least interesting silhouette | `BONE`-tinted dull pink-grey (custom low-saturation mix, proposal — not real yet), `GROUND` (dirt-brown mottling) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |
| Palefish | 1 | Slim translucent-pale fish, schooling | `BONE`/near-white base (proposal — not real yet), `GLOW_VIOLET` (undertone from internal organs) | Not yet built (not spawned) |
| Deep Quail | 1 | Plump ground bird, stubby legs, stiff fan tail | `ASH_GREY`/`RIDGE_BROWN` (mottled slate-and-rust plumage bands; `RIDGE_BROWN` still a proposal) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |

#### Tier 2 — Small Hunters & Omnivores

| Creature | Tier | Silhouette identity | Palette tokens | Status |
|---|---|---|---|---|
| Gloomferret | 2 | Long, low, sinuous — elongated torso, whip-thin tail | `CHARCOAL_BLACK` (fur), `GLOW_VIOLET` (single dull spine-to-tail stripe) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |
| Ashjackal | 2 | Lean, angular canid — sharp shoulder ridges, alert triangular ears | `ASH_GREY` (sooty-smudged coat), `AMBER_EYESHINE` (small eye-glow, not full bioluminescence) | **Built — animated CreatureRig** (tapered limbs, correct `ASH_GREY` tint + hide texture, small amber eye-glow) |
| Rockback Boar | 2 | Squat, heavy-shouldered, hexagonal-plated back armour | `RUST_DUN` (warm brown-black hide, still a proposal), `RIDGE`/`STONE_LIT` (slate plating), `EMBER` (firelit tusk highlight) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |
| Spinefowl | 2 | Tall gawky ground bird, stiff angular quill-spine ridge down the back | `RIDGE_BROWN` (dull rust-brown body, still a proposal), `BONE` (pale spine-ridge, still a proposal) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |
| Grave Otter | 2 | Sleek elongated otter, low-slung, fast in water | `CHARCOAL_BLACK` (wet-look hide), `BONE`/pale grey-white (face patch, still a proposal), `GLOW_VIOLET` (whisker/eye-patch rim glow) | Not yet built (not spawned) |
| Cinder Cockatril | 2 | Compact upright bird-reptile hybrid, cockerel posture, low crest | `ASH_GREY` (base crest), `EMBER`/`EMBER_VEIN` (crest shifting to smouldering orange-red — the toxicity tell; `EMBER_VEIN` still a proposal) | Spawned — generic rig (real stats/colour, no bespoke silhouette yet) |

#### Tier 3 — Mid Predators

| Creature | Tier | Silhouette identity | Palette tokens | Status |
|---|---|---|---|---|
| Gloamstalker Lynx | 3 | Lean long-limbed big cat, low stalking posture, flattened haunches | `STONE` (mottled dark stone-grey), `CHARCOAL_BLACK` (near-black patches), `GLOW_TEAL` (faint cold flecks along ruff) | **Built — animated CreatureRig** (tapered limbs, correct `STONE` tint + hide texture, real stub tail + ear tufts; charcoal patches/teal ruff-flecks not yet ported) |
| Hookbeak Ridgehawk | 3 | Broad-winged raptor, exaggerated hooked beak, stiff angular wings | `RIDGE_BROWN` (dusty ridge-brown plumage), `BONE` (pale cream chest), `AMBER_EYESHINE` (hunting-stare glow) | Not yet built |
| Marrow Hyena | 3 | Hunched, powerful-jawed canid, dropped-hindquarter stance | `BONE` + `MARROW_YELLOW` (bone-white/marrow-yellow blotching), `RUST_DUN` (dull grey-brown base coat) | Not yet built |
| Bog Saurian | 3 | Low wide-bodied reptile, most bulk submerged, ridged spine breaking the surface | `SWAMP_MUD` (mottled swamp-green/mud-brown scales), `TOXIN_TEAL_GLOW` (sickly tail glow-stripe, the warning) | Not yet built |
| Tunnel Constrictor | 3 | Enormously long thick-bodied serpent, smooth overlapping coil segments | `STONE`/`SWAMP_MUD` (stone-grey and root-brown wall-mimic patterning), `GLOW_VIOLET` (two small cold eye-points) | Not yet built |
| Rackjaw | 3 | Tall rangy wolf-elk hybrid, branching angular antler rack | `STONE_LIT` (cold slate-grey coat, reused per §8.1), `BONE` (antlers, pack-visible at range) | Not yet built |

#### Tier 4 — Large Predators

| Creature | Tier | Silhouette identity | Palette tokens | Status |
|---|---|---|---|---|
| Chasm Drake | 4 | Wingless wyvern, long hind-heavy body, vestigial wing-limbs as slashing forelimbs | `CHARCOAL_BLACK` (dark volcanic-black plating), `EMBER_VEIN` (banked-ember veins along ribs/jaw) | Not yet built |
| Gravemaw Ursine | 4 | Massive hunch-shouldered cave-bear, broad blocky masses — largest ground silhouette below Tier 5 | `CHARCOAL_BLACK` (deep charcoal fur), `BONE` (pale scarring), `AMBER_EYESHINE` (small deep-set eyes, no glow) | Not yet built |
| Pale Sabertooth | 4 | Lean long-fanged big cat, narrow-waisted, oversized curved fangs | `FROST_HIDE` (near-white to pale bone-grey coat), `GLOW_VIOLET` (cold bioluminescent striping) | Not yet built |
| Dire Basilisk | 4 | Heavy low-slung reptile, frilled neck/skull crest | `STONE` (dull stone-grey scaled body), `TOXIN_GREEN` (flat sickly crest), `TOXIN_TEAL_GLOW` (throat pulse before strike — the tell) | Not yet built |
| Deepwater Leviathan-eel | 4 | Enormous ribbon-long eel, coiled beneath water, only scaled back breaking surface | `CHARCOAL_BLACK` (deep near-black hide), `GLOW_VIOLET` (row of teal-violet bioluminescent spots, reads even underwater) | Not yet built |
| Stonehide Gorehorn | 4 | Colossal plated rhino, flat armoured slabs, one massive horn-wedge — largest herbivore | `STONE_LIT` (weathered stone-grey), `GLOW_FUNGUS` (lichen-green staining at plate seams), no glow of its own | Not yet built |

#### Tier 5 — Apex

| Creature | Tier | Silhouette identity | Palette tokens | Status |
|---|---|---|---|---|
| The Gloom Tyrant | 5 | Towering broad-chested apex, dwarfs Gravemaw Ursine — scale endpoint of the whole roster | `CHARCOAL_BLACK` (near-total black hide), `GLOW_VIOLET` (crown of markings around head/shoulders) | Not yet built |
| Elder Marrowmother | 5 | Outsized scarred Marrow Hyena, heavy-shouldered, pale mane marking rank | `BONE` (mane) + `MARROW_YELLOW` (darker/more saturated bone-marrow blotching), `AMBER_EYESHINE` (commanding eye-glow) | Not yet built |
| Cavern Roc | 5 | Genuinely massive raptor, wingspan wider than most chambers | `RIDGE_BROWN` + `BONE` (deep ridge-brown and bone-cream plumage), `AMBER_EYESHINE` (visible before the shape is) | Not yet built |
| The Sunless Wyrm | 5 | Immense serpent-dragon, flat overlapping plates, never fully visible at once | `STONE_DARK`/`CHARCOAL_BLACK` (negative-space-dark hide), `GLOW_VIOLET` (violet-white veins that pulse like breathing) | Not yet built |
| Titan Molebeast | 5 | Colossal rounded burrower, near-architectural blockiness, massive shovel foreclaws | `FROST_HIDE` (pale subterranean grey-white), `AMBER_EYESHINE`-family dull glow-flecks (packed mineral dust on the claws) | Not yet built |
| The Hollow Stag | 5 | Tall still stag, antlers in deliberately clean geometry — keystone, not a predator, must not visually editorialize threat (§8.2) | `BONE` (hide), `GLOW_VIOLET`/near-white (constant calm glow along antlers and spine, the calmest light in the game) | Not yet built |

### 8.4 — Insect art requirements (10 species)

Per D2 (`docs/DECISIONS.md`): the five swarm/cloud insects are built as a single
lightweight particle/emitter entity per species, NOT an individual `Creature.gd`
instance — their art need is a small glowing motes/haze VFX treatment (think particle
shader + emission colour), not a modelled body. The other five are individually-pathed
`Creature.gd` instances and need real small bespoke silhouettes, same backlog status as
the 30 creatures above. All ten are currently **Not yet built** in either form.

| Insect | Implementation kind (D2) | Silhouette / VFX identity | Palette tokens | Status |
|---|---|---|---|---|
| Razorwing Wasp | Swarm/cloud emitter | Fast humming flying swarm; wings catch a thin red-amber shimmer | `WARN`/`EMBER` (red-amber wing shimmer), small particle motes not a body | Not yet built (no VFX exists) |
| Glowmite Swarm | Swarm/cloud emitter | Drifting cluster of tiny biters, each a pinprick of cold light | `GLOW_TEAL`/`GLOW_DIM` (dazzling pinprick motes) | Not yet built (no VFX exists) |
| Deathcap Gnat Cloud | Swarm/cloud emitter | Drifting gnat cloud around a haze of pale spores | `GLOW_FUNGUS`/`BONE`-pale (spore haze), desaturated | Not yet built (no VFX exists) |
| Corpsefly Cloud | Swarm/cloud emitter | Swarms carrion; no distinct glow, reads as a dark drifting mass | `CHARCOAL_BLACK`/`RUST_DUN` (dark drifting mass, dull not glowing) | Not yet built (no VFX exists) |
| Bloodtick Crawler | Swarm/cloud emitter (per D2, despite being a single-creature threat in prose) | Small, dark, unremarkable crawler — deliberately inconspicuous | `CHARCOAL_BLACK`/`GROUND` (unremarkable dark, no glow — the point is not being noticed) | Not yet built (no VFX exists) |
| Gravel Mantis | Individual `Creature.gd` | Camouflages against loose stone/rubble, holds still, bursts out | `STONE`/`RIDGE` (loose-stone camouflage mottling) | Not yet built |
| Venomfang Centipede | Individual `Creature.gd` | Long, fast, low profile — closes distance quickly for its size | `TOXIN_GREEN` (venom-gland accent), `CHARCOAL_BLACK` (segmented body) | Not yet built |
| Chitin Scuttler | Individual `Creature.gd` | Heavily armoured overlapping plated shell, slow-moving | `RIDGE`/`RUST_DUN` (hard plated shell), no glow | Not yet built |
| Spinneret Lurker | Individual `Creature.gd` | Large tunnel-dwelling spider, strings webbing across mouths/ceilings | `CHARCOAL_BLACK` (body), `BONE`/pale (webbing, near-white so it's readable against dark tunnels) | Not yet built |
| Cinder Beetle | Individual `Creature.gd` | Slow beetle, glowing belly, detonates on death into a burn radius | `EMBER`/`EMBER_VEIN` (glowing belly, the "about to detonate" tell) | Not yet built |

### 8.5 — Flora art requirements (3 trees, 10 fruit, 10 herbs)

**Trees (3 of 3 — Built.)** Glowcap Pillar-tree, Ironbark Deeproot, and Weeping
Palewillow all have real, distinct mesh factories in `src/world/Flora.gd`
(`glowcap_tree()`, `ironbark_tree()`, `palewillow_tree()`) matching §5.1's silhouette
identity exactly — tall+glowing, squat+heavy, drooping+pale+waterside respectively. No
further work needed at the silhouette level; treat as done.

**Fruit + herbs (8 of 20 — Built; 12 of 20 — Not yet implemented in code.)** Only 8 of
the full 20-species fruit/herb roster exist anywhere in code today, via
`Recipes.INGREDIENTS` and spawned by `Main.gd`: 4 fruit (Emberberry, Gloomgrape,
Bleedberry, Duskfig) and 4 herbs (Palethyme, Stoneleaf Rosemary, Deeproot Ginger,
Marrow Mint). Each gets a real silhouette via `Flora.forageable_visual()` — berry bushes
as colour-forward rounded mounds studded with `Palette.ingredient_color`-tinted dots,
herb clumps as texture-forward low spiky blade tufts (§5.2) — and already has a hex in
`Palette.INGREDIENT`. These are **Built** and need no further silhouette work; the only
open item is that they're visually generic within their category (any berry bush is the
same lobed-mound mesh regardless of species) — a lower-priority "give each of the 8 a
small bespoke silhouette variant" pass could follow once the missing 12 exist at all.

The other 12 species are fully specified in `docs/FOOD_WEB.md`/`docs/ITEMS.md` (flavour
text, mechanical effect, floor placement) but have **no code entry whatsoever** — absent
from `Recipes.INGREDIENTS`, never spawned, no `Palette.INGREDIENT` hex, no visual. Each
row below gives the visual starting point implied by its existing flavour/mechanical
text, so whoever wires it into code next inherits a colour/silhouette direction, not
just a mechanical one, and doesn't have to round-trip back to Lore for it.

#### Fruit — not yet implemented in code (6)

| Fruit | Silhouette / colour note (derived from FOOD_WEB.md / ITEMS.md) | Status |
|---|---|---|
| Frostplum | Cooling/heat-resist fruit — should read cool-toned against the warm `emberberry` it pairs against thematically; a pale frosted blue-violet berry, kin to `GLOW_BLUE`/`GLOW_VIOLET` rather than any warm ingredient hue. Berry-bush silhouette per §5.2. | Not yet implemented in code |
| Cavern Currant | "Not exciting, never has been" — the deliberately unremarkable filler fruit; small, dense-clustered, dull muted red-brown dots, the least saturated berry colour in the set so it never competes visually with the rarer fruits. Berry-bush silhouette. | Not yet implemented in code |
| Sourlantern | Citrus-bright toxin-cleanser — should be the single brightest, most saturated warm-yellow berry dot in the set ("citrus-bright and mean about it"), closer to `MARROW_YELLOW` than to any existing ingredient hue so it reads as sharp/cleansing rather than warm/cosy. Berry-bush silhouette. | Not yet implemented in code |
| Mossmelon | Water-rich hydration fruit — larger single-fruit silhouette rather than small clustered dots (it's described as being "cut open," implying size), pale translucent green-white kin to `WATER_EMISSION`/`GLOW_FUNGUS`. Likely needs its own bespoke large-fruit mesh rather than the standard small-dot berry-bush treatment. | Not yet implemented in code |
| Goldcap Gooseberry | Rare all-round-buff fruit — explicitly gold-skinned per flavour text; should be the single most saturated, brightest metallic-adjacent warm-gold dot in the whole ingredient set (still metallic 0.0 per §2.1, just very warm/bright albedo) so it reads as "rare find" at a glance. Berry-bush silhouette, sparse spawn density. | Not yet implemented in code |
| Thornapple | Toxic-raw fruit needing Sulfur Chive — flavour text ("every part of this plant is trying to tell you not to eat it") implies visible thorns/spikes breaking the berry-bush mound silhouette, plus a `TOXIN_GREEN`-family warning dot colour rather than an appetising berry hue — the one fruit that should NOT read as colour-forward-appealing per §5.2's usual rule. | Not yet implemented in code |

#### Herbs — not yet implemented in code (6)

| Herb | Silhouette / colour note (derived from FOOD_WEB.md / ITEMS.md) | Status |
|---|---|---|
| Cave Saffron | Rare buff-amplifier herb — flavour text ("three threads of this cost me a fight") implies a sparse, thread-thin, high-value silhouette; a saturated warm-red-orange thread colour, deliberately rarer-looking (fewer, thinner blades) than the standard herb-clump density. Herb-clump silhouette, sparse spawn. | Not yet implemented in code |
| Emberpepper | Fire-resistance herb — should sit visually in the `EMBER`/`FLAME`-adjacent warm family (the only herb allowed that close to the flame hue, mirroring `deeprootginger`'s exception for ingredients), reinforcing "this is the spicy/hot one." Standard herb-clump silhouette. | Not yet implemented in code |
| Gloomsage | Scent-lowering/calming herb — should read muted, dusty, low-saturation grey-green-violet (calm, not vivid), kin to `GLOW_DIM`/`stoneleaf` rather than anything bright — it's meant to help you go unnoticed, so the plant itself shouldn't visually shout either. Herb-clump silhouette. | Not yet implemented in code |
| Bittersalt Crystal | Preservative, not a buff-herb in the usual sense — flavour/mechanical text implies a literal mineral-crystal form rather than a leafy clump; pale, faceted, crystalline white-grey, kin to `RIDGE`/`BONE`. Likely needs its own small crystal-cluster mesh rather than the standard blade-tuft herb-clump treatment. | Not yet implemented in code |
| Sulfur Chive | Toxin-neutraliser, found "near sulfurous seeps" — should carry a faint acrid yellow-green tint (distinct from `TOXIN_GREEN`'s warning read — this is the *antidote*, not the poison, so keep it duller/muddier, closer to `stoneleaf`'s grey-green than to anything alarming). Standard herb-clump silhouette. | Not yet implemented in code |
| Dreamdill | Camp-rest-quality herb — flavour text ("the ceiling stops feeling so close overhead") implies a soft, airy, feathery-fine blade texture rather than the standard stiff blade tuft, pale cool violet-blue kin to `GLOW_DIM`, reinforcing a calming/soporific read. Herb-clump silhouette, finer/softer geometry than the standard clump. | Not yet implemented in code |

---

## 9. How code consumes this

- **`src/systems/style/Palette.gd`** is the single source of truth for every colour in
  the game — structure, glow, flame, water, flora, atmosphere, and ingredient accents.
  It is pure data (constants + one lookup helper); it has no dependency on rendering
  code and can be referenced from gameplay logic, UI, and materials alike.
- **`src/systems/style/MaterialLib.gd`** (owned by the Graphics agent) vends actual
  `StandardMaterial3D` resources built from `Palette` tokens per §2's material language —
  matte structure, emissive glow, the flame/light material, the water material, and, as of
  this pass, real 64×64 tileable textures (`assets/textures/*.svg`) for the stone/bark/
  foliage/water families. Gameplay and world-assembly code should ask `MaterialLib` for a
  material, not construct one inline.
- **`src/world/Flora.gd`** vends ready-to-place low-poly plant `Node3D`s (the three trees,
  berry bushes, herb clumps) built from primitives and tuned via `MaterialLib` — silhouette
  identity (§5) lives here in code, not just in this document.
- **The contract going forward:** any script that currently does (or is tempted to do)
  `Color(0.3, 0.8, 0.6)` inline — and today that's `Main.gd`, `Player.gd`, `Pickup.gd`,
  `Forageable.gd`, `Campfire.gd`, and `Creature.gd`, per a quick repo scan — should be
  migrated to reference `Palette.SOME_TOKEN` (or, once it exists, request a material from
  `MaterialLib`) instead. New code should never introduce a fresh hardcoded `Color(...)`
  literal for anything representing stone, glow, flame, water, flora, atmosphere, or an
  ingredient — extend `Palette.gd` and use the constant. This is what keeps five floors,
  thirty creatures, twenty flora types, and a UI system all speaking the same visual
  language without a single person hand-holding every hex code.

---

*This document supersedes `DESIGN_BIBLE.md` §7 for anything visual — treat that section
as the one-paragraph pitch and this document as the working detail. If the two ever
disagree, this document wins for execution; flag the Design Bible for a sync pass.*
