# Contributing

## Setup

```bash
swift build
swift test
./scripts/ci-check.sh
```

## Development Rules

- Keep created fixtures synthetic (no personal or proprietary data).
- Real-world `.numbers` files must remain local (`PrivateCorpus/` or `SWIFT_NUMBERS_PRIVATE_CORPUS`).
- Keep private-corpus expectations local in `.private-corpus/expectations.json` (or `SWIFT_NUMBERS_PRIVATE_EXPECTATIONS`).
- Refresh expectations via `./scripts/update_private_corpus_expectations.py --write` after intentional decode behavior changes.
- Add tests for every behavior change.
- Preserve deterministic CLI output for `dump` and `list-sheets`.

## Pull Request Checklist

- [ ] Build passes locally (`swift build`)
- [ ] Tests pass locally (`swift test`)
- [ ] Full local pipeline passes (`./scripts/ci-check.sh`)
- [ ] Private corpus expectations updated if real-read behavior changed (`./scripts/update_private_corpus_expectations.py --write`)
- [ ] README/docs updated when behavior changes
