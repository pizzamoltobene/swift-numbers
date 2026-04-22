#!/usr/bin/env bash
set -euo pipefail

swift test --enable-code-coverage
CODECOV_JSON_PATH="$(swift test --show-codecov-path | tail -n 1)"

if [[ -f "$CODECOV_JSON_PATH" ]]; then
  echo "Coverage JSON: $CODECOV_JSON_PATH"
  python3 - <<'PY' "$CODECOV_JSON_PATH"
import json
import sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    payload = json.load(f)
data = payload.get('data', [])
if not data:
    print('No coverage data found')
    raise SystemExit(0)
functions = data[0].get('totals', {})
lines = functions.get('lines', {})
covered = lines.get('covered', 0)
count = lines.get('count', 0)
pct = (covered / count * 100.0) if count else 0.0
print(f"Line coverage: {covered}/{count} ({pct:.2f}%)")
PY
else
  echo "Code coverage JSON path not found"
  exit 1
fi
