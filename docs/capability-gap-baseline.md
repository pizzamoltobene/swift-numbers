# Capability Gap Baseline

Last updated: 2026-04-26

This document is the current external-baseline comparison for `SwiftNumbers`.
It is used to prioritize the roadmap by concrete capability gaps.

## Baseline Scope

- Baseline snapshot date: 2026-04-25
- Inputs reviewed:
  - baseline README + quick-start + API docs + limitations
  - baseline tests for styles/formatting/borders/formulas/pivots
  - current `SwiftNumbers` README/capabilities/source

## Capability Matrix

| Area | SwiftNumbers (current) | External baseline (snapshot) | Position |
|---|---|---|---|
| Core read (sheets/tables/cells/ranges) | Supported | Supported | Parity |
| CSV import/export CLI | Supported (`import-csv` / `export-csv`) | Supported (`csv2numbers` / `cat-numbers`) | Parity |
| Formula read fidelity | Supported (raw/tokens/AST summary) | Supported | Parity |
| Formula write | Supported (deterministic literal formula persistence) | Not supported | Advantage |
| Pivot write safety | Fail-fast guard + diagnostics | Unsupported with warning on save | Advantage |
| Grouped-table safety | Unsafe structural edits blocked deterministically | Known unsafe grouped write behavior | Advantage |
| Style read fidelity | Partial (alignment/background/border presence/number-format kind) | Broad (font/color/style objects) | Gap |
| Style write API | Not exposed | Supported | Gap |
| Border write API | Not exposed | Supported | Gap |
| Data/custom format write API | Not exposed | Supported | Gap |
| Merge/unmerge write API | Not exposed | Supported | Gap |
| Caption/table presentation metadata write | Not exposed | Supported (caption/table options) | Gap |

## Priority Queue (Roadmap Input)

Priority bands are derived from impact on day-to-day spreadsheet automation and expected implementation risk.

1. `P0` Read style fidelity expansion (`SN-R41`)
2. `P0` Style write API (`SN-R42`)
3. `P0` Cell-format write API (`SN-R43`)
4. `P1` Merge/unmerge operations (`SN-R44`)
5. `P1` Table presentation metadata (`SN-R45`)
6. `P1` Grouped-table safe non-structural edits (`SN-R46`)
7. `P2` Richer pivot read surface with safe-write guard retained (`SN-R47`)

## Non-Negotiable Quality Rules

- Keep current reliability advantages:
  - formula-write support must remain stable
  - pivot/grouped safety guards must not regress
- Every new write capability requires roundtrip save/reopen tests for:
  - package `.numbers`
  - single-file archive `.numbers`
- Public docs and CLI examples must be updated for user-visible behavior changes.
