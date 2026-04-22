# Contributing

## Setup

```bash
swift build
swift test
./scripts/ci-check.sh
```

## Development Rules

- Keep locally created fixtures synthetic (no personal or proprietary data).
- External fixtures are allowed only from public/open-source sources.
- Real-world `.numbers` files belong only in local private corpus (`PrivateCorpus/` or `SWIFT_NUMBERS_PRIVATE_CORPUS`) and must stay uncommitted.
- Keep private-corpus expectations local in `.private-corpus/expectations.json` (or `SWIFT_NUMBERS_PRIVATE_EXPECTATIONS`) and refresh via `./scripts/update_private_corpus_expectations.py --write` when decode behavior intentionally changes.
- Vendored upstream assets are refreshed via `./scripts/import_numbers_parser_assets.sh`.
- Add tests for every behavior change.
- Preserve deterministic CLI output for `dump` and `list-sheets`.

## Pull Request Checklist

- [ ] Build passes locally (`swift build`)
- [ ] Tests pass locally (`swift test`)
- [ ] Full local pipeline passes (`./scripts/ci-check.sh`)
- [ ] Private corpus expectations updated if real-read behavior changed (`./scripts/update_private_corpus_expectations.py --write`)
- [ ] Changelog/README updated when behavior changes
