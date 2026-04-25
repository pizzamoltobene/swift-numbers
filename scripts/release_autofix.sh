#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"
RELEASE_PUBLISH="$SCRIPT_DIR/release_publish.sh"

TASK_ID="${SWIFT_NUMBERS_TASK_ID:-}"
MANUAL_NUMBERS_OK="${SWIFT_NUMBERS_NUMBERS_APP_OK:-1}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/release_autofix.sh [options]

Options:
  --task-id <id>           Optional task identifier for commit metadata.
  --manual-numbers-ok <0|1>
                           Manual Numbers.app check flag passed to release gates.
                           Default: 1 (automation mode).
  -h, --help               Show help.

Behavior:
  1) Converts CHANGELOG "Unreleased" section into the next patch release section.
  2) Creates a fresh "Unreleased" template section.
  3) Commits all current workspace changes.
  4) Publishes official GitHub release through ./scripts/release_publish.sh.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --manual-numbers-ok)
      MANUAL_NUMBERS_OK="${2:-}"
      shift 2
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

if [[ "$MANUAL_NUMBERS_OK" != "0" && "$MANUAL_NUMBERS_OK" != "1" ]]; then
  echo "--manual-numbers-ok must be 0 or 1" >&2
  exit 1
fi

if [[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  echo "No local changes detected; nothing to release."
  exit 0
fi

increment_last_component() {
  local raw="$1"
  local IFS='.'
  local parts=()
  read -r -a parts <<<"$raw"
  if [[ ${#parts[@]} -eq 0 ]]; then
    echo "0.1.0"
    return
  fi
  local last_index=$(( ${#parts[@]} - 1 ))
  if ! [[ "${parts[$last_index]}" =~ ^[0-9]+$ ]]; then
    echo "Cannot increment non-numeric version component: $raw" >&2
    exit 1
  fi
  parts[$last_index]=$(( parts[$last_index] + 1 ))
  local out="${parts[0]}"
  local i
  for (( i = 1; i < ${#parts[@]}; i++ )); do
    out+=".${parts[$i]}"
  done
  echo "$out"
}

latest_tag="$(git -C "$REPO_ROOT" tag --list 'v*' --sort=-v:refname | head -n 1)"
if [[ -z "$latest_tag" ]]; then
  next_version="0.1.0"
else
  latest_version="${latest_tag#v}"
  next_version="$(increment_last_component "$latest_version")"
fi
next_tag="v$next_version"

tmp_changelog="$(mktemp "${TMPDIR:-/tmp}/swiftnumbers-changelog.XXXXXX.md")"
cleanup() {
  rm -f "$tmp_changelog"
}
trap cleanup EXIT

today_utc="$(date -u +%Y-%m-%d)"

awk -v version="$next_version" -v date="$today_utc" '
BEGIN {
  replaced = 0
}
$0 == "## [Unreleased]" && replaced == 0 {
  print "## [Unreleased]"
  print ""
  print "### Summary"
  print ""
  print "- Pending."
  print ""
  print "### Breaking Changes"
  print ""
  print "- None."
  print ""
  print "### Rollback Hint"
  print ""
  print "- Revert to the previous stable tag and redeploy package artifacts."
  print ""
  print "## [" version "] - " date
  replaced = 1
  next
}
{
  print
}
END {
  if (replaced == 0) {
    exit 66
  }
}
' "$CHANGELOG_PATH" >"$tmp_changelog" || {
  echo "Failed to promote CHANGELOG Unreleased section. Ensure CHANGELOG.md contains '## [Unreleased]'." >&2
  exit 1
}

mv "$tmp_changelog" "$CHANGELOG_PATH"

git -C "$REPO_ROOT" add -A
if git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "No staged diff after changelog promotion; skipping release."
  exit 0
fi

commit_message="chore(release): $next_tag"
if [[ -n "$TASK_ID" ]]; then
  commit_message="$commit_message ($TASK_ID)"
fi

git -C "$REPO_ROOT" commit -m "$commit_message"

echo "Running official release publish for $next_tag"
SWIFT_NUMBERS_NUMBERS_APP_OK="$MANUAL_NUMBERS_OK" \
  "$RELEASE_PUBLISH" --tag "$next_tag" --title "$next_tag"

echo "Release automation completed for $next_tag"
