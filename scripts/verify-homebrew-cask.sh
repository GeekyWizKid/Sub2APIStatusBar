#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sub2APIStatusBar"
CASK_TOKEN="sub2api-status-bar"
VERSION="${VERSION:-$(< "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_BASE="$APP_NAME-${VERSION#v}-macOS"
MANIFEST_PATH="$DIST_DIR/$ARCHIVE_BASE-manifest.json"
CASK_PATH="$DIST_DIR/$CASK_TOKEN.rb"
REPOSITORY="${GITHUB_REPOSITORY:-GeekyWizKid/Sub2APIStatusBar}"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Missing release manifest: $MANIFEST_PATH" >&2
  exit 1
fi
if [[ ! -f "$CASK_PATH" ]]; then
  echo "Missing Homebrew cask: $CASK_PATH" >&2
  exit 1
fi

MANIFEST_PATH="$MANIFEST_PATH" CASK_PATH="$CASK_PATH" VERSION="$VERSION" REPOSITORY="$REPOSITORY" python3 - <<'PY'
import json
import os
import pathlib
import re

manifest_path = pathlib.Path(os.environ["MANIFEST_PATH"])
cask_path = pathlib.Path(os.environ["CASK_PATH"])
version = os.environ["VERSION"].removeprefix("v")
repository = os.environ["REPOSITORY"]

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
cask = cask_path.read_text(encoding="utf-8")

dmg_assets = [asset for asset in manifest.get("assets", []) if asset.get("kind") == "dmg"]
if len(dmg_assets) != 1:
    raise SystemExit("manifest must contain exactly one dmg asset")
dmg = dmg_assets[0]

required_snippets = [
    'cask "sub2api-status-bar" do',
    f'  version "{version}"',
    f'  sha256 "{dmg["sha256"]}"',
    f'  url "https://github.com/{repository}/releases/download/v#{{version}}/{dmg["file"]}"',
    '  name "Sub2API Status Bar"',
    '  desc "macOS menu bar companion for Sub2API usage, spend, token, and quota monitoring"',
    f'  homepage "https://github.com/{repository}"',
    '  depends_on macos: ">= :ventura"',
    '  app "Sub2APIStatusBar.app"',
    'end',
]

for snippet in required_snippets:
    if snippet not in cask:
        raise SystemExit(f"missing cask snippet: {snippet}")

if re.search(r"sha256\s+\"[0-9a-f]{64}\"", cask) is None:
    raise SystemExit("cask sha256 is not a 64-character lowercase hex digest")

print("Homebrew cask verified.")
PY
