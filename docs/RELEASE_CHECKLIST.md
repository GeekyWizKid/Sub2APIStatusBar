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
- [x] Release DMG and SHA-256 checksum script with `/Applications` shortcut
- [x] Release verification script that checks the zip from a clean temporary extraction
- [x] DMG verification script that checks checksum, mountability, bundle plist, app alias, and code signature
- [x] Release manifest generation and verification for zip/DMG asset names, sizes, and SHA-256 digests
- [x] Homebrew Cask draft generation and verification from the release manifest
- [x] One-command release candidate verification for tests, build, zip, DMG, and manifest
- [x] Downloaded release asset verification for draft zip, DMG, checksums, manifest, and cask files
- [x] Public release mode that fails tag builds unless Apple notarization credentials are complete
- [x] GitHub release checklist issue template for tag, draft asset, checksum, manifest, DMG, and trust review
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
- [x] Tag-based CI creates a draft GitHub Release with zip, DMG, checksum, and manifest assets

## Productization Readiness Matrix

| Area | Current Status | Verification | Next Gate |
| --- | --- | --- | --- |
| App identity | Ready | `Resources/AppIcon.icns`, bundle metadata from `scripts/build-app.sh` | Keep screenshots current for each public release |
| User dashboard | Ready | `swift test` covers dashboard decoding, quota progress, status labels, menu bar summaries, and local alerts | Add anomaly or model-cost concentration insights after alert rules prove useful |
| Local configuration | Ready | `swift test` covers config persistence, legacy decoding, and multi-account token storage | Revisit Keychain only if the product promise changes |
| Menu bar maturity | Ready for v0.1.6 | Summary modes, section visibility, compact density, stale detection, and alert banners are covered by tests, build checks, and README copy | Verify compact layout manually before public release |
| Release archive | Ready | `VERSION=v0.1.6 ./scripts/verify-release-candidate.sh` runs tests, build, zip, DMG, manifest, Homebrew Cask, and downloaded-asset checks | Update the version for each tag |
| GitHub release delivery | Ready as draft | `v*` tag CI packages, verifies, uploads artifacts, creates a draft GitHub Release, and uses `REQUIRE_NOTARIZATION=auto` to choose the trust path | Publish the draft only after release notes and trust posture are reviewed |
| Public trust | Blocked by Apple credentials | `PUBLIC_RELEASE=true REQUIRE_NOTARIZATION=auto VERSION=v0.1.6 ./scripts/verify-release-candidate.sh` fails unless Developer ID and Apple credentials are present | Provide `SIGN_IDENTITY`, `APPLE_ID`, `TEAM_ID`, and `APP_SPECIFIC_PASSWORD` |
| Update delivery | Partial | GitHub Releases latest-version detection exists | Evaluate Sparkle-style signed update installation after notarization |
| Distribution channels | Prepared | Homebrew Cask draft is generated from the release manifest and uploaded as a CI/release asset | Submit or publish a cask only after a notarized public release exists |
| Support | Ready for v0.1.6 | Copy Diagnostics, Show Config, token-redacted diagnostics, and integration audit exist | Add issue templates or support bundle structure in a later MAGI pass |

## Release Commands

The repository `VERSION` file is the default release version used by local scripts and non-tag CI builds. Override `VERSION=...` only when preparing or validating a specific tag.

```bash
VERSION=v0.1.6 ./scripts/verify-release-candidate.sh
```

For the v0.1.6 productization pass:

```bash
VERSION=v0.1.6 ./scripts/verify-release-candidate.sh
```

When a `v*` tag is pushed, GitHub Actions runs the same checks and creates a draft GitHub Release using `docs/RELEASE_NOTES_<tag>.md`, for example `docs/RELEASE_NOTES_v0.1.6.md`. If `APPLE_ID`, `TEAM_ID`, `APP_SPECIFIC_PASSWORD`, and `SIGN_IDENTITY` secrets are all configured, tag builds run the notarized release gate. Draft releases are intentional until the package is reviewed and, when available, Developer ID signing and notarization are complete.

Set repository variable `PUBLIC_RELEASE=true` only when tag builds are allowed to create publishable public release candidates. In that mode, tag builds fail unless all Apple signing and notarization secrets are present.

Use the GitHub release checklist issue template before publishing a draft release. It tracks the tag run, trust posture, downloaded assets, checksum verification, manifest review, DMG mount test, and final publish decision.

After the draft release exists, download all release assets into a clean directory and run:

```bash
VERSION=v0.1.6 ./scripts/verify-downloaded-release.sh /path/to/downloaded-assets
```

Developer ID signing:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.6 \
./scripts/package-release.sh
```

Notarization requires Apple Developer account credentials. When they are available locally or in CI secrets, require the trusted release gate:

```bash
APPLE_ID="you@example.com" \
TEAM_ID="TEAMID" \
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
REQUIRE_NOTARIZATION=true \
VERSION=v0.1.6 \
./scripts/verify-release-candidate.sh
```

CI and local automation can also select the trust path automatically:

```bash
PUBLIC_RELEASE=true \
GITHUB_REF_TYPE=tag \
REQUIRE_NOTARIZATION=auto \
VERSION=v0.1.6 \
./scripts/verify-release-candidate.sh
```
