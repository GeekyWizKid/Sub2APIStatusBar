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

### 2026-05-20 Cycle K

1. 审视
   - The app had enough data, but the menu bar surface was still too fixed compared with mature menu bar products.
   - Refresh failures were visible only as connection breaks; stale but still-connected data did not feel clearly different from healthy data.

2. 执行
   - Added selectable menu bar summary modes for spend-focused, token-throughput, and quota-focused monitoring.
   - Added stale-data detection that promotes long-delayed snapshots to `Needs Refresh`.
   - Added richer status detail text in the popover tooltip, status card, and diagnostics output.

3. 提升
   - The next maturity pass should let users choose which dashboard sections stay visible, so the popover becomes as compressible as mature menu bar utilities.

### 2026-05-20 Cycle L

1. 审视
   - The popover already exposed strong usage data, but it still forced every section onto every user.
   - Mature menu bar apps usually let people hide secondary sections so the interface stays compact and personal.

2. 执行
   - Added persisted panel-layout preferences to the app config.
   - Added a new Settings > Layout section with per-block toggles for account overview, usage metrics, subscriptions, model distribution, and token trend.
   - Wired the main popover to respect those choices so users can compress the monitor to the parts they care about.

3. 提升
   - The next maturity pass should add section density controls or compact cards, so advanced users can reduce both count and visual weight of visible blocks.

### 2026-05-20 Cycle M

1. 审视
   - Compared the app against mature macOS menu bar utilities and LLM observability products.
   - Confirmed the next product jump should preserve menu bar calmness while making usage pressure actionable.

2. 执行
   - Added a committed MAGI productization design spec.
   - Promoted release readiness into a matrix that separates ready, in-progress, credential-blocked, and planned work.
   - Chose local budget and quota alerts as the next feature slice.

3. 提升
   - Implement local alert rules for daily spend, daily tokens, and highest quota usage, then surface them in status, diagnostics, and Settings.

### 2026-05-20 Cycle N

1. 审视
   - Usage data became more actionable once the menu bar and popover could show local alert pressure.
   - The alert rules stayed local, which matches the app's privacy and no-telemetry posture.

2. 执行
   - Added persisted alert thresholds for daily spend, daily tokens, and highest quota usage.
   - Surfaced active alerts in status labels, detail text, diagnostics, Settings, and the popover.
   - Verified the feature with Swift tests, build checks, and release package validation.

3. 提升
   - The next maturity pass should evaluate signed update installation and distribution channels after Apple Developer ID notarization is available.

### 2026-05-20 Cycle O

1. 审视
   - Mature open-source products make support paths explicit so users can report issues without exposing secrets.
   - The app already had support-safe diagnostics, but the repository did not yet guide users into a safe issue shape.

2. 执行
   - Added `SUPPORT.md` with the diagnostics checklist, useful environment details, release-installation details, and privacy boundary.
   - Added GitHub issue templates for bug reports and product feature requests.
   - Linked README support guidance to diagnostics and the support checklist.

3. 提升
   - The next support pass should add labels or triage automation once the public repository workflow is active.

### 2026-05-20 Cycle P

1. 审视
   - Mature desktop projects turn verified tag builds into release assets instead of leaving maintainers to upload archives by hand.
   - The project already built and uploaded CI artifacts, but tag builds did not yet create a GitHub Release record.

2. 执行
   - Added tag-based draft GitHub Release creation after tests, build, package, and archive verification pass.
   - Uploaded the release zip and checksum to the draft release while preserving normal artifact upload for all CI runs.
   - Documented that draft release status is intentional until release notes and trust posture are reviewed.

3. 提升
   - Once Developer ID credentials are available, wire signing and notarization into the tag release path before publishing final releases.

### 2026-05-20 Cycle Q

1. 审视
   - Mature public repositories separate ordinary support from vulnerability disclosure.
   - The app handles local credentials, so public issues should steer users away from sharing secrets or exploit details.

2. 执行
   - Added `SECURITY.md` with private vulnerability reporting guidance, sensitive-data boundaries, current security posture, and supported-version policy.
   - Linked support and README guidance to the security policy.

3. 提升
   - Once the repository is public, publish a real private security contact or GitHub private vulnerability reporting configuration.

### 2026-05-20 Cycle R

1. 审视
   - Mature public projects make contribution expectations explicit so future changes do not erode product quality.
   - The repository had support and security paths, but no contributor guide or pull request checklist.

2. 执行
   - Added `CONTRIBUTING.md` with local setup, verification commands, product standards, documentation expectations, and privacy rules.
   - Added a pull request template covering product area, verification, documentation, MAGI notes, diagnostics redaction, and secret hygiene.
   - Linked README development guidance to the contributor guide.

3. 提升
   - After the first external contributions, refine PR checks based on the failure modes reviewers actually see.
