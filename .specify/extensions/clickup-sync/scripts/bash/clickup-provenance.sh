#!/usr/bin/env bash
# Render a feature's commit provenance into a canonical, hash-deduped block (US6, Option A).
#
# Pure repo-side logic — no ClickUp, no MCP. Reads git history for the feature and emits a
# stable markdown block the sync pushes to the card (comment / body section). Deduped by hash so
# re-runs add nothing (SC-009). Option B (native GitHub integration) is a documented opt-in that
# stands this down — see the sync command / FR-024a.
#
# Subcommands:
#   render --feature <name> [--path <pathspec>]
#       Print the canonical provenance block (markdown) for commits touching the feature.
#       Selection: commits whose message references the feature name, OR (if --path given)
#       commits touching that path. Deterministic order (most recent first), fixed format.
#   hash --feature <name> [--path <pathspec>]
#       Print sha256 of the rendered block (the dedup key stored as card.provenanceHash).
#
# Output: the block, or its hash. Exit 0. Exit 2 on bad usage.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../../scripts/bash/common.sh"

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print "sha256:"$1}'
    elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print "sha256:"$1}'
    else echo "ERROR: no sha256sum/shasum" >&2; exit 3; fi
}

# Emit the canonical provenance block for the feature. Deterministic: fixed header, one line per
# commit "<shorthash> <subject>", no dates/authors (which would break the stable hash), newest
# first. Empty history → a header with an explicit "(no commits yet)" line.
render_block() {
    local feature="$1" pathspec="${2:-}"
    local log
    if [[ -n "$pathspec" ]]; then
        log="$(git log --no-merges --format='%h %s' -- "$pathspec" 2>/dev/null || true)"
    else
        # commits whose subject/body references the feature name (grep is fixed-string, case-insens)
        log="$(git log --no-merges --format='%h %s' --grep="$feature" -i 2>/dev/null || true)"
    fi
    printf '## Commits (%s)\n\n' "$feature"
    if [[ -z "$log" ]]; then
        printf '(no commits yet)\n'
    else
        # strip trailing whitespace per line for hash stability
        printf '%s\n' "$log" | sed 's/[[:space:]]*$//'
    fi
}

SUB="${1:-}"; shift || true
FEATURE=""; PATHSPEC=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --feature) FEATURE="${2:-}"; shift 2 ;;
        --path) PATHSPEC="${2:-}"; shift 2 ;;
        --help|-h) sed -n '2,20p' "$0"; exit 0 ;;
        *) shift ;;
    esac
done

case "$SUB" in
    render)
        [[ -n "$FEATURE" ]] || { echo "usage: render --feature <name> [--path <pathspec>]" >&2; exit 2; }
        render_block "$FEATURE" "$PATHSPEC"
        ;;
    hash)
        [[ -n "$FEATURE" ]] || { echo "usage: hash --feature <name> [--path <pathspec>]" >&2; exit 2; }
        render_block "$FEATURE" "$PATHSPEC" | sed 's/[[:space:]]*$//' | sha256
        ;;
    *)
        echo "usage: clickup-provenance.sh {render|hash} --feature <name> [--path <pathspec>]" >&2; exit 2 ;;
esac
