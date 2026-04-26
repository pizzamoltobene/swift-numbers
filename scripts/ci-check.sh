#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/swiftnumbers-profiles.XXXXXX")"
export LLVM_PROFILE_FILE="$PROFILE_DIR/%p.profraw"

./scripts/runtime-critical-check.sh
./scripts/ci-format-check.sh
./scripts/ci-lint.sh
swift test --enable-code-coverage
./scripts/coverage-summary.sh --skip-test --threshold 70
