#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LABELS_PATH="$ROOT_DIR/.github/labels.yml"
ISSUE_TEMPLATE_DIR="$ROOT_DIR/.github/ISSUE_TEMPLATE"

if [[ ! -f "$LABELS_PATH" ]]; then
  echo "Missing GitHub labels config: $LABELS_PATH" >&2
  exit 1
fi

if [[ ! -d "$ISSUE_TEMPLATE_DIR" ]]; then
  echo "Missing issue template directory: $ISSUE_TEMPLATE_DIR" >&2
  exit 1
fi

LABELS_PATH="$LABELS_PATH" ISSUE_TEMPLATE_DIR="$ISSUE_TEMPLATE_DIR" python3 - <<'PY'
import os
import pathlib
import re
import sys

labels_path = pathlib.Path(os.environ["LABELS_PATH"])
issue_template_dir = pathlib.Path(os.environ["ISSUE_TEMPLATE_DIR"])

text = labels_path.read_text(encoding="utf-8")
label_blocks = re.findall(
    r"(?ms)^- name: ([^\n]+)\n  color: ([0-9a-fA-F]{6})\n  description: ([^\n]+)",
    text,
)

if not label_blocks:
    raise SystemExit("labels.yml must define labels with name, color, and description")

labels = {}
for raw_name, raw_color, raw_description in label_blocks:
    name = raw_name.strip().strip('"').strip("'")
    color = raw_color.lower()
    description = raw_description.strip().strip('"').strip("'")
    if name in labels:
        raise SystemExit(f"duplicate label: {name}")
    if not description:
        raise SystemExit(f"missing description for label: {name}")
    labels[name] = color

required = {
    "bug",
    "enhancement",
    "release",
    "support",
    "security",
    "privacy",
    "documentation",
    "installation",
    "updates",
    "needs-triage",
    "needs-info",
}

missing = sorted(required - set(labels))
if missing:
    raise SystemExit(f"missing required labels: {', '.join(missing)}")

for path in sorted(issue_template_dir.glob("*.md")):
    content = path.read_text(encoding="utf-8")
    match = re.search(r"(?m)^labels:\s*(.+)$", content)
    if not match:
        continue
    template_labels = [
        label.strip().strip('"').strip("'")
        for label in match.group(1).split(",")
        if label.strip()
    ]
    for label in template_labels:
        if label not in labels:
            raise SystemExit(f"{path.name} references undefined label: {label}")

print("GitHub labels verified.")
PY
