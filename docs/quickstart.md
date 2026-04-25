# Quickstart

This guide is the fastest path to verify `SwiftNumbers` on your machine.

For complete API behavior, see [Capabilities](capabilities.md).  
For practical scenarios, see [Cookbook](cookbook.md).

## 1) Build

```bash
swift build
```

## 2) Run tests

```bash
swift test
```

## 3) Run full local quality gate

```bash
./scripts/ci-check.sh
```

## 4) Try CLI on public fixtures

```bash
swift run swiftnumbers list-sheets Tests/Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json
```

Expected outcomes:

- `list-sheets` prints ordered sheet names
- `dump` prints read path, counts, diagnostics
- `--format json` emits machine-friendly payload

## 5) Open → edit → save (library API)

```swift
import Foundation
import SwiftNumbersCore

let inputURL = URL(fileURLWithPath: "/absolute/path/input.numbers")
let outputURL = URL(fileURLWithPath: "/absolute/path/output.numbers")

let document = try EditableNumbersDocument.open(at: inputURL)
let sheet = try document.sheet(named: "Sales")
let table = try sheet.table(named: "Q1")

try table.setValue(.string("Done"), at: "C4")
table.appendRow([.string("Alice"), .number(42), .bool(true)])

try document.save(to: outputURL)
```

## 6) Optional in-place save

```swift
try document.saveInPlace()
```

`saveInPlace()` uses temp-write + atomic replace semantics on the current working path.

## 7) Local private-corpus workflow (optional, local only)

```bash
export SWIFT_NUMBERS_PRIVATE_CORPUS="/absolute/path/to/private-corpus"
./scripts/update_private_corpus_expectations.py --write
```

## 8) Run release checks

```bash
./scripts/release_check.sh
# After manual Numbers.app smoke checks:
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_check.sh
```

Release metadata gate requirements for the target changelog section:

- `### Summary` (with at least one bullet)
- `### Breaking Changes` (with at least one bullet, `- None.` allowed)
- `### Rollback Hint` (with at least one bullet)

Template: `scripts/release-notes-template.md`

## 9) Dry-run release pipeline

```bash
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_publish.sh --tag v0.3.2 --dry-run
```

## 10) Autorelease one completed fix

```bash
SWIFT_NUMBERS_TASK_ID=SN-RXX ./scripts/release_autofix.sh
```

This command:

- promotes `Unreleased` changelog notes into the next patch version
- creates a release commit
- pushes tag/release through `./scripts/release_publish.sh`

## Next Steps

1. Learn full operation coverage: [Capabilities](capabilities.md)
2. Copy production-ready snippets: [Cookbook](cookbook.md)
3. Use exact type/method signatures: [API Reference](api-reference.md)
4. Script CLI pipelines: [CLI Reference](cli-reference.md)
5. Debug issues quickly: [Troubleshooting](troubleshooting.md)
