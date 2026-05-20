#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
ZIP_NAME="$ARCHIVE_BASE.zip"
DMG_NAME="$ARCHIVE_BASE.dmg"
MANIFEST_PATH="$DIST_DIR/$ARCHIVE_BASE-manifest.json"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing release asset: $path" >&2
    exit 1
  fi
}

checksum_for() {
  local name="$1"
  local checksum_file="$DIST_DIR/$name.sha256"
  require_file "$checksum_file"
  awk '{print $1}' "$checksum_file"
}

size_for() {
  stat -f %z "$1"
}

require_file "$DIST_DIR/$ZIP_NAME"
require_file "$DIST_DIR/$DMG_NAME"

ZIP_SHA256="$(checksum_for "$ZIP_NAME")"
DMG_SHA256="$(checksum_for "$DMG_NAME")"
ZIP_SIZE="$(size_for "$DIST_DIR/$ZIP_NAME")"
DMG_SIZE="$(size_for "$DIST_DIR/$DMG_NAME")"
GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$MANIFEST_PATH" <<JSON
{
  "app": "$APP_NAME",
  "version": "${VERSION#v}",
  "tag": "$VERSION",
  "generatedAt": "$GENERATED_AT",
  "assets": [
    {
      "kind": "zip",
      "file": "$ZIP_NAME",
      "sha256": "$ZIP_SHA256",
      "sizeBytes": $ZIP_SIZE
    },
    {
      "kind": "dmg",
      "file": "$DMG_NAME",
      "sha256": "$DMG_SHA256",
      "sizeBytes": $DMG_SIZE
    }
  ]
}
JSON

echo "$MANIFEST_PATH"
