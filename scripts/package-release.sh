#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-v0.1.6}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
ZIP_PATH="$DIST_DIR/$ARCHIVE_BASE.zip"
ZIP_CHECKSUM_PATH="$ZIP_PATH.sha256"
DMG_PATH="$DIST_DIR/$ARCHIVE_BASE.dmg"
DMG_CHECKSUM_PATH="$DMG_PATH.sha256"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"

cd "$ROOT_DIR"
VERSION="$VERSION" "$ROOT_DIR/scripts/build-app.sh" >/dev/null

rm -f "$ZIP_PATH" "$ZIP_CHECKSUM_PATH" "$DMG_PATH" "$DMG_CHECKSUM_PATH"
(
  cd "$DIST_DIR"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$ZIP_PATH" "$APP_NAME.app"
)
shasum -a 256 "$ZIP_PATH" > "$ZIP_CHECKSUM_PATH"

rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
ditto "$APP_DIR" "$DMG_STAGING_DIR/$APP_NAME.app"
xattr -cr "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null
rm -rf "$DMG_STAGING_DIR"
shasum -a 256 "$DMG_PATH" > "$DMG_CHECKSUM_PATH"

echo "$ZIP_PATH"
echo "$ZIP_CHECKSUM_PATH"
echo "$DMG_PATH"
echo "$DMG_CHECKSUM_PATH"
