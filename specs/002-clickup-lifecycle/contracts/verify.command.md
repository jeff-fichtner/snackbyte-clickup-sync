# Contract: `/speckit-verify` command (US8)

The earned-review certification pass. Run after `implement` (and the `after_implement`→converge
chain). On success it advances the card to `in-review`; on any failure it stops and leaves the card
at `in-development`. User-invoked (not a hook) — it is a deliberate certification step.

## Preconditions
- The feature has been implemented (`implement` has run).
- The check gate exists (`npm run check:all` or the project's equivalent).

## Steps (in order — stop on first failure)
1. **Recursive code review** — invoke the consolidated review module with target `code` (US9 /
   FR-037): recursively review the implemented code + tests, fixing unambiguous issues each pass,
   until nothing fixable remains or an issue needs the user's attention. An unresolved,
   attention-needing finding is a **stop** (does not advance).
2. **Unit gate** — run the full check gate. It MUST pass. A red gate is a **stop** (FR-005/006).
3. **Automatable E2E** — drive whatever end-to-end testing the AI can automate for this feature;
   record what could not be exercised and why (FR-002/003). Inability to automate an E2E slice is
   reported, not a hard stop — but it is surfaced in the handoff.
4. **Advance** — on all of the above passing, set `lifecycle.verifyPassed = true` in the manifest
   and run the sync so the card moves to `in-review` (FR-033d / FR-034). Produce the handoff report
   (what was verified automatically vs. what remains manual — FR-004).

## Outcomes
- **Pass** → card `in-review`; `verifyPassed` recorded; handoff produced.
- **Fail at any required step** → card stays `in-development`; `verifyPassed` stays false; the
  failure is surfaced (FR-034). `in-review` is reachable ONLY through a passing verify.

## Never
- Never advances to `in-review` over a red gate or an unresolved review finding.
- Never signs off manual tasks or moves to `done` — that is `/speckit-close` (US2).
- Never writes back into repo artifacts based on tracker state (Constitution I).
