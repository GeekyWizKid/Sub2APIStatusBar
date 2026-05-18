# Sub2API Status Bar v0.1.4

This release removes macOS Keychain token storage. Auth and refresh tokens are saved in the local Application Support config file with the rest of the app preferences.

## What's Improved

- Removed Keychain token storage and all Keychain runtime dependencies.
- Restored single-file local config storage for server URL, tokens, display preferences, and refresh interval.
- Kept Settings > Disconnect for clearing saved credentials from the local config.
- Kept update checking, automatic token refresh, user-only dashboard data, release verification, and notarization scripts.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.4-macOS.zip.sha256
```
