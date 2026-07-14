# Implementation Plan: Engine Lifecycle, Test-and-Handoff, and Adaptive Sync

**Branch**: `002-clickup-lifecycle` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-clickup-lifecycle/spec.md`

## Summary

Generalize the shipped ClickUp plug (`001-clickup-sync`) into **snackbyte-speckit-engine** — a
tracker-agnostic Spec Kit lifecycle engine — and extend it with: (US3) a six-state card lifecycle
(`open → in-design → ready → in-development → in-review → done`) that syncs on **every** Spec Kit
command, config-mapped to each list's real status names and falling back to three; (US1/US2/US8)
a post-implement verify command (`/speckit-verify`: recursive code review + full unit gate +
automatable E2E → earns `in-review`) and a terminal close-out command (`/speckit-close`: sign-off
→ final sync → commit → `done`); (US4) an AI-always-writes handoff where humans signal via the
flow, never the tracker; (US5) manual/light items safe by manifest-absence; (US6) commit
provenance on the card; (US7) agent-designed per-project rules; and (US9) consolidation of the
five snackbyte-authored lifecycle extensions into the one engine, with the recursive-review module
serving both spec and code targets.

**Technical approach**: Same shape as 001 and the other snackbyte extensions — this is
spec-workflow scaffolding, not application code. Deterministic logic (status derivation across six
states, config status-mapping + 3-fallback, manifest I/O, item classification, provenance
formatting) lives in `scripts/bash/*.sh` with `*.test.sh` unit coverage (Constitution V). The
non-deterministic tracker orchestration and the review/verify/close ceremonies live in markdown
command prompts. New lifecycle hooks (`after_specify`, `after_analyze`, `after_converge`) and two
new commands (`/speckit-verify`, `/speckit-close`) are wired in `.specify/extensions.yml`. The
engine consolidates the five snackbyte extensions as command-modules; the tracker-plug boundary is
kept clean so ClickUp is one plug behind an interface (the local/multi-plug realization is deferred
per the spec, but the seam is established here).

## Technical Context

**Language/Version**: Bash (POSIX-ish, matching the existing `.specify` scripts and the 001
helpers) for deterministic repo-side logic; Markdown command prompts executed by the coding agent;
YAML for extension + hook declarations. No compiled language, no Node runtime dependency for the
engine itself (the root `package.json` exists only to run the shell check gate).

**Primary Dependencies**: The connected **ClickUp MCP server** (tools `clickup_*`) for the ClickUp
plug's tracker I/O — no custom API/auth code (Constitution II). The core
`.specify/scripts/bash/common.sh` helpers (`get_feature_paths`, `has_jq`, `json_escape`,
`find_specify_root`). `jq` when available, with a documented no-jq fallback (the 001 pattern). The
five snackbyte extensions being consolidated (git-specify-branch, specify-review-loop,
analyze-autofix, git-commit, clickup-sync) as the modules' starting sources.

**Storage**: The committed per-feature manifest `specs/<feature>/.clickup-sync.json` (the ClickUp
plug's dedup index + target locator + status/hash record), extended for the six-state lifecycle and
provenance. The secret-free `config.yml` (space/list + the logical→actual status-name mapping). No
database.

**Testing**: The repo's shell gate — `npm run check:all` (shell-syntax lint + the `*.test.sh`
runner at `.specify/scripts/bash/run-tests.sh`). New deterministic helpers get `*.test.sh` coverage
in the 001 style (pure parsing/derivation/mapping/manifest logic, no live tracker calls). The
tracker-touching command orchestration (verify/close ceremonies, per-command sync, provenance) is
validated manually via `quickstart.md` against a real ClickUp workspace (MCP is not available
headlessly).

**Target Platform**: Developer workstation running the Spec Kit flow, with the ClickUp MCP server
connected when the ClickUp plug is active. Not deployed anywhere; not exercised by app CI.

**Project Type**: Spec Kit **engine** — a consolidated extension package (the engine + its
command-modules + the ClickUp plug) living entirely in spec-workflow scaffolding space.

**Performance Goals**: A no-op sync (no artifact change) MUST make zero tracker writes (SC-006). A
per-command status change writes only the status. The manifest hash keeps unchanged elements from
incurring any read/write — "every command syncs" stays cheap because the common case is a no-op.

**Constraints** (from the constitution): one-way, repo is source of truth (I); the engine core
never talks to a tracker directly — plugs own all tracker I/O (II); idempotent (III);
scaffolding-only, no tracker refs in shipped app source/docs/CI (IV); deterministic logic is tested
(V); plugs are additive — zero/one/many, an uninstalled plug is a no-op not an error (VI).

**Scale/Scope**: A single developer's repos. The shared list holds this repo's feature-cards plus
unrelated human/tooling cards the engine must never touch (safe by manifest-absence). Tens of
features per repo; a handful of user stories and up to a few dozen task lines per feature. Not
built for many concurrent users — resilient for one.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This feature specifies the engine that the v2.0.0 constitution governs, so the check is whether the
design honors its own principles.

| Principle | Assessment | Verdict |
|---|---|---|
| **I. One-Way, Repo Is Source of Truth** | Every state/content write is repo → tracker; the AI is the sole writer; no write-back into repo artifacts (FR-017/029). Close-out's sign-off is a flow input, not a tracker-driven write. | PASS |
| **II. Plugs Own All Tracker I/O** | The engine core stays tracker-agnostic; all ClickUp I/O goes through the ClickUp plug's MCP orchestration (FR-028). New deterministic logic is tracker-free. | PASS |
| **III. Idempotent** | Manifest-hash-driven create/update/skip; a no-op run makes zero writes; status-only changes write only status (FR-014, SC-006). | PASS |
| **IV. Scaffolding-Only** | Everything lives under `.specify/` + `.claude/` + per-feature manifests; no tracker reference leaks into shipped app source/docs/CI (FR-031). | PASS |
| **V. Deterministic Logic Is Tested** | Status derivation (6-state), status-mapping + 3-fallback, item classification, provenance formatting, manifest I/O go in `scripts/bash/` with `*.test.sh` (FR-030). Ceremonies stay in prompts, validated by quickstart. | PASS |
| **VI. Plugs Are Additive** | The tracker-plug interface is kept clean so ClickUp is one plug; the engine requires only "a plug." Local/multi-plug realization is deferred (spec), but the seam does not violate additivity. | PASS |

**Result: PASS, no violations.** Complexity Tracking left empty.

Two boundary notes carried into design:
- The engine's own files necessarily contain the string "ClickUp" (the plug, its README, config) —
  allowed, because they live in scaffolding space; the prohibition (IV) is on ClickUp leaking into
  **shipped** app source/docs/CI.
- The local plug + multi-plug broadcasting are specified (FR-032/SC-013) but their full
  implementation is deferred by the spec; this plan establishes the interface seam without building
  the local plug, which is consistent with VI (an absent plug is a no-op).

## Project Structure

### Documentation (this feature)

```text
specs/002-clickup-lifecycle/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions on the 6-state model, hook wiring, consolidation shape
├── data-model.md        # Phase 1 — extended manifest + config schema, state machine, entities
├── quickstart.md        # Phase 1 — validate the full lifecycle against a real ClickUp workspace
├── contracts/           # Phase 1 — command + hook + module contracts
│   ├── verify.command.md
│   ├── close.command.md
│   ├── sync.command.md          # extended: 6-state, per-command, provenance
│   ├── provision.command.md     # extended: card born in `open`, status-name mapping
│   ├── status-model.md          # the 6 logical states, mapping, 3-fallback
│   ├── config.schema.md         # config: space/list + logical→actual status mapping
│   ├── manifest.schema.md       # manifest: 6-state status, provenance, hashes
│   └── engine-modules.md        # consolidation: the 5 modules + review module (2 targets)
├── checklists/
│   └── requirements.md   # (present from specify/clarify)
└── tasks.md              # Phase 2 (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

The delivered artifact is the consolidated engine package: the ClickUp plug (extended), the new
verify/close commands, the new hook wiring, and the five consolidated command-modules.

```text
.specify/
├── extensions.yml                              # wire new hooks: after_specify, after_analyze,
│                                               #   after_converge; register verify + close commands
├── extensions/
│   └── clickup-sync/                           # the ClickUp plug (extended)
│       ├── extension.yml                        # declare new commands + hook slots
│       ├── config.yml                           # + logical→actual status-name mapping (6→3)
│       ├── commands/
│       │   ├── speckit.clickup.provision.md      # card born in `open`; resolve status mapping
│       │   ├── speckit.clickup.sync.md           # 6-state, per-command, provenance
│       │   ├── speckit.verify.md                 # NEW — review + gate + E2E → in-review (US8)
│       │   └── speckit.close.md                  # NEW — sign-off → final sync → commit → done (US2)
│       └── scripts/bash/
│           ├── clickup-derive-status.sh          # extend: 6 logical states (card) + 3 (subtasks)
│           ├── clickup-manifest.sh               # extend: 6-state status, provenance, hashes
│           ├── clickup-parse-tasks.sh            # (reused as-is)
│           ├── clickup-status-map.sh             # NEW — logical→actual mapping + 3-fallback
│           ├── clickup-provenance.sh             # NEW — git log → card provenance (Option A)
│           └── *.test.sh                         # unit tests for every new/changed helper
├── memory/constitution.md                       # v2.0.0 (already updated)
└── README.md                                    # engine overview (already written)

# Consolidated command-modules (US9) — the five snackbyte extensions become engine modules,
# co-located as flat sibling packages under .specify/extensions/, wired by one extensions.yml
# (resolved in research.md Decision 1: one repo + one registry, not a merged monolith).
.specify/extensions/
├── clickup-sync/          # the ClickUp plug (extended above)
├── git-specify-branch/    # setup: clean tree + feature branch (before_specify)
├── specify-review-loop/   # recursive review — generalized to spec OR code target (US9 FR-037)
├── analyze-autofix/       # apply unambiguous artifact fixes (after_analyze)
└── git-commit/            # checkpoint commit (before_implement / close-out reuse)

.claude/skills/
├── speckit-clickup-provision/SKILL.md           # (present)
├── speckit-clickup-sync/SKILL.md                # (present)
├── speckit-verify/SKILL.md                      # NEW mirror
└── speckit-close/SKILL.md                       # NEW mirror
```

**Structure Decision**: Keep the proven 001 package shape (`extension.yml` + `commands/*.md` +
`scripts/bash/*.sh` + `.claude/skills/*/SKILL.md` mirrors + `.specify/extensions.yml` wiring).
Deterministic logic stays in shell helpers (testable without a live tracker); command prompts own
the ceremonies and MCP orchestration. The exact module layout for US9 consolidation (one engine
package exposing many command-modules vs. co-located sibling packages) is resolved in Phase 0
research, because it is the one genuine structural fork.

## Complexity Tracking

> No Constitution violations — this section intentionally left empty.
