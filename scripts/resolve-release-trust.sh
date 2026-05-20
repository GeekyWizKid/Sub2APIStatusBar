#!/usr/bin/env bash
set -euo pipefail

GITHUB_REF_TYPE="${GITHUB_REF_TYPE:-}"
PUBLIC_RELEASE="${PUBLIC_RELEASE:-false}"

is_truthy() {
  case "$1" in
    true|1|yes)
      return 0
      ;;
    false|0|no|"")
      return 1
      ;;
    *)
      echo "PUBLIC_RELEASE must be true or false." >&2
      exit 1
      ;;
  esac
}

all_apple_credentials_present() {
  [[ -n "${APPLE_ID:-}" ]] &&
    [[ -n "${TEAM_ID:-}" ]] &&
    [[ -n "${APP_SPECIFIC_PASSWORD:-}" ]] &&
    [[ -n "${SIGN_IDENTITY:-}" ]]
}

if [[ "$GITHUB_REF_TYPE" != "tag" ]]; then
  echo "false"
  exit 0
fi

if all_apple_credentials_present; then
  echo "true"
  exit 0
fi

if is_truthy "$PUBLIC_RELEASE"; then
  echo "PUBLIC_RELEASE=true requires APPLE_ID, TEAM_ID, APP_SPECIFIC_PASSWORD, and SIGN_IDENTITY." >&2
  exit 1
fi

echo "Apple notarization secrets are incomplete; creating ad-hoc signed draft assets." >&2
echo "false"
