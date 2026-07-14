# Quickstart / Validation: Engine Lifecycle

Proves the engine end-to-end against a **real** ClickUp workspace (the MCP server isn't available
in headless CI, so tracker-touching validation is manual; the deterministic helpers are covered by
`*.test.sh`). Each scenario maps to the success criteria it demonstrates.

## Prerequisites
- ClickUp MCP server connected; a scratch list you can create cards in.
- The engine installed: `.specify/extensions/clickup-sync/` present and the five modules wired in
  `.specify/extensions.yml` (US9).
- `config.yml` filled: real `space`/`list` + the `statuses:` mapping (six logical → actual).

## Setup
```bash
npm run check:all      # shell lint + every *.test.sh (deterministic helpers) — must be green
```

## Scenario 1 — Card born in `open`, advances on every command (US3 / SC-005)
Provision a feature, then run the lifecycle commands in turn.
**Expect**: card created in `open` at provision; then `in-design` (specify) → `ready` (tasks/analyze)
→ `in-development` (implement/converge). An observer sees the card move on **every** command, not
just late ones. A status-only change makes zero content writes (SC-006).

## Scenario 2 — 3-fallback on a reduced list (US3 / SC-011)
Point `config.yml` at a list with only three statuses.
**Expect**: the six logical states collapse onto the three (nearest-status), the sync reports the
degradation, and no run fails.

## Scenario 3 — `/speckit-verify` earns `in-review` (US8 / SC-014)
On a completed, green feature run `/speckit-verify`.
**Expect**: recursive code review runs, the unit gate runs (must pass), automatable E2E runs, and
only then the card advances to `in-review`. **Negative**: with a red gate or an unresolved review
finding, verify stops and the card stays `in-development` (never `in-review`).

## Scenario 4 — `/speckit-close` reaches `done` (US2 / SC-003, SC-004, SC-012)
From `in-review`, run `/speckit-close`.
**Expect**: it re-runs the gate (red → refuses, SC-012), surfaces manual tasks and waits for
sign-off (never auto-checks, SC-003), then on sign-off marks tasks done, syncs the card to `done`,
and commits the close-out in a distinct commit while the sync itself makes zero commits (SC-004).

## Scenario 5 — AI owns the tracker, zero human edits (US4 / SC-007)
Drive a feature `open → … → in-review → done` using only Spec Kit commands + sign-off in the flow.
**Expect**: the AI writes every status; at no point does a human edit the tracker.

## Scenario 6 — Manual item untouched (US5 / SC-008)
Create a card by hand (no feature manifest) in the shared list; run a sync.
**Expect**: the manual item is never derived, overwritten, or counted; spec-driven cards in the same
list are still reconciled.

## Scenario 7 — Commit provenance, idempotent (US6 / SC-009)
After a feature's commits exist, run the provenance step.
**Expect**: the card shows the feature's commits; re-running adds no duplicate links.

## Scenario 8 — Consolidated spine + review module two targets (US9 / SC-015)
In a clean repo with the engine installed, run the lifecycle.
**Expect**: the five modules (branch-setup, review, analyze-autofix, commit checkpoint, ClickUp
plug) are all available from the one engine; the review module runs against the spec (after specify)
and the code (inside verify); `agent-context` is untouched and still installable alongside.

## Scenario 9 — Zero/one/many plugs (US-cross / SC-013, deferred realization)
> Interface-seam check only — the local/multi-plug machinery is deferred (Decision 7). Confirm the
> engine's tracker calls route through the plug interface (so a second plug could slot in), and that
> with the ClickUp plug's `enabled: false`, the lifecycle still runs (sync is a no-op, not an error).

## Reference
- Command behavior: [contracts/](contracts/) (verify / close / sync / provision).
- State machine + mapping: [contracts/status-model.md](contracts/status-model.md).
- Manifest & config shapes: [data-model.md](data-model.md).
- Consolidation + plug seam: [contracts/engine-modules.md](contracts/engine-modules.md).
- Design rationale: [research.md](research.md).
- Carried-over 001 negative path (SC-007 provision fail-loud) — exercise the degenerate-list case
  here (see spec Assumptions).
