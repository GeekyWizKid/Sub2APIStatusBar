#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SECURITY_PATH="$ROOT_DIR/SECURITY.md"
ISSUE_CONFIG_PATH="$ROOT_DIR/.github/ISSUE_TEMPLATE/config.yml"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing security reporting file: $path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if ! grep -Fq "$text" "$path"; then
    echo "Missing security reporting text in $path: $text" >&2
    exit 1
  fi
}

reject_text() {
  local path="$1"
  local text="$2"
  if grep -Fq "$text" "$path"; then
    echo "Forbidden security reporting text in $path: $text" >&2
    exit 1
  fi
}

require_file "$SECURITY_PATH"
require_file "$ISSUE_CONFIG_PATH"

require_text "$SECURITY_PATH" "Do not open a public GitHub Issue for security vulnerabilities."
require_text "$SECURITY_PATH" "Use GitHub private vulnerability reporting from the repository Security tab"
require_text "$SECURITY_PATH" "Do not include exploit details, secrets, server URLs, tokens, or private logs in public issues."
reject_text "$SECURITY_PATH" "open a minimal public issue"

require_text "$ISSUE_CONFIG_PATH" "blank_issues_enabled: false"
require_text "$ISSUE_CONFIG_PATH" "Security vulnerability"
require_text "$ISSUE_CONFIG_PATH" "https://github.com/GeekyWizKid/Sub2APIStatusBar/security/policy"
require_text "$ISSUE_CONFIG_PATH" "Support checklist"

echo "Security reporting verified."
