#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"
THRESHOLD=""
CHECK_MODE=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/release_batch_count.sh [options]

Options:
  --changelog <path>    Path to changelog file (default: ./CHANGELOG.md)
  --threshold <number>  Threshold for --check mode (default: 15)
  --check               Exit 0 when count >= threshold, else exit 1
  -h, --help            Show help

Behavior:
  - Prints count of non-placeholder bullets in CHANGELOG "Unreleased -> Summary".
  - Excludes "- Pending." placeholder entries from the count.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --changelog)
      CHANGELOG_PATH="${2:-}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:-}"
      shift 2
      ;;
    --check)
      CHECK_MODE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$CHANGELOG_PATH" ]]; then
  echo "Changelog file not found: $CHANGELOG_PATH" >&2
  exit 1
fi

if [[ -z "$THRESHOLD" ]]; then
  THRESHOLD=15
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "--threshold must be a non-negative integer" >&2
  exit 1
fi

count="$(
  awk '
BEGIN {
  in_unreleased = 0
  in_summary = 0
  count = 0
}
$0 == "## [Unreleased]" {
  in_unreleased = 1
  in_summary = 0
  next
}
in_unreleased && /^## \[/ {
  in_unreleased = 0
  in_summary = 0
  exit
}
in_unreleased && $0 == "### Summary" {
  in_summary = 1
  next
}
in_unreleased && in_summary && /^### / {
  in_summary = 0
  exit
}
in_unreleased && in_summary && /^- / {
  item = $0
  sub(/^- /, "", item)
  trimmed = item
  gsub(/[[:space:]]/, "", trimmed)
  lower = tolower(item)
  gsub(/[[:space:]]/, "", lower)
  if (trimmed == "" || lower == "pending." || lower == "pending") {
    next
  }
  count++
}
END {
  print count + 0
}
' "$CHANGELOG_PATH"
)"

echo "$count"

if [[ "$CHECK_MODE" -eq 1 ]]; then
  if [[ "$count" -ge "$THRESHOLD" ]]; then
    exit 0
  fi
  exit 1
fi
