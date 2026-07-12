# Feature Specification: Engine Lifecycle, Test-and-Handoff, and Adaptive Sync

**Feature Branch**: `002-clickup-lifecycle`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Specify all of the lifecycle backlog (§0–§5) as one feature: the
post-implement test-everything + handoff + close-out gate, the full status lifecycle advancing per
Spec Kit command, human-testing handoff, a manual/light tracking mode, agent-designed per-project
rules, and linking GitHub commits/PRs to tracker items."

> This spec supersedes the original `BACKLOG.md` that formerly lived in this directory; the
> backlog's six tracks (§0–§5) are fully captured as the user stories below and it has been
> removed. Section references like "§0"/"§5" throughout refer to those original backlog tracks.

**Engine vs. plug — how to read this spec.** This feature specifies **snackbyte-speckit-engine**:
a generic, tracker-agnostic Spec Kit lifecycle engine that broadcasts each lifecycle event to zero
or more swappable tracker **plugs**. Almost everything below is **engine** behavior (deriving
status, the per-command lifecycle, close-out, handoff, human-vs-derived status ownership, manual
items, project-rule design) and is written tracker-agnostically. Where a requirement names ClickUp
concretely (the MCP transport, `.clickup-sync.json`, ClickUp status names), that is **the ClickUp
plug's implementation** of a generic engine capability — ClickUp is the first plug, not the
subject. A second plug (Linear, a local file, …) would satisfy the same requirements its own way.

This feature builds on the shipped **ClickUp plug** (`001-clickup-sync`: one-way, MCP-only,
idempotent, scaffolding-only) without revisiting its core mapping (feature = tracker item, user
story = subtask, `tasks.md` line = checklist item). It generalizes that plug's proven model into
the engine and extends it along six independent tracks drawn from this feature's original backlog.
Each track is a separately deliverable slice; the priorities below reflect the backlog's own
ordering (§0 and the lifecycle first, enrichment later).

## Clarifications

### Session 2026-07-11

- Q: How is the close-out ceremony (US2) invoked? → A: A distinct user-invoked command
  (`/speckit-close`), run when the human is ready — not tied to a lifecycle hook.
- Q: What does the §0 test gate do to the `after_implement` chain when the check gate is red? →
  A: Hard-stop the entire chain — converge and everything after it do not run until the gate is
  green.
- Q: Which mechanism links commit/PR provenance onto the card (US6)? → A: Both — ship Option A
  (MCP-pushed by our extension, self-contained) now; leave Option B (ClickUp's native GitHub
  integration) as a documented opt-in for teams that connect GitHub. Refinement: A and B are
  mutually exclusive per project — when B is opted in, A MUST stand down so provenance is not
  pushed redundantly (no duplicate commit links on the card).
- Q: How is the human-owned (off-limits) status set determined (US4)? → A: As the complement of
  the repo-owned set — the repo owns exactly the statuses in its resolved `statusMapping` (the
  US3-expanded lifecycle states); every other status on the list is human-owned by default. No
  hardcoded human-status name list; reuses the already-resolved per-project mapping.
- Q: How does the sync distinguish a manual item from a spec-driven feature-card (US5)? → A:
  Ownership by manifest presence — the sync only ever touches cards recorded in a feature's
  `.clickup-sync.json` manifest (reusing the 001 mechanism). Manual items (and unrelated cards)
  are simply never in a manifest, so they are never touched. No new marker/tag/custom-field.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Finish-the-job test gate and honest handoff (Priority: P1)

As a developer who just ran `/speckit-implement`, I want a single repeatable step that does
everything the AI can to verify the feature before it reaches me — run the unit gate, drive the
end-to-end path as far as is automatable, then produce an honest handoff of what was verified
versus what remains — so that "tested" means actually exercised, not asserted, and I only get
the genuinely-manual remainder.

**Why this priority**: This is the backlog's §0 and is independent of ClickUp entirely — it can
ship first and delivers value on its own (a codified pre-handoff discipline) even if no other
track lands. It closes the gap where the lifecycle ends at `after_implement`, before manual
verification and close-out.

