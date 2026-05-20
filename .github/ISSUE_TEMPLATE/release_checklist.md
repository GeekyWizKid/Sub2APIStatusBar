---
name: Release checklist
about: Track a tagged Sub2API Status Bar release from candidate build to published assets
title: "[Release]: v"
labels: release
assignees: ""
---

## Release Target

- Version:
- Tag:
- Release notes file:
- Target release type: ad-hoc draft / notarized public release

## Preflight

- [ ] `VERSION` matches the intended tag.
- [ ] `CHANGELOG.md` includes the release-visible changes.
- [ ] `docs/RELEASE_NOTES_<tag>.md` exists and matches the asset set.
- [ ] Public trust posture is decided before tag creation.
- [ ] Apple signing secrets are configured when publishing a trusted public release.

## Local Verification

- [ ] `VERSION=<tag> ./scripts/verify-release-candidate.sh`
- [ ] For trusted public release: `REQUIRE_NOTARIZATION=true VERSION=<tag> ./scripts/verify-release-candidate.sh`
- [ ] Zip checksum verifies from `dist/`.
- [ ] DMG checksum verifies from `dist/`.
- [ ] Release manifest verifies from `dist/`.

## Tag CI

- [ ] Push `v*` tag.
- [ ] GitHub Actions package job passes.
- [ ] Draft GitHub Release is created.
- [ ] Draft assets include zip, DMG, manifest, and both `.sha256` files.
- [ ] Draft assets include the generated Homebrew Cask draft.
- [ ] If Apple secrets are complete, CI logs show the notarized release gate.
- [ ] If Apple secrets are incomplete, draft release is kept unpublished or clearly treated as ad-hoc.

## Draft Asset Review

- [ ] Download zip, DMG, manifest, and checksum files from the draft release.
- [ ] Download the generated Homebrew Cask draft from the draft release.
- [ ] `VERSION=<tag> ./scripts/verify-downloaded-release.sh <download-directory>`
- [ ] For trusted public release, confirm Gatekeeper accepts the downloaded app.

## Publish Decision

- [ ] Release notes are final.
- [ ] Support and security links are correct.
- [ ] README install guidance matches the published assets.
- [ ] The draft release is published only after the trust posture above is true.

## Notes

Record links to the workflow run, draft release, and any manual verification notes.
