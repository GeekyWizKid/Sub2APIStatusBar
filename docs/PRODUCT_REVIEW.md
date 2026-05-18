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
   - Stores login tokens in the local Application Support config file, including per-account tokens for account switching.
   - Added a settings-level disconnect action for account switching and credential removal.
   - Added Launch at Login, support-safe diagnostics copy, and local config reveal actions.

6. Documentation
   - Rewrote README as a product introduction and setup guide.
   - Added a product preview image for GitHub visitors.
   - Added a changelog and release checklist.

## Remaining Product Work

The only meaningful blockers for fully trusted macOS public distribution are Apple signing assets:

- Apple Developer ID certificate for trusted signing.
- Apple notarization credentials.

## Competitive Direction

### What the category teaches

1. OpenAI usage dashboards
   - Strong at filtering usage by project, user, service account, model, and API key.
   - Strong at TPM-oriented activity views and cost/token drilldowns.
   - Weak fit for a menu bar app if copied literally, because the full table/filter experience belongs in a browser.

2. LiteLLM proxy dashboards
   - Strong at virtual-key, user, team, and budget controls.
   - Strong at rate-limit surfaces such as RPM/TPM and spend caps.
   - Useful lesson: users care less about raw totals than whether a key/account is about to hit a limit.

3. Helicone-style observability
   - Strong at requests, cost, latency, token volume, errors, rate limits, caching, and alerting.
   - Useful lesson: surface anomalies and next actions early, especially when something crosses a threshold.

4. Langfuse-style observability
   - Strong at token/cost breakdowns by usage type and model.
   - Useful lesson: model mix and usage type matter when explaining why spend moved.

### Product choice

Sub2API Status Bar should not compete as a full analytics dashboard. The winning shape is a native, low-friction personal monitor that answers three questions faster than any browser tab:

- Am I healthy right now?
- What changed in usage or cost?
- Which limit, model, or balance should I watch next?

### First product-intelligence pass

- Added a local Usage Insights engine.
- Prioritizes quota pressure, balance runway, token trend changes, model spend concentration, and latency.
- Shows the top insights directly in the popover.
- Adds the same insight headline to support-safe diagnostics.
- Added Settings controls for insight thresholds so cautious and tolerant users can tune warnings without editing config JSON.

## MAGI Log

### 2026-04-28 Cycle A

1. 审视
   - Found a release-trust gap: access and refresh tokens were still persisted in `config.json`.
   - Found the original Swift PCH error can recur after renaming or moving the project because `.build` keeps old module-cache paths.

2. 执行
   - Added an initial credential-storage hardening pass that was later superseded by local JSON storage in Cycle I.
   - Added a build-cache cleanup script and README troubleshooting instructions.
   - Added focused tests for credential storage behavior.

3. 提升
   - Next quality bar: capture product screenshots/demo GIF, add notarization when Apple credentials exist, and keep polishing first-run account switching.

### 2026-04-28 Cycle B

1. 审视
   - Safer credential storage also makes explicit account management more important.

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
   - Saved renewed credentials back to local config storage and retried the dashboard refresh after renewal.
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

### 2026-05-18 Cycle I

1. 审视
   - The app should not rely on macOS Keychain for this release.
   - The latest upstream added multi-account switching, so token storage still needs to support account-specific credentials.

2. 执行
   - Removed the Keychain runtime dependency.
   - Stored auth and refresh tokens directly in `config.json`, including per-account tokens.
   - Added the MIT license.

3. 提升
   - The persistence model is now simple and inspectable: one local config file owns server URLs, account list, preferences, and credentials.

### 2026-05-18 Cycle J

1. 审视
   - A marketable menu bar utility should start with macOS and give users a support-safe way to explain failures.
   - Settings had grown into a mixed list of account, token, update, and login controls.

2. 执行
   - Added a Launch at Login setting using the macOS login item service.
   - Added Copy Diagnostics with token redaction and Show Config for local troubleshooting.
   - Reorganized Settings into account, general, updates, login, and diagnostics sections.
   - Added a clean product preview image to the README.

3. 提升
   - The next product pass should notarize once Apple Developer credentials are available.
