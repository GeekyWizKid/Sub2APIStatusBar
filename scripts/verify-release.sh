#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-v0.1.8}"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-${VERSION#v}-macOS.zip"
ZIP_CHECKSUM_PATH="$ZIP_PATH.sha256"
DMG_PATH="$DIST_DIR/$APP_NAME-${VERSION#v}-macOS.dmg"
DMG_CHECKSUM_PATH="$DMG_PATH.sha256"
VERIFY_DIR="$(mktemp -d /tmp/sub2api-release-verify.XXXXXX)"
DMG_MOUNT_DIR="$(mktemp -d /tmp/sub2api-release-dmg.XXXXXX)"
DMG_ATTACHED=0

cleanup() {
  if [[ "$DMG_ATTACHED" -eq 1 ]]; then
    hdiutil detach "$DMG_MOUNT_DIR" -quiet || true
  fi
  rm -rf "$VERIFY_DIR"
  rm -rf "$DMG_MOUNT_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
shasum -a 256 -c "$ZIP_CHECKSUM_PATH"
shasum -a 256 -c "$DMG_CHECKSUM_PATH"
unzip -t "$ZIP_PATH" >/dev/null
unzip -q "$ZIP_PATH" -d "$VERIFY_DIR"
plutil -lint "$VERIFY_DIR/$APP_NAME.app/Contents/Info.plist" >/dev/null
plutil -extract NSUserNotificationsUsageDescription raw "$VERIFY_DIR/$APP_NAME.app/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME.app"

hdiutil attach "$DMG_PATH" -mountpoint "$DMG_MOUNT_DIR" -nobrowse -quiet
DMG_ATTACHED=1
test -d "$DMG_MOUNT_DIR/$APP_NAME.app"
test -e "$DMG_MOUNT_DIR/Applications"
ditto "$DMG_MOUNT_DIR/$APP_NAME.app" "$VERIFY_DIR/$APP_NAME-dmg.app"
xattr -cr "$VERIFY_DIR/$APP_NAME-dmg.app"
plutil -lint "$VERIFY_DIR/$APP_NAME-dmg.app/Contents/Info.plist" >/dev/null
plutil -extract NSUserNotificationsUsageDescription raw "$VERIFY_DIR/$APP_NAME-dmg.app/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$VERIFY_DIR/$APP_NAME-dmg.app"
hdiutil detach "$DMG_MOUNT_DIR" -quiet
DMG_ATTACHED=0

echo "Release archive verified."
