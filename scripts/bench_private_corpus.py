#!/usr/bin/env python3
"""Benchmark private .numbers corpus against Python numbers-parser and SwiftNumbers CLI."""

from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--corpus",
        type=Path,
        default=None,
        help="Path to private corpus root (defaults to SWIFT_NUMBERS_PRIVATE_CORPUS or ./PrivateCorpus).",
    )
    parser.add_argument("--warmup", type=int, default=1, help="Warmup runs per file per command.")
    parser.add_argument("--iterations", type=int, default=5, help="Measured runs per file per command.")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(".local/perf-last-run.json"),
        help="Output JSON path for this run.",
    )
    parser.add_argument(
        "--guardrail-percent",
        type=float,
        default=15.0,
        help="Fail if Swift command mean regresses above this threshold vs baseline.",
    )
    parser.add_argument(
        "--update-baseline",
        action="store_true",
        help="Write the current run as baseline for each configuration.",
    )
    parser.add_argument(
        "--skip-swift-build",
        action="store_true",
        help="Do not run swift build before benchmarking.",
    )
    parser.add_argument(
        "--swift-launch",
        choices=["binary", "swift-run"],
        default="binary",
        help="How to launch Swift CLI benchmarks. 'binary' is faster and preferred.",
    )
    parser.add_argument(
        "--swift-configurations",
        default=None,
        help="Comma-separated Swift build configurations to benchmark (default: debug,release).",
    )
    parser.add_argument(
        "--swift-configuration",
        choices=["debug", "release"],
        default=None,
        help="Backward-compatible single configuration mode.",
    )
    parser.add_argument(
        "--baseline-debug",
        type=Path,
        default=Path(".local/perf-baseline-debug.json"),
        help="Baseline JSON path for debug configuration.",
    )
    parser.add_argument(
        "--baseline-release",
        type=Path,
        default=Path(".local/perf-baseline-release.json"),
        help="Baseline JSON path for release configuration.",
    )
    return parser.parse_args()


def resolve_configurations(args: argparse.Namespace) -> list[str]:
    if args.swift_configurations:
        requested = [part.strip() for part in args.swift_configurations.split(",")]
        values = [part for part in requested if part]
    elif args.swift_configuration:
        values = [args.swift_configuration]
    else:
        values = ["debug", "release"]

    allowed = {"debug", "release"}
    deduplicated: list[str] = []
    for value in values:
        if value not in allowed:
            raise ValueError(f"Unsupported Swift configuration: {value}")
        if value not in deduplicated:
            deduplicated.append(value)
    return deduplicated


def resolve_corpus_path(cli_path: Path | None) -> Path:
    if cli_path is not None:
        return cli_path.expanduser().resolve()

    env_path = os.environ.get("SWIFT_NUMBERS_PRIVATE_CORPUS", "").strip()
    if env_path:
        return Path(env_path).expanduser().resolve()

    return (Path.cwd() / "PrivateCorpus").resolve()


def discover_numbers_documents(corpus: Path) -> list[Path]:
    if not corpus.exists() or not corpus.is_dir():
        return []

    results: list[Path] = []
    for path in sorted(corpus.rglob("*.numbers")):
        if path.name.startswith("."):
            continue
        results.append(path.resolve())
    return results


def measure_document_size(path: Path) -> int:
    if path.is_file():
        return path.stat().st_size

    total = 0
    for child in path.rglob("*"):
        if child.is_file():
            total += child.stat().st_size
    return total


@dataclass
class CommandSamples:
    samples_ms: list[float]

    def summary(self) -> dict[str, float]:
        if not self.samples_ms:
            return {"mean_ms": 0.0, "median_ms": 0.0, "p95_ms": 0.0, "count": 0}

        ordered = sorted(self.samples_ms)
        p95_index = min(len(ordered) - 1, int(round(0.95 * (len(ordered) - 1))))
        return {
            "mean_ms": statistics.fmean(self.samples_ms),
            "median_ms": statistics.median(self.samples_ms),
            "p95_ms": ordered[p95_index],
            "count": len(self.samples_ms),
        }


def run_command(command: list[str]) -> float:
    started = time.perf_counter()
    completed = subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    elapsed = (time.perf_counter() - started) * 1000.0

    if completed.returncode != 0:
        raise RuntimeError(f"Command failed ({completed.returncode}): {' '.join(command)}")

    return elapsed


def python_numbers_parser_command(file_path: Path) -> list[str]:
    snippet = (
        "from numbers_parser import Document;"
        "import sys;"
        "doc=Document(sys.argv[1]);"
        "sheets_attr=getattr(doc,'sheets',None);"
        "sheets=sheets_attr() if callable(sheets_attr) else sheets_attr;"
        "_ = len(sheets or [])"
    )
    return ["python3", "-c", snippet, str(file_path)]


