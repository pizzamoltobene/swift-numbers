#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

NP_REPO="$REPO_ROOT/.local/compare/numbers-parser"
OUTPUT_PATH="$REPO_ROOT/docs/numbers-parser-code-capability-map.md"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/refresh_numbers_parser_code_map.sh [options]

Options:
  --numbers-parser-repo <path>  numbers-parser checkout (default: .local/compare/numbers-parser)
  --output <path>               Output markdown path (default: docs/numbers-parser-code-capability-map.md)
  --dry-run                     Print generated markdown to stdout
  -h, --help                    Show help

Behavior:
  - Reads code symbols directly from numbers-parser and SwiftNumbers sources.
  - Rebuilds docs/numbers-parser-code-capability-map.md with stable section ordering.
  - Writes explicit snapshot metadata (commit, date, analyzed paths).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --numbers-parser-repo)
      NP_REPO="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
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

if [[ ! -d "$NP_REPO/.git" ]]; then
  echo "numbers-parser repo not found or not a git checkout: $NP_REPO" >&2
  exit 1
fi

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "SwiftNumbers repo root is not a git checkout: $REPO_ROOT" >&2
  exit 1
fi

np_required=(
  "src/numbers_parser/document.py"
  "src/numbers_parser/cell.py"
  "src/numbers_parser/_cat_numbers.py"
  "src/numbers_parser/_csv2numbers.py"
  "src/numbers_parser/_unpack_numbers.py"
  "pyproject.toml"
)

sn_required=(
  "Sources/SwiftNumbersCore/EditableNumbers.swift"
  "Sources/SwiftNumbersCore/Models.swift"
  "Sources/SwiftNumbersCore/IWASetCellWriter.swift"
  "Sources/swiftnumbers/main.swift"
)

for rel in "${np_required[@]}"; do
  if [[ ! -f "$NP_REPO/$rel" ]]; then
    echo "Missing numbers-parser source: $NP_REPO/$rel" >&2
    exit 1
  fi
done

for rel in "${sn_required[@]}"; do
  if [[ ! -f "$REPO_ROOT/$rel" ]]; then
    echo "Missing SwiftNumbers source: $REPO_ROOT/$rel" >&2
    exit 1
  fi
done

np_commit="$(git -C "$NP_REPO" rev-parse --short HEAD)"
np_commit_date="$(git -C "$NP_REPO" show -s --format=%cd --date=short HEAD)"
sn_commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
sn_commit_date="$(git -C "$REPO_ROOT" show -s --format=%cd --date=short HEAD)"
today_utc="$(date -u +%Y-%m-%d)"

match_ref() {
  local root="$1"
  local paths_csv="$2"
  local pattern="$3"

  local -a paths=()
  local rel
  IFS=';' read -r -a rel_paths <<< "$paths_csv"
  for rel in "${rel_paths[@]}"; do
    paths+=("$root/$rel")
  done

  local hit
  hit="$(rg -n --with-filename --max-count 1 -- "$pattern" "${paths[@]}" 2>/dev/null | head -n 1 || true)"
  if [[ -z "$hit" ]]; then
    printf 'not-found'
    return
  fi

  hit="${hit#"$root"/}"
  printf '%s' "$hit" | awk -F: '{print $1 ":" $2}'
}

capability_rows="$(mktemp "${TMPDIR:-/tmp}/sn-parity-capabilities.XXXXXX")"
output_tmp="$(mktemp "${TMPDIR:-/tmp}/sn-parity-map.XXXXXX")"

cleanup() {
  rm -f "$capability_rows" "$output_tmp"
}
trap cleanup EXIT

