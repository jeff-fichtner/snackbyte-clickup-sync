# snackbyte-clickup-sync

**The one-way Spec-Kit → ClickUp sync extension**, standalone in its own repo. Mirrors each
Spec Kit feature into ClickUp as a feature-card + US-subtasks + `tasks.md` checklist, derives
status from the Spec Kit flow, all MCP-only, repo-as-source-of-truth.

## What it is

A Spec Kit extension (same package shape as `git-commit`, `agent-context`, and the other
snackbyte extensions): `extension.yml` + `config.yml` + markdown command prompts
(`speckit.clickup.*`) + bash helpers with `*.test.sh` coverage. It is **not** a node package;
the `package.json` here exists only to provide the local check gate.

Two commands, wired as optional lifecycle hooks in `.specify/extensions.yml`:

- **`/speckit-clickup-provision`** (`after_plan`) — find-or-create the ClickUp space + shared
  list, resolve the status mapping, record targets in the feature manifest. On an unconfigured
  repo it asks once for the space/list, saves what you give it, and remembers a decline
  (`enabled: false`) so it never re-asks.
- **`/speckit-clickup-sync`** (`after_tasks`, `after_implement`) — make the feature's ClickUp
  card (body, US-subtasks, checklist, dependencies, status) match the repo. One-way, idempotent
  (a no-op run makes zero ClickUp writes), MCP-only.

## Configure

Edit `.specify/extensions/clickup-sync/config.yml`:

```yaml
space: "<your-space-name>"        # ClickUp space the shared list lives in
list:  "<your-shared-list-name>"  # the one shared list all feature-cards go into
```

No IDs or credentials go here — the connected ClickUp MCP server handles auth, and runtime IDs
live only in each feature's `specs/<feature>/.clickup-sync.json` manifest. In *this* repo the
config points at the `snackbyte-clickup-sync` ClickUp space; a shippable copy ships the
`<your-…>` placeholders.

## Check gate

```bash
npm run check:all      # shell-syntax lint + every *.test.sh (the clickup-* helpers)
```

## Layout

```
.specify/extensions/clickup-sync/
├── extension.yml                       # package declaration + hook slots
├── config.yml                          # per-repo space/list (no IDs/secrets)
├── commands/speckit.clickup.*.md       # the two command prompts (ClickUp MCP orchestration)
└── scripts/bash/clickup-*.sh           # repo-side helpers (parse/derive/hash/manifest) + tests
.claude/skills/speckit-clickup-*/       # user-invocable skill mirrors
.specify/extensions.yml                 # installs + wires the extension into the lifecycle
```

## Specs

- [`001-clickup-sync`](specs/001-clickup-sync/spec.md) — the shipped push-and-status extension
  (this repo). Validated end-to-end against a live ClickUp workspace.
- [`002-clickup-lifecycle`](specs/002-clickup-lifecycle/BACKLOG.md) — backlog: richer status
  lifecycle, human-testing handoff, manual mode, per-project rules, commit/PR links, and the
  post-implement test-everything + close-out gate. Not yet specified; split into per-track
  feature dirs when specifying.
