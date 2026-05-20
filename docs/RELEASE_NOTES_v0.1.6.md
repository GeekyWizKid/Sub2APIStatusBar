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
- One-command release candidate verification for tests, build, zip, DMG, and manifest checks.
- Optional notarized release candidate path that rebuilds trusted zip, DMG, and manifest assets after stapling.
- Tag CI automatically uses the notarized release gate when all Apple signing secrets are configured.
- Release checklist issue template for tag CI, draft assets, checksums, manifest review, DMG testing, and publish decision.
- Homebrew Cask draft generation and verification from the release manifest.
- Downloaded release asset verification for draft zip, DMG, checksum, manifest, and cask files.
- Public release mode that fails tag builds unless Apple signing and notarization secrets are complete.
- Product preview asset verification for README image dimensions and current feature coverage.
- GitHub label configuration and verification for public issue triage.
- Private security reporting route through GitHub Security policy and issue contact links.
- Repository settings contract for branch protection, required checks, issue settings, and private vulnerability reporting.
- Support bundle template and verification gate for support-safe diagnostics follow-up.
- In-app Copy Support Bundle action that pre-fills the support packet with token-redacted diagnostics.

## Verification

- `swift test`
- `swift build`
- `VERSION=v0.1.6 ./scripts/package-release.sh`
- `VERSION=v0.1.6 ./scripts/verify-release.sh`
- `VERSION=v0.1.6 ./scripts/package-dmg.sh`
- `VERSION=v0.1.6 ./scripts/verify-dmg.sh`
- `VERSION=v0.1.6 ./scripts/generate-release-manifest.sh`
- `VERSION=v0.1.6 ./scripts/verify-release-manifest.sh`
- `VERSION=v0.1.6 ./scripts/verify-release-candidate.sh`
- `./scripts/verify-product-preview.sh`
- `./scripts/verify-github-labels.sh`
- `./scripts/verify-security-reporting.sh`
- `./scripts/verify-repository-settings.sh`
- `./scripts/verify-support-bundle.sh`
- `VERSION=v0.1.6 ./scripts/verify-downloaded-release.sh <download-directory>`
- `PUBLIC_RELEASE=true GITHUB_REF_TYPE=tag REQUIRE_NOTARIZATION=auto VERSION=v0.1.6 ./scripts/verify-release-candidate.sh` when validating the public-release trust gate
- `REQUIRE_NOTARIZATION=true VERSION=v0.1.6 ./scripts/verify-release-candidate.sh` when Apple signing credentials are available
- `VERSION=v0.1.6 ./scripts/generate-homebrew-cask.sh`
- `VERSION=v0.1.6 ./scripts/verify-homebrew-cask.sh`

All commands passed during the v0.1.6 productization verification pass.
