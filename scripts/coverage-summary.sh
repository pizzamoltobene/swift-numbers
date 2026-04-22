#!/usr/bin/env bash
set -euo pipefail

RUN_TESTS=1
THRESHOLD=70

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-test)
      RUN_TESTS=0
      shift
      ;;
    --threshold)
      THRESHOLD="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ "$RUN_TESTS" -eq 1 ]]; then
  PROFILE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/swiftnumbers-profiles.XXXXXX")"
  export LLVM_PROFILE_FILE="$PROFILE_DIR/%p.profraw"
  swift test --enable-code-coverage

  if ! find "$PROFILE_DIR" -type f -name '*.profraw' -size +0c | grep -q .; then
    echo "No non-empty LLVM profile files were generated in $PROFILE_DIR"
    exit 1
  fi
fi

CODECOV_JSON_PATH="$(swift test --show-codecov-path | tail -n 1)"

if [[ ! -f "$CODECOV_JSON_PATH" ]]; then
  echo "Code coverage JSON path not found: $CODECOV_JSON_PATH"
  exit 1
fi

echo "Coverage JSON: $CODECOV_JSON_PATH"
python3 - <<'PY' "$CODECOV_JSON_PATH" "$THRESHOLD"
import json
import sys

path = sys.argv[1]
threshold = float(sys.argv[2])

with open(path, "r", encoding="utf-8") as f:
    payload = json.load(f)

data = payload.get("data", [])
if not data:
    print("No coverage data found")
    raise SystemExit(1)

totals = data[0].get("totals", {}).get("lines", {})
total_covered = int(totals.get("covered", 0))
total_count = int(totals.get("count", 0))
total_pct = (total_covered / total_count * 100.0) if total_count else 0.0
print(f"All code line coverage: {total_covered}/{total_count} ({total_pct:.2f}%)")

first_party_prefixes = (
    "/Sources/SwiftNumbers",
    "/Sources/swiftnumbers/",
    "/Tests/SwiftNumbersTests/",
)

first_covered = 0
first_count = 0
for file_entry in data[0].get("files", []):
    filename = file_entry.get("filename", "")
    if not any(prefix in filename for prefix in first_party_prefixes):
        continue
    lines = file_entry.get("summary", {}).get("lines", {})
    first_covered += int(lines.get("covered", 0))
    first_count += int(lines.get("count", 0))

if first_count <= 0:
    print("No first-party coverage entries found.")
    raise SystemExit(1)

first_pct = (first_covered / first_count * 100.0)
print(f"First-party line coverage: {first_covered}/{first_count} ({first_pct:.2f}%)")
print(f"First-party coverage threshold: {threshold:.2f}%")

if first_pct < threshold:
    print(
        f"Coverage gate failed: first-party coverage {first_pct:.2f}% is below threshold {threshold:.2f}%"
    )
    raise SystemExit(1)
PY
