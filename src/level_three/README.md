# Level 1 — Forest Scene

## Overview
`main.tscn` is the first real level scene: a top-down forest area built from
three hand-painted ground layers, reusable prop scenes, the player, and three
enemy types (Fox, Boar, Owl).

## How to Run
1. Open `main.tscn` in the Godot 4.6 editor.
2. Press F6 (Run Current Scene).
3. Controls (see `src/player.gd`):
   - Arrow keys / WASD (`ui_left/right/up/down`): move (8-directional)
   - `Shift`: sprint
   - `C`: hold to enter stealth (hide when inside a `HideSpot`)
   - Input action `powerup_intangible`: brief intangibility

## Scene Composition
`Main` (`Node2D`, `y_sort_enabled = true`) contains:
- **Ground** / **GroundDetail** / **GroundAccent** (`TileMapLayer`):
  hand-painted grass tiles from `design/assets/Tilesets/Tileset-Terrain2.png`,
  sharing one `tileset_ground`/`atlas_grass` `TileSet`. `GroundAccent` is a
  small detail layer (~30 tiles) drawn on top of the other two. Tile data is
  baked into `tile_map_data` — there is no runtime fill script.
- **Player** (instance of `src/player.tscn`, production `src/player.gd`)
  with a child **Camera2D** (limits `0,0,1152,648`).
- **25 reusable prop instances** from `src/props/` — see below.
- **Fox**, **Boar**, **Owl** (instances of `src/Fox.tscn`, `src/Boar.tscn`,
  `src/Owl.tscn`).

## Reusable Props (`src/props/`)
Every obstacle and decoration is its own scene, instanced here with a
`position` override only (scale/collision tuning is baked into the prop):

- **Obstacles** (`StaticBody2D` + `Sprite2D` + `CollisionShape2D`):
  `CurvedTree1`, `CurvedTree2`, `CurvedTree3`, `MegaTree1`, `Willow1`,
  `LightBallsTree1`, `LuminousTree1`, `SwirlingTree1`, `WhiteTree1`,
  `TreeIdolDeer`, `TreeIdolWolf`, `LivingGazebo1`, `BrownRuins1`,
  `BrownRuins2`, `BrownRuins4`, `BrownGrayRuins1`, `BrownGrayRuins2`,
  `BrownGrayRuins3`.
- **Decorations** (`Sprite2D` only, no collision): `BeigeMushroom1`,
  `BeigeGreenMushroom2`, `WhiteRedMushroom1`, `WhiteRedMushroom2`,
  `Chanterelles1`, `Chanterelles2`, `Chanterelles3`.
- **HideSpot.tscn**: shared stealth component (`Area2D` in
  `groups=["hide_spot"]` + `CollisionShape2D`). `CurvedTree1` includes one
  as a child — entering it while holding `C` lets `src/player.gd` enter
  `State.STEALTH` (`is_hidden()` becomes true).

To add a new prop: create a `.tscn` under `src/props/` following the same
pattern, then instance it here with `instance=ExtResource("...")` and a
`position`. See `docs/architecture/adr-002-reusable-prop-scenes.md` for the
full convention and the Ground-layer fix history.

## Status
In progress — Level 1 layout populated with reusable props and enemies.

## Findings
TBD — pending playtest.
