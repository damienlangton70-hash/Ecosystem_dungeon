# Deepforage — Design Bible

The single source of truth for *what Deepforage is*. Specialist agents align to this;
changes here are design decisions and should be deliberate.

---

## 1. Vision

You are a lone delver descending a dungeon that is not a set of rooms but a **living
underground wilderness**. It gets deeper, darker, and stranger the further you go. There
are no shops and no rations waiting for you — you survive by **hunting the dungeon's own
animals, foraging its fruit and herbs, and cooking what you gather** over campfires and
arcane cook-circles. The creatures are animals, not monsters-of-the-week: they eat each
other in a real food chain, and if you strip-mine one species the whole ecosystem turns
against you. Combat is deliberate and skill-based; a careless swing gets you killed. The
fantasy is *competent, hungry survival in a beautiful, dangerous deep.*

## 2. Inspiration & legal distinctness

Deepforage takes its **tone and central conceit** — descending a dungeon while cooking
and eating its monsters — from **Delicious in Dungeon (Ryoko Kui)**. It uses **none** of
that work's characters, names, recipes, art, or text. All species, places, items, and
lore in Deepforage are original. Where the source leans comedic-wholesome, Deepforage
leans **survival-tense with warm cooking beats** — the meal is the reward for surviving.

## 3. Design pillars

1. **The dungeon is an ecosystem, not a level.** Animals have diets, populations, and
   memory. Your choices ripple.
2. **You eat to descend.** Hunger is the clock; cooking is the core reward loop.
3. **Every fight is a decision.** Dark Souls-style: stamina, spacing, commitment, i-frames.
   Trash mobs can kill you; you can avoid most fights.
4. **Down is the only way.** A continuous sense of descent — deeper = colder, darker,
   deadlier, richer.
5. **Consequence over punishment.** Over-hunting, waste, and noise change the world; the
   game reacts rather than scolds.

## 4. Core loop

```
        ┌─────────────────────────────────────────────┐
        │  Explore a floor (descending)                │
        │      ↓ spot animals / forage flora           │
        │  Hunt (skill combat) or avoid                │
        │      ↓ carry raw ingredients                 │
        │  Make camp: shelter + fire/magic circle      │
        │      ↓ cook → restore hunger, gain buffs     │
        │  Read the ecosystem's reaction               │
        │      ↓ (over-hunted? everything's hostile)   │
        │  Find the descent shaft → go deeper ─────────┘
```

Short loop: *spot → hunt/forage → cook → recover*. Long loop: *survive a floor → descend →
harder biome, new food web*.

## 5. Systems

### 5.1 Descent & World
- The dungeon is **one continuous downward journey**; the player starts near the surface and
  the map trends **down** the whole game. Each of the **5 floors** is a full, distinct
  environment ending in a **descent shaft** to the next.
- Floors get **darker** (less ambient, more reliance on fire/glow flora), **colder** (ties to
  temperature survival), and **deadlier** (higher food-web tiers).
- Implementation: authored low-poly environments with light procedural scatter for flora and
  props; a shared "descent shaft" prefab links floors and preserves the down-only feeling.

