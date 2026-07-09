# Deepforage

*A subterranean survival-cooking game, inspired by the spirit of **Delicious in Dungeon** — descend an ever-deeper dungeon, hunt a living animal food-chain, cook what you catch on campfires and magic circles, build shelter, and survive an ecosystem that remembers how you treat it.*

> **Working title.** "Deepforage" is a placeholder — easy to rename.
> **Built by an autonomous studio.** This repo is developed by a small team of AI
> agents (a "Studio Director" plus specialists) that commit a little every day.
> A human progress report is emailed each morning.

---

## Status

**Milestone M0 — Foundation (complete).** Cloning the repo and pressing Play gives you a
walkable, descending cavern with a third-person controller, a live survival stat
(hunger/stamina), a depth read-out, and the code skeletons for the ecosystem and
survival systems. Everything is deliberately low-poly/procedural so specialist
agents can replace stubs without scene-merge pain.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for what's next.

---

## Run it (2 minutes)

1. Install **[Godot 4.3](https://godotengine.org/download)** (standard edition; no C#/.NET needed).
2. Clone this repo:
   ```bash
   git clone https://github.com/damienlangton70-hash/Ecosystem_dungeon.git
   cd Ecosystem_dungeon
   ```
3. Open **Godot → Import → select this folder's `project.godot` → Play (F5)**.

**Controls:** `WASD` move · `Shift` sprint · `Space` jump · mouse look · `Esc` release cursor.

## Build a desktop installer

- **Automatic:** every push to `main` runs [`.github/workflows/build.yml`](.github/workflows/build.yml),
  which validates the project and (once export templates are confirmed) uploads Windows/Linux
  builds as workflow artifacts.
- **Manual:** in Godot, `Project → Export`, add the Windows/Linux/macOS presets, and export.

## Validate locally (what CI and the QA agent run)

```bash
GODOT=/path/to/godot ./tools/validate.sh .
```
Passes only when there are no real script/runtime errors (it ignores the harmless
headless `Parameter "m" is null` renderer noise).

---

## Repository layout

```
deepforage/
├─ project.godot            # Godot 4.3 project config
├─ icon.svg                 # app icon
├─ export_presets.cfg       # desktop export presets (CI + manual)
├─ src/
│  ├─ game/                 # Main.tscn + Main.gd (bootstrap, world assembly)
│  ├─ player/               # Player.gd (controller; grows into skill combat)
│  ├─ systems/
│  │  ├─ survival/          # hunger/stamina/temperature, cooking buffs
│  │  └─ ecosystem/         # Species + Ecosystem sim, over-hunting hostility
│  └─ ui/                   # HUD and menus (grows over time)
├─ assets/                  # textures/audio/models (added by Graphics/Audio agents)
├─ docs/                    # the design bible and living plans (read these!)
├─ tools/                   # validate.sh and build helpers
└─ .github/workflows/       # CI: validate + export
```

## The design docs (start here)

| Doc | What it covers |
|-----|----------------|
| [`docs/DESIGN_BIBLE.md`](docs/DESIGN_BIBLE.md) | Vision, pillars, systems, floors, art direction, tech |
| [`docs/FOOD_WEB.md`](docs/FOOD_WEB.md) | The 30-monster / 5-tier food chain, insects, flora, over-hunting rules |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones, current status, next steps, risks |
| [`docs/AGENT_TEAM.md`](docs/AGENT_TEAM.md) | The AI studio: who does what, the daily loop, working agreements |

---

*Deepforage is an original work inspired by the tone of Delicious in Dungeon (Ryoko Kui).
It reuses none of that work's characters, names, art, or text.*