cat >"$capability_rows" <<'ROWS'
Merge create API	src/numbers_parser/document.py	def merge_cells\(	Sources/SwiftNumbersCore/EditableNumbers.swift	func mergeCells\(	SN-R44,SN-R72
Unmerge API	src/numbers_parser/document.py	def unmerge\(	Sources/SwiftNumbersCore/EditableNumbers.swift	func unmergeCells\(	SN-R72
Delete row/column API	src/numbers_parser/document.py	def (delete_row|delete_column)\(	Sources/SwiftNumbersCore/EditableNumbers.swift	func (deleteRow|deleteColumn)\(	SN-R71
Header row/column mutation API	src/numbers_parser/document.py	def num_header_(rows|cols)\(	Sources/SwiftNumbersCore/EditableNumbers.swift	header(Row|Column)	SN-R73
Table geometry API	src/numbers_parser/document.py	def (row_height|col_width|coordinates)\(	Sources/SwiftNumbersCore/EditableNumbers.swift	(rowHeight|columnWidth|coordinates)	SN-R74
Document style registry API	src/numbers_parser/document.py	def add_style\(	Sources/SwiftNumbersCore/EditableNumbers.swift	addStyle	SN-R75
Document custom-format registry API	src/numbers_parser/document.py	def add_custom_format\(	Sources/SwiftNumbersCore/EditableNumbers.swift	addCustomFormat	SN-R76
Border mutation API	src/numbers_parser/document.py	def set_cell_border\(	Sources/SwiftNumbersCore/EditableNumbers.swift	setCellBorder	SN-R77
Extended format families	src/numbers_parser/document.py	def set_cell_formatting\(	Sources/SwiftNumbersCore/EditableNumbers.swift	case scientific	SN-R78
Interactive control formats	src/numbers_parser/document.py	tickbox	Sources/SwiftNumbersCore/EditableNumbers.swift	(tickbox|rating|slider|stepper|popup)	SN-R79
Categorized/grouped read surface	src/numbers_parser/document.py	def categorized_data\(	Sources/SwiftNumbersCore/Models.swift	categorizedData	SN-R80
Table presentation metadata	src/numbers_parser/document.py	def (table_name_enabled|caption_enabled|caption)\(	Sources/SwiftNumbersCore/Models.swift	tableNameEnabled	SN-R81
CLI parity toggles/listing surface	src/numbers_parser/_cat_numbers.py	add_argument\(	Sources/swiftnumbers/main.swift	struct (Dump|ListFormulas|ListTables)\b	SN-R82
CLI CSV transform pipeline	src/numbers_parser/_csv2numbers.py	add_argument\(	Sources/swiftnumbers/main.swift	struct (ExportCSVCommand|ImportCSVCommand)\b	SN-R83
CLI unpack/inspection surface	src/numbers_parser/_unpack_numbers.py	add_argument\(	Sources/swiftnumbers/main.swift	struct Dump\b	SN-R84
Continuous parity scoring workflow	pyproject.toml	cat-numbers	scripts/refresh_numbers_parser_code_map.sh	capability_rows	SN-R70,SN-R85
ROWS

{
  echo "# numbers-parser Code Capability Map"
  echo ""
  echo "Last updated: ${today_utc}"
  echo "Generated by: \`./scripts/refresh_numbers_parser_code_map.sh\`"
  echo ""
  echo "This document is refreshed from code symbols only (no README/API prose claims)."
  echo ""
  echo "## Snapshot Metadata"
  echo ""
  echo "- numbers-parser repository: \`https://github.com/masaccio/numbers-parser\`"
  echo "- numbers-parser baseline commit: \`${np_commit}\`"
  echo "- numbers-parser commit date: \`${np_commit_date}\`"
  echo "- SwiftNumbers comparison commit: \`${sn_commit}\`"
  echo "- SwiftNumbers commit date: \`${sn_commit_date}\`"
  echo "- numbers-parser analyzed paths:"
  for rel in "${np_required[@]}"; do
    echo "  - \`${rel}\`"
  done
  echo "- SwiftNumbers analyzed paths:"
  for rel in "${sn_required[@]}"; do
    echo "  - \`${rel}\`"
  done
  echo ""
  echo "## Deterministic Refresh Workflow"
  echo ""
  echo "1. Refresh local comparison clone as needed:"
  echo "   - \`git -C .local/compare/numbers-parser fetch --all --tags\`"
  echo "   - \`git -C .local/compare/numbers-parser checkout <commit>\`"
  echo "2. Regenerate map:"
  echo "   - \`./scripts/refresh_numbers_parser_code_map.sh\`"
  echo "3. Re-run to verify no formatting drift:"
  echo "   - \`./scripts/refresh_numbers_parser_code_map.sh && git diff -- docs/numbers-parser-code-capability-map.md\`"
  echo ""
  echo "## Conveyor Matrix (Code-Symbol Evidence)"
  echo ""
  echo "| Capability Area | numbers-parser evidence | SwiftNumbers evidence | Conveyor Task |"
  echo "|---|---|---|---|"

  while IFS=$'\t' read -r area np_paths np_pattern sn_paths sn_pattern task; do
    np_ref="$(match_ref "$NP_REPO" "$np_paths" "$np_pattern")"
    sn_ref="$(match_ref "$REPO_ROOT" "$sn_paths" "$sn_pattern")"
    echo "| ${area} | \`${np_ref}\` | \`${sn_ref}\` | \`${task}\` |"
  done <"$capability_rows"

  echo ""
  echo "## Notes"
  echo ""
  echo "- Evidence values are first-match symbol references in deterministic row order."
  echo "- \`not-found\` means no matching symbol was found in configured source paths."
  echo "- This map is a parity signal input for roadmap selection, not a release gate by itself."
} >"$output_tmp"

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat "$output_tmp"
  exit 0
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
cp "$output_tmp" "$OUTPUT_PATH"
echo "Updated $OUTPUT_PATH"
