# Sub2API Status Bar v0.1.1

This release tightens the app for real user distribution and adds a clear disconnect path for switching accounts or removing saved credentials.

## What's Improved

- Credential storage iteration, superseded by v0.1.4 local config storage.
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
