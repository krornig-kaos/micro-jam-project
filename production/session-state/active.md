# Active Session State

## Current Task
Concept prototype: **forest-movement** (`/prototype`)

## Hypothesis
If the player navigates a forest built from vegetation/structure tile assets
(collision on trees/ruins) and a carry-weight value scales movement speed down,
movement will feel like weaving through a living forest with mounting burden —
confirmed if a player can path through a cluster of 5+ obstacles at full speed,
then again "weighted," and notices a real maneuverability difference, not just
a number change.

## Riskiest Assumption
128px top-down assets, placed as collision obstacles at normal camera zoom, read
as navigable terrain (clear paths vs. blockers) rather than a flat asset dump —
and the weight-speed curve feels meaningfully different at low vs. high carry.

## Path
Engine (Godot 4.6, GDScript) — `prototypes/forest-movement-concept/`

## Scope
- Player CharacterBody2D, 8-directional top-down move
- Hand-placed forest patch: ~15-20 vegetation/structure sprites as StaticBody2D +
  CollisionShape2D obstacles, mixed sizes for path variety
- Debug input (+/- keys) simulates carried-orb count → speed = base / (1 + k*orbs)
- Simple top-down camera (fixed or basic follow)
- Cut: stealth/detection, enemies, orb pickups, soul delivery, intangibility,
  death/restart, UI, sound, TileMap

## Current Phase
Phase 6 — Playtest Debrief (awaiting user to run + report back)

## Files Written
- prototypes/forest-movement-concept/main.tscn (run this with F6) — hand-authored
  scene: Ground TileMapLayer (grass tiles, Tileset-Terrain2.png, 16x16, runtime
  fill via ground_fill.gd), Player instance, 12 obstacles (StaticBody2D +
  Sprite2D + CollisionShape2D, trunk-sized collision), 5 decorations (Sprite2D
  only). All nodes editable in 2D viewport.
- prototypes/forest-movement-concept/ground_fill.gd (fills Ground TileMapLayer
  with random plain-grass variants at _ready())
- prototypes/forest-movement-concept/player.tscn
- prototypes/forest-movement-concept/player.gd (movement, weight formula, debug HUD)
- prototypes/forest-movement-concept/README.md

## Note: TiledMap Editor / Props / Character Rigs
Deferred per user decision (lightweight option). The Tiled-format pack
(`design/assets/TiledMap Editor/`, `Props/`, NPC merchant + luck creature rigs)
is not imported — only Tileset-Terrain2.png's plain-grass tiles are used for
ground fill, with no autotile rules.

## Controls
Arrow keys = move (8-dir, MOTION_MODE_FLOATING). +/- (or numpad) = add/remove
carried orb (debug). HUD shows orb count + resulting speed (220 / (1+0.15*orbs)).

## Source Assets
- `design/assets/vegetation/Assets/` (128px trees, mushrooms, ent figures, gazebos)
- `design/assets/structures/Assets/` (112-128px ruins, 5 biome palettes)

## Brainstorm Status
Concept brief paused mid-discovery (pillars/MVP not yet locked). Resume with
`/brainstorm` after this prototype if needed — original concept details captured
in conversation: top-down forest survival/stealth, blue rabbit/deer player,
floating orb-spirits, weight-based slowdown, Fox/Boar/Owl enemies, soul delivery
to revive animals, 3s intangibility power-up. Review mode: lean.