def python_numbers_parser_available() -> bool:
    probe = subprocess.run(
        ["python3", "-c", "import numbers_parser"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return probe.returncode == 0


def benchmark_documents(
    documents: Iterable[Path],
    warmup: int,
    iterations: int,
    include_python: bool,
    swift_commands: dict[str, list[str]],
) -> dict[str, dict[str, float] | dict[str, list[float]]]:
    samples: dict[str, CommandSamples] = {
        "swift_list_sheets": CommandSamples(samples_ms=[]),
        "swift_dump": CommandSamples(samples_ms=[]),
    }

    if include_python:
        samples["python_numbers_parser"] = CommandSamples(samples_ms=[])

    for document in documents:
        for _ in range(warmup):
            for key, base in swift_commands.items():
                _ = run_command([*base, str(document)])
            if include_python:
                try:
                    _ = run_command(python_numbers_parser_command(document))
                except RuntimeError as error:
                    print(f"[warn] Skipping python warmup for {document.name}: {error}")

        for _ in range(iterations):
            for key, base in swift_commands.items():
                elapsed = run_command([*base, str(document)])
                samples[key].samples_ms.append(elapsed)

            if include_python:
                try:
                    elapsed = run_command(python_numbers_parser_command(document))
                    samples["python_numbers_parser"].samples_ms.append(elapsed)
                except RuntimeError as error:
                    print(f"[warn] Skipping python measurement for {document.name}: {error}")

    payload: dict[str, dict[str, float] | dict[str, list[float]]] = {}
    for key, command_samples in samples.items():
        payload[key] = {
            "summary": command_samples.summary(),
            "samples_ms": command_samples.samples_ms,
        }

    return payload


def print_summary(
    results_by_config: dict[str, dict[str, dict[str, float] | dict[str, list[float]]]]
) -> None:
    print("Benchmark summary (ms):")
    for config in sorted(results_by_config.keys()):
        print(f"[{config}]")
        for key in ["python_numbers_parser", "swift_list_sheets", "swift_dump"]:
            if key not in results_by_config[config]:
                continue
            summary = results_by_config[config][key]["summary"]
            print(
                f"- {key}: mean={summary['mean_ms']:.2f}, "
                f"median={summary['median_ms']:.2f}, p95={summary['p95_ms']:.2f}, n={int(summary['count'])}"
            )


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: dict) -> None:
    ensure_parent(path)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)


def check_guardrail(current: dict, baseline: dict, threshold_percent: float) -> list[str]:
    failures: list[str] = []

    for command in ["swift_list_sheets", "swift_dump"]:
        if command not in current or command not in baseline:
            continue

        current_mean = float(current[command]["summary"]["mean_ms"])
        baseline_mean = float(baseline[command]["summary"]["mean_ms"])
        if baseline_mean <= 0:
            continue

        regression = ((current_mean - baseline_mean) / baseline_mean) * 100.0
        if regression > threshold_percent:
            failures.append(
                f"{command}: regression {regression:.2f}% exceeds {threshold_percent:.2f}% "
                f"(baseline {baseline_mean:.2f}ms -> current {current_mean:.2f}ms)"
            )

    return failures


def assert_swift_samples(results: dict, configuration: str) -> list[str]:
    failures: list[str] = []
    for command in ["swift_list_sheets", "swift_dump"]:
        if command not in results:
            failures.append(f"{configuration}: missing benchmark result for {command}")
            continue
        count = int(results[command]["summary"]["count"])
        if count <= 0:
            failures.append(
                f"{configuration}: {command} produced zero samples (n=0) which is invalid for perf gating"
            )
    return failures


def baseline_path_for(configuration: str, args: argparse.Namespace) -> Path:
    if configuration == "debug":
        return args.baseline_debug
    if configuration == "release":
        return args.baseline_release
    raise ValueError(f"Unsupported configuration: {configuration}")


