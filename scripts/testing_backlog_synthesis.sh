#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

ROADMAP_PATH="$REPO_ROOT/docs/testing-autopilot-roadmap.md"
POLICY_PATH="$REPO_ROOT/docs/testing-autopilot-policy.md"
DATE_UTC="$(date -u +%Y%m%d)"
TARGET_TEST_COUNT=1000
FORCE=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/testing_backlog_synthesis.sh [options]

Options:
  --roadmap <path>       Testing roadmap path (default: docs/testing-autopilot-roadmap.md)
  --policy <path>        Testing policy path (default: docs/testing-autopilot-policy.md)
  --date <YYYYMMDD>      Deterministic ID date override (default: UTC today)
  --target <count>       Target declared test count (default: 1000)
  --force                Run synthesis even if TODO tasks are present
  --dry-run              Print generated milestone block instead of appending
  -h, --help             Show help

Behavior:
  - Generates at least 12 candidate testing tasks from project signals
  - Scores with policy formula:
      priorityScore = (Impact * Confidence) - (Risk + Effort) + GrowthWeight
      GrowthWeight = ceil(estimatedTests / 20)
  - Selects top tasks with mandatory area coverage:
      cli, editable, read, pipeline
  - Appends a new testing milestone with deterministic IDs:
      SN-TEST-YYYYMMDD-XX
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --roadmap)
      ROADMAP_PATH="${2:-}"
      shift 2
      ;;
    --policy)
      POLICY_PATH="${2:-}"
      shift 2
      ;;
    --date)
      DATE_UTC="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_TEST_COUNT="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
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

if [[ ! -f "$ROADMAP_PATH" ]]; then
  echo "Roadmap not found: $ROADMAP_PATH" >&2
  exit 1
fi
if [[ ! -f "$POLICY_PATH" ]]; then
  echo "Policy not found: $POLICY_PATH" >&2
  exit 1
fi
if ! [[ "$DATE_UTC" =~ ^[0-9]{8}$ ]]; then
  echo "--date must be YYYYMMDD" >&2
  exit 1
fi
if ! [[ "$TARGET_TEST_COUNT" =~ ^[0-9]+$ ]]; then
  echo "--target must be an integer" >&2
  exit 1
fi

if [[ "$FORCE" -ne 1 ]] && grep -q '^- \[TODO\]' "$ROADMAP_PATH"; then
  echo "TODO tasks exist in testing roadmap. Skipping synthesis."
  exit 0
fi

collect_count() {
  local pattern="$1"
  local root="$2"
  (rg -n "$pattern" "$root" -g '*.swift' 2>/dev/null || true) | wc -l | tr -d ' '
}

TEST_ROOT="$REPO_ROOT/Tests/SwiftNumbersTests"
declared_xctest_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$TEST_ROOT")"
declared_swift_testing_count="$(collect_count '^[[:space:]]*@Test(\b|\()' "$TEST_ROOT")"
declared_test_count=$((declared_xctest_count + declared_swift_testing_count))

remaining_to_target=$((TARGET_TEST_COUNT - declared_test_count))
if [[ "$remaining_to_target" -lt 0 ]]; then
  remaining_to_target=0
fi

todo_fixme_count="$( (rg -n 'TODO|FIXME' "$REPO_ROOT/Sources" "$REPO_ROOT/Tests" "$REPO_ROOT/docs" "$REPO_ROOT/scripts" \
  -g '!docs/testing-autopilot-roadmap.md' 2>/dev/null || true) | wc -l | tr -d ' ' )"

cli_declared_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$REPO_ROOT/Tests/SwiftNumbersTests/CLIOutputFormatTests.swift")"
editable_declared_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$REPO_ROOT/Tests/SwiftNumbersTests/EditableNumbersTests.swift")"
read_declared_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$REPO_ROOT/Tests/SwiftNumbersTests/NumbersDocumentTests.swift")"
pipeline_declared_count="$(collect_count '^[[:space:]]*func[[:space:]]+test[[:alnum:]_]*[[:space:]]*\(' "$REPO_ROOT/Tests/SwiftNumbersTests/RealReadPipelineUnitTests.swift")"

