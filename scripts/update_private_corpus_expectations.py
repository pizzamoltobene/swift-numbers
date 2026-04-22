#!/usr/bin/env python3
"""Generate/update private corpus expectations for local regression tests."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--corpus",
        type=Path,
        default=None,
        help="Path to private corpus root (defaults to SWIFT_NUMBERS_PRIVATE_CORPUS or ./PrivateCorpus).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Manifest path (defaults to SWIFT_NUMBERS_PRIVATE_EXPECTATIONS or ./.private-corpus/expectations.json).",
    )
    parser.add_argument(
        "--swift-configuration",
        choices=["debug", "release"],
        default="debug",
        help="Swift build configuration for swiftnumbers CLI.",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write manifest to disk. Without this flag, runs as dry-run and prints JSON.",
    )
    return parser.parse_args()


def resolve_corpus_path(cli_path: Path | None) -> Path:
    if cli_path is not None:
        return cli_path.expanduser().resolve()

    env_path = os.environ.get("SWIFT_NUMBERS_PRIVATE_CORPUS", "").strip()
    if env_path:
        return Path(env_path).expanduser().resolve()

    return (Path.cwd() / "PrivateCorpus").resolve()


def resolve_output_path(cli_path: Path | None) -> Path:
    if cli_path is not None:
        return cli_path.expanduser().resolve()

    env_path = os.environ.get("SWIFT_NUMBERS_PRIVATE_EXPECTATIONS", "").strip()
    if env_path:
        return Path(env_path).expanduser().resolve()

    return (Path.cwd() / ".private-corpus" / "expectations.json").resolve()


def discover_numbers_documents(corpus: Path) -> list[Path]:
    if not corpus.exists() or not corpus.is_dir():
        return []
    return sorted(path.resolve() for path in corpus.rglob("*.numbers") if not path.name.startswith("."))


def resolve_swiftnumbers_executable(configuration: str) -> Path:
    cmd = ["swift", "build", "--show-bin-path", "-c", configuration]
    completed = subprocess.run(cmd, check=True, capture_output=True, text=True)
    executable = Path(completed.stdout.strip()) / "swiftnumbers"
    if not executable.exists():
        subprocess.run(["swift", "build", "--product", "swiftnumbers", "-c", configuration], check=True)
    if not executable.exists():
        raise RuntimeError(f"swiftnumbers executable not found at {executable}")
    return executable.resolve()


def relative_path(path: Path, root: Path) -> str:
    return str(path.resolve().relative_to(root.resolve()))


def collect_metrics(executable: Path, document: Path) -> dict:
    cmd = [str(executable), "dump", str(document), "--format", "json"]
    completed = subprocess.run(cmd, check=True, capture_output=True, text=True)
    payload = json.loads(completed.stdout)

    resolved_cells = int(payload.get("resolvedCellCount", 0))
    return {
        "path": None,  # filled later
        "minSheets": int(payload.get("sheetCount", 0)),
        "minTables": int(payload.get("tableCount", 0)),
        "minPopulatedCells": resolved_cells,
        "allowEmptyCells": resolved_cells == 0,
    }


def main() -> int:
    args = parse_args()
    corpus = resolve_corpus_path(args.corpus)
    output = resolve_output_path(args.output)

    documents = discover_numbers_documents(corpus)
    if not documents:
        print(f"No .numbers documents found in corpus: {corpus}")
        return 2

    executable = resolve_swiftnumbers_executable(args.swift_configuration)

    entries = []
    for document in documents:
        metrics = collect_metrics(executable, document)
        metrics["path"] = relative_path(document, corpus)
        entries.append(metrics)

    manifest = {
        "version": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "swiftConfiguration": args.swift_configuration,
        "corpus": str(corpus),
        "documents": entries,
    }

    rendered = json.dumps(manifest, ensure_ascii=False, indent=2)
    if not args.write:
        print(rendered)
        return 0

    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_suffix(output.suffix + ".tmp")
    temp.write_text(rendered + "\n", encoding="utf-8")
    temp.replace(output)
    print(f"Updated private corpus expectation manifest: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
