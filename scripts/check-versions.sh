#!/usr/bin/env bash
# Fail if the version string disagrees across the files named in .version-bump.json.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 - <<'PY'
import json, re, sys, pathlib

spec = json.load(open('.version-bump.json'))
found = {}
for entry in spec['files']:
    p = pathlib.Path(entry['path'])
    if not p.exists():
        print(f"  MISSING {p} (listed in .version-bump.json)"); sys.exit(1)
    field = entry['field']
    if field.startswith('badge:'):
        m = re.search(field[len('badge:'):], p.read_text())
        v = m.group(1) if m else None
    else:
        node = json.loads(p.read_text())
        for part in field.split('.'):
            node = node[int(part)] if part.isdigit() else node[part]
        v = node
    if v is None:
        print(f"  MISSING version in {p} (field {field})"); sys.exit(1)
    found[str(p)] = v
    print(f"  {v}  {p}")

if len(set(found.values())) != 1:
    print("\nVersion mismatch across files:"); sys.exit(1)
print(f"\nAll versions agree: {next(iter(found.values()))}")
PY
