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

read -r DMG_FILE DMG_SHA256 < <(
  MANIFEST_PATH="$MANIFEST_PATH" python3 - <<'PY'
import json
import os

with open(os.environ["MANIFEST_PATH"], "r", encoding="utf-8") as handle:
    manifest = json.load(handle)

for asset in manifest.get("assets", []):
    if asset.get("kind") == "dmg":
        print(asset["file"], asset["sha256"])
        break
else:
    raise SystemExit("manifest does not contain a dmg asset")
PY
)

cat > "$CASK_PATH" <<RUBY
cask "$CASK_TOKEN" do
  version "${VERSION#v}"
  sha256 "$DMG_SHA256"

  url "https://github.com/$REPOSITORY/releases/download/v#{version}/$DMG_FILE"
  name "Sub2API Status Bar"
  desc "macOS menu bar companion for Sub2API usage, spend, token, and quota monitoring"
  homepage "https://github.com/$REPOSITORY"

  depends_on macos: ">= :ventura"

  app "Sub2APIStatusBar.app"
end
RUBY

echo "$CASK_PATH"
