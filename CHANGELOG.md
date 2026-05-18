# Changelog

## Unreleased

- Added Usage Insights for quota pressure, balance runway, token trend changes, model cost concentration, and latency.
- Added local proactive alerts for important Usage Insights, with Settings controls for severity and cooldown.
- Added visible notification-permission status and diagnostics so blocked macOS alerts are easier to identify.
- Added configurable Usage Insight thresholds in Settings.
- Added guided recovery suggestions for onboarding and connection failures.
- Added Usage Insights to diagnostics so support reports explain the current top signal without exposing tokens.
- Documented the product direction against usage dashboards and LLM observability tools.

## v0.1.5

- Added Launch at Login control.
- Added support-safe diagnostics copy and local config reveal actions.
- Reworked Settings into clearer account, general, updates, login, and diagnostics sections.

## v0.1.4

- Removed macOS Keychain token storage.
- Saved auth and refresh tokens in the local Application Support config file.
- Simplified config loading so login state is managed from one local JSON file.

## v0.1.3

- Added GitHub Releases update checking.
- Added a silent launch-time update check and manual Settings > Updates check.
- Added an in-app update banner when a newer release is available.
- Added semantic version comparison and release payload tests.

## v0.1.2

- Added automatic access-token refresh on `401` responses when a refresh token is available.
- Retried the user dashboard refresh after successful token renewal.
- Added test coverage for unauthorized-response classification.

## v0.1.1

- Added a credential-storage iteration that was superseded by v0.1.4 local config storage.
- Added a settings action to disconnect and clear saved credentials.
- Added account identity display and model-usage progress bars.
- Removed remaining admin-mode client surface from the user-focused app.
- Removed the unfinished language picker until localization is implemented.
- Added Swift build-cache troubleshooting and cleanup script.
- Added release archive verification script for checksum, zip, plist, and signing checks.
- Added a notarization script for Developer ID signed releases.

## v0.1.0

- Added native macOS menu bar monitor for Sub2API user usage.
- Added first-run login, manual token setup, and local config storage.
- Added user dashboard cards for balance, API keys, requests, costs, tokens, performance, and latency.
- Added subscription quota cards with daily, weekly, and monthly limits.
- Added model distribution and seven-day token trend.
- Added optional menu bar text summary.
- Added generated app icon, app bundle build script, release zip packaging, checksum generation, and GitHub Actions build workflow.
