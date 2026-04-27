#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
TEST_ROOT="$REPO_ROOT/Tests/SwiftNumbersTests"
ROADMAP_PATH="$REPO_ROOT/docs/testing-autopilot-roadmap.md"

TARGET=1000
RUN_TESTS=0
ENFORCE_TARGET=0
BASELINE_PATH=""
REQUIRE_GROWTH=0
WRITE_BASELINE=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/test-growth-report.sh [options]

Options:
  --target <count>      Target total tests (default: 1000)
  --run-tests           Execute `swift test` and parse executed/skip counts
  --enforce-target      Exit non-zero when declared test count is below target
  --roadmap <path>      Testing roadmap path (default: docs/testing-autopilot-roadmap.md)
  --baseline <path>     Optional baseline file storing previous declared test count
  --require-growth      Exit non-zero when declared count is not above baseline
  --write-baseline      Write current declared count to baseline path
  -h, --help            Show help

Examples:
  ./scripts/test-growth-report.sh --target 1000
  ./scripts/test-growth-report.sh --run-tests --target 1000
  ./scripts/test-growth-report.sh --baseline .local/test-count-baseline.txt --require-growth
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --run-tests)
      RUN_TESTS=1
      shift
      ;;
    --enforce-target)
      ENFORCE_TARGET=1
      shift
      ;;
    --roadmap)
      ROADMAP_PATH="${2:-}"
      shift 2
      ;;
    --baseline)
      BASELINE_PATH="${2:-}"
      shift 2
      ;;
    --require-growth)
      REQUIRE_GROWTH=1
      shift
      ;;
    --write-baseline)
      WRITE_BASELINE=1
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

if [[ ! "$TARGET" =~ ^[0-9]+$ ]]; then
  echo "--target must be an integer" >&2
  exit 1
fi

if [[ "$WRITE_BASELINE" -eq 1 && -z "$BASELINE_PATH" ]]; then
  echo "--write-baseline requires --baseline <path>" >&2
  exit 1
fi

if [[ ! -d "$TEST_ROOT" ]]; then
  echo "Test directory not found: $TEST_ROOT" >&2
  exit 1
fi

collect_count() {
  local pattern="$1"
  local root="$2"
  (rg -n "$pattern" "$root" -g '*.swift' 2>/dev/null || true) | wc -l | tr -d ' '
}

declared_xctest_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$TEST_ROOT")"
declared_swift_testing_count="$(collect_count '^[[:space:]]*@Test(\b|\()' "$TEST_ROOT")"
declared_total=$((declared_xctest_count + declared_swift_testing_count))

per_file_report="$(mktemp "${TMPDIR:-/tmp}/test-growth-per-file.XXXXXX")"
test_log=""
cleanup() {
  rm -f "$per_file_report"
  if [[ -n "$test_log" ]]; then
    rm -f "$test_log"
  fi
}
trap cleanup EXIT

( rg -n '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(|^[[:space:]]*@Test(\b|\()' "$TEST_ROOT" -g '*.swift' 2>/dev/null || true ) \
  | awk -F: '{print $1}' \
  | sort \
  | uniq -c \
  | sort -nr > "$per_file_report"

executed_total="not-run"
skipped_total="not-run"
runtime_seconds="n/a"
swift_test_exit=0

if [[ "$RUN_TESTS" -eq 1 ]]; then
  test_log="$(mktemp "${TMPDIR:-/tmp}/test-growth-swift-test.XXXXXX.log")"
  started_epoch="$(date +%s)"
  set +e
  swift test --package-path "$REPO_ROOT" | tee "$test_log"
  swift_test_exit=$?
  set -e
  finished_epoch="$(date +%s)"
  runtime_seconds=$((finished_epoch - started_epoch))

  parsed_executed="$(sed -n 's/.*Executed \([0-9][0-9]*\) tests.*/\1/p' "$test_log" | tail -n 1)"
  parsed_skipped="$(sed -n 's/.*with \([0-9][0-9]*\) test skipped.*/\1/p' "$test_log" | tail -n 1)"

  if [[ -n "$parsed_executed" ]]; then
    executed_total="$parsed_executed"
  fi
  if [[ -n "$parsed_skipped" ]]; then
    skipped_total="$parsed_skipped"
  fi
