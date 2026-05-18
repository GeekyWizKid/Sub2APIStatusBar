# Sub2API Status Bar v0.1.6

This release turns Sub2API Status Bar from a passive menu bar dashboard into a proactive personal usage guardrail. It keeps the user-focused dashboard, then adds smarter insights, local alerts, and clearer cost signals.

## What's New

- Added Usage Insights for quota pressure, balance runway, token trend, spend surge, model concentration, and latency.
- Added local macOS alerts for important insights, with warning/error level and quiet-period controls.
- Added notification permission status in Settings, including a quick path to macOS notification settings when alerts are blocked.
- Added configurable insight thresholds for quota, balance, token surge, spend surge, model concentration, and latency.
- Added a blended Cost / MTok metric so users can see when the same token volume becomes more expensive.
- Improved quota insight text with subscription names and reset timing when available.
- Added guided recovery cards for setup and connection failures.
- Added release verification for notification-purpose metadata in the packaged app.

## Verify The Download

After downloading the zip and checksum:

```bash
shasum -a 256 -c Sub2APIStatusBar-0.1.6-macOS.zip.sha256
```