declare -i selected_target=8
if [[ "$remaining_to_target" -gt 700 ]]; then
  selected_target=12
elif [[ "$remaining_to_target" -gt 450 ]]; then
  selected_target=10
fi

candidates_file="$(mktemp "${TMPDIR:-/tmp}/testing-candidates.XXXXXX")"
scored_file="$(mktemp "${TMPDIR:-/tmp}/testing-scored.XXXXXX")"
sorted_file="$(mktemp "${TMPDIR:-/tmp}/testing-sorted.XXXXXX")"
selected_file="$(mktemp "${TMPDIR:-/tmp}/testing-selected.XXXXXX")"
block_file="$(mktemp "${TMPDIR:-/tmp}/testing-block.XXXXXX")"
cleanup() {
  rm -f "$candidates_file" "$scored_file" "$sorted_file" "$selected_file" "$block_file"
}
trap cleanup EXIT

# Candidate schema:
# id|area|title|impact|risk|effort|confidence|estimated_tests|definition_of_done|validation
cat >"$candidates_file" <<'EOF_CANDIDATES'
C01|cli|Expand read-cell selector conflict matrix across format modes|5|1|2|5|36|all conflicting selector combinations return deterministic diagnostics in text and json modes|swift test --filter CLIOutputFormatTests
C02|cli|Add JSON schema stability matrix for dump and read subcommands|4|1|2|5|32|json payload keys and ordering-sensitive golden snapshots stay stable across commands|swift test --filter CLIOutputFormatTests
C03|editable|Add setValue type matrix across package and single-file archives|5|2|3|5|54|string number bool date formula and empty values roundtrip identically for both archive forms|swift test --filter EditableNumbersTests
C04|editable|Add structural mutation ordering matrix with save and saveInPlace variants|5|2|3|4|48|mutation sequences retain deterministic row and column coordinates after chained saves|swift test --filter EditableNumbersTests
C05|editable|Add merge and unmerge negative matrix for overlap and bounds failures|4|2|2|5|42|invalid merge and unmerge requests fail fast with deterministic errors and no side effects|swift test --filter EditableNumbersTests
C06|read|Add read-column and read-range header semantics matrix|4|2|2|5|34|header row and include-header options produce deterministic output rows across selectors|swift test --filter CLIOutputFormatTests
C07|read|Add NumbersDocument typed accessor nil and type mismatch matrix|4|2|2|5|30|typed accessor APIs return deterministic nil or typed values for mismatch scenarios|swift test --filter NumbersDocumentTests
C08|pipeline|Add AST fallback matrix for unsupported formula node combinations|5|2|3|5|46|fallback summaries remain sorted deterministic and warning-limited across node combinations|swift test --filter RealReadPipelineUnitTests
C09|pipeline|Add resolver diagnostics matrix for partial and missing drawable links|5|2|3|4|40|resolver diagnostics include stable codes and candidate identities across partial graph cases|swift test --filter RealReadPipelineUnitTests
C10|fixture|Add strict fixture variants for sparse and wide-table documents|4|2|3|4|26|strict fixtures represent sparse and wide geometry layouts with deterministic metadata|swift test --filter GoldenOutputTests
C11|golden|Add golden snapshots for list-tables and list-formulas text and json outputs|4|1|2|5|28|golden outputs pin deterministic rendering for list commands across fixture variants|swift test --filter GoldenOutputTests
C12|integration|Add private corpus contract checks for deterministic skip and manifest mismatches|3|2|2|4|18|private corpus integration path provides deterministic skip and mismatch diagnostics|swift test --filter PrivateCorpusIntegrationTests
C13|safety|Add grouped and pivot guard regression matrix for write APIs|5|2|2|5|38|unsafe grouped and pivot-linked mutations remain blocked while safe in-bounds edits pass|swift test --filter EditableNumbersTests
C14|perf|Add bounded runtime smoke matrix for core CLI read commands|3|2|2|4|20|core CLI read commands stay under bounded runtime budgets on strict fixtures|swift test --filter CLIOutputFormatTests
EOF_CANDIDATES

