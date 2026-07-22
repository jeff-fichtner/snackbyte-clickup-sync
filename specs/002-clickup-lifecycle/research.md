# Phase 0 Research: Engine Lifecycle

The spec is fully clarified (0 `[NEEDS CLARIFICATION]` markers), so this phase records the design
decisions the plan depends on rather than resolving open unknowns. Each decision follows
Decision / Rationale / Alternatives.

## Decision 1: US9 consolidation shape — co-located modules under the ClickUp plug's package, not a new umbrella package

- **Decision**: Consolidate the five snackbyte extensions by co-locating them as command-modules
  inside this repo's `.specify/extensions/`, keeping each as its own module directory
  (`git-specify-branch/`, `specify-review-loop/`, `analyze-autofix/`, `git-commit/`, and the
  existing `clickup-sync/`), all registered through the one `.specify/extensions.yml`. "One engine"
  is realized as **one repo + one registry that wires them as a single lifecycle spine**, not by
  physically merging five packages into one directory.
- **Rationale**: The five extensions already share an identical package shape (`extension.yml` +
  `commands/*.md` + optional `scripts/bash/`), are self-contained (no cross-references beyond
  README prose), and the ecosystem already treats `.specify/extensions.yml` as the unifying
  registry. Co-locating + one-registry gets "install the engine, get the whole spine" with minimal
  churn and keeps each module independently testable and later-extractable. Physically merging into
  a single package directory would blur module boundaries and make the recursive-review module
  harder to point at two targets cleanly.
- **Alternatives considered**: (a) A single monolithic `engine/` package containing all commands —
  rejected: blurs boundaries, larger blast radius, harder to keep modules independently swappable.
  (b) Leave them as five separate installed extensions with no unification — rejected: that is the
  status quo the consolidation is meant to end. (c) A new top-level package that `requires` the
  five — rejected: adds a dependency layer the Spec Kit extension model doesn't need.

## Decision 2: The recursive-review module serves two targets via a target parameter

- **Decision**: Generalize `specify-review-loop` into a single review module whose command prompt
  takes a **target**: `spec` (review `spec.md`, the existing behavior, invoked after specify) or
  `code` (review the implemented code + tests, invoked inside `/speckit-engine-verify`). One prompt, one
  recursive-review pattern, branch on target for what it reads and what "fixable" means.
- **Rationale**: FR-037 requires one implementation, two invocation points. The recursion,
  fix-unambiguous-then-reloop, and stop-when-nothing-fixable logic are target-independent; only the
  artifact read and the fix surface differ. A parameterized prompt keeps the logic in one place.
- **Alternatives considered**: Two separate review commands sharing a copied prompt — rejected:
  duplicates the pattern, the thing FR-037 forbids.

## Decision 3: Six-state derivation extends the existing 001 status helper

- **Decision**: Extend `derive-status.sh` to emit the six card-level logical states from
  observable repo state + the triggering command, and keep subtasks on the existing three-state
  derivation. Card state is a function of "furthest lifecycle command run" (tracked via artifact
  presence + a recorded lifecycle marker), not just checkbox counts: no spec → `open`; spec present
  → `in-design`; tasks/analyze done → `ready`; implement done → `in-development`; `/speckit-engine-verify`
  passed → `in-review`; `/speckit-engine-close` signed off → `done`.
- **Rationale**: 001 already derives status from artifact presence + checkbox counts; the six-state
  model is the same idea widened. Keeping subtasks three-state matches FR-016 (subtasks are units
  of work). Deriving from observable state preserves idempotence (re-running yields the same state).
- **Alternatives considered**: Store the state explicitly in the manifest and advance it
  imperatively per command — rejected as the primary mechanism: it risks drift from repo reality
  and breaks "re-derive on every command." A recorded marker is used only where artifact presence
  alone can't distinguish (e.g. verify-passed vs. not), never as the sole source of truth.

## Decision 4: Config carries the logical→actual status mapping; provision resolves it; 3-fallback is deterministic

- **Decision**: `config.yml` gains a `statuses:` block mapping each of the six logical states to the
  list's actual status name. Provision resolves/validates it against the real list (via
  `clickup_get_list`), and a new `status-map.sh` helper applies the mapping and the
  fall-back-to-three collapse deterministically (unit-tested). A logical state with no distinct
  actual status collapses to the nearest of not-started / in-progress / done.
- **Rationale**: Constitution's config-only-retargeting constraint + FR-015. Putting the mapping in
  config (not code) keeps retargeting a config edit. Making the collapse a tested pure function
  keeps the non-deterministic MCP prompt thin (Constitution V).
- **Alternatives considered**: Hardcode the mapping to this repo's list — rejected: violates
  config-only retargeting and the "names differ per list" requirement.

## Decision 5: New hooks + two commands wired in extensions.yml; verify/close are user-invoked

- **Decision**: Add `after_specify` → sync (`in-design`), `after_analyze` → sync (`ready`),
  `after_converge` → sync (stays `in-development`) to `.specify/extensions.yml`, alongside the
  existing `after_plan`/`after_tasks`/`after_implement`. `/speckit-engine-verify` and `/speckit-engine-close` are
  **user-invoked commands** (not automatic hooks) with skill mirrors, because both are human-paced
  (verify is a deliberate certification pass; close waits for sign-off).
- **Rationale**: FR-013/013b (every command syncs) + FR-011 (close is a distinct command) + US8
  (verify is a distinct command that earns `in-review`). Matches the established registry schema
  (enabled/optional/priority/prompt) already in `.specify/extensions.yml`.
- **Alternatives considered**: Make verify/close automatic hooks — rejected: they wait on human
  judgment, which no fixed hook moment can time (same rationale the spec gives for close).

## Decision 6: Provenance is Option A (git log → card via MCP), idempotent; Option B is a documented opt-in

- **Decision**: Implement provenance as a tested `provenance.sh` that renders the feature's
  git log into a canonical block, pushed to the card via the ClickUp plug's MCP orchestration
  (comment or body section), deduped by hash so re-runs add nothing. Option B (native GitHub
  integration) is documented as opt-in only; when opted in, Option A stands down (FR-024a).
- **Rationale**: Option A is self-contained, needs no remote, matches the one-way model, and the
  card-created-at-provision change (FR-013a) means the task ID exists before commits — the old
  ordering snag is gone.
- **Alternatives considered**: Build Option B now — rejected: needs a remote + message convention;
  deferred to opt-in per the spec.

## Decision 7: Local plug + multi-plug are deferred; only the interface seam is established

- **Decision**: This feature keeps ClickUp as the single concrete plug but factors the engine's
  needs behind a documented tracker-interface boundary (resolve-target / create-update-item /
  set-checklist / link-dependency / update-status / attach-provenance) so a second plug *could*
  slot in. The built-in local plug and many-at-once broadcasting (FR-032/SC-013) are **not built**
  in this feature — the seam is, the machinery isn't.
- **Rationale**: Matches the user's "build it resiliently for me, not for hypothetical setups"
  guidance and the constitution's additivity principle (an absent plug is a no-op). Establishing the
  seam is cheap insurance; building the local/multi realization is not needed yet.
- **Alternatives considered**: Build the local plug now — deferred as premature. Hard-weld ClickUp
  with no seam — rejected: throws away the engine reframe.
