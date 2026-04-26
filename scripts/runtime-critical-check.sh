#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

critical_paths=(
  "scripts/ci-check.sh"
  "scripts/ci-format-check.sh"
  "scripts/ci-lint.sh"
  "scripts/coverage-summary.sh"
  "scripts/release_autofix.sh"
  "scripts/release_publish.sh"
  "scripts/release_check.sh"
  ".github/workflows/ci.yml"
)

forbidden_runtime_pattern='(^|[[:space:]])(python3?|pip3?|node|npm|npx|ruby|bundle|gem)([[:space:]]|$)'
found_forbidden_runtime=0

for rel_path in "${critical_paths[@]}"; do
  abs_path="$REPO_ROOT/$rel_path"
  if [[ ! -f "$abs_path" ]]; then
    echo "Missing critical-path file: $rel_path" >&2
    exit 1
  fi

  matches="$(grep -nE "$forbidden_runtime_pattern" "$abs_path" || true)"
  if [[ -n "$matches" ]]; then
    found_forbidden_runtime=1
    echo "Forbidden runtime reference detected in $rel_path" >&2
    echo "$matches" >&2
  fi
done

if [[ "$found_forbidden_runtime" -ne 0 ]]; then
  echo "Critical-path runtime audit failed: remove Python/Node/Ruby tooling from CI/release path." >&2
  exit 1
fi

echo "Critical-path runtime audit passed."
