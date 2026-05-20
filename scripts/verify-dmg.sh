#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/$APP_NAME-${VERSION#v}-macOS.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
MOUNT_DIR="$(mktemp -d /tmp/sub2api-dmg-mount.XXXXXX)"
ATTACHED=0

cleanup() {
  if [[ "$ATTACHED" == "1" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$MOUNT_DIR"
}
trap cleanup EXIT

cd "$DIST_DIR"
shasum -a 256 -c "$(basename "$CHECKSUM_PATH")"
cd "$ROOT_DIR"
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse -quiet
ATTACHED=1

test -d "$MOUNT_DIR/$APP_NAME.app"
test -L "$MOUNT_DIR/Applications"
plutil -lint "$MOUNT_DIR/$APP_NAME.app/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$MOUNT_DIR/$APP_NAME.app"

echo "DMG archive verified."
