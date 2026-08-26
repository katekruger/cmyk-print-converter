#!/usr/bin/env bash
#
# bump-version.sh <new-version>
#
# Updates every version field named in .version-bump.json, then verifies they agree.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ $# -eq 1 ] || { echo "Usage: scripts/bump-version.sh <new-version>   e.g. 0.2.0" >&2; exit 1; }
echo "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo "ERROR: '$1' is not semver (x.y.z)" >&2; exit 1; }

NEW="$1" python3 - <<'PY'
import json, os, re, sys, pathlib
new = os.environ['NEW']
spec = json.load(open('.version-bump.json'))
for entry in spec['files']:
    p = pathlib.Path(entry['path'])
    if not p.exists():
        print(f"ERROR: {p} listed in .version-bump.json but missing", file=sys.stderr); sys.exit(1)
    field = entry['field']
    if field.startswith('badge:'):
        pat = field[len('badge:'):]
        text = p.read_text()
        m = re.search(pat, text)
        if not m:
            print(f"ERROR: no version badge match in {p}", file=sys.stderr); sys.exit(1)
        s, e = m.span(1)
        p.write_text(text[:s] + new + text[e:])
    else:
        data = json.loads(p.read_text())
        node, parts = data, field.split('.')
        for part in parts[:-1]:
            node = node[int(part)] if part.isdigit() else node[part]
        last = parts[-1]
        node[int(last) if last.isdigit() else last] = new
        p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"  updated {p}")
print(f"\nBumped to {new}. Now add a CHANGELOG entry and tag v{new}.")
PY
bash scripts/check-versions.sh
