# Contract: Engine consolidation & module layout (US9)

## What consolidation means
The engine is **one repo + one registry** (`.specify/extensions.yml`) that wires the snackbyte
lifecycle extensions as a single spine. The five snackbyte-authored extensions are co-located here
as command-modules, each keeping its package shape and prior behavior (Decision 1). Installing the
engine gives a project the whole spine plus the tracker-plug interface.

## The modules

| Module | Role | Lifecycle point |
|---|---|---|
| `git-specify-branch` | clean tree + feature branch | `before_specify` |
| `specify-review-loop` (→ review module) | recursive review, **target: spec or code** | after specify; inside `/speckit-verify` |
| `analyze-autofix` | apply unambiguous artifact fixes | `after_analyze` |
| `git-commit` | checkpoint commit | `before_implement`; reused by `/speckit-close` |
| `clickup-sync` (the ClickUp plug) | tracker mirroring | `after_*` + verify/close |

## Review module — two targets (FR-037)
One implementation, parameterized by target:
- `target: spec` — review `spec.md` (the existing `specify-review-loop` behavior), after specify.
- `target: code` — review implemented code + tests, invoked by `/speckit-verify` step 1.
Same recursion (fix-unambiguous → reloop → stop when nothing fixable or needs the user). The review
logic exists once (not duplicated).

## Exclusions & scope
- **`agent-context` is excluded** (authored by `spec-kit-core`, not snackbyte) — neither absorbed
  nor broken; it remains a separate community extension the engine coexists with (FR-038).
- **Other repos' migration is out of scope** — build + prove the engine here first; downstream
  adoption is follow-on (FR-039).

## Tracker-plug interface (the seam — Decision 7)
The engine core talks to a tracker only through a plug that implements:
`resolve-target` · `create/update-item` · `set-checklist` · `link-dependency` · `update-status` ·
`attach-provenance`. ClickUp is the one concrete plug (its MCP orchestration). The local plug and
multi-plug broadcasting (FR-032/SC-013) are **not built** in this feature — the seam is established,
the machinery is deferred. An uninstalled plug is a no-op, not an error (Constitution VI).
