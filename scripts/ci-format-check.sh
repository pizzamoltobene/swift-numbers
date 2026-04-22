#!/usr/bin/env bash
set -euo pipefail

if swift format --help >/dev/null 2>&1; then
  swift format lint --recursive Sources Tests Package.swift
else
  echo "swift format is not available in this toolchain"
  exit 1
fi
