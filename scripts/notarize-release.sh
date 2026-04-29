#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-v0.1.3}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-${VERSION#v}-macOS.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_env APPLE_ID
require_env TEAM_ID
require_env APP_SPECIFIC_PASSWORD

if [[ -z "$SIGN_IDENTITY" || "$SIGN_IDENTITY" == "-" ]]; then
  echo "SIGN_IDENTITY must be a Developer ID Application certificate for notarization." >&2
  exit 1
fi

cd "$ROOT_DIR"
VERSION="$VERSION" SIGN_IDENTITY="$SIGN_IDENTITY" "$ROOT_DIR/scripts/package-release.sh" >/dev/null

xcrun notarytool submit "$ZIP_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --wait

xcrun stapler staple "$APP_DIR"

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
(
  cd "$DIST_DIR"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$ZIP_PATH" "$APP_NAME.app"
)
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
