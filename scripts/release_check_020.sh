#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="${1:-.local/release-check-020.json}"
MANUAL_NUMBERS_OK="${SWIFT_NUMBERS_NUMBERS_APP_OK:-0}"

mkdir -p "$(dirname "$REPORT_PATH")"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

swift_build_status="pass"
swift_test_status="pass"
manual_numbers_status="fail"

swift_build_error=""
swift_test_error=""

if ! swift build -c release >/dev/null 2>&1; then
  swift_build_status="fail"
  swift_build_error="swift build -c release failed"
fi

if ! swift test >/dev/null 2>&1; then
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
  "$manual_numbers_status"
do
  if [[ "$status" != "pass" ]]; then
    overall_status="fail"
    break
  fi
done

cat >"$REPORT_PATH" <<JSON
{
  "schemaVersion": 1,
  "releaseTarget": "0.2.0",
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
    }
  }
}
JSON

echo "Release check report written to $REPORT_PATH"
if [[ "$overall_status" != "pass" ]]; then
  echo "Release check failed. See report for details."
  exit 1
fi