**Independent Test**: On a feature with a green unit suite, run the gate → it runs the project
check gate, attempts the E2E path (or loudly reports the per-app E2E hook is absent), and emits
a handoff report listing verified-automatically vs. remaining-manual items with evidence. On a
feature with a red gate, the gate fails loud and does not emit a "verified" handoff.

**Acceptance Scenarios**:

1. **Given** a feature whose unit tests and project check gate pass, **When** the test gate runs,
   **Then** it records the gate as green with evidence (suite counts / gate output) and proceeds.
2. **Given** a feature whose check gate is red, **When** the test gate runs, **Then** it stops
   with the failure surfaced and does NOT produce a "verified" handoff.
3. **Given** a feature with a declared per-app E2E hook, **When** the test gate runs, **Then** it
   invokes that hook and folds its result into the report; **Given** no such hook, **Then** it
   records a loud "E2E not automated here — reason" note rather than silently skipping.
4. **Given** the automated phases complete, **When** the handoff is produced, **Then** it lists
   what the feature does and where it lives, what was verified automatically (with evidence),
   what remains manual and why, and the exact manual steps left for the human.

---

### User Story 2 - Close-out ceremony: sign-off, final sync, commit (Priority: P1)

As a developer whose feature has an irreducible manual verification slice, I want a terminal
close-out step that surfaces the remaining manual tasks for my explicit sign-off, marks them done
in `tasks.md` only once I sign off, runs the final sync so the ClickUp card reaches done, and
commits the close-out edits — so that "commit vs. sync vs. close" is one ordered ceremony instead
of three decoupled acts a human has to remember to run in order.

**Why this priority**: This is §0's Phase C — the missing terminal step. It pairs with US1 (they
share the same lifecycle moment) and encodes the exact hand-run steps that 001's own dogfood
required. Without it a feature is never truly "done" in the flow.

**Independent Test**: On a feature with unchecked manual tasks in `tasks.md`, run close-out → it
lists those tasks and waits; on sign-off it checks them in `tasks.md`, runs the final sync
(card → done), and commits the edits. It never silently checks a manual task, and the sync step
itself never commits (constitution I / 001 FR-019).

**Acceptance Scenarios**:

1. **Given** a feature with unchecked human-in-the-loop tasks, **When** close-out runs, **Then**
   it surfaces exactly those tasks and waits for explicit sign-off — it never auto-checks them.
2. **Given** the human signs off, **When** close-out continues, **Then** it marks those tasks done
   in `tasks.md`, runs the final one-way sync (card + subtasks → done/shipped), and creates a
   fresh commit of the close-out edits.
3. **Given** close-out runs, **When** it performs the sync, **Then** the sync makes no commit
   itself; the commit is a distinct close-out step (the implement-time git-commit hook already
   fired before these edits existed).
4. **Given** non-manual tasks are still incomplete, **When** close-out runs, **Then** it refuses
   to close and reports what remains.

---

### User Story 3 - Status advances per Spec Kit command (Priority: P1)

As a stakeholder watching a feature's ClickUp card, I want the card's status to reflect the stage
the feature is actually at right now — advancing as each Spec Kit command runs (specify → clarify
→ plan → tasks → implement) — instead of barely moving until late, so the board is a live picture
of progress rather than a lagging one.

**Why this priority**: This is §1 and is the heart of "lifecycle." 001 derives only
not-started / in-progress / done and only re-syncs at two late hooks, so a feature can be
specified, clarified, and planned while the card looks idle. This makes the card move with the
work.

**Independent Test**: Run each lifecycle command in turn on a feature and observe the card's
status advance through the mapped states; a status-only bump on an unchanged card still makes
zero content writes (idempotence preserved). A target list with fewer statuses degrades to the
nearest available state without error.

**Acceptance Scenarios**:

1. **Given** the grouped lifecycle phases are defined, **When** `/speckit-specify` →
   `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` each run, **Then** the card's status
   is re-synced to the phase that command maps to, advancing whenever a command crosses into a new
   phase (multiple commands may map to the same phase).
2. **Given** the status changed but no content changed, **When** the per-command sync runs,
   **Then** it writes the status and nothing else (no duplicate content writes; constitution III).
3. **Given** a target list whose status set is smaller than the full lifecycle, **When** a state
   with no exact match is derived, **Then** it maps to the nearest available status and reports
   the degradation rather than failing.

