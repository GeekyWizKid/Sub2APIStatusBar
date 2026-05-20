#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
CASK_TOKEN="sub2api-status-bar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"

usage() {
  echo "Usage: VERSION=v0.1.6 $0 /path/to/downloaded-release-assets" >&2
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing downloaded release asset: $path" >&2
    exit 1
  fi
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 1
fi

DOWNLOAD_DIR="$1"
if [[ ! -d "$DOWNLOAD_DIR" ]]; then
  echo "Downloaded release asset directory does not exist: $DOWNLOAD_DIR" >&2
  exit 1
fi
DOWNLOAD_DIR="$(cd "$DOWNLOAD_DIR" && pwd)"

require_file "$DOWNLOAD_DIR/$ARCHIVE_BASE.zip"
require_file "$DOWNLOAD_DIR/$ARCHIVE_BASE.zip.sha256"
require_file "$DOWNLOAD_DIR/$ARCHIVE_BASE.dmg"
require_file "$DOWNLOAD_DIR/$ARCHIVE_BASE.dmg.sha256"
require_file "$DOWNLOAD_DIR/$ARCHIVE_BASE-manifest.json"
require_file "$DOWNLOAD_DIR/$CASK_TOKEN.rb"

DIST_DIR="$DOWNLOAD_DIR" VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release.sh"
DIST_DIR="$DOWNLOAD_DIR" VERSION="$VERSION" "$ROOT_DIR/scripts/verify-dmg.sh"
DIST_DIR="$DOWNLOAD_DIR" VERSION="$VERSION" "$ROOT_DIR/scripts/verify-release-manifest.sh"
DIST_DIR="$DOWNLOAD_DIR" VERSION="$VERSION" "$ROOT_DIR/scripts/verify-homebrew-cask.sh"

echo "Downloaded release assets verified."
