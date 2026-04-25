#!/usr/bin/env bash
set -euo pipefail

echo "warning: scripts/release_check_020.sh is deprecated; use ./scripts/release_check.sh" >&2
exec "$(dirname "$0")/release_check.sh" "${1:-.local/release-check-020.json}"
