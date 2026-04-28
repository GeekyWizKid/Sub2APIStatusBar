#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"
swift package clean >/dev/null 2>&1 || true
rm -rf "$ROOT_DIR/.build"

echo "Cleaned Swift build cache."
