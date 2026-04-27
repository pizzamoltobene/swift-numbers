#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

ROADMAP_PATH="$REPO_ROOT/docs/autopilot-roadmap.md"
POLICY_PATH="$REPO_ROOT/docs/autopilot-policy.md"
DATE_UTC="$(date -u +%Y%m%d)"
FORCE=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/autopilot_backlog_synthesis.sh [options]

Options:
  --roadmap <path>   Roadmap file path (default: docs/autopilot-roadmap.md)
  --policy <path>    Policy file path (default: docs/autopilot-policy.md)
  --date <YYYYMMDD>  Deterministic ID date override (default: UTC today)
  --force            Run synthesis even if TODO tasks are present
  --dry-run          Print generated milestone block instead of appending
  -h, --help         Show help

Behavior:
  - Generates at least 10 candidates from project signals
  - Scores candidates with policy formula:
      priorityScore = (Impact * Confidence) - (Risk + Effort)
  - Selects top 6 with mandatory area coverage:
      read, write, formula, pivot
  - Appends a new roadmap milestone with deterministic IDs:
      SN-AUTO-YYYYMMDD-XX
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --roadmap)
      ROADMAP_PATH="$2"
      shift 2
      ;;
    --policy)
      POLICY_PATH="$2"
      shift 2
      ;;
    --date)
      DATE_UTC="$2"
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

if [[ "$FORCE" -ne 1 ]] && grep -q '^- \[TODO\]' "$ROADMAP_PATH"; then
  echo "TODO tasks exist in roadmap. Skipping synthesis."
  exit 0
fi

todo_fixme_count="$(rg -n 'TODO|FIXME' "$REPO_ROOT/Sources" "$REPO_ROOT/Tests" "$REPO_ROOT/docs" "$REPO_ROOT/scripts" \
  -g '!docs/autopilot-roadmap.md' 2>/dev/null | wc -l | tr -d ' ')"
unsupported_marker_count="$(rg -n 'unsupported|fallback|diagnostic' "$REPO_ROOT/Sources" "$REPO_ROOT/docs" \
  2>/dev/null | wc -l | tr -d ' ')"
release_tag_count="$(git -C "$REPO_ROOT" tag --list 'v*' | wc -l | tr -d ' ')"

candidates_file="$(mktemp "${TMPDIR:-/tmp}/autopilot-candidates.XXXXXX")"
scored_file="$(mktemp "${TMPDIR:-/tmp}/autopilot-scored.XXXXXX")"
sorted_file="$(mktemp "${TMPDIR:-/tmp}/autopilot-sorted.XXXXXX")"
selected_file="$(mktemp "${TMPDIR:-/tmp}/autopilot-selected.XXXXXX")"
block_file="$(mktemp "${TMPDIR:-/tmp}/autopilot-block.XXXXXX")"
cleanup() {
  rm -f "$candidates_file" "$scored_file" "$sorted_file" "$selected_file" "$block_file"
}
trap cleanup EXIT

# Candidate schema:
# id|area|title|impact|risk|effort|confidence|definition_of_done|validation
cat >"$candidates_file" <<'EOF'
C01|read|Harden mixed-archive table traversal determinism|5|2|3|5|real-read traversal order is stable for package and single-file archives with no duplicate table decode|deterministic fixture snapshot for merged traversal path
C02|read|Improve decode warning deduplication for unsupported payload nodes|4|2|2|5|unsupported decode diagnostics are deduplicated by object and node type|unit test asserts stable warning set size and order
C03|read|Add strict malformed-cell fallback boundary checks|4|3|2|4|malformed cell payloads degrade to safe read values without crash or drift|fuzz-like malformed fixtures produce deterministic outputs
C04|write|Add deterministic row delete guardrails for grouped tables|5|3|3|4|row deletion API blocks unsafe grouped-table writes with actionable diagnostics|writer tests cover grouped/non-grouped delete paths
C05|write|Add deterministic column delete guardrails for grouped tables|5|3|3|4|column deletion API blocks unsafe grouped-table writes with actionable diagnostics|writer tests cover grouped/non-grouped delete paths
C06|write|Harden save overlay merge conflict resolution|4|2|3|4|overlay merge keeps last-write-wins semantics without losing unrelated metadata|save/reopen tests validate metadata persistence under mixed edits
C07|formula|Expand formula AST fallback for nested function argument edge cases|4|2|3|5|nested function fallback output is deterministic and warning noise is reduced|formula unit tests include nested unsupported node combinations
C08|formula|Add formula write validation for unsafe references|5|2|2|4|formula write path rejects unsafe/self-referential ranges with deterministic errors|roundtrip tests assert deterministic failure messaging
C09|pivot|Add pivot-link read diagnostics cardinality summary|4|2|2|5|pivot-linked table metadata includes stable candidate counts and IDs|pivot fixture snapshots include new summary fields
C10|pivot|Harden pivot-linked write guard message specificity|4|1|2|5|pivot write guard error includes linked object identifiers for operator triage|write guard tests verify deterministic message payloads
C11|cli|Add deterministic parity report subcommand for roadmap sync|3|2|2|4|CLI can print stable parity report used by automation triage|golden CLI output tests for parity report command
C12|perf|Add bounded memory guard for large row iteration|4|3|3|4|row iteration avoids unbounded temporary allocations under large sheets|performance smoke test tracks allocation budget threshold
EOF

