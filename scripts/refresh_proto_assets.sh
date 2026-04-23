#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${1:-$ROOT/.vendor/format-source}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source directory not found: $SOURCE_DIR"
  echo "Pass a path as first argument, for example:"
  echo "  ./scripts/refresh_proto_assets.sh /path/to/format-assets"
  exit 1
fi

PROTO_SRC="$SOURCE_DIR/src/protos"
TARGET_PROTO_DIR="$ROOT/Sources/SwiftNumbersProto/Protos/BaseMessages"

if [[ ! -f "$PROTO_SRC/TSPMessages.proto" || ! -f "$PROTO_SRC/TSPArchiveMessages.proto" ]]; then
  echo "Missing required proto files in $PROTO_SRC"
  exit 1
fi

cp "$PROTO_SRC/TSPMessages.proto" "$TARGET_PROTO_DIR/TSPMessages.proto"
cp "$PROTO_SRC/TSPArchiveMessages.proto" "$TARGET_PROTO_DIR/TSPArchiveMessages.proto"

REFERENCE_FIXTURE="$(find "$SOURCE_DIR" -type f -name 'empty.numbers' | head -n 1)"
if [[ -n "$REFERENCE_FIXTURE" ]]; then
  cp "$REFERENCE_FIXTURE" "$ROOT/Tests/Fixtures/reference-empty.numbers"
fi

sed -i '' 's#import "TSPMessages.proto";#import "Protos/BaseMessages/TSPMessages.proto";#' \
  "$TARGET_PROTO_DIR/TSPArchiveMessages.proto"

echo "Refreshed base proto assets into Sources/SwiftNumbersProto/Protos/BaseMessages"
if [[ -n "$REFERENCE_FIXTURE" ]]; then
  echo "Updated reference fixture: Tests/Fixtures/reference-empty.numbers"
fi
