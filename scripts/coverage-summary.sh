#!/usr/bin/env bash
set -euo pipefail

RUN_TESTS=1
THRESHOLD=70

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-test)
      RUN_TESTS=0
      shift
      ;;
    --threshold)
      THRESHOLD="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ "$RUN_TESTS" -eq 1 ]]; then
  PROFILE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/swiftnumbers-profiles.XXXXXX")"
  export LLVM_PROFILE_FILE="$PROFILE_DIR/%p.profraw"
  swift test --enable-code-coverage

  if ! find "$PROFILE_DIR" -type f -name '*.profraw' -size +0c | grep -q .; then
    echo "No non-empty LLVM profile files were generated in $PROFILE_DIR"
    exit 1
  fi
fi

CODECOV_JSON_PATH="$(swift test --show-codecov-path | tail -n 1)"

if [[ ! -f "$CODECOV_JSON_PATH" ]]; then
  echo "Code coverage JSON path not found: $CODECOV_JSON_PATH"
  exit 1
fi

echo "Coverage JSON: $CODECOV_JSON_PATH"
swift - "$CODECOV_JSON_PATH" "$THRESHOLD" <<'SWIFT'
import Foundation
import Darwin

func fail(_ message: String) -> Never {
  fputs("\(message)\n", stderr)
  Darwin.exit(1)
}

func intValue(_ raw: Any?) -> Int {
  if let intValue = raw as? Int {
    return intValue
  }
  if let numberValue = raw as? NSNumber {
    return numberValue.intValue
  }
  return 0
}

let args = CommandLine.arguments
guard args.count >= 3 else {
  fail("Expected arguments: <coverage-json-path> <threshold>")
}

let path = args[1]
guard let threshold = Double(args[2]) else {
  fail("Invalid threshold value: \(args[2])")
}

let url = URL(fileURLWithPath: path)
let data: Data
do {
  data = try Data(contentsOf: url)
} catch {
  fail("Failed to read coverage JSON at \(path): \(error)")
}

let rootObject: Any
do {
  rootObject = try JSONSerialization.jsonObject(with: data)
} catch {
  fail("Failed to parse coverage JSON at \(path): \(error)")
}

guard
  let payload = rootObject as? [String: Any],
  let dataArray = payload["data"] as? [[String: Any]],
  let firstEntry = dataArray.first
else {
  fail("No coverage data found")
}

let totals = (firstEntry["totals"] as? [String: Any])?["lines"] as? [String: Any] ?? [:]
let totalCovered = intValue(totals["covered"])
let totalCount = intValue(totals["count"])
let totalPct = totalCount > 0 ? (Double(totalCovered) / Double(totalCount) * 100.0) : 0.0
print(
  "All code line coverage: \(totalCovered)/\(totalCount) (\(String(format: "%.2f", totalPct))%)"
)

let firstPartyPrefixes = [
  "/Sources/SwiftNumbers",
  "/Sources/swiftnumbers/",
  "/Tests/SwiftNumbersTests/",
]

var firstCovered = 0
var firstCount = 0

let files = firstEntry["files"] as? [[String: Any]] ?? []
for fileEntry in files {
  let filename = fileEntry["filename"] as? String ?? ""
  guard firstPartyPrefixes.contains(where: { filename.contains($0) }) else {
    continue
  }

  let lines = ((fileEntry["summary"] as? [String: Any])?["lines"] as? [String: Any]) ?? [:]
  firstCovered += intValue(lines["covered"])
  firstCount += intValue(lines["count"])
}

guard firstCount > 0 else {
  fail("No first-party coverage entries found.")
}

let firstPct = Double(firstCovered) / Double(firstCount) * 100.0
print(
  "First-party line coverage: \(firstCovered)/\(firstCount) (\(String(format: "%.2f", firstPct))%)"
)
print("First-party coverage threshold: \(String(format: "%.2f", threshold))%")

if firstPct < threshold {
  fail(
    "Coverage gate failed: first-party coverage \(String(format: "%.2f", firstPct))% is below threshold \(String(format: "%.2f", threshold))%"
  )
}
SWIFT
