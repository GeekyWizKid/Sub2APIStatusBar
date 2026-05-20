# Release Evidence Productization Design

## Purpose

Sub2API Status Bar already has a credible v0.1.6 productization baseline: a native macOS menu bar app, local alerts, support-safe diagnostics, zip and DMG packaging, release manifests, Homebrew Cask draft generation, downloaded-asset verification, and a guarded notarization path.

The next maturity pass should make each candidate release auditable. A maintainer should be able to answer these questions from one generated artifact:

- Which version was built?
- Which trust path was used?
- Which zip, DMG, manifest, and cask assets were reviewed?
- Do the hashes in the evidence file match the files in `dist/`?
- Which local and downloaded-asset verification commands prove the candidate?
- Which workflow run, draft release, Gatekeeper result, and publish decision completed the human review?

This pass does not claim that productization is finished. It turns the existing release pipeline from "repeatable packaging" into "repeatable packaging with durable release evidence".

## Current State

The repository already has:

- `scripts/verify-release-candidate.sh` as the one-command release gate.
- Zip, DMG, checksum, manifest, cask draft, product preview, label, security, repository-settings, support-bundle, and downloaded-asset verification.
- Tag CI that creates a draft GitHub Release.
- A public-release guard that fails closed when `PUBLIC_RELEASE=true` and Apple signing credentials are unavailable.
- An uncommitted `scripts/verify-release-evidence.sh` that expects a release evidence Markdown file and verifies asset names, hashes, required commands, and manual review fields.

The gap is that no script generates the evidence file, the release gate does not verify it, CI does not upload it, the draft release does not include it, and release docs do not require maintainers to fill or review it.

## Mature Product Reference

Mature macOS distribution is built around evidence, not only archives:

- Apple notarization and Gatekeeper make trusted distribution an explicit review path.
- Sparkle-style update systems rely on signed metadata and predictable update artifacts.
- Homebrew Cask workflows depend on stable URLs, versions, and checksums.
- Mature menu bar utilities such as iStat Menus and Stats make maintenance boring by keeping releases predictable and supportable.

The lesson for this project is practical: every release candidate should produce a small, human-readable evidence file that connects automated verification with the human publish decision.

## Chosen Approach

Add a release evidence chain for v0.1.7.

### New Artifact

Generate:

```text
dist/Sub2APIStatusBar-<version>-macOS-release-evidence.md
```

The file should include:

- Title: `# Sub2API Status Bar Release Evidence`
- `Version: <VERSION>`
- `Trust posture: ad-hoc draft` or `Trust posture: notarized public candidate`
- Asset section listing zip, DMG, manifest, and Homebrew Cask draft file names and SHA-256 hashes.
- Verification command section including:
  - `VERSION=<VERSION> ./scripts/verify-release-candidate.sh`
  - `VERSION=<VERSION> ./scripts/verify-downloaded-release.sh <download-directory>`
  - `VERSION=<VERSION> ./scripts/verify-release-evidence.sh`
- Manual review section with placeholders:
  - `Workflow run URL: pending`
  - `Draft release URL: pending`
  - `Gatekeeper result: pending`
  - `Publish decision: pending`

The existing verifier should accept the generated placeholder state for local candidate builds, while the release checklist requires maintainers to replace `pending` values before publishing a public release.

### Scripts

Add `scripts/generate-release-evidence.sh`.

Responsibilities:

- Read `VERSION` from the environment or root `VERSION` file, matching existing release scripts.
- Require the zip, DMG, manifest, and cask draft to exist.
- Compute SHA-256 hashes from the actual files in `dist/`.
- Resolve the trust posture from `REQUIRE_NOTARIZATION` and the current build context, using the same semantics as `verify-release-candidate.sh`.
- Write the evidence Markdown file.

Promote the existing `scripts/verify-release-evidence.sh` into the maintained release pipeline.

Responsibilities:

- Verify that the evidence file exists.
- Verify that it references the correct version, asset names, and current SHA-256 hashes.
- Verify that the required local, downloaded-asset, and evidence verification commands are listed.
- Verify that manual review fields exist.

### Release Gate

Update `scripts/verify-release-candidate.sh` so the final release candidate gate includes:

1. Generate release evidence after zip, DMG, manifest, cask, and downloaded-asset verification have passed.
2. Verify release evidence.

The gate should fail if evidence is missing, stale, or mismatched.

### CI And Draft Release

Update `.github/workflows/build.yml` so:

- CI artifacts include `dist/*-release-evidence.md`.
- Tag draft releases upload `dist/*-release-evidence.md`.

This makes the evidence file part of the release payload reviewers download and inspect.

### Documentation And Operating Model

Update:

- `README.md`: mention release evidence in the release output list and post-draft review flow.
- `docs/RELEASE_CHECKLIST.md`: add evidence generation, verification, download, manual field completion, and publish-review requirements.
- `.github/ISSUE_TEMPLATE/release_checklist.md`: add checklist items for evidence file review.
- `docs/RELEASE_NOTES_v0.1.6.md`: include the evidence chain if this lands before v0.1.6 is published, or leave v0.1.6 as-is and create v0.1.7 release notes if the version line advances.
- `CHANGELOG.md`: record release evidence as release-process maturity work.
- `docs/PRODUCT_REVIEW.md`: add a new MAGI cycle.

Suggested MAGI cycle:

审视:

- Mature desktop releases preserve evidence for the assets users actually download.
- The project already verifies release archives, manifests, casks, and downloaded assets, but the proof is scattered across logs and checklists.

执行:

- Add generated release evidence for zip, DMG, manifest, and cask assets.
- Verify evidence against current artifact hashes.
- Upload evidence through CI artifacts and draft GitHub Releases.
- Require release checklist review before publishing.

提升:

- After a real tag draft exists, fill the evidence file with workflow, draft release, Gatekeeper, and publish-decision details before public release.

## Alternatives Considered

### Sparkle Updates First

Sparkle would improve the user update experience, but it depends on a settled trust path, signing metadata, and appcast policy. It should follow after Developer ID notarization and release evidence are reliable.

### UI Architecture Split First

`Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift` is large enough to deserve extraction, but release evidence moves the project more directly toward a publishable product. UI extraction remains important for future product work.

### Manual Checklist Only

The release checklist already exists, but a checklist without generated hashes and asset names is too easy to drift from the files being published. A generated evidence file keeps the checklist grounded in artifacts.

## Verification

Implementation is complete only when these pass:

```bash
VERSION=v0.1.6 ./scripts/generate-release-evidence.sh
VERSION=v0.1.6 ./scripts/verify-release-evidence.sh
VERSION=v0.1.6 ./scripts/verify-release-candidate.sh
```

The release candidate command is the broad gate; it must prove tests, build, package, manifest, cask, downloaded assets, and release evidence still work together.

## Scope Boundaries

This pass will not:

- Add Sparkle or signed update installation.
- Change Swift app behavior.
- Change token storage or privacy posture.
- Publish a release.
- Claim Gatekeeper acceptance without a real downloaded artifact and, for public releases, Developer ID notarization.

## Approval Gate

This design is ready for implementation planning when:

- It preserves the larger productization objective.
- It focuses this cycle on release evidence rather than unrelated feature expansion.
- It identifies concrete artifacts, scripts, CI changes, docs, and verification commands.
- It leaves Sparkle updates and UI architecture cleanup as explicit later stages.
