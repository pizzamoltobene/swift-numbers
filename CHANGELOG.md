# Changelog

All notable changes to this project are documented in this file.

## [0.1.0] - 2026-04-22

### Added

- Public read-only API v0 for opening `.numbers` documents and reading sheets/tables/cells.
- CLI commands:
  - `swiftnumbers dump <file.numbers>`
  - `swiftnumbers list-sheets <file.numbers>`
  - JSON output mode via `--format json`.
- Real-read decode pipeline on typed Swift protobuf subset with structured diagnostics.
- Safe metadata fallback path with explicit reason tracking in dump output.
- Public synthetic fixture corpus and golden output tests.
- Local private-corpus integration flow with per-file expectations and helper scripts.
- Debug and release benchmark harness with baseline comparison and guardrails.
- CI baseline with format check, lint/warnings-as-errors build, tests, and coverage gate.
- Initial docs/branding package for GitHub presentation.

### Changed

- First-party coverage gate now evaluates only project-owned sources and tests.
- Protobuf asset layout and compatibility test naming were normalized for neutral terminology.

### Notes

- Real user files remain local-only and are intentionally excluded from version control.
- Formula engine, pivot tables, encrypted documents, and mutation APIs are out of scope for this release.
