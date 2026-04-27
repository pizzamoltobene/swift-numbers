#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

ROADMAP_PATH="$REPO_ROOT/docs/autopilot-roadmap.md"
CODE_MAP_PATH="$REPO_ROOT/docs/numbers-parser-code-capability-map.md"
MAX_TASKS=20
INCLUDE_IN_PROGRESS=1

usage() {
  cat <<'USAGE'
Usage: ./scripts/parity_task_queue.sh [options]

Options:
  --roadmap <path>               Roadmap path (default: docs/autopilot-roadmap.md)
  --code-map <path>              Code capability map path (default: docs/numbers-parser-code-capability-map.md)
  --max <n>                      Maximum queue items to print (default: 20)
  --exclude-in-progress          Only include [TODO] parity tasks
  -h, --help                     Show help

Output:
  NEXT_TASK=<task-id-or-empty>
  QUEUE_SIZE=<n>
  taskId|status|score|theme|capabilityArea|swiftEvidence|numbersParserEvidence|matrixRow

Notes:
  - Queue is deterministic: sorted by score DESC, then matrix row ASC, then task ID ASC.
  - Score favors policy themes (read > write > formula > pivot > cli) and open parity gaps
    (where Swift evidence is `not-found` in the capability matrix).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --roadmap)
      ROADMAP_PATH="${2:-}"
      shift 2
      ;;
    --code-map)
      CODE_MAP_PATH="${2:-}"
      shift 2
      ;;
    --max)
      MAX_TASKS="${2:-}"
      shift 2
      ;;
    --exclude-in-progress)
      INCLUDE_IN_PROGRESS=0
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
if [[ ! -f "$CODE_MAP_PATH" ]]; then
  echo "Code map not found: $CODE_MAP_PATH" >&2
  exit 1
fi
if ! [[ "$MAX_TASKS" =~ ^[0-9]+$ ]] || [[ "$MAX_TASKS" -lt 1 ]]; then
  echo "--max must be a positive integer" >&2
  exit 1
fi

status_file="$(mktemp "${TMPDIR:-/tmp}/sn-parity-status.XXXXXX")"
queue_raw="$(mktemp "${TMPDIR:-/tmp}/sn-parity-queue-raw.XXXXXX")"
queue_sorted="$(mktemp "${TMPDIR:-/tmp}/sn-parity-queue-sorted.XXXXXX")"
cleanup() {
  rm -f "$status_file" "$queue_raw" "$queue_sorted"
}
trap cleanup EXIT

sed -n -E 's/^- \[(TODO|IN_PROGRESS|DONE|BLOCKED)\] `([^`]+)`.*/\2|\1/p' "$ROADMAP_PATH" > "$status_file"

awk -F'|' -v include_in_progress="$INCLUDE_IN_PROGRESS" '
  function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    gsub(/`/, "", s)
    return s
  }

  function derive_theme(area, lower) {
    lower = tolower(area)
    if (index(lower, "pivot") > 0) {
      return "pivot"
    }
    if (index(lower, "formula") > 0) {
      return "formula"
    }
    if (index(lower, "read") > 0 || index(lower, "diagnostic") > 0 || index(lower, "inspection") > 0 || index(lower, "categorized") > 0) {
      return "read"
    }
    if (index(lower, "write") > 0 || index(lower, "mutation") > 0 || index(lower, "merge") > 0 || index(lower, "delete") > 0 || index(lower, "format") > 0 || index(lower, "style") > 0 || index(lower, "header") > 0 || index(lower, "geometry") > 0 || index(lower, "border") > 0 || index(lower, "interactive") > 0) {
      return "write"
    }
    if (index(lower, "cli") > 0) {
      return "cli"
    }
    return "other"
  }

  function theme_weight(theme) {
    if (theme == "read") return 500
    if (theme == "write") return 450
    if (theme == "formula") return 400
    if (theme == "pivot") return 350
    if (theme == "cli") return 300
    return 200
  }

  NR == FNR {
    split($0, parts, "|")
    if (length(parts) >= 2) {
      roadmap_status[parts[1]] = parts[2]
    }
    next
  }

  /^\|/ {
    area = trim($2)
    npEvidence = trim($3)
    swiftEvidence = trim($4)
    taskField = trim($5)

    if (area == "" || area == "Capability Area" || area ~ /^---/) {
      next
    }

    row += 1
    if (taskField == "") {
      next
    }

    theme = derive_theme(area)
    areaWeight = theme_weight(theme)
    gapWeight = (swiftEvidence == "not-found") ? 120 : 40
    npWeight = (npEvidence == "not-found") ? -80 : 20
    rowWeight = 100 - row
    if (rowWeight < 0) {
      rowWeight = 0
    }

    split(taskField, taskParts, ",")
    for (i = 1; i <= length(taskParts); i += 1) {
      taskID = trim(taskParts[i])
      if (taskID == "") {
        continue
      }

      status = roadmap_status[taskID]
      if (status == "") {
        status = "UNKNOWN"
      }
      if (status == "DONE" || status == "BLOCKED" || status == "UNKNOWN") {
        continue
      }
      if (status == "IN_PROGRESS" && include_in_progress != 1) {
        continue
      }

      statusWeight = (status == "TODO") ? 30 : 20
      score = areaWeight + gapWeight + npWeight + statusWeight + rowWeight

      if (!(taskID in bestScore) || score > bestScore[taskID] || (score == bestScore[taskID] && row < bestRow[taskID])) {
        bestScore[taskID] = score
        bestRow[taskID] = row
        bestStatus[taskID] = status
        bestTheme[taskID] = theme
        bestArea[taskID] = area
        bestSwift[taskID] = swiftEvidence
        bestNP[taskID] = npEvidence
      }
    }
  }

  END {
    for (taskID in bestScore) {
      printf "%s|%s|%d|%s|%s|%s|%s|%d\n", taskID, bestStatus[taskID], bestScore[taskID], bestTheme[taskID], bestArea[taskID], bestSwift[taskID], bestNP[taskID], bestRow[taskID]
    }
  }
' "$status_file" "$CODE_MAP_PATH" > "$queue_raw"

if [[ ! -s "$queue_raw" ]]; then
  echo "NEXT_TASK="
  echo "QUEUE_SIZE=0"
  exit 0
fi

sort -t'|' -k3,3nr -k8,8n -k1,1 "$queue_raw" > "$queue_sorted"

queue_size="$(wc -l < "$queue_sorted" | tr -d ' ')"
next_task="$(head -n 1 "$queue_sorted" | cut -d'|' -f1)"

echo "NEXT_TASK=$next_task"
echo "QUEUE_SIZE=$queue_size"
head -n "$MAX_TASKS" "$queue_sorted"
