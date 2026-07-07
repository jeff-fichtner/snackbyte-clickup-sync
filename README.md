# snackbyte-clickup-sync

**Implementation repo — the one-way Spec-Kit → ClickUp sync extension.** The first
(and, for now, only) real Spec Kit extension in the snackbyte ecosystem. The template
repo [`snackbyte-speckit-base`](../snackbyte-speckit-base) will be **generalized out of
this one** — not the other way around.

## What it is

The one-way Spec-Kit → ClickUp sync extension: mirrors each feature into ClickUp as a
feature-card + US-subtasks + `tasks.md` checklist, derives status from the Spec Kit flow,
all MCP-only, repo-as-source-of-truth. It is **not** a node package — it is
`extension.yml` + `config.yml` + markdown command prompts (`speckit.clickup.*`) + bash
scripts with `*.test.sh` coverage.

## Direction: implementation first, template second

We have a single extension, so we do here what we did with `spec-render` → `npm-base`:
**build the real thing first, then spin the template out of it.**

- **`snackbyte-clickup-sync`** (this repo) — the concrete, working extension. Source of truth.
- **[`snackbyte-speckit-base`](../snackbyte-speckit-base)** — the Spec Kit extension
  *template*, to be extracted **from what this repo proves out**. It exists *because of*
  this implementation, not before it.

Analogy: `snackbyte-spec-render` (impl) → `snackbyte-npm-base` (template generalized from it).

## Where the code is being migrated from

The extension was developed **in-tree inside `snackbyte-base`** at
`.specify/extensions/clickup-sync/` (via specs `004-clickup-sync` and the
`006-clickup-lifecycle` backlog — formerly numbered `005`). This repo is the destination
for extracting it into a standalone, shareable extension. Extraction preserves the existing
`extension.yml` / `config.yml` / `commands/` / `scripts/bash/` layout.

## Status

**Migration in progress.** Standing this repo up as a real Spec Kit project (impl-first),
then generalizing `snackbyte-speckit-base` from it. Small standalone extension — Spec Kit
kept, but light (no npm release-flow; distributed as a preset).
