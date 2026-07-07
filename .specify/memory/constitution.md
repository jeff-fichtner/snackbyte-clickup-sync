<!--
SYNC IMPACT REPORT
Version change: (template, unversioned) → 1.0.0
Bump rationale: MAJOR — initial ratification; first concrete constitution replacing the
  unfilled template. No prior versioned principles to compare against.
Modified principles: all five placeholders defined for the first time:
  [PRINCIPLE_1] → I. One-Way, Repo Is Source of Truth
  [PRINCIPLE_2] → II. MCP-Only
  [PRINCIPLE_3] → III. Idempotent
  [PRINCIPLE_4] → IV. Scaffolding-Only
  [PRINCIPLE_5] → V. Deterministic Logic Is Tested (NON-NEGOTIABLE)
Added sections:
  - "Additional Constraints" (portability / config-only retargeting)
  - "Development Workflow" (test gate + manual MCP validation)
Removed sections: none.
Templates requiring updates:
  ✅ .specify/memory/constitution.md (this file)
  ✅ .specify/templates/plan-template.md — reviewed; Constitution Check gate aligns (generic).
  ✅ .specify/templates/spec-template.md — reviewed; no mandatory-section conflict.
  ✅ .specify/templates/tasks-template.md — reviewed; test-first categorization consistent
     with Principle V.
Deferred TODOs: none.
-->
# snackbyte-clickup-sync Constitution

The one-way Spec-Kit → ClickUp sync extension. This constitution captures the guarantees the
extension already makes to any repo that adopts it. The principles are non-negotiable
invariants, not aspirations: a change that violates one is a defect, not a trade-off.

## Core Principles

### I. One-Way, Repo Is Source of Truth
The sync flows in exactly one direction: repo → ClickUp. It MUST overwrite ClickUp toward the
repo and MUST NOT write back to `tasks.md`, `spec.md`, or any other repo artifact. A hand-edit
made in ClickUp is transient and MUST be reverted on the next sync. There is no bidirectional
mode and no "merge" — the repo wins, always.
Rationale: bidirectional sync creates ambiguous conflict resolution and lets a PM tool mutate
source. One direction keeps the repo authoritative and the sync reasoning trivial.

### II. MCP-Only
Every ClickUp operation MUST go through the connected ClickUp MCP server. This extension MUST
ship no ClickUp API client, no auth flow, and no credentials — none in the repo, none in
`config.yml`, none in any committed manifest. `config.yml` names only WHERE (space/list); the
MCP server owns authentication.
Rationale: no bespoke API/auth code to maintain or leak; credentials never enter the repo's
trust boundary.

### III. Idempotent
Running the sync when nothing changed MUST make zero ClickUp writes. Create/update/skip
decisions are driven by the committed per-feature manifest
(`specs/<feature>/.clickup-sync.json`) via content hashes and recorded target IDs. Re-running is
always safe and never duplicates cards, subtasks, or checklist lines.
Rationale: idempotence makes the sync safe to wire into lifecycle hooks that fire repeatedly,
and makes a no-op observable (zero writes) rather than merely harmless.

### IV. Scaffolding-Only
The extension MUST live entirely under `.specify/`, `.claude/`, and per-feature manifests. It
MUST NOT introduce any ClickUp reference into shipped application source, product docs, or CI of
the repo that adopts it. Runtime ClickUp IDs are confined to the per-feature manifest — the only
place they are committed.
Rationale: an adopting repo's product and pipeline stay clean and tool-agnostic; the extension
is fully removable by deleting scaffolding.

### V. Deterministic Logic Is Tested (NON-NEGOTIABLE)
All deterministic logic — `tasks.md` parsing, status derivation, manifest I/O, hashing — MUST
live in `scripts/bash/` and MUST carry `*.test.sh` unit coverage that passes before any change
is committed. The non-deterministic ClickUp MCP orchestration lives in the command prompts and
is validated manually against a real workspace via the feature's `quickstart.md`; it MUST NOT
embed deterministic logic that belongs in a tested script.
Rationale: the parts that can be tested cheaply must be; the boundary between tested bash and
manually-validated MCP orchestration is deliberate and must not blur.

## Additional Constraints

- **Config-only retargeting**: pointing the sync at a different workspace/space/list MUST require
  editing only `config.yml` — never a code change. Provisioning MUST refuse to run while the
  `<...>` placeholders remain in `config.yml`.
- **No node package**: this is `extension.yml` + `config.yml` + markdown command prompts + bash.
  It MUST NOT acquire a `package.json` publish contract or importable JS; it is distributed as a
  Spec Kit preset/extension.

## Development Workflow

- **Test gate**: the full `scripts/bash/*.test.sh` suite MUST pass locally before a commit that
  touches deterministic logic. New deterministic behavior lands with its test in the same change
  (test-first where it fits).
- **Manual MCP validation**: changes to the command prompts' ClickUp orchestration are validated
  by running the feature `quickstart.md` against a real ClickUp workspace, since MCP side effects
  cannot be unit-tested here.
- **Amendments**: changes to this constitution follow the Governance rules below.

## Governance

This constitution supersedes ad-hoc practice for this repo. Amendments MUST be made by editing
this file, with the version bumped per the policy below and the change recorded in the Sync
Impact Report at the top.

Versioning policy (semantic):
- **MAJOR**: a principle is removed or redefined in a backward-incompatible way.
- **MINOR**: a new principle or section is added, or guidance is materially expanded.
- **PATCH**: clarifications, wording, or non-semantic refinements.

Compliance: any change to the extension MUST be checked against these five principles before it
is committed; a change that breaks an invariant is a defect. Complexity that appears to require
violating a principle MUST instead be justified and, if genuinely warranted, ratified as an
explicit amendment first.

**Version**: 1.0.0 | **Ratified**: 2026-07-07 | **Last Amended**: 2026-07-07
