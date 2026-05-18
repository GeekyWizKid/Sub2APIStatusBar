# Competitive Strategy

_Last updated: 2026-05-19_

## Positioning

Sub2API Status Bar should be the fastest personal cockpit for Sub2API users, not a second web dashboard. The product should win by answering three questions from the macOS menu bar:

- Can I keep using my account right now?
- What changed in cost, tokens, requests, or model mix?
- Which quota, balance, or reliability signal needs attention next?

## Competitive Lessons

### OpenAI Usage Dashboard

Useful patterns:

- Cost, token, request, model, project, user, service-account, and API-key slices.
- TPM-oriented usage views and cost categories.
- Exportable usage records for analysis outside the dashboard.

What to copy:

- Daily cost/token/request trend.
- Model and token-type breakdown.
- Safe report/export loops.

What to avoid:

- Large filter tables inside a menu bar popover.
- Admin-only project/user management surfaces.

### LiteLLM Proxy Dashboard

Useful patterns:

- Budgets, spend limits, virtual-key/user/team visibility, and rate-limit context.
- Clear indicators for whether a key or user is about to hit a limit.

What to copy:

- Local budget guardrails.
- RPM/TPM and quota pressure as first-class signals.
- Remaining quota and reset countdowns.

What to avoid:

- Team administration, key provisioning, and policy editing inside the native app.

### Helicone / Portkey-Style Observability

Useful patterns:

- Cost, latency, errors, cache impact, model concentration, and alerts.
- Anomaly detection that turns raw telemetry into action.

What to copy:

- Proactive local alerts.
- Spend surge and token trend insights.
- Support-safe diagnostics.

What to avoid:

- Full request tracing, prompt logs, evaluations, or proxy configuration in the menu bar app.

### Langfuse-Style Product Analytics

Useful patterns:

- Model-level cost and usage breakdown.
- Separation between high-level dashboard and deeper investigation.

What to copy:

- Model distribution, cost concentration insight, and model-level unit economics.
- A clear handoff from native app to web dashboard for deeper work.

What to avoid:

- Prompt/session observability features that Sub2API Status Bar cannot verify locally.

## Product Decisions

### Keep

- User-account focus.
- Local JSON config storage by design.
- Menu bar text as optional, compact status with spend, balance, quota, tokens, and request modes.
- Usage trend across Tokens, Spend, and Requests.
- Quota cards with remaining amount and reset time.
- Local alerts with quiet periods.
- Copy Usage Report and Copy Diagnostics as separate actions.
- GitHub Releases update checks.

### Defer

- CSV export. The current Usage Report is enough for early marketability; CSV only matters if users need spreadsheet reconciliation.
- Multi-service aggregation beyond Sub2API. The app should first become excellent for one server.
- Rich localization. Reintroduce language settings only when all app text is wired.
- Request-level tracing. That belongs in the Sub2API web dashboard or a proxy observability product.

### Reject

- Admin mode and admin credentials.
- Team/user/key management.
- Storing credentials in Keychain for this release, per product constraint.
- Heavy browser-style filter tables in the popover.

## Next Bets

1. Onboarding polish: clearer first-run state, sample screenshots, and install instructions for non-developers.
2. Menu bar intelligence: let users choose the primary compact metric, such as spend, quota, balance, or RPM.
3. Visual refinement: make the dashboard denser but calmer, with quota and trend above lower-priority cards.
4. Release trust: publish notarized artifacts once Apple Developer credentials exist.
5. Lightweight export: add CSV only if Usage Report proves insufficient.
