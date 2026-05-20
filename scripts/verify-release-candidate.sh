#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
REQUIRE_NOTARIZATION="${REQUIRE_NOTARIZATION:-false}"
NOTARIZATION_REQUESTED=false

step() {
  printf '\n==> %s\n' "$1"
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

cd "$ROOT_DIR"

case "$REQUIRE_NOTARIZATION" in
  true|1|yes)
    NOTARIZATION_REQUESTED=true
    ;;
  false|0|no)
    NOTARIZATION_REQUESTED=false
    ;;
  *)
    echo "REQUIRE_NOTARIZATION must be true or false." >&2
    exit 1
    ;;
esac

if [[ "$NOTARIZATION_REQUESTED" == "true" ]]; then
  require_env APPLE_ID
  require_env TEAM_ID
  require_env APP_SPECIFIC_PASSWORD
  require_env SIGN_IDENTITY
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "SIGN_IDENTITY must be a Developer ID Application certificate for notarization." >&2
    exit 1
  fi
fi

step "Run Swift tests"
swift test

step "Build debug product"
swift build

if [[ "$NOTARIZATION_REQUESTED" == "true" ]]; then
  step "Package and notarize release"
  VERSION="$VERSION" "$ROOT_DIR/scripts/notarize-release.sh"
else
  step "Package zip release"
  VERSION="$VERSION" "$ROOT_DIR/scripts/package-release.sh"
fi

step "Verify zip release"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release.sh"

if [[ "$NOTARIZATION_REQUESTED" != "true" ]]; then
  step "Package DMG release"
  VERSION="$VERSION" "$ROOT_DIR/scripts/package-dmg.sh"
fi

step "Verify DMG release"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-dmg.sh"

if [[ "$NOTARIZATION_REQUESTED" != "true" ]]; then
  step "Generate release manifest"
  VERSION="$VERSION" "$ROOT_DIR/scripts/generate-release-manifest.sh"
fi

step "Verify release manifest"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release-manifest.sh"

step "Generate Homebrew cask"
VERSION="$VERSION" "$ROOT_DIR/scripts/generate-homebrew-cask.sh"

step "Verify Homebrew cask"
VERSION="$VERSION" "$ROOT_DIR/scripts/verify-homebrew-cask.sh"

step "Release candidate verified for $VERSION"
