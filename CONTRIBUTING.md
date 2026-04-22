# Contributing

## Setup

```bash
swift build
swift test
```

## Development Rules

- Keep locally created fixtures synthetic (no personal or proprietary data).
- External fixtures are allowed only from public/open-source sources.
- Vendored upstream assets are refreshed via `./scripts/import_numbers_parser_assets.sh`.
- Add tests for every behavior change.
- Preserve deterministic CLI output for `dump` and `list-sheets`.

## Pull Request Checklist

- [ ] Build passes locally (`swift build`)
- [ ] Tests pass locally (`swift test`)
- [ ] Formatting check passes (`./scripts/ci-format-check.sh`)
- [ ] Changelog/README updated when behavior changes
