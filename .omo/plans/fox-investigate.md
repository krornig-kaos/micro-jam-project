# Work Plan: Fox Investigate State

## Goal
Enhance the existing `Fox.gd` enemy by replacing the instant give-up behavior with an "Investigate" state. When losing track of the player, the Fox will run to the player's last known position, wait for a configurable duration (default 3 seconds), and only then return to its patrol route.

## Scope
**IN SCOPE:**
- Modifying `src/Fox.gd`.
- Adding `INVESTIGATE` to the state machine.
- Adding exported variables for tuning the investigate behavior.
- Handling re-detection during the investigation phase.

**OUT OF SCOPE:**
- Modifying other enemies (Boar, Owl).
- Modifying the player's stealth mechanics.
- Adding complex pathfinding (A*) if not already present (Fox currently uses basic directional movement).

## Guardrails & Assumptions
- **Data-Driven Values**: The 3-second wait must be exported (`@export var investigate_duration: float = 3.0`) to comply with project rules.
- **Re-detection**: If the player is spotted again while the Fox is investigating, it must instantly revert to the `CHASE` state.
- **Animations**: While moving to the last position, the Fox will use its `run` animation. While waiting at the spot, it will use its `idle` (or similar standing) animation.

## TODOs

- [x] 1. `src/Fox.gd`: Add `INVESTIGATE` to State enum. Add `@export var investigate_duration: float = 3.0`. Add state variables `var _last_known_position: Vector2` and `var _investigate_timer: float = 0.0`. - expect variables ready for use.
- [x] 2. `src/Fox.gd`: Update `_on_detection_exited` and `on_player_stealthed` to transition to `State.INVESTIGATE`, save `_player.global_position` into `_last_known_position`, and reset `_investigate_timer` to `investigate_duration`. - expect Fox to enter investigate mode instead of patrol.
- [x] 3. `src/Fox.gd`: Implement `_do_investigate(delta: float)` in `_physics_process`. Move towards `_last_known_position` at `chase_speed` with `run` animation. If distance < 10.0, stop moving, play `idle`/`walk` animation (depending on availability), and countdown `_investigate_timer`. When timer <= 0, transition to `State.PATROL`. - expect Fox to run to spot, wait, and return.
- [x] 4. `src/Fox.gd`: Ensure re-detection works. Update `on_player_stealthed(false)` and `_on_detection_entered` to override `INVESTIGATE` and transition immediately to `State.CHASE`. - expect immediate reaction if player is spotted again.

## Final Verification Wave
- [~] F1. Visual QA: Trigger the Fox, run out of its range, verify it runs to where you disappeared.
- [~] F2. Visual QA: Trigger the Fox, enter stealth (`C` key / hide spot), verify it runs to where you hid.
- [~] F3. Visual QA: Verify it waits at the spot for exactly `investigate_duration` seconds, playing an idle animation, before resuming patrol.
- [~] F4. Visual QA: Verify that if you un-stealth or re-enter its radius while it's investigating, it immediately resumes chasing.