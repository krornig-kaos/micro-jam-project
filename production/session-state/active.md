# Active Session State

## Current Task
Level 1 scene refactor: reusable prop scenes + Ground layer fix
(`src/level_one/main.tscn`) — **COMPLETE**

## What Changed
- `src/level_one/main_test.tscn` (the more complete iteration, with
  Fox/Boar/Owl) became the new `src/level_one/main.tscn`. Old `main.tscn`
  and `main_test.tscn` removed.
- Fixed the broken triple-nested `Ground/Ground/Ground` TileMapLayer
  structure: now three sibling layers `Ground` (pos -2,-1), `GroundDetail`
  (pos -4,-2), and `GroundAccent` (pos -6,-3) under `Main`, sharing one
  deduplicated `tileset_ground`/`atlas_grass` TileSet. Removed the leftover
  `ground_fill.gd` script reference (it would have overwritten painted tiles
  at runtime).
- **Correction (2026-06-14)**: the innermost original Ground layer
  (519 chars of `tile_map_data`, ~30 painted tiles) was initially mistaken
  for empty and dropped during the refactor above. Recovered from
  `git show HEAD:src/level_one/main_test.tscn` and re-added as `GroundAccent`
  (pos -6,-3, `tileset_ground`, no script), drawn on top of `Ground`/
  `GroundDetail` to match the original stacking order.
- `Player` (+ `Camera2D`, limits 0,0,1152,648) moved to be a direct child of
  `Main` (was incorrectly nested under `Ground/Ground`).
- Extracted all 17 obstacles/decorations into reusable scenes under
  `src/props/`, plus a shared `HideSpot.tscn` stealth component
  (`Area2D`, `groups=["hide_spot"]`, instanced as a child of `CurvedTree1`).
- Added 8 new prop scenes to flesh out Level 1: `CurvedTree3`,
  `SwirlingTree1`, `LivingGazebo1`, `TreeIdolWolf`, `BrownRuins4`,
  `BrownGrayRuins2`, `BeigeGreenMushroom2`, `WhiteRedMushroom2`.
- New `main.tscn` instances all 25 props + Player + Fox/Boar/Owl under
  `Main`.
- Cleaned up dead prototype files from `src/level_one/`: `ground_fill.gd`
  (+`.uid`), `tile_map_layer.gd` (+`.uid`), `player.gd` (+`.uid`),
  `player.tscn`.
- Wrote `docs/architecture/adr-002-reusable-prop-scenes.md` (Accepted) —
  documents the prop-scene/HideSpot convention and the Ground fix.
- Updated `src/level_one/README.md` to describe the new scene structure.

## Verification
No `godot`/`godot4` CLI available — could not run a headless scene check.
Verified structurally: ext_resource/sub_resource counts (`load_steps=33`
unchanged), `tile_map_data` byte lengths preserved (47271 + 36023 + 519
chars across Ground/GroundDetail/GroundAccent), node tree order
(Ground → GroundDetail → GroundAccent → Player → props → Fox/Boar/Owl), and
all new asset UIDs cross-checked against their `.import` files. **Open
`src/level_one/main.tscn` in the Godot 4.6 editor to confirm it loads
without errors** (see ADR-002 Validation Criteria).

## Next Steps
- Open the editor, confirm Validation Criteria in ADR-002.
- Resume `/brainstorm` to lock pillars/MVP if not yet done (see below).
- Consider `/architecture-review` to register ADR-002 in the TR registry.

## Brainstorm Status
Concept brief paused mid-discovery (pillars/MVP not yet locked). Resume with
`/brainstorm` if needed — original concept: top-down forest survival/stealth,
blue rabbit/deer player, floating orb-spirits, weight-based slowdown,
Fox/Boar/Owl enemies, soul delivery to revive animals, 3s intangibility
power-up. Review mode: lean.

## Source Assets
- `design/assets/vegetation/Assets/` (128px trees, mushrooms, ent figures, gazebos)
- `design/assets/structures/Assets/` (112-128px ruins, 5 biome palettes)
