# Quickstart

This guide is the fastest path to verify `SwiftNumbers` on your machine.

For complete API behavior, see [Capabilities](capabilities.md).  
For practical scenarios, see [Cookbook](cookbook.md).
For full CLI contract, see [CLI Reference](cli-reference.md).

## Prerequisites

- macOS with Swift toolchain available (`swift --version`)
- Repository checked out locally

## Optional: Install prebuilt CLI (no local compile)

```bash
brew install <github-user>/tap/swiftnumbers
swiftnumbers --help
```

See [Homebrew Distribution](homebrew-distribution.md) for maintainer setup and release flow.

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

## 4) CLI smoke test on public fixtures

```bash
swift run swiftnumbers --help
swift run swiftnumbers help read-column
swift run swiftnumbers list-sheets Tests/Fixtures/multi-sheet.numbers
swift run swiftnumbers list-tables Tests/Fixtures/multi-sheet.numbers --format json
swift run swiftnumbers list-formulas Tests/Fixtures/simple-table.numbers --format json
swift run swiftnumbers read-cell Tests/Fixtures/simple-table.numbers A1 --sheet "Sheet 1" --table "Table 1" --format json
swift run swiftnumbers read-range Tests/Fixtures/simple-table.numbers A2:B3 --sheet "Sheet 1" --table "Table 1" --jsonl
swift run swiftnumbers dump Tests/Fixtures/simple-table.numbers --format json --cells --formatting
swift run swiftnumbers inspect Tests/Fixtures/simple-table.numbers --format json --redact --compact
```

Expected outcomes:

- `list-sheets` / `list-tables` return deterministic ordering
- `read-cell` / `read-range` return typed read snapshots
- `dump --cells --formatting` includes structural + cell-level diagnostics
- `inspect --redact --compact` emits machine-friendly low-level payload
- scoped commands require one sheet selector (`--sheet` or `--sheet-index`) and one table selector (`--table` or `--table-index`)

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
```

Keep `.private-corpus/expectations.json` in sync with your local corpus baseline before running private-corpus regression checks.

## 8) Check release batch gate and run release checks

```bash
./scripts/release_batch_count.sh --changelog ./CHANGELOG.md
./scripts/release_batch_count.sh --changelog ./CHANGELOG.md --check --threshold 5
./scripts/release_check.sh
# After manual Numbers.app smoke checks:
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_check.sh
```

Notes:

- `release_batch_count.sh --check --threshold 5` returns success when `Unreleased -> Summary` has at least 5 non-placeholder bullets.
- `release_check.sh` validates release metadata, `swift build -c release`, `swift test`, and manual Numbers.app smoke status.

Release metadata gate requirements for the target changelog section:

- `### Summary` (with at least one bullet)
- `### Breaking Changes` (with at least one bullet, `- None.` allowed)
- `### Rollback Hint` (with at least one bullet)

Template: `scripts/release-notes-template.md`

## 9) Dry-run release pipeline

```bash
SWIFT_NUMBERS_NUMBERS_APP_OK=1 ./scripts/release_publish.sh --tag vX.Y.Z --dry-run
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
