# Sub2API Status Bar v0.1.0

First packaged build of Sub2API Status Bar, a native macOS menu bar companion for Sub2API user accounts.

## Included

- User dashboard cards for balance, API key count, requests, spend, token totals, RPM/TPM, and average response time
- Daily, weekly, and monthly subscription quota progress
- Model distribution and seven-day token trend
- First-run login and manual Bearer token setup
- Optional menu bar text summary
- Custom app icon
- Local `.app` bundle and zipped release artifact

## Notes

This build is ad-hoc signed unless `SIGN_IDENTITY` is provided during packaging. For broad distribution outside your own machines, build with a Developer ID Application certificate and notarize with Apple.
