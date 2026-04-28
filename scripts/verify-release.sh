#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-v0.1.2}"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-${VERSION#v}-macOS.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"
VERIFY_DIR="$(mktemp -d /tmp/sub2api-release-verify.XXXXXX)"

cleanup() {
  rm -rf "$VERIFY_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
shasum -a 256 -c "$CHECKSUM_PATH"
unzip -t "$ZIP_PATH" >/dev/null
unzip -q "$ZIP_PATH" -d "$VERIFY_DIR"
plutil -lint "$VERIFY_DIR/$APP_NAME.app/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME.app"

echo "Release archive verified."
