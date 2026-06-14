# ADR-002: Reusable Prop Scenes, HideSpot Component, and Ground Layer Composition

## Status

Accepted

## Date

2026-06-14

## Last Verified

2026-06-14

## Decision Makers

- Sisyphus-Junior (Executor)

## Summary

This ADR establishes the convention that level decoration objects (trees,
ruins, mushrooms, etc.) are authored as standalone reusable scenes under
`src/props/` and instanced into level scenes, rather than defined inline.
It also extracts the stealth "hide spot" mechanic into a shared
`src/props/HideSpot.tscn` component, and documents the structural fix to
`src/level_one/main.tscn`'s Ground TileMapLayer hierarchy (flattened from a
broken triple-nested structure, with the leftover prototype fill script
removed).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Scene Composition / 2D |
| **Knowledge Risk** | MEDIUM — `TileMapLayer` is a post-cutoff node type |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | `TileMapLayer` (split out from `TileMap` in 4.3+, refined in 4.4–4.6) |
| **Verification Required** | Open `src/level_one/main.tscn` in the Godot 4.6 editor — confirm TileSet/TileMapLayer references resolve, painted tiles render unchanged, and no broken resource warnings appear |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Reuse of `src/props/*.tscn` and `HideSpot.tscn` in future level scenes (Level 2+) |
| **Blocks** | None |
| **Ordering Note** | Independent of ADR-001 (scene transitions) |

## Context

### Problem Statement

`src/level_one/main.tscn` and its near-duplicate `src/level_one/main_test.tscn`
had grown through repeated editor "duplicate node" operations:

- 12 obstacle `StaticBody2D`s and 5 decorative `Sprite2D`s were defined inline
  as one-off nodes with no reuse path.
- The "Ground" `TileMapLayer` had been duplicated into a broken triple-nested
  `Ground/Ground/Ground` hierarchy, with a duplicated `TileSet` sub-resource
  (`atlas_grass`/`tileset_ground` vs. `TileSetAtlasSource_5yx2l`/`TileSet_okjjw`,
  both registering the same 844 tiles from `Tileset-Terrain2.png`).
- A leftover prototype script, `ground_fill.gd` (random-grass `_ready()` fill,
  marked "PROTOTYPE - NOT FOR PRODUCTION"), was still attached to all three
  Ground copies. Since `_ready()` runs regardless of scene-root status, this
  would have silently overwritten the hand-painted `tile_map_data` with random
  grass at runtime.
- `Player` (and its `Camera2D` child) was accidentally reparented under
  `Ground/Ground` during these duplication operations.

### Current State

`main_test.tscn` was the more complete iteration (it includes `Fox`, `Boar`,
and `Owl` enemy instances) and is promoted to become the canonical
`src/level_one/main.tscn`. The old `main.tscn` and `main_test.tscn` are
removed. All 17 obstacle/decoration nodes plus the stealth hide-spot were
inline, non-reusable nodes.

### Constraints

- Godot 4.6, GDScript (`src/CLAUDE.md`): public APIs need doc comments,
  gameplay values must be data-driven, DI over singletons.
- Solo/micro-jam timeline — refactor must not block Level 1 progress.
- `src/player.gd` (the production player script) already implements
  `_on_hide_spot_entered`/`_on_hide_spot_exited`/`is_hidden()` against
  `groups=["hide_spot"]` — this contract must remain intact.

### Requirements

- Trees, structures, and decorations must be defined once and reused across
  level scenes.
- The stealth hide-spot must be a drop-in component, not duplicated per-tree.
- Ground tile data must render correctly and must not be overwritten at
  runtime.
- The level scene must retain `Fox`/`Boar`/`Owl` enemies and `Player` +
  `Camera2D`.

## Decision

