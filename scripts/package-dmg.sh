#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
SKIP_BUILD="${SKIP_BUILD:-false}"
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

remove_packaging_detritus() {
  local path="$1"
  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.FinderInfo "$path" 2>/dev/null || true
    xattr -dr com.apple.ResourceFork "$path" 2>/dev/null || true
  fi
  find "$path" \( -name '.DS_Store' -o -name '._*' \) -delete
}

cd "$ROOT_DIR"
case "$SKIP_BUILD" in
  true|1|yes)
    if [[ ! -d "$APP_DIR" ]]; then
      echo "Missing app bundle for SKIP_BUILD=true: $APP_DIR" >&2
      exit 1
    fi
    ;;
  false|0|no)
    VERSION="$VERSION" "$ROOT_DIR/scripts/build-app.sh" >/dev/null
    ;;
  *)
    echo "SKIP_BUILD must be true or false." >&2
    exit 1
    ;;
esac

rm -f "$DMG_PATH" "$CHECKSUM_PATH"
cp -R "$APP_DIR" "$STAGING_DIR/"
remove_packaging_detritus "$STAGING_DIR/$APP_NAME.app"
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
