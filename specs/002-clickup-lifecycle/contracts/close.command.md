# Contract: `/speckit-close` command (US2)

The terminal ceremony: surface remaining manual tasks → human sign-off → mark done → final sync →
commit. User-invoked (human-paced), run when the human is ready. Reaches the `done` state.

## Preconditions
- The card is at `in-review` (i.e. `/speckit-verify` passed — the normal path).
- The check gate is green (close re-runs it — FR-010a).

## Steps (in order)
1. **Re-run the check gate** (FR-010a). Red → refuse to close (no sign-off, no sync, no commit),
   surface the failure. Close never closes over a red gate.
2. **Confirm non-manual completeness** — all non-manual tasks complete, else refuse and report what
   remains (FR-010).
3. **Surface manual tasks** — list the remaining manual / human-in-the-loop tasks and **wait for
   explicit sign-off**. Never auto-check them (FR-007). The human answers in the flow (terminal),
   not by editing the tracker.
4. **On sign-off** — mark those tasks done in `tasks.md`; set `lifecycle.closedOut = true`.
5. **Final sync** — run the one-way sync so the card + subtasks reach `done`/shipped (FR-008). The
   sync itself makes **no commit** (FR-009 / Constitution I).
6. **Commit** — commit the close-out edits as a distinct commit (reusing the git-commit module),
   because the implement-time checkpoint fired before these edits existed.
7. **Handoff** — emit the closing handoff report.

## Outcomes
- **Signed off** → tasks checked, card `done`, close-out committed, handoff emitted.
- **Refused** (red gate / incomplete non-manual work / no sign-off) → nothing changes; report why.

## Never
- Never auto-checks a manual task (FR-007) or advances to `done` without sign-off (FR-020).
- The sync step never commits (FR-009); the commit is a separate step.
- Never requires the human to touch the tracker — sign-off is a flow input (FR-017).
