# Sub2API Status Bar

Sub2API Status Bar is a macOS menu bar companion for Sub2API users. It keeps daily spend, token usage, quota pressure, model distribution, and subscription limits visible without keeping the web dashboard open.

![Sub2API Status Bar preview](docs/assets/product-preview.png)

## Highlights

- Native macOS menu bar app with a compact SwiftUI popover
- Usage Insights that turn balance, quotas, monthly budget, spend trend, usage trend, model concentration, and latency into prioritized signals
- Local proactive alerts for warning/error insights, with severity and quiet-period controls
- Notification permission status inside Settings, including quick access to macOS notification settings
- Custom insight thresholds for quota pressure, balance runway, monthly budget, token surge, model concentration, and latency
- User dashboard cards for balance, API keys, requests, spend, blended cost per million tokens, token totals, RPM/TPM, and response time
- Subscription quota card with separate daily, weekly, and monthly progress bars
- Seven-day usage trend with Tokens, Spend, and Requests views
- Model distribution with cost and token share
- Optional menu bar text summary, for example `$120.75 · 1219 req · 3 RPM`
- First-run login and optional manual Bearer token setup
- Guided recovery cards for missing URLs, expired sessions, token replacement, and server reachability problems
- Multiple saved accounts with quick switching
- Launch at Login, manual refresh, copied diagnostics, and config-file reveal actions
- Local config storage; no telemetry or third-party analytics
- GitHub Releases update checking from Settings

## Product Direction

Sub2API Status Bar is intentionally optimized for ordinary users who need a fast answer to: am I healthy, what changed, and what should I watch next? It borrows the useful parts of larger usage dashboards without turning the menu bar into another full analytics console:

- OpenAI-style usage visibility: project-like daily usage, costs, tokens, model mix, and throughput.
- LiteLLM-style operational guardrails: quota pressure, budget runway, and rate-limit-adjacent RPM/TPM signals.
- Helicone/Langfuse-style observability cues: local alerts, cost concentration, usage trend changes, latency, and support-safe diagnostics.

The product bias is to surface actionable signals first, then leave deep investigation to the configured Sub2API web dashboard.

## Requirements

- macOS 13 or later
- Swift 6.1 or later for local development
- A Sub2API server with user API endpoints enabled

## User API Endpoints

The app expects a Sub2API server with `/api/v1` endpoints:

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `GET /api/v1/subscriptions/summary`
- `GET /api/v1/usage/dashboard/stats`
- `GET /api/v1/usage/dashboard/trend`
- `GET /api/v1/usage/dashboard/models`

Requests send `Authorization: Bearer <token>` after login or manual token setup.

## Run From Source

```bash
swift run Sub2APIStatusBar
```

On first launch, click the menu bar icon and fill:

- Server URL, for example `https://sub2api.example.com`
- Account email
- Password

Non-secret preferences are saved at:

```text
~/Library/Application Support/Sub2APIStatusBar/config.json
```

Login tokens are stored in the same local config file. The app does not use macOS Keychain.

To switch accounts or remove saved credentials, open Settings and choose **Disconnect**.

Settings also includes:

- **Show text in menu bar** for a compact always-visible usage summary
- **Notify on insights** to receive local macOS alerts when important usage signals cross the configured level
- **Notification status** to confirm alerts are ready or open macOS settings when permissions are blocked
- **Insights thresholds** to tune when quota, balance, spend surge, token surge, model-share, and latency warnings appear
- **Launch at login** so the monitor starts with macOS
- **Copy Diagnostics** for support-safe status details with tokens redacted
- **Show Config** to reveal the local `config.json`

Optional first-run environment variables:

```bash
SUB2API_BASE_URL=https://sub2api.example.com \
SUB2API_AUTH_TOKEN=your-token \
SUB2API_SHOW_MENU_BAR_TEXT=true \
swift run Sub2APIStatusBar
```

## Build A macOS App

```bash
VERSION=v0.1.6 ./scripts/build-app.sh
```

Output:

```text
dist/Sub2APIStatusBar.app
```

The build script generates the app icon, copies bundle resources, and applies ad-hoc signing by default. To sign with a Developer ID certificate:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.6 \
./scripts/build-app.sh
```

## Package A Release

```bash
VERSION=v0.1.6 ./scripts/package-release.sh
```

Output:

```text
dist/Sub2APIStatusBar-0.1.6-macOS.zip
dist/Sub2APIStatusBar-0.1.6-macOS.zip.sha256
```

## Notarize A Release

After signing with a Developer ID Application certificate, notarize and staple the app with:

```bash
APPLE_ID="you@example.com" \
TEAM_ID="TEAMID" \
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.6 \
./scripts/notarize-release.sh
```

## GitHub Release Signing

Tagged GitHub Actions releases require Apple signing and notarization secrets. Add all of these repository secrets before pushing a `v*` tag:

- `APPLE_CERTIFICATE_BASE64`: base64-encoded `.p12` Developer ID Application certificate
- `APPLE_CERTIFICATE_PASSWORD`: password for that `.p12`
- `APPLE_KEYCHAIN_PASSWORD`: temporary CI keychain password
- `DEVELOPER_ID_APPLICATION`: certificate identity, for example `Developer ID Application: Your Name (TEAMID)`
- `APPLE_ID`: Apple ID email used by `notarytool`
- `TEAM_ID`: Apple Developer Team ID
- `APP_SPECIFIC_PASSWORD`: app-specific password for notarization

If no signing secrets are configured, branch and pull-request builds still produce ad-hoc signed artifacts. Tagged releases fail until the full signing set is present, so public downloads are not accidentally shipped as unnotarized builds.

## Updates

The app checks GitHub Releases once on launch and lets users check manually from Settings > Updates. When a newer release is available, the popover shows a small update banner with a link to the download page.

GitHub only exposes published releases through the public latest-release API. Draft releases are intentionally not shown to users.

## Development Checks

```bash
swift test
swift build
./scripts/capture-product-preview.swift
./scripts/package-release.sh
./scripts/verify-release.sh
```

GitHub Actions runs the same checks on `main`, pull requests, tags, and manual workflow dispatches.

Regenerate the README product preview after visual changes:

```bash
./scripts/capture-product-preview.swift
```

## Troubleshooting

If Swift reports that a PCH was compiled with a different module cache path, the project was probably moved or renamed while `.build` still points at the old folder. Clean the local build cache and run again:

```bash
./scripts/clean-build-cache.sh
swift run Sub2APIStatusBar
```

## Privacy

Sub2API Status Bar stores the server URL, auth token, refresh token, display preferences, insight thresholds, account list, and refresh interval in the local Application Support config file. It does not use macOS Keychain and does not send data anywhere except the configured Sub2API server and GitHub Releases when checking for updates.

## Acknowledgements
Thanks to the [LinuxDo](https://linux.do/) community for the discussions, sharing, and feedback.

## License

MIT
