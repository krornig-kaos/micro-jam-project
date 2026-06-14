# ADR-001: Scene Transition Mechanism

## Status

Accepted

## Date

2026-06-13

## Last Verified

2026-06-13

## Decision Makers

- Sisyphus-Junior (Executor)

## Summary

This ADR establishes the use of Godot's built-in `get_tree().change_scene_to_file()` method for transitioning between the game's initial scenes (Boot Screen, Main Menu, and Credits). It prioritizes engine idiomaticity and implementation simplicity for the current Concept phase.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | HIGH — Post-cutoff version |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Verify scene cleanup on transition |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Menu System implementation |
| **Blocks** | None |
| **Ordering Note** | None |

## Context

### Problem Statement

The "Spirit Hope" project requires a reliable way to move the player between different high-level game states represented as scenes (e.g., transitioning from the Boot Screen to the Main Menu). Without a defined mechanism, implementation might diverge into inconsistent or overly complex patterns.

### Current State

The project is in the Concept phase with no existing scene management code.

### Constraints

- **Technical**: Must be idiomatic to Godot 4.6.
- **Timeline**: Rapid development for the micro jam project.
- **Complexity**: Current scope only involves 3-4 simple scenes.

### Requirements

- Must transition from Boot Screen to Main Menu.
- Must transition from Main Menu to Credits stub.
- Must be easy to implement and maintain.

## Decision

We will use `get_tree().change_scene_to_file(path: String)` for all scene transitions. 

This method is the standard Godot way to replace the current scene with a new one loaded from the filesystem. It handles the removal of the old scene and the instantiation of the new one automatically.

### Architecture

```
[ Current Scene ] --( get_tree().change_scene_to_file() )--> [ New Scene ]
        |                                                        |
        v                                                        v
 [ Free from Tree ]                                       [ Added to Tree ]
```

### Key Interfaces

```gdscript
# Standard transition call
get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
```

### Implementation Guidelines

1. **Path Constants**: Store scene paths in a global `Paths` script or as constants within the calling class to avoid magic strings.
2. **Visual Polish**: If a fade is required, the current scene should play a fade-out animation (using a `CanvasLayer` and `Tween`) before calling the transition method.
3. **Error Handling**: While `change_scene_to_file` returns an `Error` code, for the current scope, we will rely on standard engine behavior unless specific failure cases are identified.

## Alternatives Considered

### Alternative 1: Custom SceneManager Autoload

- **Description**: A global singleton that manages loading, instantiating, and transitioning between scenes with built-in fade support.
- **Pros**: Centralized control, reusable transitions.
- **Cons**: Overkill for 3 scenes, adds extra boilerplate.
- **Estimated Effort**: Low-Medium.
- **Rejection Reason**: Excessive complexity for the current minimal scope. We can upgrade to this if the game grows.

### Alternative 2: Manual Node Management

- **Description**: Using `add_child()` and `remove_child()` on a root node to swap scenes manually.
- **Pros**: Maximum control over the transition process.
- **Cons**: Error-prone, ignores built-in engine convenience, requires manual state management.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Not idiomatic for simple full-screen scene swaps.

## Consequences

### Positive

- Zero boilerplate: uses the engine's built-in functionality.
- Well-documented: developers familiar with Godot will immediately understand the mechanism.
- Clean state: Godot handles freeing the previous scene's memory.

### Negative

- No built-in transition control: each scene must handle its own entry/exit effects.
- No scene caching: scenes are reloaded from disk each time.

### Neutral

- Scene paths are hardcoded strings by default (mitigated by using constants).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Scene load stutters | Low | Medium | Use `ResourceLoader.load_threaded_request` if scenes become heavy (future ADR). |
| Transition logic duplication | Medium | Low | Use a shared `TransitionLayer` scene if multiple scenes need the same fade effect. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A | < 1ms (trigger) | 16.6ms |
| Memory | 0MB | Peak during load | 512MB |
| Load Time | 0s | < 100ms | 1s |

## Migration Plan

No existing code to migrate.

## Validation Criteria

- [ ] Transition from Boot to Menu works without errors.
- [ ] Transition from Menu to Credits works without errors.
- [ ] Previous scenes are correctly removed from the SceneTree (verified via Remote tab).

## GDD Requirements Addressed

Foundational — no GDD requirement. Enables: Main Menu navigation and Boot Screen flow.

## Related

- [Main Menu GDD (Future)]
- [Boot Screen GDD (Future)]
