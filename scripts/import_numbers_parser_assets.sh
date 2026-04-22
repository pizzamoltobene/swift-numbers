#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT/.vendor/numbers-parser"

if [[ ! -d "$VENDOR_DIR/.git" ]]; then
  git clone --depth 1 https://github.com/masaccio/numbers-parser "$VENDOR_DIR"
else
  git -C "$VENDOR_DIR" pull --ff-only
fi

cp "$VENDOR_DIR/src/protos/TSPMessages.proto" "$ROOT/Sources/SwiftNumbersProto/Protos/NumbersParser/TSPMessages.proto"
cp "$VENDOR_DIR/src/protos/TSPArchiveMessages.proto" "$ROOT/Sources/SwiftNumbersProto/Protos/NumbersParser/TSPArchiveMessages.proto"
cp "$VENDOR_DIR/src/numbers_parser/data/empty.numbers" "$ROOT/Fixtures/reference-empty.numbers"

# The SwiftProtobuf plugin resolves imports relative to the target root.
sed -i '' 's#import \"TSPMessages.proto\";#import \"Protos/NumbersParser/TSPMessages.proto\";#' \
  "$ROOT/Sources/SwiftNumbersProto/Protos/NumbersParser/TSPArchiveMessages.proto"

echo "Imported proto files and reference-empty fixture from numbers-parser"
