# Sub2API Status Bar v0.1.3

This release adds an update detection path. The app checks GitHub Releases in the background on launch, lets users check manually from Settings, and shows an in-app banner when a newer version is available.

## What's Improved

- GitHub Releases update checking.
- Silent launch-time update detection.
- Manual Settings > Updates check.
- In-app update banner with a link to the latest release.
- Semantic version comparison for tags like `v0.1.3`.
- Existing v0.1.2 reliability work: automatic token renewal, Keychain storage, disconnect action, user-only client surface, release verification, and notarization scripts.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.3-macOS.zip.sha256
```
