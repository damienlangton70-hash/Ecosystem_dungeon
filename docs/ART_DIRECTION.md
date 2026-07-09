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

## 7. How code consumes this

- **`src/systems/style/Palette.gd`** is the single source of truth for every colour in
  the game — structure, glow, flame, water, flora, atmosphere, and ingredient accents.
  It is pure data (constants + one lookup helper); it has no dependency on rendering
  code and can be referenced from gameplay logic, UI, and materials alike.
- **`src/systems/style/MaterialLib.gd`** (owned by the Graphics agent, not yet written)
  will vend actual `Material`/`ShaderMaterial` resources built from `Palette` tokens per
  §2's material language — the shared toon-ramp-plus-rim stylized material, the emissive
  glow material, the flame/light material, the water material, and so on. Gameplay and
  world-assembly code should ask `MaterialLib` for a material, not construct one inline.
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
