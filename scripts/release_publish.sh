#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"
RELEASE_CHECK="$SCRIPT_DIR/release_check.sh"

DRY_RUN=0
TAG=""
TITLE=""
NOTES_FILE=""
MANUAL_NUMBERS_OK="${SWIFT_NUMBERS_NUMBERS_APP_OK:-0}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/release_publish.sh [options]

Options:
  --tag <tag>            Release tag, e.g. v0.3.3 (required unless deriving from changelog)
  --title <title>        Release title (defaults to tag)
  --notes-file <path>    Release notes file (defaults to changelog section for tag)
  --dry-run              Validate and print planned release commands without publishing
  -h, --help             Show help

Environment:
  SWIFT_NUMBERS_NUMBERS_APP_OK=1   Mark manual Numbers.app smoke check as passed for release_check.sh
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --notes-file)
      NOTES_FILE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
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

derive_tag_from_changelog() {
  sed -n 's/^## \[\([^]]*\)\].*/\1/p' "$CHANGELOG_PATH" | \
    awk '$1 != "Unreleased" { print $1; exit }'
}

if [[ -z "$TAG" ]]; then
  derived="$(derive_tag_from_changelog)"
  if [[ -z "$derived" ]]; then
    echo "Unable to derive tag from CHANGELOG.md; pass --tag" >&2
    exit 1
  fi
  TAG="$derived"
fi

if [[ -z "$TITLE" ]]; then
  TITLE="$TAG"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
    echo "Refusing to publish release with dirty working tree. Commit or stash changes first." >&2
    exit 1
  fi
fi

if [[ "$TAG" != v* ]]; then
  TAG="v$TAG"
fi

tmp_notes=""
cleanup() {
  if [[ -n "$tmp_notes" && -f "$tmp_notes" ]]; then
    rm -f "$tmp_notes"
  fi
}
trap cleanup EXIT

if [[ -z "$NOTES_FILE" ]]; then
  tmp_notes="$(mktemp "${TMPDIR:-/tmp}/swiftnumbers-release-notes.XXXXXX.md")"
  version_no_v="${TAG#v}"
  awk -v section="$version_no_v" '
    $0 ~ "^## \\[" section "\\]" { in_section=1; next }
    in_section && $0 ~ "^## \\[" { exit }
    in_section { print }
  ' "$CHANGELOG_PATH" > "$tmp_notes"
  if [[ ! -s "$tmp_notes" ]]; then
    echo "No changelog section found for $version_no_v in CHANGELOG.md" >&2
    exit 1
  fi
  NOTES_FILE="$tmp_notes"
fi

echo "Running release quality gate..."
SWIFT_NUMBERS_NUMBERS_APP_OK="$MANUAL_NUMBERS_OK" "$RELEASE_CHECK" "$REPO_ROOT/.local/release-check.json"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run mode. Planned commands:"
  echo "  git -C \"$REPO_ROOT\" tag -a \"$TAG\" -m \"$TITLE\""
  echo "  git -C \"$REPO_ROOT\" push origin HEAD"
  echo "  git -C \"$REPO_ROOT\" push origin \"$TAG\""
  echo "  gh release create \"$TAG\" --title \"$TITLE\" --notes-file \"$NOTES_FILE\" --verify-tag"
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required for publishing releases." >&2
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "gh is not authenticated for github.com." >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" rev-parse "$TAG" >/dev/null 2>&1; then
  git -C "$REPO_ROOT" tag -a "$TAG" -m "$TITLE"
fi

git -C "$REPO_ROOT" push origin HEAD
git -C "$REPO_ROOT" push origin "$TAG"

gh release create "$TAG" --title "$TITLE" --notes-file "$NOTES_FILE" --verify-tag
echo "Published GitHub release $TAG"
