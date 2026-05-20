# Support Bundle Template

Use Settings > Diagnostics > Copy Support Bundle when possible. If the app is not available, fill this template manually and paste the reviewed text into the GitHub issue.

Do not attach `config.json`, access tokens, refresh tokens, passwords, private server logs, full Application Support directories, release archives, or crash dumps that have not been reviewed for secrets.

## Diagnostics

Paste Settings > Diagnostics > Copy Diagnostics output here when filling this template manually. If you used Copy Support Bundle, the diagnostics section is already filled in the copied text.

```text

```

## Environment

- App version:
- macOS version:
- Sub2API server version or commit, if known:
- Install source: GitHub Release / Homebrew Cask draft / built from source
- Release asset name, if applicable:
- Release asset SHA-256 verification result, if applicable:

## Reproduction

1.
2.
3.

## Expected Behavior

What did you expect to happen?

## Actual Behavior

What happened instead?

## Recent Changes

- Did login, manual token setup, refresh, update checking, or installation work before?
- Did this begin after changing Sub2API server version, app version, account, network, or macOS settings?

## Local Checks

- [ ] Diagnostics report contains token presence only, not token values.
- [ ] No `config.json` content is included.
- [ ] No access token, refresh token, password, private server URL, or private log is included.
- [ ] Release archive checksums were verified before reporting an installation issue.