candidate_count="$(wc -l < "$candidates_file" | tr -d ' ')"
if [[ "$candidate_count" -lt 12 ]]; then
  echo "Backlog synthesis requires at least 12 candidates; got $candidate_count" >&2
  exit 1
fi

awk -F'|' '{
  growthWeight = int(($8 + 19) / 20)
  score = ($4 * $7) - ($5 + $6) + growthWeight
  print $0 "|" growthWeight "|" score
}' "$candidates_file" >"$scored_file"

sort -t'|' -k12,12nr -k1,1 "$scored_file" >"$sorted_file"

for area in cli editable read pipeline; do
  awk -F'|' -v area="$area" '$2 == area { print; exit }' "$sorted_file" >>"$selected_file"
done

while IFS= read -r line; do
  candidate_id="${line%%|*}"
  if ! grep -q "^${candidate_id}|" "$selected_file"; then
    echo "$line" >>"$selected_file"
  fi
  selected_count="$(wc -l < "$selected_file" | tr -d ' ')"
  if [[ "$selected_count" -ge "$selected_target" ]]; then
    break
  fi
done <"$sorted_file"

selected_count="$(wc -l < "$selected_file" | tr -d ' ')"
if [[ "$selected_count" -lt 4 ]]; then
  echo "Backlog synthesis failed to select mandatory area coverage." >&2
  exit 1
fi

max_milestone="$( (grep -E '^### T[0-9]+' "$ROADMAP_PATH" || true) | sed -E 's/^### T([0-9]+).*/\1/' | sort -n | tail -n 1)"
if [[ -z "$max_milestone" ]]; then
  max_milestone=0
fi
next_milestone=$((max_milestone + 1))

existing_date_ids="$( (grep -oE "SN-TEST-${DATE_UTC}-[0-9]{2}" "$ROADMAP_PATH" || true) | wc -l | tr -d ' ' )"
start_index=$((existing_date_ids + 1))

estimated_delta_total=0
while IFS='|' read -r _ _ _ _ _ _ _ estimated_tests _ _ _ _; do
  estimated_delta_total=$((estimated_delta_total + estimated_tests))
done < "$selected_file"

{
  echo ""
  echo "### T${next_milestone} - Autogenerated Test Expansion (${DATE_UTC})"
  echo ""
  echo "Generated by \`./scripts/testing_backlog_synthesis.sh\` from policy signals:"
  echo "- \`declaredTestCount=${declared_test_count}\`"
  echo "- \`remainingToTarget=${remaining_to_target}\`"
  echo "- \`todoFixmeCount=${todo_fixme_count}\`"
  echo "- \`suiteLoad.cli=${cli_declared_count}\`"
  echo "- \`suiteLoad.editable=${editable_declared_count}\`"
  echo "- \`suiteLoad.read=${read_declared_count}\`"
  echo "- \`suiteLoad.pipeline=${pipeline_declared_count}\`"
  echo "- Candidate count: \`${candidate_count}\` (policy minimum: 12)"
  echo "- Selected tasks: \`${selected_count}\`"
  echo "- Estimated declared test delta from selected tasks: \`+${estimated_delta_total}\`"
  echo ""

  idx="$start_index"
  while IFS='|' read -r _ area title impact risk effort confidence estimated_tests definition validation growth_weight score; do
    task_id="$(printf "SN-TEST-%s-%02d" "$DATE_UTC" "$idx")"
    echo "- [TODO] \`${task_id}\` ${title}."
    echo "  - Definition of done: ${definition}."
    echo "  - Validation: ${validation}."
    echo "  - Estimated declared test delta: +${estimated_tests}."
    echo "  - Policy scoring: impact=${impact}, risk=${risk}, effort=${effort}, confidence=${confidence}, growthWeight=${growth_weight}, priorityScore=${score}, area=${area}."
    idx=$((idx + 1))
  done <"$selected_file"
} >"$block_file"

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat "$block_file"
  exit 0
fi

cat "$block_file" >> "$ROADMAP_PATH"
echo "Appended autogenerated testing milestone T${next_milestone} to $ROADMAP_PATH"
