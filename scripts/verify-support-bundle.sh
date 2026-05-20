#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SUPPORT_PATH="$ROOT_DIR/SUPPORT.md"
TEMPLATE_PATH="$ROOT_DIR/docs/SUPPORT_BUNDLE.md"
BUG_TEMPLATE_PATH="$ROOT_DIR/.github/ISSUE_TEMPLATE/bug_report.md"
README_PATH="$ROOT_DIR/README.md"
CORE_REPORT_PATH="$ROOT_DIR/Sources/Sub2APIStatusCore/SupportBundleReport.swift"
APP_PATH="$ROOT_DIR/Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift"
TEST_PATH="$ROOT_DIR/Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing support bundle file: $path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if ! grep -Fq "$text" "$path"; then
    echo "Missing support bundle text in $path: $text" >&2
    exit 1
  fi
}

require_file "$SUPPORT_PATH"
require_file "$TEMPLATE_PATH"
require_file "$BUG_TEMPLATE_PATH"
require_file "$README_PATH"
require_file "$CORE_REPORT_PATH"
require_file "$APP_PATH"
require_file "$TEST_PATH"

require_text "$TEMPLATE_PATH" "Support Bundle Template"
require_text "$TEMPLATE_PATH" "Settings > Diagnostics > Copy Support Bundle"
require_text "$TEMPLATE_PATH" "Do not attach"
require_text "$TEMPLATE_PATH" 'config.json'
require_text "$TEMPLATE_PATH" "access tokens"
require_text "$TEMPLATE_PATH" "refresh tokens"
require_text "$TEMPLATE_PATH" "passwords"
require_text "$TEMPLATE_PATH" "private server logs"
require_text "$TEMPLATE_PATH" "App version"
require_text "$TEMPLATE_PATH" "macOS version"
require_text "$TEMPLATE_PATH" "Install source"
require_text "$TEMPLATE_PATH" "Release asset SHA-256 verification result"
require_text "$TEMPLATE_PATH" "Reproduction"
require_text "$TEMPLATE_PATH" "Expected Behavior"
require_text "$TEMPLATE_PATH" "Actual Behavior"
require_text "$TEMPLATE_PATH" "Diagnostics report contains token presence only, not token values"
require_text "$SUPPORT_PATH" "docs/SUPPORT_BUNDLE.md"
require_text "$BUG_TEMPLATE_PATH" "docs/SUPPORT_BUNDLE.md"
require_text "$README_PATH" "Copy Support Bundle"
require_text "$CORE_REPORT_PATH" "SupportBundleReport"
require_text "$CORE_REPORT_PATH" "Support Bundle"
require_text "$CORE_REPORT_PATH" "DiagnosticReport.make"
require_text "$CORE_REPORT_PATH" "Diagnostics report contains token presence only, not token values"
require_text "$APP_PATH" "copySupportBundle"
require_text "$APP_PATH" "Copy Support Bundle"
require_text "$TEST_PATH" "supportBundleReportIncludesSafeDiagnosticsAndTemplateSections"

echo "Support bundle verified."
