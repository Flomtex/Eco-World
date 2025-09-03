# Eco-World (Godot 4.4.1)

A small, deterministic-friendly ecosystem simulation built in **Godot 4.4.1 (Forward+)**.
Creatures and plants live on a grid. All grid logic flows through `Scenes/Map/TerrainMap.gd` (no direct GridMap poking from agents). We add features as tiny “vertical slices” (e.g., “thirst → find water → drink”), one at a time.

**Docs:** Official Godot GDScript — https://docs.godotengine.org/en/stable/
**Repo:** https://github.com/Flomtex/Eco-World

---

## What it is / will be
- A tile-based eco-sim: simple agents, simple rules, emergent behaviors.
- Terrain is a `GridMap`; agents move **cell-by-cell** (snapped via `cell_to_world`).
- Over time: multiple plant types, herbivores, carnivores, needs (energy/water), and light AI.

---

## What’s done so far
- Project scaffolding (`Main.tscn`, `EcoMap3D/GridMap`, free camera rig).
- Terrain API (`TerrainMap.gd`) that exposes: `world_to_cell`, `cell_to_world`, `neighbors4`, `is_walkable_cell`, etc.
- **Plant-Food v0.1 (complete):**
  - `Scenes/Plant/Plant.tscn` + `Plant.gd` (edible, ground-snapped with scene default **Y Offset = +0.5** for the current mesh).
  - `Scenes/Plant/PlantSpawner.gd` spawns only on **walkable cells adjacent to rock**.
  - Randomized layout per run (`randomize_on_ready`), with an optional seed for reproducible tests.
  - `Plant.consume()` removes the instance and **respawns elsewhere** after a small delay.
  - Minimal changes in `TerrainMap.gd`: `is_rock_cell()` and `pick_spawn_cell_near_rock()` (rock IDs are inspector-configurable).

**Last completed slice:** *Plant-Food v0.1 — next-to-rock spawn, random per run, consume + timed respawn.*

---

## Run it
1. Open the project in **Godot 4.4.1**.
2. Open `Scenes/Main/Main.tscn`, press **Play**.
3. You’ll see plants spawned on valid cells. No player input; it’s a simulation.

> If plants appear too high/low, adjust the **Y Offset** on `Plant.tscn` (currently `+0.5` for this mesh/cell setup).

---


---

## Dev notes
- **Grid contract:** all placement/pathing uses `TerrainMap.gd`. Don’t call `GridMap` directly from agents.
- **Determinism:** use per-system RNG with explicit seed when testing; use `randomize()` for natural runs.
- **Performance posture:** fixed/timer ticks for agents; prefer small searches (neighbors4, bounded BFS). Scale up with simple occupancy maps if needed.
- **Godot version:** 4.4.1 stable.

---

## Roadmap / next tasks (tick these off as you commit)
### Creature – Foraging vertical slice
- [ ] Creature has **energy** and a simple **hunger** tick.
- [ ] **Grid scan** for nearby plants (bounded radius).
- [ ] **Path** to nearest plant (shortest path over walkable cells).
- [ ] On arrival (same cell), **consume()** and gain energy.
- [ ] **Wander** when nothing is found (per-creature RNG).

### Plant – Small refinements
- [ ] Tune spawn density & `respawn_delay`.
- [ ] Optional: basic growth stages (visual only).
- [ ] Optional: distribution bias (e.g., prefer multiple next-to-rock sides).

### Terrain / Systems
- [ ] Confirm/adjust **rock IDs** via inspector on `GridMap`.
- [ ] Add a tiny **cell→entity index** for O(1) lookups (when we need scale).
- [ ] Seed/save snapshot (serialize RNG seed + placements).

### Debug / Tools
- [ ] On-screen counters (plants alive, creature energy).
- [ ] Toggle deterministic seed vs randomized runs.

---

## Contributing / workflow (you, future you)
- Keep changes **small and vertical** (something we can watch in-engine).
- Commit messages like: `Creature: add hunger tick + grid-scan(3) + eat on arrival`.
- Respect the contract: **Terrain rules live in `TerrainMap.gd`**.

---

## License
TBD (MIT suggested for code; check licenses for any external assets).



## Live file links (for ChatGPT viewing)
<!-- CODEMAP:START
## Full code map
_Auto-generated list of raw links._

# CODEMAP
All raw links for ChatGPT viewing.
https://raw.githubusercontent.com/Flomtex/Eco-World/main/.gitattributes
https://raw.githubusercontent.com/Flomtex/Eco-World/main/CODEMAP.md
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/.editorconfig
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/.gitattributes
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/.gitignore
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/Plant_1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_A_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_B_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_C_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_D_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_E_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_F_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/Bush_1_G_Color1.bin
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/simple_small_plant_fr_0831023843_texture.mtl
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/simple_small_plant_fr_0831023843_texture.obj
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/simple_small_plant_fr_0831023843_texture.obj.import
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/simple_small_plant_fr_0831023843_texture.png
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Assets/Models/SimplePlant/simple_small_plant_fr_0831023843_texture.png.import
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/Brains/CreatureBrainWander.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/Brains/CreatureBrainWander.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/Creature.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/Creature.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/Creature.tscn
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureDebug.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureDebug.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureMover.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureMover.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureSense.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/CreatureSense.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/GridPath.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Creature/GridPath.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Main/CameraRig.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Main/CameraRig.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Main/Main.tscn
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Main/PlantSpawner.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Main/PlantSpawner.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Map/EcoMap3D.tscn
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Map/EcoMap3d.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Map/EcoMap3d.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Map/TerrainMap.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Map/TerrainMap.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Plant/Plant.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Plant/Plant.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Scenes/Plant/Plant.tscn
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Tools/GenerateEcoGrid.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Tools/GenerateEcoGrid.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Tools/MakeEcoMeshLibrary.gd
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/Tools/MakeEcoMeshLibrary.gd.uid
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/icon.svg
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/icon.svg.import
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/lib/EcoTiles.tres
https://raw.githubusercontent.com/Flomtex/Eco-World/main/Eco-world/project.godot
https://raw.githubusercontent.com/Flomtex/Eco-World/main/MOST_IMPORTANT_INFORMATION+MUST_USE!!.md
https://raw.githubusercontent.com/Flomtex/Eco-World/main/README.md

< CODEMAP:END -->

