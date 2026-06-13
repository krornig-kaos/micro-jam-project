# AGENTS.md

## What This Repo Is

This is **Claude Code Game Studios (CCGS)** — a coordination framework of 49 agents, 73 slash-command skills, and 12 hooks for indie game development. It is NOT a game. It is the template that helps build games.

The game project being built with it is called "micro jam project" (Godot 4.6, C#).

## Critical: Engine Knowledge Gap

**Engine: Godot 4.6 (GDScript)**. LLM training data covers ~4.3 max. Versions 4.4–4.6 have breaking API changes the model does NOT know about.

**Before suggesting any Godot API call, check `docs/engine-reference/godot/` first.** Specifically:
- `VERSION.md` — knowledge gap timeline and risk levels
- `breaking-changes.md` — API changes between versions
- `deprecated-apis.md` — "don't use X → use Y" lookup

## Collaboration Protocol (Mandatory)

This system is user-driven collaborative, not autonomous. Every interaction follows:

**Question → Options → Decision → Draft → Approval → Write**

- Agents MUST ask clarifying questions before proposing solutions
- Agents MUST present 2–4 options with trade-offs
- Agents MUST get explicit user approval before writing any file
- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- No unilateral decisions. No autonomous file writes.

## Project Phase & Navigation

Current phase tracked in `production/stage.txt` (currently: **Concept**).

| Command | When to use |
|---------|-------------|
| `/start` | First session — routes to correct workflow path |
| `/help` | Anytime — reads phase + artifacts, tells you what to do next |
| `/gate-check <transition>` | Verify readiness to advance between phases |
| `/project-stage-detect` | Full audit when stage seems wrong |

Phase gates: `concept` → `systems-design` → `technical-setup` → `pre-production` → `production` → `polish` → `release`

## Directory Ownership

```
src/              → Game source code (currently empty — no game code yet)
design/gdd/       → Game Design Documents (8-section format required)
design/ux/        → UX specifications
docs/architecture/→ ADRs, architecture docs, control manifest, TR registry
docs/engine-reference/ → Version-pinned engine API snapshots
production/       → Sprint plans, epics, stories, session state
.claude/skills/   → Skill definitions (SKILL.md in subdirectories)
.claude/agents/   → Agent definitions (49 .md files)
.claude/hooks/    → Shell hooks (12 .sh files)
.claude/rules/    → Path-scoped coding rules (auto-applied by file extension)
```

Directory-scoped `CLAUDE.md` files exist in `src/`, `design/`, `docs/` — they provide path-specific instructions when agents work in those directories.

## Key Conventions

- **Commit format**: Conventional Commits — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`. Reference story ID in body.
- **Gameplay values**: Data-driven (external config files), never hardcoded
- **Public APIs**: Require doc comments
- **Tests**: Live in `tests/`, not `src/`. Run `/test-setup` to scaffold.
- **Every system**: Needs an ADR in `docs/architecture/`
- **GDDs**: Must include all 8 sections (Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria)
- **ADR lifecycle**: `Proposed` → `Accepted` → `Superseded`. Stories referencing `Proposed` ADRs are auto-blocked.

## Review Intensity Modes

Set in `production/review-mode.txt`. Controls how much director review runs:
- `full` — all director gates at every checkpoint (default for new projects)
- `lean` — directors only at phase gates
- `solo` — no director reviews (game jams, max speed)

Override per-run: `/brainstorm idea --review solo`

## Agent Hierarchy (3 Tiers)

```
Tier 1 (Directors):   creative-director, technical-director, producer
Tier 2 (Leads):       game-designer, lead-programmer, art-director, audio-director,
					  narrative-director, qa-lead, release-manager, localization-lead
Tier 3 (Specialists): gameplay/engine/ai/network/ui/tools-programmer, systems/level/economy
					  designer, world-builder, writer, technical-artist, sound-designer, etc.
```

Conflicts escalate vertically. Design → `creative-director`. Technical → `technical-director`. Scope → `producer`.

## Session Recovery

- `production/session-state/active.md` — living checkpoint (update after milestones)
- `pre-compact.sh` hook dumps state before compaction
- `session-start.sh` hook detects and previews `active.md` on session start
- After crash/compact: read `active.md` first

## Hooks (12, all automatic)

Key hooks agents should be aware of:
- `validate-commit.sh` — checks for design doc references, valid JSON, no hardcoded values
- `validate-push.sh` — warns on pushes to main/develop
- `validate-assets.sh` — checks asset naming and size
- `validate-skill-change.sh` — advises running `/skill-test` after `.claude/skills/` changes

All hooks use `grep -E` (never `grep -P` — breaks on Windows Git Bash). Must exit quickly (`exit 0`) when not applicable.

## Skill Testing Framework

`CCGS Skill Testing Framework/` — self-contained, optional. Tests the skills/agents themselves, not any game. Deletable without affecting the main framework.

Key commands: `/skill-test static [name]`, `/skill-test spec [name]`, `/skill-test audit`

## What's Not Set Up Yet

- Engine preferences in `.claude/docs/technical-preferences.md` (all fields say "TO BE CONFIGURED")
- No game source code in `src/`
- No tests directory
- No CI/CD pipeline
- No GDDs, ADRs, or architecture docs yet

Run `/start` to begin the guided onboarding flow.
