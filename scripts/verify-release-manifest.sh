#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
MANIFEST_PATH="$DIST_DIR/$ARCHIVE_BASE-manifest.json"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
}

require_file "$MANIFEST_PATH"

MANIFEST_PATH="$MANIFEST_PATH" DIST_DIR="$DIST_DIR" VERSION="$VERSION" APP_NAME="$APP_NAME" python3 - <<'PY'
import hashlib
import json
import os
import pathlib
import sys

manifest_path = pathlib.Path(os.environ["MANIFEST_PATH"])
dist_dir = pathlib.Path(os.environ["DIST_DIR"])
version = os.environ["VERSION"]
app_name = os.environ["APP_NAME"]

with manifest_path.open("r", encoding="utf-8") as handle:
    manifest = json.load(handle)

if manifest.get("app") != app_name:
    raise SystemExit(f"manifest app mismatch: {manifest.get('app')!r}")
if manifest.get("tag") != version:
    raise SystemExit(f"manifest tag mismatch: {manifest.get('tag')!r}")
if manifest.get("version") != version.removeprefix("v"):
    raise SystemExit(f"manifest version mismatch: {manifest.get('version')!r}")

assets = manifest.get("assets")
if not isinstance(assets, list) or len(assets) != 2:
    raise SystemExit("manifest must contain exactly zip and dmg assets")

kinds = {asset.get("kind") for asset in assets}
if kinds != {"zip", "dmg"}:
    raise SystemExit(f"manifest asset kinds mismatch: {sorted(kinds)!r}")

for asset in assets:
    file_name = asset.get("file")
    if not isinstance(file_name, str) or "/" in file_name:
        raise SystemExit(f"invalid asset file name: {file_name!r}")
    path = dist_dir / file_name
    if not path.is_file():
        raise SystemExit(f"missing asset file: {path}")

    size = path.stat().st_size
    if asset.get("sizeBytes") != size:
        raise SystemExit(f"size mismatch for {file_name}")

    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if asset.get("sha256") != digest:
        raise SystemExit(f"sha256 mismatch for {file_name}")

print("Release manifest verified.")
PY
