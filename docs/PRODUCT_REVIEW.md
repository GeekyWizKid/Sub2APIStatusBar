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
   - Added local proactive alerts for high-priority Usage Insights, with deterministic cooldown behavior to avoid noisy repeated notifications.

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

### 2026-05-18 Cycle K

1. 审视
   - The status bar target had grown into one 1,679-line Swift file mixing lifecycle, refresh state, login, settings, dashboard cards, quota UI, charts, and shared components.
   - That shape slows down product iteration because every UI change requires navigating unrelated app, networking, and settings code.

2. 执行
   - Split the app into focused files for app lifecycle, monitor state, main panel, login views, settings views, dashboard components, quota views, chart views, and shared view primitives.
   - Kept the split mechanical and behavior-preserving, with Swift build verification after each major move.

3. 提升
   - The codebase is now friendlier to deeper product work: future passes can improve settings, charts, alerts, and onboarding without crowding a single file.

### 2026-05-18 Cycle L

1. 审视
   - First-run and failure states still behaved like a demo: users saw a form or raw error text, but not a clear next action.
   - Mature monitoring tools should recover gracefully from bad URLs, expired sessions, token replacement, and unreachable servers.

2. 执行
   - Added a core `RecoverySuggestion` model that maps common connection and authentication failures to short explanations and actions.
   - Added guided recovery cards to the login panel and disconnected dashboard state.
   - Kept the guidance local and deterministic so diagnostics and UI can share the same recovery language later.

3. 提升
   - The app now helps users recover without reading logs or guessing whether they should retry, replace a token, open the server, or sign in again.

### 2026-05-18 Cycle M

1. 审视
   - Competitive products such as Helicone make alerting part of the monitoring loop, while LiteLLM-style budgets and OpenAI-style dashboards make it clear users need protection before they run out of quota or balance.
   - Sub2API Status Bar already explained risk inside the popover, but still required the user to look at it.

2. 执行
   - Added a core `InsightAlertPolicy` that picks the highest-priority warning/error Usage Insight and suppresses repeats during a configurable quiet period.
   - Added local macOS notifications for actionable insights, with Settings controls for enabling alerts, choosing warning versus error-only mode, and tuning the cooldown.
   - Added diagnostics output for alert state so support reports include whether proactive protection is enabled.
   - Added visible notification-permission status in Settings, including a direct path to macOS notification settings when alerts are blocked.

3. 提升
   - The product now acts more like a personal usage guardrail than a passive dashboard: users can keep working and let the menu bar call attention only when something important changes.

### 2026-05-18 Cycle N

1. 审视
   - Quota insight was directionally useful but too generic: "Daily quota" did not say which subscription was under pressure or when the limit resets.

2. 执行
   - Upgraded quota insights to preserve the subscription name, quota window, percentage, and reset timing when available.
   - Added regression coverage so future changes keep the more actionable quota language.

3. 提升
   - Usage alerts are now closer to the decision a user needs to make: which subscription needs attention, and whether it is about to reset soon enough to keep working.

### 2026-05-18 Cycle O

1. 审视
   - Proactive notifications add a release-trust requirement: the distributed app bundle should explain why it requests notification permission, and release verification should catch missing metadata.

2. 执行
   - Added a notification-purpose string to the generated `Info.plist`.
   - Extended release verification to assert that notification metadata is present in the packaged app.
   - Ran the package and verification scripts successfully against `v0.1.6`.

3. 提升
   - Release validation now covers the new proactive-alert capability, reducing the chance that a polished feature ships with incomplete macOS metadata.

### 2026-05-18 Cycle P

1. 审视
   - Token trend alone misses an important class of user pain: spend can spike because model mix or pricing changed even when token volume stays steady.

2. 执行
   - Added a spend-surge Usage Insight based on recent actual-cost trend data.
   - Added a Settings threshold for spend surge and diagnostics output for the active threshold.
   - Added regression coverage proving spend surge can trigger while token trend remains healthy.

3. 提升
   - The product now treats money as a first-class signal, closer to the way mature usage dashboards and LLM observability tools protect users.

### 2026-05-18 Cycle Q

1. 审视
   - Spend totals show absolute burn, but users also need unit economics to notice when the same token volume becomes more expensive.

2. 执行
   - Added a Cost / MTok formatter with low-cost precision and zero-token fallback.
   - Added the blended Cost / MTok metric to the dashboard and diagnostics.

3. 提升
   - Users can now see whether today's workload is merely larger or actually more expensive per token, which makes the app more useful for model-mix decisions.

### 2026-05-18 Cycle R

1. 审视
   - The README preview image existed, but the repo did not contain a reliable way to regenerate it after visual product changes.

2. 执行
   - Added a WebKit-based preview capture script that renders `docs/assets/product-preview.html` into `docs/assets/product-preview.png`.
   - Added release tests that assert the preview HTML and 1200x820 PNG asset are present.
   - Added the preview capture step to development and release documentation.

