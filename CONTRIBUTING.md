# Contributing

Thanks for helping improve Sub2API Status Bar. This project is a native macOS menu bar utility, so changes should preserve a quiet, glanceable, privacy-conscious user experience.

## Development Setup

Requirements:

- macOS 13 or later.
- Swift 6.1 or later.
- A Sub2API server with user API endpoints enabled when manually testing live data.

Run local checks before opening a pull request:

```bash
swift test
swift build
```

For release-affecting changes, also run:

```bash
VERSION=v0.1.6 ./scripts/verify-release-candidate.sh
```

Use the version you are preparing, not necessarily `v0.1.6`.

For repository operations changes, also run:

```bash
./scripts/verify-github-labels.sh
./scripts/verify-security-reporting.sh
```

## Product Standards

- Keep the menu bar status glanceable.
- Keep the popover compact and configurable.
- Keep alerts actionable and local.
- Do not add telemetry.
- Do not require admin-only Sub2API endpoints for ordinary user monitoring.
- Keep diagnostics support-safe and token-redacted.

## Documentation

Update docs when behavior changes:

- `README.md` for user-facing setup or feature changes.
- `CHANGELOG.md` for release-visible changes.
- `docs/RELEASE_CHECKLIST.md` for release process or readiness changes.
- `docs/PRODUCT_REVIEW.md` for MAGI cycle notes when a change moves the product maturity bar.
- Release notes under `docs/RELEASE_NOTES_<tag>.md` for tagged releases.

## Issue Triage

The canonical label set lives in `.github/labels.yml`. Keep issue template labels and triage labels in sync with:

```bash
./scripts/verify-github-labels.sh
```

Use `needs-triage` for newly reviewed issues that need routing and `needs-info` when diagnostics or reproduction details are missing.

## Security And Privacy

Do not commit:

- Access tokens.
- Refresh tokens.
- Passwords.
- Local `config.json` files.
- Private Sub2API server logs.
- Generated release archives in `dist/`.

Security vulnerabilities should follow `SECURITY.md` instead of public issue discussion.

Issue template configuration must keep blank public issues disabled and preserve the private security contact link.

## Pull Request Checklist

Before requesting review:

- Run the relevant local checks.
- Include screenshots or short notes for visible UI changes.
- Explain whether the change affects release packaging, update checking, diagnostics, or credential storage.
- Confirm that diagnostics still avoid exposing secrets.
