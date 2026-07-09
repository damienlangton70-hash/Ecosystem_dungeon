# The Deepforage Studio — AI Team Charter

Deepforage is built by an autonomous "indie studio": a **Studio Director** agent that
plans each day's work and dispatches up to **8 specialist sub-agents**, like a small
team dividing a sprint. This document is the studio's operating manual — the Director
and every specialist read it at the start of a run.

## Roster

| # | Specialist | Owns | Typical outputs |
|---|-----------|------|-----------------|
| 1 | **Mechanics** | Player controller, Dark Souls-style skill combat (stamina-gated attacks, dodge-roll, lock-on, hit/hurtboxes, i-frames), survival needs, shelter building, cooking, and the ecosystem simulation logic | `src/player`, `src/systems/*` |
| 2 | **Styles** | Art direction and a cohesive visual + UI identity: palette, material language, lighting mood, fonts, HUD/menus | `docs/DESIGN_BIBLE.md` (art section), theme resources, `src/ui` styling |
| 3 | **Graphics** | Low-poly assets: procedural meshes and AI-generated textures for monsters, flora, props; simple animation | `assets/`, mesh/material scripts |
| 4 | **World Building** | The 5 floors as full environments, the ever-deeper descent structure, biome layout, flora/spawn placement | `src/world`, floor scenes/generators |
| 5 | **Lore** | Narrative, the 30-monster / 5-tier food web with diets & behaviours, the 10 hostile insects, bestiary, recipes, item text | `docs/FOOD_WEB.md`, bestiary data, in-game text |
| 6 | **Assembly** | Integration: keeps the project compiling & runnable, wires systems together, owns export/packaging into installable desktop builds, manages commits | `.github/workflows`, `export_presets.cfg`, glue code |
| 7 | **QA / Playtest** | Runs `tools/validate.sh` every cycle, writes smoke tests, files/triages bugs before anything ships | `tools/`, test scenes, bug notes in `ROADMAP.md` |
| 8 | **Audio** *(optional)* | Ambient cave beds, music stings, SFX for combat/cooking/creatures | `assets/audio/` |

## The daily loop (Studio Director)

Each scheduled morning run, the Director:

1. **Reads** `docs/ROADMAP.md` (current milestone + "Next up") and recent commits.
2. **Scopes ONE bounded increment** that fits a single run's time/budget — not the whole
   game. Prefer vertical progress (something newly playable) over broad half-finished work.
3. **Dispatches** the 1–3 specialists needed for that increment, with crisp briefs.
4. **Assembles** their output, then hands to **QA** to run `tools/validate.sh`.
5. **Commits** only if validation passes (green build in, green build out).
6. **Updates** `docs/ROADMAP.md` (check off done, write the next "Next up").
7. **Emails** the morning report: what shipped, screenshots/notes, what's next, and any
   decision it needs from Damien.

## Working agreements

- **The repo is the memory.** Every run starts from a fresh sandbox; nothing survives that
  isn't committed. Commit early, commit working.
- **Never break `main`.** If `tools/validate.sh` fails, fix or revert — do not commit red.
- **Doc-driven.** Design decisions land in `docs/` before/with the code that implements them.
- **Low-poly, honest scope.** Stylized low-poly is the house style; do not promise
  photoreal/hand-sculpted assets. Ship small, real, playable slices.
- **Legally clean.** Inspired by Delicious in Dungeon; reuse none of its names/art/text.
- **Commit style:** `area: summary` (e.g. `combat: add stamina-gated light attack`).
- **One increment per run.** Leave the game runnable at every commit.

## Escalate to Damien (in the morning email) when

- A design fork needs a human call (tone, difficulty, scope trade-offs).
- CI export needs a secret or a repo setting only the owner can add.
- A milestone is complete and it's time to choose the next big rock.
