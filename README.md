# Sub2APIStatusBar

macOS menu bar monitor for Sub2API.

## Features

- Native menu bar status item and SwiftUI popover
- User usage dashboard:
  - balance, API key count, requests, costs, tokens, RPM/TPM, and average response time
  - model distribution and seven-day token trend
  - subscription count, USD usage progress, and expiring subscription count
- Optional menu bar text summary
- Settings sheet with Base URL, Bearer token, language, menu bar text, and refresh interval
- First-run login page for server URL, account, and password
- Optional manual Bearer token entry

## API Endpoints

The app expects a Sub2API server with `/api/v1` endpoints.

User dashboard uses:

- `GET /api/v1/subscriptions/summary`
- `GET /api/v1/usage/dashboard/stats`
- `GET /api/v1/usage/dashboard/trend`
- `GET /api/v1/usage/dashboard/models`

Login uses:

- `POST /api/v1/auth/login`

Requests send `Authorization: Bearer <token>` when a token is configured.

## Run

```bash
swift run Sub2APIStatusBar
```

On first launch, click the menu bar icon and fill:

- Server URL, for example `http://127.0.0.1:8080`
- Account email
- Password

The app logs in through `/api/v1/auth/login`, stores the returned access token, and switches to the monitor view.

Optional first-run environment variables:

```bash
SUB2API_BASE_URL=http://127.0.0.1:8080 \
SUB2API_AUTH_TOKEN=your-token \
SUB2API_SHOW_MENU_BAR_TEXT=true \
swift run Sub2APIStatusBar
```

Configuration is saved at:

```text
~/Library/Application Support/Sub2APIStatusBar/config.json
```

## Build App

```bash
VERSION=v0.1.0 ./scripts/build-app.sh
```

Output:

```text
dist/Sub2APIStatusBar.app
```

This local build is unsigned. On first launch, macOS may require right-clicking the app and choosing Open.
