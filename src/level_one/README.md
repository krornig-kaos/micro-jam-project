# Forest Movement Concept Prototype

## Hypothesis
If the player navigates a forest built from vegetation/structure tile assets
(collision on trees/ruins) and a carry-weight value scales movement speed down,
movement will feel like weaving through a living forest with mounting burden —
confirmed if a player can path through a cluster of 5+ obstacles at full speed,
then again "weighted," and notices a real maneuverability difference, not just
a number change.

## How to Run
1. Open `main.tscn` in the Godot 4.6 editor.
2. Press F6 (Run Current Scene).
3. Controls:
   - Arrow keys: move (8-directional)
   - `+` / `-` (or numpad +/-): add/remove a carried orb (debug)
   - HUD shows orb count and current speed: `220 / (1 + 0.15 * orbs)`

## World Layout
`main.tscn` is hand-authored — every obstacle and decoration is a real node,
fully editable in the 2D viewport:
- **Ground** (TileMapLayer): grass tiles from `design/assets/Tilesets/Tileset-Terrain2.png`
  (16x16 atlas, 4x4 block of plain-grass variants at atlas coords (38-41, 10-13)).
  No autotile rules — `ground_fill.gd` fills the play area at runtime by randomly
  picking one of the 16 grass variants per cell. Open the TileSet in the Inspector
  to add more tiles to the palette and paint manually in the editor if desired.
- **Obstacles** (StaticBody2D + Sprite2D + CollisionShape2D): trees, ruins —
  drag to reposition, resize the collision shape via its gizmo handles, or
  swap the `texture` field in the Inspector. 12 placed: Curved_tree1/2,
  Mega_tree1, Willow1, Light_balls_tree1, Luminous_tree1, White_tree1,
  Tree_idol_deer, Brown_ruins1/2, Brown-gray_ruins1/3.
- **Decorations** (Sprite2D only, no collision): mushrooms + chanterelles —
  purely visual, drag freely. 5 placed: Beige_green_mushroom1,
  White-red_mushroom1, Chanterelles1/2/3.
- Root `Main` node has `y_sort_enabled = true` for top-down depth.

Collision boxes are sized to each sprite's trunk/base, not the full canopy, so
the player can walk close to and visually pass behind tall trees — groundwork
for the later hide-behind-obstacles stealth mechanic (not implemented yet).

## Status
In progress.

## Findings
TBD — pending playtest.
