# Changelog

## v0.1.6

- Added MAGI productization design, implementation plan, and integration audit documentation.
- Added a release-readiness matrix for product maturity, public trust, update delivery, distribution channels, and support.
- Added local alert thresholds for daily spend, daily tokens, and subscription quota pressure.
- Surfaced active alerts in status labels, detail text, diagnostics, Settings controls, and the popover.
- Added compact panel density, dashboard section visibility, stale-data status detail, and menu bar summary modes.
- Added contributor guidance and a pull request checklist for public collaboration.
- Aligned default build, package, CI, and documentation examples with the v0.1.6 release line.
- Added a repository `VERSION` file as the default release version source for scripts and non-tag CI builds.
- Added repeatable DMG packaging and verification for macOS-style installation assets.
- Added a release manifest with zip/DMG file names, SHA-256 digests, and file sizes.
- Added a one-command release candidate verification script.
- Extended the release candidate gate to require the notarized zip, DMG, and manifest path when Apple credentials are provided.
- Wired tag CI to use the notarized release gate when Apple signing secrets are configured.
- Added a GitHub release checklist issue template for draft asset and trust review.
- Added Homebrew Cask draft generation and verification from the release manifest.
- Added downloaded release asset verification for draft zip, DMG, checksum, manifest, and cask files.
- Added public release mode to fail tag builds unless Apple signing and notarization secrets are complete.
- Added product preview asset verification and refreshed the README preview for alerts, Settings, and diagnostics.
- Added GitHub label configuration and verification for public issue triage.
- Verified the release with `swift test`, `swift build`, `VERSION=v0.1.6 ./scripts/package-release.sh`, and `VERSION=v0.1.6 ./scripts/verify-release.sh`.

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