1. **Reusable prop scenes** — every obstacle/decoration is extracted into a
   standalone `.tscn` under `src/props/` (format=3), containing the
   `StaticBody2D`/`Sprite2D` root plus `CollisionShape2D` where applicable,
   with the original position/scale/collision tuning baked in as the
   scene's default transform. 25 prop scenes now exist: 17 carried over from
   the original level (`CurvedTree1`, `CurvedTree2`, `MegaTree1`, `Willow1`,
   `LightBallsTree1`, `LuminousTree1`, `WhiteTree1`, `TreeIdolDeer`,
   `BrownRuins1`, `BrownRuins2`, `BrownGrayRuins1`, `BrownGrayRuins3`,
   `BeigeMushroom1`, `WhiteRedMushroom1`, `Chanterelles1`, `Chanterelles2`,
   `Chanterelles3`) plus 8 new ones added to flesh out Level 1
   (`CurvedTree3`, `SwirlingTree1`, `LivingGazebo1`, `TreeIdolWolf`,
   `BrownRuins4`, `BrownGrayRuins2`, `BeigeGreenMushroom2`,
   `WhiteRedMushroom2`).

2. **HideSpot component** — the stealth hide-spot is extracted into
   `src/props/HideSpot.tscn`: an `Area2D` in `groups=["hide_spot"]` with a
   `CollisionShape2D` (`CircleShape2D`, radius 8.246211). It is instanced as
   a child of any prop the player should be able to hide in/behind
   (currently `CurvedTree1`).

3. **Instancing pattern** — level scenes instance props via
   `[node name="X" parent="." instance=ExtResource("...")]` plus a
   `position` override only. No per-instance `scale` override is needed
   since scale is baked into the prop's `Sprite2D`.

4. **Ground layer flattening** — `src/level_one/main.tscn`'s three real
   painted `TileMapLayer`s become siblings `Ground` (pos `(-2,-1)`),
   `GroundDetail` (pos `(-4,-2)`), and `GroundAccent` (pos `(-6,-3)`)
   directly under `Main`, in that draw order, sharing one deduplicated
   `tileset_ground`/`atlas_grass` `TileSet`. Each position is the compound
   transform of the original nested layer's offsets (e.g. `GroundAccent`'s
   `(-6,-3)` = three stacked `(-2,-1)` offsets), preserving the original
   visual stacking. The duplicate `TileSet_okjjw`/`TileSetAtlasSource_5yx2l`
   sub-resources are dropped (identical 844-tile registration to
   `tileset_ground`). The `script = ground_fill.gd` reference is removed
   from all three layers.

5. **Player reparenting** — `Player` (with its `Camera2D` child, limits
   `0,0,1152,648` unchanged) becomes a direct child of `Main` instead of
   `Ground/Ground`.

### Architecture

```
Main (Node2D, y_sort_enabled)
├── Ground         (TileMapLayer, tileset_ground)  pos (-2, -1)
├── GroundDetail   (TileMapLayer, tileset_ground)  pos (-4, -2)
├── GroundAccent   (TileMapLayer, tileset_ground)  pos (-6, -3)
├── Player          (instance src/player.tscn)     pos (108, 45)
│   └── Camera2D                                   limits 0,0,1152,648
├── <25 prop instances from src/props/*.tscn>
│   └── CurvedTree1 → HideSpot (instance, groups=["hide_spot"])
├── Fox   (instance src/Fox.tscn)
├── Boar  (instance src/Boar.tscn)
└── Owl   (instance src/Owl.tscn)
```

### Key Interfaces

```gdscript
# Instancing a reusable prop with a position override
[node name="CurvedTree1" parent="." instance=ExtResource("p01")]
position = Vector2(600, 200)
```

```gdscript
# src/props/HideSpot.tscn — shared stealth component
[gd_scene load_steps=2 format=3]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 8.246211

[node name="HideSpot" type="Area2D" groups=["hide_spot"]]

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
```

### Implementation Guidelines

1. New props always go in `src/props/`, format=3 `.tscn`, named in
   PascalCase after the source asset (e.g., `Curved_tree3.png` →
   `CurvedTree3.tscn`).
2. Any prop the player can hide behind/in gets a `HideSpot.tscn` child
   instance positioned over its collision shape.
3. Reference props from level scenes via `path=` (no `uid=` required —
   Godot assigns one on first editor save).
