# Contract: Six-state lifecycle + status mapping (US3)

## The six logical states (card level)

```
open → in-design → ready → in-development → in-review → done
```

| State | Derivation | Set by |
|---|---|---|
| `open` | no `spec.md` (feature just provisioned) | provision (card born here, FR-013a) |
| `in-design` | `spec.md` present | after_specify / clarify / plan sync |
| `ready` | `tasks.md` present | after_tasks / after_analyze sync |
| `in-development` | implement run | after_implement sync; after_converge stays here |
| `in-review` | `lifecycle.verifyPassed == true` | `/speckit-verify` on pass |
| `done` | `lifecycle.closedOut == true` | `/speckit-close` on sign-off |

Subtasks use **three** states only (not-started / in-progress / done) from their own task
completion — never the design/ready/review states (FR-016).

## Command → state mapping (every command syncs — FR-013)

| Command / hook | Card state after |
|---|---|
| provision | `open` |
| after_specify, after_clarify, after_plan | `in-design` |
| after_tasks, after_analyze | `ready` |
| after_implement, after_converge | `in-development` |
| `/speckit-verify` (pass) | `in-review` |
| `/speckit-close` (sign-off) | `done` |

Every command runs a sync (content and/or status). A command that changes nothing is a no-op sync
(zero writes — FR-014), not a skipped one.

## Logical → actual mapping + 3-fallback (FR-015)

- `config.yml`'s `statuses:` block maps each logical state to the list's actual status name;
  provision resolves/validates it and records it in the manifest's `statusMapping`.
- **Fallback**: a list without six distinct statuses collapses the six logical states onto three
  (not-started / in-progress / done) by nearest-status. Deterministic + unit-tested
  (`clickup-status-map.sh`). The sync reports the degradation rather than failing.

## Derivation contract (`clickup-derive-status.sh`, extended)
- Input: feature dir + triggering command (+ manifest `lifecycle` markers for states 5–6).
- Output: one of the six logical states (card) or three (subtask, via `--us`).
- Pure, idempotent for states 1–4 (re-running the same repo state yields the same state);
  states 5–6 read the recorded markers. No time/random in hashed input.
