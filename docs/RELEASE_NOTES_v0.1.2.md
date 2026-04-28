# Sub2API Status Bar v0.1.2

This release adds automatic token renewal on top of the v0.1.1 hardening work. If the access token expires and a refresh token is available, the app renews credentials, saves them back to Keychain, and retries the user dashboard refresh.

## What's Improved

- Automatic access-token refresh after `401` responses.
- Dashboard retry after successful token renewal.
- Keychain-backed auth and refresh token storage.
- Automatic migration and scrubbing for older local config files.
- Disconnect action in Settings.
- Account identity card in the dashboard.
- Model distribution progress bars.
- User-only client surface with remaining admin endpoint methods removed.
- Cleaner Settings UI with unfinished localization controls hidden.
- Release archive verification script for checksum, zip, plist, and code-signing checks.
- Developer ID notarization script for Apple distribution.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.2-macOS.zip.sha256
```