fi

roadmap_todo_count=0
roadmap_in_progress_count=0
roadmap_done_count=0
roadmap_blocked_count=0
if [[ -f "$ROADMAP_PATH" ]]; then
  roadmap_todo_count="$( (grep -E '^- \[TODO\]' "$ROADMAP_PATH" || true) | wc -l | tr -d ' ' )"
  roadmap_in_progress_count="$( (grep -E '^- \[IN_PROGRESS\]' "$ROADMAP_PATH" || true) | wc -l | tr -d ' ' )"
  roadmap_done_count="$( (grep -E '^- \[DONE\]' "$ROADMAP_PATH" || true) | wc -l | tr -d ' ' )"
  roadmap_blocked_count="$( (grep -E '^- \[BLOCKED\]' "$ROADMAP_PATH" || true) | wc -l | tr -d ' ' )"
fi

target_gap=$((TARGET - declared_total))
if [[ "$target_gap" -lt 0 ]]; then
  target_gap=0
fi

progress_pct="$(awk -v total="$declared_total" -v target="$TARGET" 'BEGIN { if (target <= 0) { print "100.00" } else { printf "%.2f", (total / target) * 100.0 } }')"

baseline_count=""
baseline_delta=""
if [[ -n "$BASELINE_PATH" && -f "$BASELINE_PATH" ]]; then
  baseline_count="$(tr -cd '0-9\n' < "$BASELINE_PATH" | head -n 1)"
  if [[ -n "$baseline_count" ]]; then
    baseline_delta=$((declared_total - baseline_count))
  fi
fi

if [[ "$WRITE_BASELINE" -eq 1 ]]; then
  mkdir -p "$(dirname "$BASELINE_PATH")"
  printf "%s\n" "$declared_total" > "$BASELINE_PATH"
fi

echo "Test Growth Report"
echo "Generated at UTC: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Declared tests: $declared_total (xctest funcs: $declared_xctest_count, swift-testing annotations: $declared_swift_testing_count)"
echo "Target tests: $TARGET"
echo "Progress to target: ${progress_pct}%"
echo "Remaining to target: $target_gap"
echo "Executed tests (latest run): $executed_total"
echo "Skipped tests (latest run): $skipped_total"
echo "swift test runtime (seconds): $runtime_seconds"
if [[ -f "$ROADMAP_PATH" ]]; then
  echo "Roadmap status ($ROADMAP_PATH): TODO=$roadmap_todo_count IN_PROGRESS=$roadmap_in_progress_count DONE=$roadmap_done_count BLOCKED=$roadmap_blocked_count"
fi
if [[ -n "$baseline_count" ]]; then
  echo "Baseline count: $baseline_count"
  echo "Delta vs baseline: $baseline_delta"
elif [[ -n "$BASELINE_PATH" ]]; then
  echo "Baseline count: unavailable at $BASELINE_PATH"
fi

echo ""
echo "Declared tests by file:"
if [[ -s "$per_file_report" ]]; then
  cat "$per_file_report"
else
  echo "(no matching tests found under $TEST_ROOT)"
fi

if [[ "$REQUIRE_GROWTH" -eq 1 ]]; then
  if [[ -z "$baseline_count" ]]; then
    echo "Growth check failed: baseline is required but not available" >&2
    exit 1
  fi
  if [[ "$baseline_delta" -le 0 ]]; then
    echo "Growth check failed: declared tests did not increase (delta=$baseline_delta)" >&2
    exit 1
  fi
fi

if [[ "$ENFORCE_TARGET" -eq 1 && "$declared_total" -lt "$TARGET" ]]; then
  echo "Target check failed: declared tests $declared_total is below target $TARGET" >&2
  exit 1
fi

if [[ "$RUN_TESTS" -eq 1 && "$swift_test_exit" -ne 0 ]]; then
  echo "swift test failed during report generation (exit=$swift_test_exit)." >&2
  exit "$swift_test_exit"
fi
