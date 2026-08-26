#!/usr/bin/env bash
#
# build-plugin.sh — package this repo into an installable .plugin bundle.
#
# The bundle is generated, never committed. CI attaches it to releases.
#
# Usage:
#   scripts/build-plugin.sh [-o OUTPUT]     (default: dist/cmyk-print-converter.plugin)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/dist/cmyk-print-converter.plugin"

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--out) OUT="$2"; shift 2;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
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

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
zip -qr "$OUT" "${CONTENTS[@]}" -x '*.DS_Store' '__MACOSX/*'

echo "Built: $OUT"
echo "Size:  $(wc -c < "$OUT") bytes"
# awk, not `head -n -2`: BSD/macOS head has no negative-count form.
unzip -l "$OUT" | awk 'NR>3 && !/^-----/ && NF>=4 {print "  " $4}'
