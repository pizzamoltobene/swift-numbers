#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="${1:-.local/release-check.json}"
MANUAL_NUMBERS_OK="${SWIFT_NUMBERS_NUMBERS_APP_OK:-0}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"

if [[ -n "${SWIFT_NUMBERS_RELEASE_TARGET:-}" ]]; then
  release_target="$SWIFT_NUMBERS_RELEASE_TARGET"
  release_target_source="env:SWIFT_NUMBERS_RELEASE_TARGET"
else
  release_target="$(sed -n 's/^## \[\([^]]*\)\].*/\1/p' "$CHANGELOG_PATH" | head -n 1)"
  if [[ -z "$release_target" ]]; then
    release_target="unversioned"
    release_target_source="fallback"
  else
    release_target_source="CHANGELOG.md"
  fi
fi

mkdir -p "$(dirname "$REPORT_PATH")"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

swift_build_status="pass"
swift_test_status="pass"
manual_numbers_status="fail"
release_notes_status="pass"

swift_build_error=""
swift_test_error=""
release_notes_error=""

extract_changelog_section() {
  local section="$1"
  awk -v section="$section" '
    /^## \[/ {
      header = $0
      sub(/^## \[/, "", header)
      sub(/\].*$/, "", header)
      if (in_section) {
        exit
      }
      if (header == section) {
        in_section = 1
        next
      }
    }
    in_section {
      print
    }
  ' "$CHANGELOG_PATH"
}

heading_has_bullet_content() {
  local heading="$1"
  local section_text="$2"
  awk -v heading="$heading" '
    $0 == heading { in_heading = 1; next }
    in_heading && /^### / { exit }
    in_heading && /^- / { found = 1 }
    END { exit(found ? 0 : 1) }
  ' <<<"$section_text"
}

section_text="$(extract_changelog_section "$release_target")"
if [[ -z "$section_text" ]]; then
  release_notes_status="fail"
  release_notes_error="Missing changelog section for [$release_target]"
else
  required_headings=(
    "### Summary"
    "### Breaking Changes"
    "### Rollback Hint"
  )
  missing_metadata=()
  for heading in "${required_headings[@]}"; do
    if ! grep -q "^${heading}$" <<<"$section_text"; then
      missing_metadata+=("${heading#\#\#\# }")
      continue
    fi
    if ! heading_has_bullet_content "$heading" "$section_text"; then
      missing_metadata+=("${heading#\#\#\# } (no bullet items)")
    fi
  done
  if [[ ${#missing_metadata[@]} -gt 0 ]]; then
    release_notes_status="fail"
    release_notes_error="Missing required release metadata: ${missing_metadata[*]}"
  fi
fi

if ! swift build -c release --package-path "$REPO_ROOT" >/dev/null 2>&1; then
  swift_build_status="fail"
  swift_build_error="swift build -c release failed"
fi

if ! swift test --package-path "$REPO_ROOT" >/dev/null 2>&1; then
  swift_test_status="fail"
  swift_test_error="swift test failed"
fi

if [[ "$MANUAL_NUMBERS_OK" == "1" ]]; then
  manual_numbers_status="pass"
fi

overall_status="pass"
for status in \
  "$swift_build_status" \
  "$swift_test_status" \
  "$manual_numbers_status" \
  "$release_notes_status"
do
  if [[ "$status" != "pass" ]]; then
    overall_status="fail"
    break
  fi
done

cat >"$REPORT_PATH" <<JSON
{
  "schemaVersion": 1,
  "releaseTarget": "$release_target",
  "releaseTargetSource": "$release_target_source",
  "generatedAtUTC": "$timestamp",
  "overallStatus": "$overall_status",
  "checks": {
    "swiftBuildRelease": {
      "status": "$swift_build_status",
      "error": "$swift_build_error"
    },
    "swiftTests": {
      "status": "$swift_test_status",
      "error": "$swift_test_error"
    },
    "manualNumbersAppSmoke": {
      "status": "$manual_numbers_status",
      "instructions": "Open generated files in Apple Numbers and confirm no repair dialog. Re-run with SWIFT_NUMBERS_NUMBERS_APP_OK=1 once confirmed."
    },
    "releaseNotesMetadata": {
      "status": "$release_notes_status",
      "error": "$release_notes_error",
      "requiredHeadings": [
        "Summary",
        "Breaking Changes",
        "Rollback Hint"
      ],
      "templatePath": "scripts/release-notes-template.md"
    }
  }
}
JSON

echo "Release check report written to $REPORT_PATH"
if [[ "$overall_status" != "pass" ]]; then
  echo "Release check failed. See report for details."
  exit 1
fi
