# Quickstart

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

## 4) Use the CLI

```bash
swift run swiftnumbers list-sheets Fixtures/multi-sheet.numbers
swift run swiftnumbers dump Fixtures/simple-table.numbers
swift run swiftnumbers dump Fixtures/simple-table.numbers --format json
```

## 5) Work with private real-world corpus (local only)

```bash
export SWIFT_NUMBERS_PRIVATE_CORPUS="/absolute/path/to/private-corpus"
./scripts/update_private_corpus_expectations.py --write
./scripts/bench_private_corpus.py --update-baseline
./scripts/bench_private_corpus.py
```