---

### User Story 4 - Human-testing handoff without clobbering human status (Priority: P2)

As a person who moves a card into a human-only state (review, testing, QA, blocked), I want the
one-way sync to own only the states it derives and never overwrite a status a human set, so that
marking a card "in QA" or "blocked" survives the next sync instead of being reset to a
repo-derived value.

**Why this priority**: This is §2 and is the key correctness constraint 001 explicitly deferred.
It is a direct tension with constitution I (one-way, repo wins) and must be resolved as a
bounded, principled exception: the repo owns the states it derives; humans own a disjoint set the
sync treats as off-limits.

**Independent Test**: A human sets a card to a human-owned status (e.g. "in review"); the next
sync runs and leaves that status untouched while still overwriting the repo-owned content
(body, checkboxes, dependencies). When the card returns to a repo-derived state, the sync resumes
ownership.

**Acceptance Scenarios**:

1. **Given** a card in a human-owned status, **When** the sync runs, **Then** it does NOT change
   the status, but still reconciles repo-owned content (body/checkboxes/deps).
2. **Given** a card in a repo-derived status, **When** the sync runs, **Then** it derives and sets
   the status as usual.
3. **Given** the set of human-owned states is defined, **When** the sync classifies the card's
   current status, **Then** repo-owned and human-owned states are disjoint and unambiguous.

---

### User Story 5 - Manual / light tracking mode (Priority: P2)

As someone doing work outside the full Spec Kit pipeline, I want a lighter tracking mode for a
hand-maintained item — one with no backing `tasks.md` to derive status from — so I can track
one-off work on the same board without the sync clobbering my manually-set status.

**Why this priority**: This is §3. It generalizes the extension beyond spec-driven features, but
depends on the human-status-ownership rule from US4 to avoid clobbering, so it follows it.

**Independent Test**: Create a manually-tracked item; the sync recognizes it as manual (no
derivation), never overwrites its human-set status or hand-maintained content, and tells it apart
from spec-driven feature-cards in the shared list.

**Acceptance Scenarios**:

1. **Given** a manually-tracked item with no backing `tasks.md`, **When** the sync runs, **Then**
   it does not derive or overwrite the item's status or content.
2. **Given** a shared list holding both spec-driven and manual items, **When** the sync runs,
   **Then** it correctly distinguishes the two and only reconciles the spec-driven cards it owns.

---

### User Story 6 - Card shows the code that shipped it (Priority: P3)

As a reviewer looking at a ClickUp card, I want to see which commits (and, where available, PRs)
implemented the feature, so the card closes the loop between the tracker and the code — not just
"what/why" from the spec but "what actually shipped it."

**Why this priority**: This is §5 and is pure enrichment on top of a working card. It stays
one-way (repo → ClickUp) and is the lowest priority because the card is fully useful without it.

**Independent Test**: After a feature's commits exist, the sync (or close-out) attaches the
feature's commit provenance to the card via MCP; re-running does not duplicate the links.

**Acceptance Scenarios**:

1. **Given** a feature with commits, **When** the provenance step runs, **Then** the card shows
   the feature's commits (as a comment, a body section, or task links per the chosen mechanism).
2. **Given** the provenance was already attached, **When** the step re-runs unchanged, **Then** it
   adds no duplicate links (idempotence; constitution III).

---

### User Story 7 - Agent-designed, project-specific ClickUp rules (Priority: P3)

As a team with our own ClickUp conventions, I want an agent step that inspects our real workspace
and proposes a tailored ruleset — which lifecycle states to use and how they map, whether phases
or user stories become tags vs. subtasks vs. lists, what the card body emphasizes, custom-field
usage — recorded as config the sync then honors, so the extension adapts to our board instead of
forcing our board to adapt to its one baked-in default.

