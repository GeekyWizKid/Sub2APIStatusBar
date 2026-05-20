#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
README_PATH="$ROOT_DIR/README.md"
HTML_PATH="$ROOT_DIR/docs/assets/product-preview.html"
PNG_PATH="$ROOT_DIR/docs/assets/product-preview.png"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing product preview asset: $path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if ! grep -Fq "$text" "$path"; then
    echo "Missing preview text in $path: $text" >&2
    exit 1
  fi
}

require_file "$README_PATH"
require_file "$HTML_PATH"
require_file "$PNG_PATH"

require_text "$README_PATH" "![Sub2API Status Bar preview](docs/assets/product-preview.png)"

read -r WIDTH HEIGHT < <(
  PNG_PATH="$PNG_PATH" python3 - <<'PY'
import os
import struct

path = os.environ["PNG_PATH"]
with open(path, "rb") as handle:
    signature = handle.read(8)
    if signature != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("product preview is not a PNG")
    length = struct.unpack(">I", handle.read(4))[0]
    chunk_type = handle.read(4)
    if chunk_type != b"IHDR" or length < 8:
        raise SystemExit("product preview PNG has invalid IHDR")
    width, height = struct.unpack(">II", handle.read(8))

print(width, height)
PY
)

if [[ "$WIDTH" != "1200" || "$HEIGHT" != "820" ]]; then
  echo "Product preview PNG must be 1200x820, got ${WIDTH}x${HEIGHT}." >&2
  exit 1
fi

require_text "$HTML_PATH" "Sub2API Status Bar Preview"
require_text "$HTML_PATH" "Daily spend"
require_text "$HTML_PATH" "Token trend"
require_text "$HTML_PATH" "Subscriptions"
require_text "$HTML_PATH" "High Usage"
require_text "$HTML_PATH" "Local alerts"
require_text "$HTML_PATH" "Settings"
require_text "$HTML_PATH" "Copy Diagnostics"

echo "Product preview assets verified."
