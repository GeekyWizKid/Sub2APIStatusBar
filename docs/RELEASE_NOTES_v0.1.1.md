# Sub2API Status Bar v0.1.1

This release tightens the app for real user distribution. Login tokens now live in the macOS Keychain, older JSON-stored tokens migrate automatically, and Settings includes a clear disconnect path for switching accounts or removing saved credentials.

## What's Improved

- Keychain-backed auth and refresh token storage.
- Automatic migration and scrubbing for older local config files.
- Disconnect action in Settings.
- Account identity card in the dashboard.
- Model distribution progress bars.
- User-only client surface with remaining admin endpoint methods removed.
- Cleaner Settings UI with unfinished localization controls hidden.
- Swift build-cache cleanup script for moved or renamed project folders.
- Release archive verification script for checksum, zip, plist, and code-signing checks.
- Developer ID notarization script for Apple distribution.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.1-macOS.zip.sha256
```
