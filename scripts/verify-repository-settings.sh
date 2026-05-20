#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SETTINGS_PATH="$ROOT_DIR/.github/repository-settings.yml"
ISSUE_CONFIG_PATH="$ROOT_DIR/.github/ISSUE_TEMPLATE/config.yml"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing repository settings file: $path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if ! grep -Fq "$text" "$path"; then
    echo "Missing repository setting in $path: $text" >&2
    exit 1
  fi
}

require_file "$SETTINGS_PATH"
require_file "$ISSUE_CONFIG_PATH"

require_text "$SETTINGS_PATH" "private_vulnerability_reporting: true"
require_text "$SETTINGS_PATH" "delete_branch_on_merge: true"
require_text "$SETTINGS_PATH" "name: main"
require_text "$SETTINGS_PATH" "required_pull_request_reviews: true"
require_text "$SETTINGS_PATH" "dismiss_stale_reviews: true"
require_text "$SETTINGS_PATH" "required_linear_history: true"
require_text "$SETTINGS_PATH" "required_status_checks:"
require_text "$SETTINGS_PATH" "strict: true"
require_text "$SETTINGS_PATH" "Test and Package"
require_text "$SETTINGS_PATH" "blank_issues_enabled: false"
require_text "$SETTINGS_PATH" "security_contact_link: https://github.com/GeekyWizKid/Sub2APIStatusBar/security/policy"
require_text "$ISSUE_CONFIG_PATH" "blank_issues_enabled: false"
require_text "$ISSUE_CONFIG_PATH" "https://github.com/GeekyWizKid/Sub2APIStatusBar/security/policy"

echo "Repository settings verified."
