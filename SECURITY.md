# Security Policy

## Reporting A Vulnerability

Do not open a public GitHub Issue for security vulnerabilities.

Use GitHub private vulnerability reporting from the repository Security tab: <https://github.com/GeekyWizKid/Sub2APIStatusBar/security/policy>

Report privately to the project maintainer with:

- A short summary of the vulnerability.
- Affected app version or commit.
- macOS version.
- Reproduction steps or proof-of-concept details.
- Whether local config files, auth tokens, refresh tokens, release archives, or update checks are involved.

Do not include exploit details, secrets, server URLs, tokens, or private logs in public issues.

## Sensitive Data

Do not share:

- `config.json`
- Access tokens
- Refresh tokens
- Passwords
- Private Sub2API server logs
- Full local Application Support directories

Settings > Diagnostics > Copy Diagnostics is the preferred support artifact. It reports whether tokens are present without including token values.

## Current Security Posture

Sub2API Status Bar stores server URLs, account metadata, auth tokens, refresh tokens, display preferences, and refresh interval locally in Application Support. It does not use macOS Keychain in the current release line.

The app sends network requests only to:

- The configured Sub2API server.
- GitHub Releases when update checking is enabled by normal app behavior.

Release archives are zip files with SHA-256 checksums. Public trust for broad distribution still depends on Developer ID signing and Apple notarization credentials.

## Supported Versions

Security fixes target the latest release line. Older versions may be asked to update before receiving support unless a vulnerability affects the latest release too.
