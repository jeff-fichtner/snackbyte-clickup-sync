# Contract: Config placeholder schema — `.specify/extensions/clickup-sync/config.yml`

Committed, secret-free. The only per-repo knobs an adopter sets.

## Shape

```yaml
space: "<your-space-name>"        # required — ClickUp space the shared list lives in
list:  "<your-shared-list-name>"  # required — the one shared list all feature-cards go into
enabled: true                     # optional — set false to opt this repo out of ClickUp sync
```

## Rules

- Two required string keys: `space`, `list`. One optional boolean key: `enabled`.
- MUST contain **no** workspace/space/list IDs and **no** credentials (FR-021, SC-012).
- Ships with the `<your-…>` placeholder values.
- **Placeholder → ask → remember** (provision + sync): while `space`/`list` are placeholders,
  provision **asks the user once** for the space/list.
  - If the user provides them, provision **saves** the real values into this file — the
    question is never asked again.
  - If the user declines, provision writes `enabled: false` here — both provision and sync then
    **silently no-op** on every future run (never re-asking). Re-enable by deleting the key or
    setting `enabled: true` and filling `space`/`list`.
- Retargeting to a different workspace/space/list is a config edit only — no code change
  (FR-022, SC-011).
- Auth is entirely the MCP server's concern; this file never references it.
