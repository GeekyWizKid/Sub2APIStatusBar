# Release Checklist

## Completed

- [x] User-only dashboard flow using non-admin Sub2API endpoints
- [x] Admin mode removed from the public app/client surface
- [x] Balance decoding from `/auth/me`
- [x] Daily, weekly, and monthly subscription quota card
- [x] Clear status labels: `OK`, `High Usage`, `Near Limit`, `Disconnected`
- [x] App icon generation and `AppIcon.icns`
- [x] macOS `.app` bundle script
- [x] Release zip and SHA-256 checksum script
- [x] Release verification script that checks the zip from a clean temporary extraction
- [x] Ad-hoc signing for local builds
- [x] Notarization script ready for Apple credentials
- [x] GitHub Actions workflow for tests, builds, and packaged artifacts
- [x] Product-oriented README
- [x] Changelog
- [x] Unit tests for config, API decoding, quota progress, menu bar text, and status labels
- [x] Local JSON token storage with multi-account switching
- [x] Automatic token refresh and dashboard retry on expired access tokens
- [x] GitHub Releases update checking with launch-time and manual checks
- [x] Troubleshooting path for stale Swift build cache errors
- [x] Launch at Login setting
- [x] Support-safe diagnostics copy action with token redaction
- [x] Local config reveal action
- [x] Local alert thresholds for daily spend, daily tokens, and quota pressure
- [x] Alert-aware status labels, diagnostics, Settings controls, and popover summary
- [x] MAGI productization design, implementation plan, and v0.1.6 integration audit
- [x] Tag-based CI creates a draft GitHub Release with zip and checksum assets

## Productization Readiness Matrix

| Area | Current Status | Verification | Next Gate |
| --- | --- | --- | --- |
| App identity | Ready | `Resources/AppIcon.icns`, bundle metadata from `scripts/build-app.sh` | Keep screenshots current for each public release |
| User dashboard | Ready | `swift test` covers dashboard decoding, quota progress, status labels, menu bar summaries, and local alerts | Add anomaly or model-cost concentration insights after alert rules prove useful |
| Local configuration | Ready | `swift test` covers config persistence, legacy decoding, and multi-account token storage | Revisit Keychain only if the product promise changes |
| Menu bar maturity | Ready for v0.1.6 | Summary modes, section visibility, compact density, stale detection, and alert banners are covered by tests, build checks, and README copy | Verify compact layout manually before public release |
| Release archive | Ready | `VERSION=v0.1.6 ./scripts/package-release.sh` and `VERSION=v0.1.6 ./scripts/verify-release.sh` | Update the version for each tag |
| GitHub release delivery | Ready as draft | `v*` tag CI packages, verifies, uploads artifacts, and creates a draft GitHub Release | Publish the draft only after release notes and trust posture are reviewed |
| Public trust | Blocked by Apple credentials | Developer ID signing and notarization scripts exist | Provide `SIGN_IDENTITY`, `APPLE_ID`, `TEAM_ID`, and `APP_SPECIFIC_PASSWORD` |
| Update delivery | Partial | GitHub Releases latest-version detection exists | Evaluate Sparkle-style signed update installation after notarization |
| Distribution channels | Planned | GitHub Release zip and checksum are produced by CI | Consider Homebrew Cask after a notarized public release exists |
| Support | Ready for v0.1.6 | Copy Diagnostics, Show Config, token-redacted diagnostics, and integration audit exist | Add issue templates or support bundle structure in a later MAGI pass |

## Release Commands

```bash
swift test
swift build
VERSION=v0.1.6 ./scripts/package-release.sh
VERSION=v0.1.6 ./scripts/verify-release.sh
```

For the v0.1.6 productization pass:

```bash
swift test
swift build
VERSION=v0.1.6 ./scripts/package-release.sh
VERSION=v0.1.6 ./scripts/verify-release.sh
```

When a `v*` tag is pushed, GitHub Actions runs the same checks and creates a draft GitHub Release using `docs/RELEASE_NOTES_<tag>.md`, for example `docs/RELEASE_NOTES_v0.1.6.md`. Draft releases are intentional until the package is reviewed and, when available, Developer ID signing and notarization are complete.

Developer ID signing:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.6 \
./scripts/package-release.sh
```

Notarization requires Apple Developer account credentials and is intentionally not automated until those secrets are available in GitHub Actions or the local keychain.

```bash
APPLE_ID="you@example.com" \
TEAM_ID="TEAMID" \
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.6 \
./scripts/notarize-release.sh
```
