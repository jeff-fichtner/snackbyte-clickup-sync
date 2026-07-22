---
description: "Task list for the Engine Lifecycle feature"
---

# Tasks: Engine Lifecycle, Test-and-Handoff, and Adaptive Sync

**Input**: Design documents from `specs/002-clickup-lifecycle/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included for the deterministic repo-side bash helpers — **required by Constitution V**
(all deterministic logic carries `*.test.sh` coverage that passes before commit). The
tracker-touching command/ceremony orchestration is validated manually via quickstart.md against a
real ClickUp workspace (MCP is not available headlessly), not by automated tests.

**Organization**: Grouped by user story. This is a Spec Kit **engine** package — everything lives
under `.specify/extensions/`, `.claude/skills/`, and `.specify/extensions.yml` (see plan.md
"Project Structure"), not a `src/` app.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US9); Setup/Foundational/Polish carry no story label
- Exact file paths included in every task

## Path Conventions

- ClickUp plug: `.specify/extensions/clickup/`
- Helpers + tests: `.specify/extensions/clickup/scripts/bash/*.sh` (+ `*.test.sh`)
- Command prompts: `.specify/extensions/clickup/commands/*.md`
- Consolidated modules: `.specify/extensions/{git-specify-branch,specify-review-loop,analyze-autofix,git-commit}/`
- Skill mirrors: `.claude/skills/speckit-*/SKILL.md`
- Hook wiring: `.specify/extensions.yml`

---

## Phase 1: Setup

**Purpose**: Confirm the package baseline before extending it.

- [X] T001 Verify the check gate is green (`npm run check:all`) and the existing ClickUp plug
      helpers pass, establishing the baseline this feature extends
- [X] T002 [P] Add the six-state + provenance fields to the config/manifest **example** docs by
      reconciling `.specify/extensions/clickup/config.yml` comments with
      `specs/002-clickup-lifecycle/data-model.md` (no logic yet — placeholders + comments only)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The consolidated engine structure + shared deterministic helpers every story depends
on. **US9 consolidation is the structural foundation** (research Decision 1); the shared helpers
(status derivation across six states, status mapping + 3-fallback, manifest extensions) are used by
every ClickUp-facing story.

**⚠️ CRITICAL**: No user-story command work begins until these exist and their tests pass.

### US9 consolidation (structural foundation)

- [X] T003 [US9] Co-locate the four snackbyte modules into this repo by copying
      `git-specify-branch/`, `specify-review-loop/`, `analyze-autofix/`, `git-commit/` from
      `snackbyte-base/.specify/extensions/` into `.specify/extensions/` (clickup-sync already present),
      preserving each package's shape per contracts/engine-modules.md
- [X] T004 [US9] Register all five modules + their hook rows in `.specify/extensions.yml`
      (before_specify → git-specify-branch; after_specify → specify-review-loop; after_analyze →
      analyze-autofix; before_implement → git-commit; plus the existing clickup-sync rows), matching
      the canonical schema (enabled/optional/priority/prompt/condition)
- [X] T005 [US9] Generalize the review module: edit
      `.specify/extensions/specify-review-loop/commands/speckit.specify.review-loop.md` to take a
      **target** (`spec` | `code`) per FR-037 / contracts/engine-modules.md — one recursive-review
      pattern, branch on target for what it reads and what "fixable" means
- [X] T006 [US9] Confirm `agent-context` is NOT copied/absorbed and the engine coexists with it
      (FR-038); document the exclusion in `.specify/README.md`

### Shared deterministic helpers (used by US3 and downstream)

- [X] T007 [P] Extend `.specify/extensions/engine/scripts/bash/derive-status.sh` to
      emit the six card-level logical states (open/in-design/ready/in-development/in-review/done)
      from artifact presence + triggering command + manifest `lifecycle` markers, keeping subtasks
      three-state (per contracts/status-model.md, research Decision 3)
- [X] T008 [P] Create `.specify/extensions/engine/scripts/bash/status-map.sh` —
      logical→actual status mapping from config + the deterministic 3-fallback collapse
      (nearest-status), per FR-015 / research Decision 4
- [X] T009 [US9] Extend `.specify/extensions/engine/scripts/bash/manifest.sh` for the
      additive fields (`lifecycle.verifyPassed`/`closedOut`, `card.provenanceHash`, six-state
      `statusMapping`) per data-model.md, keeping `schemaVersion` "1" and all changes additive
- [X] T010 [P] Test `derive-status.sh` six-state derivation in
      `.specify/extensions/engine/scripts/bash/derive-status.test.sh` (each state's
      trigger condition; subtasks stay three-state; markers gate states 5–6)
- [X] T011 [P] Test `status-map.sh` in
      `.specify/extensions/engine/scripts/bash/status-map.test.sh` (full six-status
      map; degenerate three-status list collapses correctly; reports degradation)
- [X] T012 [P] Test the manifest extensions in
      `.specify/extensions/engine/scripts/bash/manifest.test.sh` (lifecycle markers
      round-trip, provenanceHash, six-state mapping, no clobber of existing fields, no-jq fallback)

**Checkpoint**: The engine spine is wired and the shared helpers pass under `npm run check:all` —
command work can begin on a trustworthy base.

---

## Phase 3: User Story 3 - Every command advances the card (Priority: P1) 🎯 MVP

**Goal**: The card is created in `open` at provision and re-synced on **every** Spec Kit command,
advancing through the six logical states — making the artifact phase visible as work.

**Independent Test**: Provision → card in `open`; run specify/tasks/implement → card advances
in-design → ready → in-development; a status-only change makes zero content writes; a 3-status list
degrades cleanly (quickstart Scenarios 1, 2).

- [X] T013 [US3] Extend `.specify/extensions/clickup/commands/speckit.clickup.provision.md`
      to create the card in `open` at provision (FR-013a) and resolve/record the six-state
      `statusMapping` (via `status-map.sh`), writing the `statuses:` config block
- [X] T014 [US3] Extend `.specify/extensions/clickup/commands/speckit.clickup.sync.md` to set
      the card's six-state status from `derive-status.sh` + `status-map.sh` on every
      run, and subtasks' three-state status; only write status when it changed (FR-013/014)
- [X] T015 [US3] Wire the new sync hooks in `.specify/extensions.yml`: `after_specify` (→in-design),
      `after_analyze` (→ready), `after_converge` (→stays in-development), alongside existing
      after_plan/after_tasks/after_implement (FR-013b, research Decision 5)
- [X] T016 [US3] In sync, implement the config'd logical→actual mapping + 3-fallback path end to end
      (call `status-map.sh`, report degradation) so a reduced-status list never fails (FR-015)

**Checkpoint**: MVP — the card moves on every command through the six states, config-mapped and
degradable (quickstart 1–2). This is the demoable core of the engine.

---

## Phase 4: User Story 1 - Test gate + honest handoff capability (Priority: P1)

**Goal**: The test-and-handoff **capability** — run the check gate, drive whatever E2E is
automatable, and produce the honest verified-vs-manual report. This is the capability the verify
(US8) and close (US2) commands invoke, so it is built **before** them.

> Ordered before US8/US2 because they call this capability (fixes the earlier ordering inversion:
> the gate logic is a dependency of `/speckit-engine-verify`, not a follow-on).

**Independent Test**: Green feature → gate + E2E run, report lists verified/manual with evidence;
red gate → fails loud, no "verified" handoff (quickstart 3, US1 scenarios).

- [X] T024 [US1] Implement the check-gate + automatable-E2E logic that verify/close call: run the
      project gate (`npm run check:all` or equivalent), drive whatever E2E the AI can automate for
      the feature at hand, capture evidence and the un-automatable remainder with reasons
      (FR-001/002/003). Lands as a helper/prompt the command steps invoke.
- [X] T025 [US1] Implement the handoff report content (feature summary + location, verified-with-
      evidence vs. remaining-manual-and-why, follow-ups, exact manual steps) per FR-004, produced in
      the flow and reused by verify and close — no committed HANDOFF file.

**Checkpoint**: The gate/handoff capability is solid and ready for verify + close to invoke
(SC-001/002).

---

## Phase 5: User Story 8 - `/speckit-engine-verify` earns the review state (Priority: P1)

**Goal**: A verify command that recursively reviews the code, runs the unit gate + automatable E2E,
and only on success advances the card to `in-review`.

**Independent Test**: On a green feature, `/speckit-engine-verify` → review + gate + E2E → `in-review`; on
a red gate or unresolved finding, it stops and the card stays `in-development` (quickstart 3).

- [X] T017 [US8] Write `.specify/extensions/clickup/commands/speckit.engine.verify.md` implementing
      contracts/verify.command.md: step 1 recursive code review (invoke the review module with
      `target: code`, T005), step 2 full unit gate (invoke the US1 capability T024, must pass), step
      3 automatable E2E (best-effort, report the rest), step 4 on pass set `lifecycle.verifyPassed`
      + sync to `in-review`
- [X] T018 [US8] In verify, enforce the fail-stops: a red gate or unresolved review finding leaves
      the card at `in-development` and never sets `verifyPassed` (FR-034); converge-added work is
      still gated by verify (FR-035)
- [X] T019 [US8] In verify, emit the handoff report by invoking the US1 handoff capability (T025)
      — verified-automatically vs. remaining-manual with evidence, in the flow (FR-004), no
      committed HANDOFF file
- [X] T020 [P] [US8] Create the skill mirror `.claude/skills/speckit-engine-verify/SKILL.md` pointing at
      the verify command

**Checkpoint**: `in-review` is reachable only through a passing verify (quickstart 3, SC-014).

---

## Phase 6: User Story 2 - Close-out ceremony (Priority: P1)

**Goal**: A terminal close-out command: re-run gate → confirm completeness → surface manual tasks →
sign-off → mark done → final sync → commit → `done`.

**Independent Test**: From `in-review`, `/speckit-engine-close` surfaces manual tasks and waits; on sign-off
it checks them, syncs to `done`, and commits — sync itself never commits (quickstart 4).

- [X] T021 [US2] Write `.specify/extensions/clickup/commands/speckit.engine.close.md` implementing
      contracts/close.command.md: re-run gate (red→refuse, FR-010a), confirm non-manual complete
      (FR-010), surface manual tasks + wait for sign-off (never auto-check, FR-007)
- [X] T022 [US2] In close, on sign-off: mark manual tasks done in `tasks.md`, set
      `lifecycle.closedOut`, run the final sync to `done`/shipped (FR-008), then commit the close-out
      edits as a distinct commit reusing the `git-commit` module — the sync itself makes no commit
      (FR-009)
- [X] T023 [P] [US2] Create the skill mirror `.claude/skills/speckit-engine-close/SKILL.md` pointing at the
      close command

**Checkpoint**: Full lifecycle open→…→done runs end to end (quickstart 4, 5; SC-003/004/012).

---

## Phase 7: User Story 4 - AI owns the tracker (Priority: P2)

**Goal**: The AI is the sole writer; the six states are engine-owned; humans signal via the flow,
never the tracker. `in-review` rests until close-out.

**Independent Test**: Drive a feature to `done` with zero human tracker edits — the AI writes every
status (quickstart 5, SC-007).

- [X] T026 [US4] Audit the sync/verify/close prompts to guarantee the engine writes all six logical
      states one-way and never reads tracker state back into the repo (FR-017/019/029); document in
      speckit.clickup.sync.md that the tracker is a read-only mirror for humans
- [X] T027 [US4] Ensure `in-review` is set by verify and then rests (no further engine write until
      close-out runs), and `done` only after sign-off (FR-017a/020)

**Checkpoint**: Zero-human-edit path verified (quickstart 5).

---

## Phase 8: User Story 5 - Manual / light items (Priority: P2)

**Goal**: A manual item (no backing `tasks.md`) is safe by manifest-absence — never derived or
overwritten.

**Independent Test**: A hand-made card not in any manifest is untouched by sync; spec-driven cards
in the same list are still reconciled (quickstart 6, SC-008).

- [X] T028 [US5] Confirm + document in speckit.clickup.sync.md that the sync only ever touches
      manifest-recorded cards (reusing the 001 ownership mechanism, FR-022) — a manual item is never
      in a manifest, so no new marker/logic is needed; add a quickstart check for a hand-made card

**Checkpoint**: Manual items provably untouched (quickstart 6).

---

## Phase 9: User Story 6 - Commit provenance (Priority: P3)

**Goal**: The card shows the commits that shipped the feature (Option A), idempotently.

**Independent Test**: After commits exist, provenance appears on the card; re-run adds no duplicates
(quickstart 7, SC-009).

- [X] T029 [P] [US6] Create `.specify/extensions/engine/scripts/bash/provenance.sh` —
      render the feature's git log into a canonical, hash-deduped block (research Decision 6)
- [X] T030 [P] [US6] Test `provenance.sh` in
      `.specify/extensions/engine/scripts/bash/provenance.test.sh` (stable hash for
      same commits; different commits differ; empty history handled)
- [X] T031 [US6] In sync, push provenance to the card via MCP (comment/body section), deduped by
      `card.provenanceHash`, staying one-way. Route provenance through a single mode-check
      (`provenance-mode`: A default) so Option B (native GitHub) tacks on later as the other branch
      without reworking A — build only A now; document B as the opt-in that stands A down
      (FR-023/024/024a)

**Checkpoint**: Provenance on the card, idempotent (quickstart 7).

---

## Phase 10: User Story 7 - Agent-designed project rules (Priority: P3)

**Goal**: An agent inspects the real workspace and proposes a per-project ruleset for approval;
approved rules are honored, else baked-in defaults apply.

**Independent Test**: Run the design step → proposed ruleset for approval; approved → sync honors it;
none → defaults unchanged (spec US7).

- [X] T032 [US7] Write a design-rules command prompt
      `.specify/extensions/clickup/commands/speckit.clickup.design-rules.md`: inspect the real
      space/list/statuses/custom-fields (via ClickUp MCP read tools) and **propose** a ruleset for
      explicit approval — never silently apply board-reshaping changes (FR-025)
- [X] T033 [US7] In sync + config, honor an approved ruleset when present and fall back to baked-in
      defaults when absent; reject a ruleset that would violate a constitution principle (FR-026/027)
- [X] T034 [P] [US7] Create the skill mirror `.claude/skills/speckit-clickup-design-rules/SKILL.md`

**Checkpoint**: Opt-in per-project rules; defaults untouched without them.

---

## Phase 11: Polish & Cross-Cutting

**Purpose**: Finalize docs, plug seam, and full validation.

- [X] T035 [P] Document the tracker-plug interface seam (resolve-target / create-update-item /
      set-checklist / link-dependency / update-status / attach-provenance) in
      `.specify/extensions/clickup/README.md`, noting the local/multi-plug realization is
      deferred (research Decision 7 / FR-032)
- [X] T036 [P] Update `.claude/skills/` mirrors and each module README to reflect the consolidated
      engine (US9) and the new commands
- [X] T037 Run `npm run check:all` and fix any formatting/shell issues so the gate is green
- [X] T038 **(manual — requires a live ClickUp workspace via MCP; not runnable headlessly)** Walk
      quickstart.md Scenarios 1–9 against a real ClickUp workspace and record results; explicitly
      exercise the SC-007 provision fail-loud negative path with a purpose-built degenerate list
      (carried over from 001)
- [X] T039 [P] Confirm scaffolding-only (Constitution IV) by grep: no tracker refs leak into shipped
      app source/docs/CI (only `.specify/`, `.claude/`, per-feature manifests carry them)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories** (US9 spine + shared
  helpers). Within it: T003–T006 (consolidation) and T007–T012 (helpers+tests) can largely proceed
  in parallel, but helper tests gate the command phases.
- **US3 (Phase 3, P1)**: After Foundational. The lifecycle core — first real story (MVP).
- **US1 (Phase 4, P1)**: After Foundational. The gate/handoff capability — built **before** US8/US2
  because they invoke it (T024/T025 are called by T017/T019/T021).
- **US8 (Phase 5, P1)**: After US3 (uses the six-state sync), US1 (invokes the gate T024), and the
  review module (T005).
- **US2 (Phase 6, P1)**: After US8 (close-out starts from `in-review`), US1 (invokes the gate/
  handoff), and the git-commit module.
- **US4 (Phase 7, P2)**: After the sync/verify/close prompts exist (audits them).
- **US5 (Phase 8, P2)**: Independent — reuses 001 ownership; can run any time after Foundational.
- **US6 (Phase 9, P3)**: After US3 sync (attaches to the card).
- **US7 (Phase 10, P3)**: After US3 (extends the mapping/rules the sync honors).
- **Polish (Phase 11)**: Last.

### Within Each User Story

- Helpers (Phase 2) before any command that calls them.
- Command prompt before its skill mirror before its hook registration.
- Tasks that edit the same file (e.g. `speckit.clickup.sync.md` across US3/US4/US6/US7) are
  sequential, not [P].

### Parallel Opportunities

- Setup: T002 with T001.
- Foundational: consolidation (T003–T006) alongside helper authoring (T007–T009); then the tests
  T010–T012 in parallel.
- Skill mirrors (T020, T023, T034) are [P] with each other.
- Provenance helper + test (T029, T030) in parallel.
- Polish docs (T035, T036, T039) in parallel.

---

## Parallel Example: Phase 2 Foundational helpers

```bash
# Author the shared helpers together (distinct files):
Task: "derive-status.sh six-state extension"   (T007)
Task: "status-map.sh + 3-fallback"             (T008)
# Then their tests together:
Task: "derive-status.test.sh"                  (T010)
Task: "status-map.test.sh"                     (T011)
Task: "manifest.test.sh"                       (T012)
```

---

## Implementation Strategy

### MVP First

1. Phase 1 Setup → Phase 2 Foundational (US9 spine + helpers + tests green).
2. Phase 3 US3 (the six-state lifecycle syncing on every command).
3. **STOP and VALIDATE**: the card moves on every command through the six states, config-mapped and
   degradable (quickstart 1–2). This is the demoable MVP — the heart of the engine.

### Incremental Delivery

1. Setup + Foundational → engine spine ready.
2. + US3 → live six-state lifecycle (**MVP**).
3. + US1 (gate/handoff capability) + US8 (verify) + US2 (close) → the full verify→close→done
   ceremony with honest handoff (US1 first — the commands invoke it).
4. + US4 + US5 → AI-owns-tracker + manual items (trustworthy mirror).
5. + US6 + US7 → provenance + per-project rules (enrichment).
6. Polish → docs, plug seam, full quickstart pass.

---

## Notes

- This is a spec-workflow **engine**, not app code — paths are under `.specify/`/`.claude/`, and
  Constitution IV keeps trackers out of shipped app source/docs/CI.
- `*.test.sh` coverage for deterministic helpers is **required** (Constitution V), not optional;
  MCP/ceremony orchestration is validated by quickstart against a real workspace.
- Manifest changes are additive (`schemaVersion` stays "1") per the 001 upgrade contract.
- The local/multi-plug machinery is deferred (research Decision 7); only the interface seam is built.
- Commit after each phase.
