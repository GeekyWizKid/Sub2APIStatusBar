#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
ZIP_PATH="$DIST_DIR/$ARCHIVE_BASE.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

cd "$ROOT_DIR"
VERSION="$VERSION" "$ROOT_DIR/scripts/build-app.sh" >/dev/null

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
(
  cd "$DIST_DIR"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$ZIP_PATH" "$APP_NAME.app"
)
(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
