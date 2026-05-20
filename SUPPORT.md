# Support

Use GitHub Issues for bugs, product feedback, and release questions.

For security vulnerabilities, do not open a public issue. Follow [SECURITY.md](SECURITY.md).

## Issue Routing

New public issues should be labeled from `.github/labels.yml`:

- `bug` for broken behavior.
- `enhancement` for product improvements.
- `release` for packaging, notarization, Homebrew Cask, or publish checks.
- `support` for diagnostics and reproduction follow-up.
- `installation` for app bundle, DMG, Gatekeeper, or install problems.
- `updates` for GitHub Releases update checking or future signed update delivery.
- `privacy` for token handling, local config storage, or data exposure.
- `security` only for security-sensitive coordination that is safe to track publicly.
- `needs-triage` and `needs-info` for routing state.

## Before Opening An Issue

1. Update to the newest GitHub Release when possible.
2. Open Settings > Diagnostics > Copy Diagnostics.
3. Paste the diagnostics report into the issue.
4. Do not paste `config.json`, access tokens, refresh tokens, passwords, or private server logs.

The diagnostics report is designed to be support-safe: it reports whether tokens are present, but it does not include token values.

## Useful Details

For connection or data issues, include:

- App version.
- macOS version.
- Sub2API server version or commit, if known.
- Whether login, manual token setup, or refresh worked before.
- A short description of the expected behavior and actual behavior.

For release or installation issues, include:

- Whether the build came from GitHub Releases or local source.
- Whether the app was ad-hoc signed, Developer ID signed, or notarized.
- The exact release archive name and checksum file used.

## Privacy Boundary

Sub2API Status Bar stores preferences and tokens locally. It does not send telemetry. Support requests should preserve that boundary by sharing diagnostics summaries instead of raw secrets or full local config files.
