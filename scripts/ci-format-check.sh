#!/usr/bin/env bash
set -euo pipefail

if swift format --help >/dev/null 2>&1; then
  swift format lint --strict --recursive Sources Tests Package.swift
elif command -v swift-format >/dev/null 2>&1; then
  swift-format lint --strict --recursive Sources Tests Package.swift
else
  echo "Neither 'swift format' nor 'swift-format' is available in this toolchain"
  exit 1
fi
