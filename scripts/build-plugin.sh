#!/usr/bin/env bash
#
# build-plugin.sh — package this repo into an installable .plugin bundle.
#
# The bundle is generated, never committed. CI attaches it to releases.
#
# The bundle at the repo root is committed on purpose — the README ships it as an
# install path. It must be rebuilt whenever any packaged source file changes;
# CI runs --check to enforce that.
#
# Usage:
#   scripts/build-plugin.sh            rebuild the committed bundle
#   scripts/build-plugin.sh --check    fail if the committed bundle is stale
#   scripts/build-plugin.sh -o PATH    write elsewhere
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/cmyk-print-converter.plugin"
CHECK=0

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--out) OUT="$2"; shift 2;;
    --check)  CHECK=1; shift;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
done

# Everything the installed plugin needs at runtime. Deliberately excludes tests,
# CI config, docs, and the repo's own meta files.
CONTENTS=(README.md LICENSE .claude-plugin scripts/rgb2cmyk.sh skills)

cd "$REPO_ROOT"
for item in "${CONTENTS[@]}"; do
  [ -e "$item" ] || { echo "ERROR: missing required content: $item" >&2; exit 1; }
done

# --check rebuilds into a temp file and compares against the committed bundle,
# so a source edit that was never re-packaged fails CI instead of shipping stale.
if [ "$CHECK" -eq 1 ]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  REBUILT="$TMP/rebuilt.plugin"
  zip -qrX "$REBUILT" "${CONTENTS[@]}" -x '*.DS_Store' '__MACOSX/*'
  [ -f "$OUT" ] || { echo "ERROR: committed bundle missing: $OUT" >&2; exit 1; }
  # Compare contents, not zip bytes: timestamps differ between builds.
  A="$TMP/a"; B="$TMP/b"; mkdir -p "$A" "$B"
  unzip -qo "$OUT" -d "$A"; unzip -qo "$REBUILT" -d "$B"
  if diff -r "$A" "$B" >/dev/null 2>&1; then
    echo "Bundle is up to date with source."
    exit 0
  fi
  echo "ERROR: cmyk-print-converter.plugin is STALE — it does not match the source tree." >&2
  echo "       Rebuild it and commit the result:  scripts/build-plugin.sh" >&2
  diff -r "$A" "$B" | head -20 >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
zip -qrX "$OUT" "${CONTENTS[@]}" -x '*.DS_Store' '__MACOSX/*'

echo "Built: $OUT"
echo "Size:  $(wc -c < "$OUT") bytes"
# awk, not `head -n -2`: BSD/macOS head has no negative-count form.
unzip -l "$OUT" | awk 'NR>3 && !/^-----/ && NF>=4 {print "  " $4}'
