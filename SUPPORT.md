# Support

Use GitHub Issues for bugs, product feedback, and release questions.

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