### 5.2 Combat (skill-based, Dark Souls-like)
- **Stamina-gated.** Attacks, dodges, and sprinting drain stamina; empty stamina = vulnerable.
- **Dodge-roll with i-frames**, directional; commitment on attacks (you can't cancel freely).
- **Lock-on** to a target; light/heavy attacks; poise/hitstun; hurtboxes & hitboxes.
- **Weapons as tools:** some weapons harvest cleaner meat (butchery quality → better food).
- **Readability:** clear tells on enemy attacks; positioning and patience beat button-mashing.

### 5.3 Survival
- **Hunger** is the master clock (drains over time and with exertion). Starvation drains health.
- **Stamina** governs combat/traversal; regenerates when not exerting; cooked food can buff it.
- **Thirst** (M3) from water sources.
- **Body temperature** (M3): colder as you descend; fire, shelter, and hot food warm you.

### 5.4 Shelter & Cooking
- **Camp anywhere reasonable.** Build:
  - **Tent** (quick, portable; light rest, minor warmth),
  - **Den** (dug/found; sturdier, better rest, hides you from wandering animals),
  - **Campfire** (cook + warmth + light — but noise/attention),
  - **Magic circle** (arcane cook-point: cook without an open flame → quieter, no smoke;
    unlocked later; ties to lore of the deep).
- **Cooking** turns raw ingredients into meals: restore hunger, grant **buffs** (warmth,
  stamina regen, resistances) based on ingredients (meat + herb/spice + fruit). Bad combos or
  raw/toxic items cause penalties. Recipes are discoverable.

### 5.5 Ecosystem & Over-hunting  *(the signature system)*
- Each species has a **population**, a **diet** (what it eats), **aggression**, and
  **awareness** (how easily it detects you). See `FOOD_WEB.md`.
- Predators hunt prey; if prey collapses, predators starve, roam wider, and get desperate.
- **Over-hunting one species raises global hostility.** As hostility rises:
  - animals **notice you from further away** (awareness multiplier),
  - they are **more aggressive** and more likely to attack rather than flee,
  - packs form; ambushes increase; the floor feels "stirred up".
- Code hooks already exist: `Ecosystem.record_kill()`, `global_hostility`,
  `aggression_multiplier()`, `awareness_multiplier()`.
- **Design intent:** reward *sustainable* hunting and *avoidance*; punish greed without a
  nagging UI — the world's mood is the feedback.

### 5.6 Flora & Foraging
- **3 tree types**, **10 fruit/berry bushes**, **10 herb/spice types** (full list in
  `FOOD_WEB.md`). Flora is biome-placed and also part of the food web (many animals eat it).
- Foraging is low-risk food + cooking ingredients; over-foraging can also stress herbivores.

## 6. The Five Floors (overview)

| Floor | Name (working) | Mood | Food-web tiers present |
|------:|----------------|------|------------------------|
| 1 | Fungal Shallows | Dim, mossy, luminous fungi, first water | Tier 1–2 |
| 2 | The Rootways | Ironbark roots, tangled dens | Tier 1–3 |
| 3 | The Sunless Marsh | Wet, foggy, bioluminescent pools | Tier 2–4 |
| 4 | The Bonefields | Dry, cold, predator territory, remains | Tier 3–4, apex signs |
| 5 | The Maw | Vast, dark, primeval — apex domain | Tier 4–5 |

Detail is owned by the World Building + Lore agents; see `FOOD_WEB.md` for the ecology.

## 7. Art direction (house style)

- **Stylized low-poly**, readable silhouettes, chunky forms — an honest, achievable indie look
  (think a hand-crafted, painterly PS2-era clarity, not photoreal).
- **Palette:** deep desaturated stone and shadow, punctuated by **warm firelight** and
  **cold bioluminescence** (teal/violet glow flora, amber flame). Light *is* the art.
- **Materials:** flat-ish, low-spec, gentle roughness; color and light do the work.
- **Texture pipeline:** AI-generated tileable textures + vertex color; the Styles agent keeps a
  consistent palette; the Graphics agent produces meshes/props to match.
- **UI:** minimal, diegetic-leaning; a delver's journal aesthetic for the bestiary/recipes.

## 8. Audio direction
- Low, resonant cave ambience per floor; sparse, warm music that swells at camp/cooking.
- Meaty, weighty combat SFX; distinct creature vocalizations that telegraph aggression.

## 9. Tech stack & architecture
- **Engine:** Godot 4.3, GDScript. Native desktop export (Windows/Linux/macOS).
- **Why:** free, text-based scenes/scripts (AI-friendly + version-control-friendly), light.
- **Conventions:** systems under `src/systems/*` as self-contained nodes/resources; the world is
  assembled in `src/game/Main` (procedural now, authored scenes as they arrive); prefer
  composition and small scripts; keep `main` runnable at every commit.
- **QA:** `tools/validate.sh` runs headless import + boot smoke-test and gates CI.

## 10. Glossary
- **Delve / descent shaft** — the down-connection between floors.
- **Cook-point** — campfire or magic circle where cooking happens.
- **Hostility** — global 0..1 ecosystem agitation from over-hunting.
- **Tier** — trophic level 1 (grazers) → 5 (apex) in the food web.