def resolve_swift_commands(args: argparse.Namespace, configuration: str) -> dict[str, list[str]]:
    if args.swift_launch == "swift-run":
        return {
            "swift_list_sheets": [
                "swift",
                "run",
                "-c",
                configuration,
                "--skip-build",
                "swiftnumbers",
                "list-sheets",
            ],
            "swift_dump": [
                "swift",
                "run",
                "-c",
                configuration,
                "--skip-build",
                "swiftnumbers",
                "dump",
            ],
        }

    show_bin_path_cmd = ["swift", "build", "--show-bin-path", "-c", configuration]
    show_bin_path = subprocess.run(show_bin_path_cmd, check=True, capture_output=True, text=True)
    bin_path = Path(show_bin_path.stdout.strip())
    executable = (bin_path / "swiftnumbers").resolve()

    if not executable.exists():
        raise RuntimeError(f"Swift benchmark executable not found: {executable}")

    return {
        "swift_list_sheets": [str(executable), "list-sheets"],
        "swift_dump": [str(executable), "dump"],
    }


def main() -> int:
    args = parse_args()
    configurations = resolve_configurations(args)

    corpus = resolve_corpus_path(args.corpus)
    documents = discover_numbers_documents(corpus)
    if not documents:
        print(f"No .numbers documents found in corpus: {corpus}")
        return 2

    if not args.skip_swift_build:
        for configuration in configurations:
            print(f"Building Swift package before benchmark ({configuration})...")
            subprocess.run(["swift", "build", "-c", configuration], check=True)

    include_python = python_numbers_parser_available()
    if not include_python:
        print("numbers-parser not available in Python environment; python baseline will be skipped.")

    print(
        f"Benchmarking {len(documents)} document(s) from {corpus} for configurations: {', '.join(configurations)}"
    )

    started = time.time()
    results_by_config: dict[str, dict[str, dict[str, float] | dict[str, list[float]]]] = {}
    swift_commands_by_config: dict[str, dict[str, list[str]]] = {}
    sample_failures: list[str] = []

    for configuration in configurations:
        swift_commands = resolve_swift_commands(args, configuration)
        swift_commands_by_config[configuration] = swift_commands

        raw_results = benchmark_documents(
            documents=documents,
            warmup=max(args.warmup, 0),
            iterations=max(args.iterations, 1),
            include_python=include_python,
            swift_commands=swift_commands,
        )
        results_by_config[configuration] = raw_results
        sample_failures.extend(assert_swift_samples(raw_results, configuration))

    duration_s = time.time() - started

    report = {
        "meta": {
            "timestamp_epoch": int(time.time()),
            "duration_seconds": duration_s,
            "corpus": str(corpus),
            "documents": [str(path) for path in documents],
            "document_sizes_bytes": {str(path): measure_document_size(path) for path in documents},
            "warmup": args.warmup,
            "iterations": args.iterations,
            "swift_launch": args.swift_launch,
            "swift_configurations": configurations,
            "swift_commands_by_configuration": swift_commands_by_config,
        },
        "results_by_configuration": results_by_config,
    }

    print_summary(results_by_config)
    write_json(args.output, report)
    print(f"Saved run report: {args.output}")

    if sample_failures:
        print("Invalid benchmark run:")
        for failure in sample_failures:
            print(f"- {failure}")
        return 4

    if args.update_baseline:
        for configuration in configurations:
            baseline_path = baseline_path_for(configuration, args)
            baseline_report = {
                "meta": {
                    "timestamp_epoch": report["meta"]["timestamp_epoch"],
                    "duration_seconds": report["meta"]["duration_seconds"],
                    "corpus": report["meta"]["corpus"],
                    "documents": report["meta"]["documents"],
                    "document_sizes_bytes": report["meta"]["document_sizes_bytes"],
                    "warmup": report["meta"]["warmup"],
                    "iterations": report["meta"]["iterations"],
                    "swift_launch": report["meta"]["swift_launch"],
                    "swift_configuration": configuration,
                    "swift_commands": swift_commands_by_config[configuration],
                },
                "results": results_by_config[configuration],
            }
            write_json(baseline_path, baseline_report)
            print(f"Updated baseline ({configuration}): {baseline_path}")
        return 0

    any_baseline_checked = False
    guardrail_failures: list[str] = []
    for configuration in configurations:
        baseline_path = baseline_path_for(configuration, args)
        baseline_payload = load_json(baseline_path)
        if baseline_payload is None:
            print(f"Baseline file not found for {configuration}: {baseline_path}")
            continue

        any_baseline_checked = True
        failures = check_guardrail(
            current=results_by_config[configuration],
            baseline=baseline_payload.get("results", {}),
            threshold_percent=args.guardrail_percent,
        )
        guardrail_failures.extend([f"{configuration}: {failure}" for failure in failures])

    if not any_baseline_checked:
        print("No baselines found. Run again with --update-baseline to create debug/release baselines.")
        return 0

    if guardrail_failures:
        print("Guardrail failed:")
        for failure in guardrail_failures:
            print(f"- {failure}")
        return 3

    print("Guardrail passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
