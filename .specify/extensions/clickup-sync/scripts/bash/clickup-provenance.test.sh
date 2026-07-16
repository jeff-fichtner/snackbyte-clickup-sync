#!/usr/bin/env bash
# Tests for clickup-provenance.sh — git log → canonical, hash-deduped provenance block.
# Run: bash .specify/extensions/clickup-sync/scripts/bash/clickup-provenance.test.sh
set -uo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROV="$DIR/clickup-provenance.sh"
FAIL_F="$(mktemp)"
ok()  { printf '  ok   %s\n' "$1"; }
bad() { echo x >> "$FAIL_F"; printf '  FAIL %s — got %s\n' "$1" "$2"; }

# Build a scratch git repo with known history so the test is deterministic.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  git init -q
  git config user.email t@t.t; git config user.name t
  git config commit.gpgsign false
  echo a > a.txt; git add a.txt; git commit -q -m "feat: add thing for zzz-feat"
  echo b > b.txt; git add b.txt; git commit -q -m "fix: unrelated work"
  echo c >> a.txt; git add a.txt; git commit -q -m "docs: more zzz-feat notes"
) || { echo "  FAIL could not build scratch git repo"; echo x >> "$FAIL_F"; }

run() { ( cd "$TMP" && bash "$PROV" "$@" ); }

# 1. render by feature name → block contains the two matching commits, not the unrelated one
block="$(run render --feature zzz-feat)"
echo "$block" | grep -q 'zzz-feat' && ok "render includes feature commits" || bad "render-includes" "no match"
echo "$block" | grep -q 'unrelated' && bad "render excludes unrelated" "leaked" || ok "render excludes unrelated commit"
echo "$block" | grep -q '^## Commits (zzz-feat)' && ok "render has canonical header" || bad "render-header" "no header"

# 2. hash is stable across runs for the same history
h1="$(run hash --feature zzz-feat)"; h2="$(run hash --feature zzz-feat)"
[[ "$h1" == "$h2" && "$h1" == sha256:* ]] && ok "hash stable + sha256-prefixed" || bad "hash-stable" "$h1/$h2"

# 3. different feature selection → different hash
h3="$(run hash --feature nomatch-xyz)"
[[ "$h3" != "$h1" ]] && ok "different selection → different hash" || bad "hash-differ" "same"

# 4. empty selection (no matching commits) → the "(no commits yet)" block, still hashes
echo "$(run render --feature nomatch-xyz)" | grep -q 'no commits yet' && ok "empty selection handled" || bad "empty" "no placeholder"
[[ "$h3" == sha256:* ]] && ok "empty selection still hashes" || bad "empty-hash" "$h3"

# 5. bad usage → non-zero exit
if run render >/dev/null 2>&1; then bad "missing --feature should fail" "exit0"; else ok "missing --feature → non-zero exit"; fi

n="$(wc -l < "$FAIL_F" | tr -d "[:space:]")"; n="${n:-0}"
echo ""
if [[ "$n" -eq 0 ]]; then echo "provenance: ALL PASS"; else echo "provenance: $n FAIL"; exit 1; fi