4. Never attach prototype fill scripts to production `TileMapLayer` nodes —
   ground painting is authored once in the editor and baked into
   `tile_map_data`.

## Alternatives Considered

### Alternative 1: Keep props inline per level

- **Description**: Leave each tree/ruin as a one-off node, duplicated into
  every level that needs it.
- **Pros**: No upfront refactor cost.
- **Cons**: Duplication compounds with each new level; tuning a shared
  asset (e.g., a collision box) requires editing every instance — this is
  exactly the pattern that produced the triple-nested Ground bug.
- **Estimated Effort**: None now, growing cost later.
- **Rejection Reason**: Violates DRY and directly caused the bug this ADR
  fixes.

### Alternative 2: Single "PropLibrary" scene with hidden variant children

- **Description**: One scene holding every prop as a disabled child,
  duplicated into levels via script at runtime.
- **Pros**: Single file to browse.
- **Cons**: Non-idiomatic; awkward editor workflow; harder diffs; no benefit
  over per-prop scenes plus `ExtResource` instancing, which Godot already
  supports natively.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Godot's scene-instancing model already solves
  reuse; a library scene adds indirection without benefit.

## Consequences

### Positive

- 25 reusable prop scenes are available for Level 2+ — drag-and-drop reuse
  with no duplication.
- `HideSpot` is now a one-line addition to any future hideable prop.
- The Ground random-grass overwrite bug is fixed.
- `Player`/`Camera2D` are correctly parented under `Main`.

### Negative

- 26 new small files to maintain under `src/props/`.
- Per-instance position tuning now requires opening the level scene (props
  no longer carry a level-specific position — this is the intended
  separation).

### Neutral

- `src/level_one/main_test.tscn` is removed; its content lives on as the
  new `main.tscn`.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Prop scene `uid` collision on first editor save | Low | Low | No manual `uid` was set on the new prop scenes; Godot assigns one on save, avoiding collisions. |
| `GroundDetail`/`GroundAccent` offsets (`-4,-2`/`-6,-3`) do not visually match the original nested compound offsets | Low | Medium | Offsets were computed to preserve the original compound transform; verify visually in the editor (Validation Criteria). |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Scene file size (`main.tscn`) | ~115KB (`main_test.tscn`, 3 Ground layers + duplicate TileSet) | ~99KB (3 Ground layers, deduplicated TileSet) | N/A |
| Draw calls (Ground layers) | 3 TileMapLayers | 3 TileMapLayers | N/A |
| Runtime tile overwrite bug | Present (`ground_fill.gd._ready()` on 3 layers) | Removed | N/A |

## Migration Plan

- `src/level_one/main_test.tscn` deleted; `src/level_one/main.tscn` rebuilt
  from its content with the structural fixes above.
- Dead prototype files removed: `src/level_one/ground_fill.gd` (+`.uid`),
  `src/level_one/tile_map_layer.gd` (+`.uid`), `src/level_one/player.gd`
  (+`.uid`), and `src/level_one/player.tscn` (a wrapper scene with no
  purpose other than hosting the dead `player.gd`).

## Validation Criteria

- [ ] Open `src/level_one/main.tscn` in the Godot 4.6 editor with no broken
      resource errors.
- [ ] `Ground`/`GroundDetail`/`GroundAccent` render the same painted tiles as before
      (visual match against the pre-refactor screenshot).
- [ ] `Player` spawns at the correct position; `Camera2D` limits unchanged
      (`0,0,1152,648`).
- [ ] Entering `CurvedTree1`'s `HideSpot` triggers `src/player.gd`'s stealth
      state (`is_hidden()` returns `true`).
- [ ] `Fox`/`Boar`/`Owl` are present and positioned as before.
- [ ] All 25 prop instances render at their correct positions and scales.

## GDD Requirements Addressed

Foundational — no Level 1 GDD exists yet. Enables: future level scenes
(e.g., `src/level_two/`) to reuse `src/props/*.tscn` and `HideSpot.tscn`
without re-authoring assets.

## Related

- [ADR-001: Scene Transition Mechanism](adr-001-scene-transitions.md)
- `src/level_one/README.md`
