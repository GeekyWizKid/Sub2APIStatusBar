# Product Review

## Release Readiness Work

1. App identity
   - Added a custom app icon and bundle metadata.
   - Added release version wiring through build scripts.

2. Build and distribution
   - Added reproducible `.app` generation.
   - Added zip packaging and SHA-256 checksum output.
   - Added archive verification from a clean temporary extraction so macOS workspace metadata does not produce false signature failures.
   - Added ad-hoc signing by default and Developer ID signing hooks.
   - Added a notarization script that submits, staples, rezips, and rewrites the checksum when Apple credentials are available.
   - Added GitHub Releases update detection with an in-app update banner and manual Settings check.

3. GitHub delivery
   - Added CI for tests, debug build, packaged release artifact, and checksum.
   - Kept generated build outputs out of git.

4. User experience
   - Kept the app user-account focused.
   - Removed remaining admin mode and admin endpoint methods from the app/client surface.
   - Improved metric cards with icons and color grouping.
   - Reworked subscription quotas into daily, weekly, and monthly rows.
   - Clarified warning labels so quota pressure is not shown as a generic app error.
   - Added an account identity card and model-usage progress bars.
   - Removed the unfinished language picker from Settings until localization is actually wired.

5. Reliability
   - Added tests for user dashboard payloads, balance decoding, quota progress, and status labels.
   - Preserved local config compatibility and user-only mode migration.
   - Moved login tokens into macOS Keychain and migrates older JSON-stored tokens on load.
   - Added a settings-level disconnect action for account switching and credential removal.

6. Documentation
   - Rewrote README as a product introduction and setup guide.
   - Added a changelog and release checklist.

## Remaining Product Work

The only meaningful blockers for public distribution are external materials and launch assets:

- Apple Developer ID certificate for trusted signing.
- Apple notarization credentials.
- Product screenshots or a demo GIF captured from the final running app.
- A decision on whether the GitHub repository should stay private or become public.

## MAGI Log

### 2026-04-28 Cycle A

1. 审视
   - Found a release-trust gap: access and refresh tokens were still persisted in `config.json`.
   - Found the original Swift PCH error can recur after renaming or moving the project because `.build` keeps old module-cache paths.

2. 执行
   - Added Keychain token storage with automatic migration from legacy JSON tokens.
   - Added a build-cache cleanup script and README troubleshooting instructions.
   - Added focused tests for token scrubbing and legacy migration.

3. 提升
   - Next quality bar: capture product screenshots/demo GIF, add notarization when Apple credentials exist, and keep polishing first-run account switching.

### 2026-04-28 Cycle B

1. 审视
   - Keychain storage improves privacy, but also makes explicit account management more important.

2. 执行
   - Added `Disconnect` in Settings to clear saved credentials and return to the login panel.
   - Added a core helper and test for clearing auth tokens.

3. 提升
   - The next UX pass should make the empty/login state feel more productized and capture screenshots for the README.

### 2026-04-28 Cycle C

1. 审视
   - Settings exposed a Language option before the app actually applied localization.
   - The dashboard had useful numbers, but the current account and model-share hierarchy were too easy to miss.

2. 执行
   - Removed the unfinished Language setting from the visible UI.
   - Added a current-account card and progress bars inside model distribution.

3. 提升
   - Once localization is implemented, reintroduce language as a working preference rather than a placeholder.

### 2026-04-28 Cycle D

1. 审视
   - Public macOS distribution still needs Apple notarization, but the repo only documented it as a manual blocker.

2. 执行
   - Added `scripts/notarize-release.sh` to package with Developer ID signing, submit to Apple, staple the app, rebuild the zip, and refresh the checksum.
   - Documented the notarization command and required environment variables.

3. 提升
   - When Apple credentials are available, wire the same script into GitHub Actions using encrypted secrets.

### 2026-04-28 Cycle E

1. 审视
   - Strict local signature verification failed inside the `Documents` workspace because macOS file-provider metadata was attached to the `.app` after packaging.
   - The release zip itself did not contain that metadata and verified after extraction to `/tmp`.

2. 执行
   - Added `scripts/verify-release.sh` to validate checksum, zip integrity, Info.plist, and code signature from a clean temporary extraction.
   - Updated release docs to use the verification script.

3. 提升
   - Keep release validation focused on the distributable archive, not the workspace copy of the app bundle.

### 2026-04-28 Cycle F

1. 审视
   - The visible UI was user-only, but the core client still exposed admin mode and admin endpoints.

2. 执行
   - Removed admin mode from `MonitorMode`.
   - Removed admin endpoint methods from `Sub2APIClient`.
   - Kept legacy config decoding safe by mapping old `monitorMode: "admin"` values back to user mode.

3. 提升
   - The app now matches the intended release promise: ordinary users can see usage without needing an admin account.

### 2026-04-28 Cycle G

1. 审视
   - Refresh tokens were stored but not used, so an expired access token could still force the user back into manual login.

2. 执行
   - Added automatic token refresh on `401` responses.
   - Saved renewed credentials back to Keychain and retried the dashboard refresh after renewal.
   - Added test coverage for unauthorized-response classification.

3. 提升
   - The status bar can now run longer as a quiet monitor instead of becoming another thing the user has to babysit.

### 2026-04-29 Cycle H

1. 审视
   - Distribution still lacked a user-visible way to know a newer build exists.

2. 执行
   - Added semantic version comparison and GitHub latest-release decoding.
   - Added silent launch-time update detection, Settings > Updates manual checking, and an in-app update banner.
   - Documented that GitHub only exposes published releases through the public latest-release API.

3. 提升
   - Once the app is notarized and the release is published, older builds can guide users to the newest download without requiring them to watch GitHub manually.