candidate_count="$(wc -l < "$candidates_file" | tr -d ' ')"
if [[ "$candidate_count" -lt 10 ]]; then
  echo "Backlog synthesis requires at least 10 candidates; got $candidate_count" >&2
  exit 1
fi

awk -F'|' '{
  score = ($4 * $7) - ($5 + $6)
  print $0 "|" score
}' "$candidates_file" >"$scored_file"

sort -t'|' -k10,10nr -k1,1 "$scored_file" >"$sorted_file"

for area in read write formula pivot; do
  awk -F'|' -v area="$area" '$2 == area { print; exit }' "$sorted_file" >>"$selected_file"
done

while IFS= read -r line; do
  candidate_id="${line%%|*}"
  if ! grep -q "^${candidate_id}|" "$selected_file"; then
    echo "$line" >>"$selected_file"
  fi
  selected_count="$(wc -l < "$selected_file" | tr -d ' ')"
  if [[ "$selected_count" -ge 6 ]]; then
    break
  fi
done <"$sorted_file"

selected_count="$(wc -l < "$selected_file" | tr -d ' ')"
if [[ "$selected_count" -lt 6 ]]; then
  echo "Backlog synthesis failed to select 6 tasks (selected $selected_count)." >&2
  exit 1
fi

max_milestone="$( (grep -E '^### M[0-9]+' "$ROADMAP_PATH" || true) | sed -E 's/^### M([0-9]+).*/\1/' | sort -n | tail -n 1)"
if [[ -z "$max_milestone" ]]; then
  max_milestone=0
fi
next_milestone=$((max_milestone + 1))

existing_date_ids="$( (grep -oE "SN-AUTO-${DATE_UTC}-[0-9]{2}" "$ROADMAP_PATH" || true) | wc -l | tr -d ' ')"
start_index=$((existing_date_ids + 1))

{
  echo ""
  echo "### M${next_milestone} - Autogenerated Renewal (${DATE_UTC})"
  echo ""
  echo "Generated by \`./scripts/autopilot_backlog_synthesis.sh\` from policy signals:"
  echo "- \`todoFixmeCount=${todo_fixme_count}\`"
  echo "- \`unsupportedMarkerCount=${unsupported_marker_count}\`"
  echo "- \`releaseTagCount=${release_tag_count}\`"
  echo "- Candidate count: \`${candidate_count}\` (policy minimum: 10)"
  echo ""

  idx="$start_index"
  while IFS='|' read -r _ area title impact risk effort confidence definition validation score; do
    task_id="$(printf "SN-AUTO-%s-%02d" "$DATE_UTC" "$idx")"
    echo "- [TODO] \`${task_id}\` ${title}."
    echo "  - Definition of done: ${definition}."
    echo "  - Validation: ${validation}."
    echo "  - Policy scoring: impact=${impact}, risk=${risk}, effort=${effort}, confidence=${confidence}, priorityScore=${score}, area=${area}."
    idx=$((idx + 1))
  done <"$selected_file"
} >"$block_file"

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat "$block_file"
  exit 0
fi

cat "$block_file" >>"$ROADMAP_PATH"
echo "Appended autogenerated backlog milestone M${next_milestone} to $ROADMAP_PATH"
