# Phase 1 Data Model: Engine Lifecycle

Extends the 001 ClickUp plug's data model **additively** (per the manifest upgrade contract) — no
existing field is renamed or removed. New fields carry the six-state lifecycle, provenance, and the
config status mapping.

## Entities

### Feature-card
The one tracker item per feature. Carries the **six-state** lifecycle status, a synthesized body,
and (US6) commit provenance. Owned solely by the engine (the AI writes it; humans never do).
- **status**: one of the six logical states (below), mapped to the list's actual status name.
- **body**: spec summary + user-story list + artifact links (from 001, unchanged).
- **provenance**: the feature's commits rendered into the card (Option A), deduped by hash.

### US-subtask
One per user story. **Three-state** (not-started / in-progress / done), derived from that story's
own task completion. Never carries the design/ready/review states (FR-016). Carries `waiting_on`
dependency edges from the spec's story order (from 001, unchanged).

### Six-state lifecycle (the card state machine)

| # | Logical state | Enters when | Derivation source |
|---|---|---|---|
| 1 | `open` | feature provisioned, before specify | no `spec.md` yet |
| 2 | `in-design` | after specify / clarify / plan | `spec.md` present |
| 3 | `ready` | after tasks / analyze | `tasks.md` present (design complete) |
| 4 | `in-development` | after implement (and converge) | implement run; converge stays here |
| 5 | `in-review` | `/speckit-verify` passes | recorded verify-pass marker |
| 6 | `done` | `/speckit-close` + sign-off | recorded close/sign-off marker |

**Transitions**: strictly forward in the normal flow; the engine re-derives on every command. States
1–4 derive from artifact presence (idempotent). States 5–6 require a recorded marker (verify-passed,
signed-off) because artifact presence alone can't distinguish them — the marker is set by the
verify/close commands, never inferred.

### Status mapping (logical → actual, with 3-fallback)
The six logical states mapped to a list's real status names, held in `config.yml` and resolved into
the manifest. Where a list lacks six distinct statuses, the mapping collapses to three
(not-started / in-progress / done) via the nearest-status rule — a deterministic, tested function.

### Manual item
A tracker card with no backing `tasks.md`. Distinguished purely by **absence from any feature
manifest** (FR-022) — the engine only touches manifest-recorded cards, so a manual item is never
derived or overwritten. No marker needed.

### Designed ruleset (US7)
Agent-proposed, human-approved per-project config layered over the baked-in defaults; the sync
honors it when present, else uses defaults unchanged.

## Extended manifest — `specs/<feature>/.clickup-sync.json`

```jsonc
{
  "schemaVersion": "1",                     // unchanged — additions are additive
  "feature": "002-clickup-lifecycle",
  "workspaceId": "…", "spaceId": "…", "listId": "…",
  "statusMapping": {                         // EXTENDED: six logical states (was three)
    "open": "backlog",
    "in-design": "in design",
    "ready": "ready for development",
    "in-development": "in development",
    "in-review": "in review",
    "done": "shipped"
  },
  "lifecycle": {                             // NEW — the recorded markers for states 5–6
    "verifyPassed": false,                   // set true by /speckit-verify on pass
    "closedOut": false                       // set true by /speckit-close on sign-off
  },
  "card": {
    "id": "86abcd123",
    "hash": "sha256:…",                      // derived body + 6-state status
    "provenanceHash": "sha256:…"             // NEW — dedup for US6 commit provenance
  },
  "userStories": [
    { "us": "US1", "id": "…", "hash": "sha256:…", "dependsOn": [] }
  ]
}
```

**Rules** (extend 001's, all additive):
- `statusMapping` now maps the **six** logical states; a 3-status list maps multiple logical states
  to the same actual status (the fallback). Values are the list's actual status names.
- `lifecycle.verifyPassed` / `closedOut` are the only imperatively-set fields — set by the verify /
  close commands, read by status derivation for states 5–6. Everything else re-derives from repo
  state each run (idempotence preserved).
- `card.provenanceHash` dedups provenance so re-runs add no duplicate links (SC-009).
- Unknown fields are ignored by older readers; `schemaVersion` stays `1` (additive change).

## Extended config — `.specify/extensions/clickup-sync/config.yml`

```yaml
space: "<your-space-name>"
list:  "<your-shared-list-name>"
enabled: true                    # from the opt-out flow
statuses:                        # NEW — logical → actual status names (six)
  open: "backlog"
  in-design: "in design"
  ready: "ready for development"
  in-development: "in development"
  in-review: "in review"
  done: "shipped"
```

**Rules**: `statuses` is optional — absent, provision resolves a best-effort mapping from the list's
real statuses and records it in the manifest. No IDs or secrets (Constitution II/IV). Retargeting or
remapping is a config edit only.

## Validation rules (from the spec)

- Card status is always one of the six logical states, mapped through `statusMapping`; never a raw
  actual name in logic (FR-012/015).
- Subtask status is always one of three (FR-016).
- A no-op run writes nothing; a status-only change writes only status (FR-014, SC-006).
- `in-review` is set only when `lifecycle.verifyPassed` is true (FR-034); `done` only when
  `closedOut` is true after sign-off (FR-020).
- The engine touches only manifest-recorded cards (FR-022).