**Why this priority**: This is §4 and is the most open-ended, highest-impact track (it can reshape
a team's board), so it is lowest priority and gated behind explicit approval. The baked-in 001
defaults remain the always-present fallback; this is opt-in enrichment.

**Independent Test**: Run the design step against a real workspace → it produces a proposed
ruleset for approval; on approval the ruleset is recorded as config and the next sync honors it;
with no ruleset the baked-in defaults are used unchanged.

**Acceptance Scenarios**:

1. **Given** a project with an existing ClickUp workflow, **When** the design step runs, **Then**
   it inspects the real space/list/statuses/custom-fields and proposes a ruleset for approval —
   it does not silently apply board-reshaping changes.
2. **Given** an approved ruleset recorded as config, **When** the sync runs, **Then** it honors
   the ruleset; **Given** no ruleset, **Then** the baked-in defaults are used unchanged.

---

### Edge Cases

- **Red gate at close-out**: close-out (`/speckit-close`, FR-011) re-runs the phase-A test gate
  before it does anything; if the gate is red, close-out refuses to proceed (no sign-off, no final
  sync, no commit) and surfaces the failure — consistent with FR-005/FR-006's fail-loud posture.
  It never closes over a red gate.
- **Converge interaction**: `converge` runs at `after_implement` and appends unbuilt work as new
  tasks. Per FR-006 the test gate runs before converge in the chain and a red gate hard-stops the
  chain, so converge does not run while the gate is red; open question deferred to planning:
  whether converge-added work (once the gate is green and converge runs) re-opens the gate on the
  next pass.
- **Status write-back conflict**: a human sets a human-owned status mid-flow while a repo-derived
  status would also change — the sync must not fight the human (US4).
- **Manual item mistaken for spec-driven** (or vice versa) in a shared list — structurally
  prevented by FR-022: ownership is manifest presence, so a card not in any feature manifest is
  never touched regardless of appearance; the sync never re-scans or classifies list contents.
- **Commit predates the card**: the commit that finishes a feature usually cannot carry the
  ClickUp task ID because the card is created by sync, which runs after implement commits — so at
  commit time the ID may not exist (the §5 ordering snag).
- **Fewer statuses than the lifecycle needs**: a target list with a reduced status set (US3
  degradation).
- **Designed ruleset conflicts with the baked-in defaults or the constitution** (e.g. a proposed
  rule that would require two-way sync) — must be rejected, not honored (US7 vs. constitution I).

## Requirements *(mandatory)*

### Functional Requirements

**Test-and-handoff gate (US1)**

- **FR-001**: The system MUST provide a repeatable post-implement step that runs the project's
  full check gate (unit + any feature-specific `*.test.sh`) and records the result with evidence.
- **FR-002**: The system MUST attempt the end-to-end path as far as is automatable via a declared,
  per-app E2E hook/script when present, and MUST loudly record a reason when no such hook exists
  rather than silently skipping.
- **FR-003**: The system MUST identify and clearly delimit the irreducible manual remainder, with
  a stated reason each item could not be automated.
- **FR-004**: The system MUST emit a handoff report listing: what the feature does and where it
  lives; what was verified automatically (with evidence) vs. what remains manual and why; any
  follow-ups/known gaps; and the exact manual steps left for the human.
- **FR-005**: A red check gate MUST prevent a "verified" handoff (fail-loud).
- **FR-006**: A red check gate MUST hard-stop the entire `after_implement` hook chain — `converge`
  and every step after it MUST NOT run until the gate is green. The stop MUST surface the failure
  loudly; the flow only resumes once the gate passes.

**Close-out ceremony (US2)**

- **FR-007**: The system MUST provide a terminal close-out step that surfaces remaining
  manual/human-in-the-loop tasks and waits for explicit human sign-off — it MUST NOT auto-check
  them.
- **FR-008**: On sign-off, close-out MUST mark those tasks done in `tasks.md`, run the final
  one-way sync (card + subtasks → done/shipped), and commit the close-out edits as a distinct
  commit.
- **FR-009**: The sync invoked by close-out MUST NOT itself commit (constitution I / 001 FR-019);
  committing is a separate close-out step.
- **FR-010**: Close-out MUST refuse to close while non-manual tasks are incomplete.
- **FR-010a**: Close-out MUST re-run the phase-A check gate (FR-001) before it surfaces tasks for
  sign-off; a red gate MUST make close-out refuse to proceed (no sign-off, no final sync, no
  commit), surfacing the failure — close-out never closes over a red gate.
- **FR-011**: Close-out MUST be a distinct user-invoked command (`/speckit-close`), run when the
  human is ready — NOT wired to an automatic lifecycle hook (it is human-paced: it waits for
  sign-off on manual verification, which no fixed hook moment can time).

**Per-command status lifecycle (US3)**

- **FR-012**: The system MUST support a richer, ordered status set beyond not-started /
  in-progress / done, and MUST define which states are auto-derivable from Spec Kit artifacts and
  which require an external signal.
- **FR-013**: The system MUST re-sync the card's status on each lifecycle command (specify,
  clarify, plan, tasks, implement), setting it to the grouped lifecycle phase that command maps to
  (per FR-016). Several commands may map to the same phase; the card advances when a command
  crosses into a new phase.
