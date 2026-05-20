# Release Notes v0.1.6

This release continues the MAGI productization pass. It makes usage pressure more actionable while keeping the menu bar experience compact and quiet.

## Added

- Local warning thresholds for daily spend, daily tokens, and highest subscription quota usage.
- Alert-aware status text, diagnostics, and menu bar detail.
- Productization roadmap documentation and release-readiness matrix.
- Contributor guidance, issue flow, security policy, and pull request checklist for public collaboration.
- Repository-level release version source for local scripts and non-tag CI builds.
- DMG packaging and verification scripts for a macOS-style install artifact.
- Release manifest generation and verification for asset names, checksums, and sizes.

## Verification

- `swift test`
- `swift build`
- `VERSION=v0.1.6 ./scripts/package-release.sh`
- `VERSION=v0.1.6 ./scripts/verify-release.sh`
- `VERSION=v0.1.6 ./scripts/package-dmg.sh`
- `VERSION=v0.1.6 ./scripts/verify-dmg.sh`
- `VERSION=v0.1.6 ./scripts/generate-release-manifest.sh`
- `VERSION=v0.1.6 ./scripts/verify-release-manifest.sh`

All commands passed during the v0.1.6 productization verification pass.
