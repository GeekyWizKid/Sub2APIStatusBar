#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"

step() {
  printf '\n==> %s\n' "$1"
}

cd "$ROOT_DIR"

step "Run Swift tests"
swift test

step "Build debug product"
swift build

step "Package zip release"
VERSION="$VERSION" "$ROOT_DIR/scripts/package-release.sh"

step "Verify zip release"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release.sh"

step "Package DMG release"
VERSION="$VERSION" "$ROOT_DIR/scripts/package-dmg.sh"

step "Verify DMG release"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-dmg.sh"

step "Generate release manifest"
VERSION="$VERSION" "$ROOT_DIR/scripts/generate-release-manifest.sh"

step "Verify release manifest"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release-manifest.sh"

step "Release candidate verified for $VERSION"