- **FR-014**: A per-command status change on otherwise-unchanged content MUST make zero content
  writes — a status-only bump (constitution III).
- **FR-015**: When the target list has fewer statuses than the full lifecycle, the system MUST map
  to the nearest available status and report the degradation rather than failing.
- **FR-016**: The card's status MUST advance through grouped lifecycle phases (planning →
  in-development → review → testing → done) rather than a distinct state per command; the mapping
  from each Spec Kit command to its phase MUST be defined, and status MUST apply to both the
  feature-card and its US-subtasks (each reflecting its own progress).

**Human-testing handoff (US4)**

- **FR-017**: The system MUST treat a disjoint set of human-owned statuses as off-limits (the sync
  MUST NOT overwrite them). That set is defined by FR-017a as the complement of the repo-owned
  `statusMapping` statuses on the target list — not a hardcoded name list.
- **FR-017a**: The human-owned (off-limits) status set MUST be derived as the **complement** of
  the repo-owned set on the target list: the repo owns exactly the statuses present in its
  resolved `statusMapping` (the US3 grouped lifecycle phases — planning → in-development → review →
  testing → done — as resolved by provision onto the list's real statuses), and **every other
  status on the list is human-owned by default**. No separate hardcoded human-status name list is
  maintained; the two sets are disjoint by construction because one is the complement of the
  other. This reuses the already-resolved, per-project `statusMapping` rather than adding new
  config.
- **FR-018**: When a card is in a human-owned status, the sync MUST leave the status unchanged
  while still reconciling repo-owned content (body, checkboxes, dependencies).
- **FR-019**: When a card is in a repo-derived status, the sync MUST derive and set the status
  normally.
- **FR-020**: Human sign-off (via the close-out ceremony, US2) MUST be the path to the terminal
  "done" state for a feature that has manual tasks: the sync alone MUST NOT advance a card to
  "done" while unchecked manual tasks remain; close-out's sign-off is what checks them and
  triggers the final done-sync. (Informed default — see Assumptions.)

**Manual / light mode (US5)**

- **FR-021**: The system MUST support a manually-tracked item (an item with no backing `tasks.md`)
  whose status and content are human-set and never derived or overwritten by the sync.
- **FR-022**: The sync MUST distinguish manual items from spec-driven feature-cards by **ownership
  via manifest presence** (reusing the 001 mechanism): it only ever touches cards recorded in a
  feature's `.clickup-sync.json` manifest and never re-scans the list. A manual item — like any
  unrelated card — is simply never recorded in a manifest, so it is never derived, overwritten, or
  counted. No tag, custom field, or separate registry is required to mark an item as manual.

**Commit/PR provenance (US6)**

- **FR-023**: The system MUST attach the feature's commit provenance to the card via MCP, staying
  one-way (repo → ClickUp), and MUST NOT duplicate links on re-run.
- **FR-024**: Provenance MUST ship as Option A — the extension reads the feature's git log and
  attaches it to the card via MCP (comment / body section / task links), self-contained, needing
  no GitHub remote or commit-message convention. Option B (ClickUp's native GitHub integration via
  `CU-<taskid>` in commit/branch/PR messages) MUST be offered as a documented opt-in for teams
  that connect GitHub — it is not required and not a dependency of the baseline provenance.
- **FR-024a**: Options A and B MUST be mutually exclusive per project. When B (native GitHub
  integration) is opted in, A MUST NOT also push provenance — the extension defers to ClickUp's
  first-party links so the card never shows the same commits/PRs twice. Exactly one provenance
  source is active at a time.

**Agent-designed rules (US7)**

- **FR-025**: The system MUST let an agent inspect the real workspace (space/list/statuses/custom
  fields) and propose a project-specific ruleset for explicit human approval — never silently
  applying board-reshaping changes.
- **FR-026**: An approved ruleset MUST be recorded as config the sync honors; with no ruleset the
  baked-in 001 defaults MUST be used unchanged (opt-in enrichment, defaults always present).
- **FR-027**: A proposed ruleset that would violate a constitution principle (e.g. require two-way
  sync) MUST be rejected, not honored.

**Cross-cutting invariants (engine + plug / constitution)**

- **FR-028**: The engine core MUST NOT talk to any tracker directly; all tracker I/O MUST go
  through a plug that owns its own transport and auth, shipping no API client and no credentials in
  the repo or config (constitution II). For the ClickUp plug, that transport is the ClickUp MCP
  server; another plug would use its own.
- **FR-029**: The sync MUST remain one-way (constitution I) except for the explicitly-bounded
  human-owned-status carve-out (FR-017/018), which is a read-only deferral (the sync declines to
  write those statuses), NOT a write-back into the repo.
- **FR-030**: All new deterministic logic (status derivation, item classification, provenance
  formatting, ruleset resolution) MUST live in `scripts/bash/` with `*.test.sh` coverage
  (constitution V); each plug's tracker orchestration stays in its command prompts, validated via
  quickstart.
- **FR-031**: The engine and every plug MUST remain scaffolding-only (constitution IV) — no plug
  may put a reference to its tracker into shipped app source/docs/CI of an adopting repo.
- **FR-032**: The engine MUST function with zero external plugs (recording lifecycle state via a
  built-in local plug), one plug, or many at once; plugs MUST be independent and purely additive —
  attaching or removing a plug MUST NOT change engine behavior, and an uninstalled plug is a no-op,
  not an error (constitution VI). Every ClickUp-specific requirement above is satisfied by the
  ClickUp plug; the engine itself requires only "a plug" (the local plug suffices).

### Key Entities *(include if feature involves data)*

- **Status set / lifecycle mapping**: the ordered set of grouped lifecycle phases (planning →
  in-development → review → testing → done) and their mapping onto a target list's real statuses,
  resolved into the manifest's `statusMapping`. The repo owns exactly these mapped statuses; every
  other status on the list is human-owned (off-limits) by construction (FR-017a). Extends 001's
  fixed 3-state mapping.
- **Handoff report**: the end-of-feature artifact summarizing what was verified vs. what remains.
  Defaults to a committed `specs/<feature>/HANDOFF.md` plus stdout, optionally the ClickUp card
  body when the ClickUp tracks are active (see Assumptions).
- **Manual item**: a card with no backing `tasks.md` and human-set status/content. Distinguished
  from spec-driven feature-cards purely by **absence from any feature manifest** (FR-022) — not by
  any marker on the card itself.
- **Commit provenance**: the feature's commits/PRs as attached to the card (mechanism per FR-024).
- **Designed ruleset**: agent-proposed, human-approved per-project config that the sync honors,
  layered over the baked-in defaults.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A feature cannot reach a "verified" handoff while its check gate is red — 100% of
  red-gate runs are stopped before handoff.
- **SC-002**: The handoff report, for every feature it is run on, lists at least: feature summary
  + location, automatically-verified items with evidence, and the remaining manual steps — with
  no "verified" claim unbacked by evidence.
- **SC-003**: Close-out never auto-checks a manual task — 100% of manual tasks are checked only
  after explicit human sign-off.
- **SC-004**: After close-out, the ClickUp card reads done/shipped and the close-out edits are
  committed in a distinct commit; the sync step made zero commits.
- **SC-005**: Across a full run of the Spec Kit commands, the card's status advances at each stage
  rather than only at tasks/implement — an observer sees at least one status change per lifecycle
  command that maps to a new state.
- **SC-006**: A status-only change makes zero content writes (a no-op content re-sync stays a
  no-op) — idempotence is preserved under per-command syncing.
- **SC-007**: A human-set status in a human-owned state survives every subsequent sync — 0%
  clobber rate on human-owned statuses.
- **SC-008**: A manually-tracked item is never overwritten by the sync — 0% clobber rate on manual
  items — while spec-driven cards in the same list are still reconciled.
- **SC-009**: Commit provenance appears on the card and re-running the sync adds no duplicate
  links.
- **SC-010**: With no designed ruleset present, behavior is byte-for-byte the 001 defaults; a
  designed ruleset is applied only after explicit approval, and one that would break a constitution
  principle is rejected.
- **SC-011**: A target list with fewer statuses than the lifecycle degrades gracefully (nearest
  status, reported) with no failed sync.
- **SC-012**: Close-out re-runs the check gate first and, when the gate is red, refuses to close —
  0% of close-outs proceed (sign-off / final sync / commit) over a red gate.
- **SC-013**: The engine produces a correct lifecycle with zero external plugs (local plug only),
  one plug, and many plugs; adding or removing a plug changes only how many trackers are mirrored,
  never the derived lifecycle — an uninstalled plug causes no error.

## Assumptions

- **Independent, prioritized slices**: the six backlog tracks are specified together but remain
  independently deliverable; §0 (US1–US2) is pure engine and can ship with no external tracker
  plug at all, and each ClickUp-facing track (US3–US7) builds on the shipped ClickUp plug without
  revisiting its core mapping.
- **The ClickUp plug is the proven base**: `001-clickup-sync` (the ClickUp plug) is shipped and
  validated (one-way, MCP-only, idempotent, scaffolding-only); this feature generalizes its model
  into the engine and extends it — it does not re-implement the plug.
- **Constitution governs**: all six engine principles hold. The one apparent tension — human-owned
  statuses (US4) vs. one-way (I) — is treated as a read-only deferral (the sync declines to write
  certain statuses), never a write-back into the repo, so principle I is preserved.
- **Generic across spun-up apps**: the §0 E2E phase invokes a declared per-app hook/script if
  present and otherwise records a loud no-op, rather than hardcoding any app's E2E into the
  template.
- **Handoff report location** defaults to a committed `specs/<feature>/HANDOFF.md` plus stdout;
  optionally the ClickUp card body if the ClickUp tracks are active (final choice deferred to
  planning).
- **Non-goals** (from the backlog): no two-way sync of task content back into `tasks.md`; no change
  to 001's core mapping (feature = card, line = checklist item); no app-specific E2E logic baked
  into the template (only the generic hook + per-app extension point).
- **Split-vs-combined**: the original backlog recommended splitting these tracks into separate
  feature dirs; per explicit direction this spec intentionally carries all six as one feature,
  using prioritized user stories to keep them independently deliverable.
- **Per-command status shape (FR-016 default)**: statuses are grouped lifecycle phases (planning →
  in-development → review → testing → done), not one distinct state per command, and apply to both
  the card and its US-subtasks. Chosen because grouped phases map more robustly onto real ClickUp
  lists (which have ~7 statuses, not one per Spec Kit command) and degrade better on smaller lists.
- **Sign-off and "done" (FR-020 default)**: human sign-off is not a separate gate bolted onto the
  status machine — it is the close-out ceremony (US2), which is the path to "done" for any feature
  with manual tasks. The sync never advances a card to "done" while unchecked manual tasks remain.
- **Resolved design forks**: the genuine forks (close-out trigger, red-gate failure contract,
  provenance mechanism, human-owned status set, manual-item discriminator) were decided in the
  2026-07-11 clarify session — see the `## Clarifications` section. No open clarification markers
  remain.
- **Carried-over validation from 001 (SC-007 negative path)**: 001's live validation (T030,
  2026-07-11) exercised every positive scenario plus one-way/idempotence against a real workspace
  but did NOT trigger the provision fail-loud path where a target list cannot represent the logical
  states as distinct statuses — every list in the workspace ships the full 9-status set, so it
  needs a purpose-built degenerate list. The fail-loud logic exists in the 001 provision contract;
  only the live trigger is unverified. Because this feature's provisioning/lifecycle work
  (US3/US7) touches status resolution, that negative path MUST be exercised as part of this
  feature's validation (build a degenerate list; confirm provision stops, names the gap, and
  leaves the manifest untouched).
