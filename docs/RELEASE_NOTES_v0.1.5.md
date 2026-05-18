# Sub2API Status Bar v0.1.5

This release makes the app feel more like a daily-use macOS utility: it can start with macOS, Settings is easier to scan, and users can copy support-safe diagnostics without exposing tokens.

## What's Improved

- Added Launch at Login from Settings.
- Added Copy Diagnostics with token redaction.
- Added Show Config to reveal the local `config.json`.
- Reorganized Settings into account, general, updates, login, and diagnostics sections.
- Kept user-only dashboard data, multi-account switching, local config token storage, automatic token refresh, and GitHub Releases update checking.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.5-macOS.zip.sha256
```