3. 提升
   - Product marketing assets are now reproducible from the repository instead of being a fragile manual artifact.

### 2026-05-18 Cycle S

1. 审视
   - CI still packaged non-tag builds as `v0.1.5` and did not verify the newly reproducible preview asset, so release automation had drifted from the product docs.

2. 执行
   - Updated GitHub Actions to use `v0.1.6` for non-tag package builds.
   - Added a CI preview-generation step that fails when `docs/assets/product-preview.png` is not reproducible.
   - Updated the release checklist to mark preview-asset verification as automated.

3. 提升
   - The repository now treats marketing assets as part of the release surface, not a side artifact outside automation.

### 2026-05-18 Cycle T

1. 审视
   - Competitive dashboards make trend exploration prominent, while the app still buried a token-only trend near the bottom of the popover.
   - A token-only chart also missed the user's more important question: whether cost or request volume changed, not just token volume.

2. 执行
   - Replaced the token-only display state with a Usage Trend model that supports Tokens, Spend, and Requests modes.
   - Moved Usage Trend into the first refreshable dashboard area so it remains visible even when lower cards push content down.
   - Updated tests, README, and product-preview HTML to reflect the broader trend feature.

3. 提升
   - Trend is now a core product surface instead of a trailing chart: the user can compare volume, money, and request activity without opening the web dashboard.

### 2026-05-19 Cycle U

1. 审视
   - LiteLLM-style products make budget protection a first-class guardrail, but this app only inferred risk from balance and spend spikes.
   - For a personal menu bar monitor, the useful slice is not team budget administration; it is a local monthly budget warning that stays private and simple.

2. 执行
   - Added an optional monthly budget threshold to local insight settings.
   - Added a Monthly budget Usage Insight that projects 30-day spend from recent daily actual cost.
   - Added Settings and diagnostics surfaces so the budget is user-editable and support-visible without exposing tokens.

3. 提升
   - The product now protects against quota exhaustion, balance exhaustion, spend spikes, and budget overrun, covering the main usage-risk loop without becoming an admin dashboard.

### 2026-05-19 Cycle V

1. 审视
   - Local notarization was documented, but tag builds on GitHub still produced ad-hoc artifacts unless someone manually ran the Apple signing flow.
   - For public distribution, silently publishing an unnotarized tag artifact is worse than failing loudly.

2. 执行
   - Added a GitHub Actions signing gate that detects whether the complete Apple signing and notarization secret set is present.
   - Added a temporary-keychain Developer ID certificate import step for CI.
   - Changed tag packaging to run `scripts/notarize-release.sh` when signing is configured, and to fail tagged releases when signing secrets are absent or partial.
   - Documented the required GitHub secrets in README and the release checklist.

3. 提升
   - The release pipeline now has a real path from source to notarized public artifact; the remaining blocker is supplying Apple credentials, not missing automation.

### 2026-05-19 Cycle W

1. 审视
   - A monitoring product must distinguish fresh data from old-but-still-visible data.
   - The app showed the last successful values indefinitely if refreshes stopped succeeding, which could make the menu bar look healthier than reality.

2. 执行
   - Added stale-data detection based on the last successful refresh time and the configured refresh interval.
   - Updated status labels, menu bar summaries, and tooltips to show `Stale Data` / `Stale` when cached data is too old.
   - Added a lightweight clock tick so the UI can become stale even without a new network response.
   - Added diagnostics output for data freshness and regression coverage for stale behavior.

3. 提升
   - The app now behaves more like a trustworthy monitor: old usage numbers remain visible, but they are clearly labeled as old instead of masquerading as current state.

### 2026-05-19 Cycle X

1. 审视
   - Mature monitoring tools do not only label stale data; they notify when the monitor itself stops receiving fresh data.
   - The app had stale labels, but a user could still miss the problem unless they opened the popover or looked closely at the menu bar.

2. 执行
   - Added stale-data alerts to the same local notification policy used by Usage Insights.
   - Reused the existing alert cooldown map so stale refresh warnings do not repeat noisily.
   - Triggered stale alert checks from the lightweight clock tick, so the warning can appear without another network response.

3. 提升
   - The app now guards the monitor itself: if usage visibility stops updating, the user can be notified before making decisions from stale numbers.

### 2026-05-19 Cycle Y

1. 审视
   - Competitive usage products expose exports or shareable summaries so users can reconcile spend, discuss spikes, or ask for help without stitching screenshots together.
   - For this menu bar product, a full export system would be too heavy; the best fit is a clean local usage report that omits credentials.

2. 执行
   - Added a core Usage Report generator covering account, balance, spend, requests, tokens, token mix, quota, latest trend, model spend, and prioritized insights.
   - Added a Copy Usage Report action in the connected popover and Settings diagnostics area.
   - Kept support diagnostics separate from user-facing reports: diagnostics help debug the app, while usage reports help explain usage.

3. 提升
   - The product now has a lightweight reporting loop: see usage, understand risk, and share a safe summary without opening the web dashboard.
