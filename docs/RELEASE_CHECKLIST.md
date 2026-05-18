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
- [x] GitHub Actions preview-asset verification
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
- [x] Notification permission purpose string included in the app bundle and checked by release verification

## Before Public Distribution

- [x] Choose a public version tag, for example `v0.1.6`
- [ ] Build with a Developer ID Application certificate
- [ ] Notarize the app with Apple
- [x] Attach the release zip and checksum to a GitHub Release
- [x] Add product screenshots or a short demo GIF to the README
- [x] Reproducible product preview capture script
- [x] Decide whether the repository should stay private or become public

## Release Commands

```bash
swift test
swift build
./scripts/capture-product-preview.swift
VERSION=v0.1.6 ./scripts/package-release.sh
VERSION=v0.1.6 ./scripts/verify-release.sh
```

`verify-release.sh` checks checksum integrity, zip structure, `Info.plist`, notification-purpose metadata, and code signature validity from a clean temporary extraction.

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
