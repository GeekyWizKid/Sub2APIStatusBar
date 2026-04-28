# Sub2API Status Bar

Sub2API Status Bar is a macOS menu bar companion for Sub2API users. It keeps daily spend, token usage, quota pressure, model distribution, and subscription limits visible without keeping the web dashboard open.

## Highlights

- Native macOS menu bar app with a compact SwiftUI popover
- User dashboard cards for balance, API keys, requests, spend, token totals, RPM/TPM, and response time
- Subscription quota card with separate daily, weekly, and monthly progress bars
- Seven-day token trend and model distribution
- Optional menu bar text summary, for example `$120.75 · 1219 req · 3 RPM`
- First-run login and optional manual Bearer token setup
- Local config storage only; no telemetry or third-party analytics

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

Configuration is saved at:

```text
~/Library/Application Support/Sub2APIStatusBar/config.json
```

Optional first-run environment variables:

```bash
SUB2API_BASE_URL=https://sub2api.example.com \
SUB2API_AUTH_TOKEN=your-token \
SUB2API_SHOW_MENU_BAR_TEXT=true \
swift run Sub2APIStatusBar
```

## Build A macOS App

```bash
VERSION=v0.1.0 ./scripts/build-app.sh
```

Output:

```text
dist/Sub2APIStatusBar.app
```

The build script generates the app icon, copies bundle resources, and applies ad-hoc signing by default. To sign with a Developer ID certificate:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
VERSION=v0.1.0 \
./scripts/build-app.sh
```

## Package A Release

```bash
VERSION=v0.1.0 ./scripts/package-release.sh
```

Output:

```text
dist/Sub2APIStatusBar-0.1.0-macOS.zip
dist/Sub2APIStatusBar-0.1.0-macOS.zip.sha256
```

## Development Checks

```bash
swift test
swift build
./scripts/package-release.sh
```

GitHub Actions runs the same checks on `main`, pull requests, tags, and manual workflow dispatches.

## Privacy

Sub2API Status Bar stores only the server URL, auth token, refresh token, display preferences, and refresh interval in the local Application Support config file. It does not send data anywhere except the configured Sub2API server.
