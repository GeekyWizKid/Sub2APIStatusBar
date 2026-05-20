#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
DMG_PATH="$DIST_DIR/$ARCHIVE_BASE.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
STAGING_DIR="$(mktemp -d /tmp/sub2api-dmg-stage.XXXXXX)"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
VERSION="$VERSION" "$ROOT_DIR/scripts/build-app.sh" >/dev/null

rm -f "$DMG_PATH" "$CHECKSUM_PATH"
cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "Sub2API Status Bar" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

echo "$DMG_PATH"
echo "$CHECKSUM_PATH"
