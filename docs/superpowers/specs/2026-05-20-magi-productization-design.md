# MAGI Productization Design

## Purpose

Sub2API Status Bar should evolve from a working macOS menu bar companion into a product that users can install, trust, understand, and keep running every day. The next phase will use the MAGI spiral:

1. 审视: compare the current app against mature products and the current codebase.
2. 执行: ship one small, verifiable product improvement.
3. 提升: turn the result into the next, higher-quality loop.

This design keeps the original scope intact: compare mature market projects, plan the evolution, and push the project toward product readiness. It does not treat documentation alone as the final product state.

## Current Product State

The app already has a credible early product base:

- Native SwiftUI macOS menu bar app.
- User-only Sub2API usage dashboard.
- Multi-account switching.
- Automatic token refresh.
- Menu bar text summary modes.
- Customizable dashboard section visibility.
- Compact panel density preference.
- Stale-data status detection.
- Diagnostics copy and config reveal actions.
- App icon, app bundle scripts, zip packaging, checksum generation, release verification, and notarization script.
- GitHub Releases update checking.

The biggest remaining product gaps are:

- Public distribution trust still depends on Apple Developer ID signing and notarization credentials.
- Updates are detected but not installed in-app.
- Usage data is mostly descriptive; it does not yet guide users through budgets, alerts, or anomalies.
- Support, privacy, and release readiness are documented, but not yet organized as a product operating system.
- `Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift` is large enough that future UI work should start carving out focused views.

## Mature Product Reference Set

The reference set is intentionally split across three mature categories.

### macOS Menu Bar Utilities

- iStat Menus: dense but configurable menu bar monitoring, status at a glance, notification-oriented threshold behavior, polished preference surfaces.
- Stats: open-source menu bar monitoring with modular sensors and user-selectable visible modules.
- SwiftBar: a menu bar shell built around simple plugin outputs, demonstrating the value of extensible and inspectable status surfaces.
- Dato and similar calendar/status utilities: low-friction everyday presence, compact popover, predictable settings, and native macOS feel.

Product lesson: the menu bar surface must be glanceable, compressible, and personally configurable. The app should feel quiet until the user needs attention.

### LLM Usage And Observability Products

- Langfuse, Helicone, Portkey, and LiteLLM Proxy: token/cost tracking, latency visibility, model breakdowns, budgets, rate-limit awareness, and operational alerts.

Product lesson: token and cost data becomes valuable when it explains pressure, risk, or the next action. The app should move from "what happened" toward "what needs attention".

### Distribution And Trust Infrastructure

- Apple Developer ID and notarization: required trust path for broad distribution outside the Mac App Store.
- Sparkle-style app updates: a mature pattern for signed update delivery, appcast metadata, and update verification.
- Homebrew Cask: a common macOS developer distribution channel for GitHub-hosted apps.

Product lesson: mature desktop products make install, update, and verification boring. The current release pipeline is close, but trust and update installation need a clearer path.

## Productization Principles

1. Glance first, detail second.
   The menu bar and first popover viewport should answer whether usage is healthy, pressured, stale, or disconnected.

2. Compress without hiding risk.
   Users can hide sections and choose compact density, but high quota pressure, stale data, and failed refreshes should remain visible.

3. Prefer actionable monitoring.
   Metrics should lead toward budget warnings, quota pressure, refresh health, model cost concentration, or diagnostic next steps.

4. Make trust explicit.
   Release readiness, signing status, notarization, checksums, privacy posture, and update behavior should be visible in product docs and release checklists.

5. Keep each MAGI loop shippable.
   Every loop must leave the repo in a better product state with tests or documented verification.

## MAGI Spiral Roadmap

### Cycle M: Menu Bar Maturity

审视:

- Mature menu bar apps let users choose what remains visible and keep the popover scannable under daily use.
- The current app has summary modes, section visibility, compact density, and stale-data detection in progress.

执行:

- Finish and verify compact product controls: summary mode, panel layout toggles, compact density, and stale-data labels.
- Update release notes and README so the visible product promise matches the app.

提升:

- Next loop should add budget and alert thresholds because the surface is now configurable enough to carry warnings.

### Cycle A: Alerts And AI Usage Insight

审视:

- LLM observability products treat budget pressure, rate limits, latency, and model concentration as actionable signals.
- The current app shows costs, tokens, quotas, RPM/TPM, response time, model distribution, and trend, but does not let users define concern thresholds.

执行:

- Add lightweight local alert preferences for daily spend, daily tokens, and highest subscription quota.
- Show alert state in the menu bar tooltip, status section, diagnostics report, and relevant cards.
- Keep alerts local and deterministic; do not add server-side state.

提升:

- Future MAGI loops can add anomaly detection and per-model cost concentration once local alert rules prove useful.

### Cycle G: General Availability Trust

审视:

- Mature macOS products provide signed, notarized, checksummed releases with a predictable update path.
- The repo has scripts for app bundling, packaging, verification, and notarization, plus GitHub Releases update checking.

执行:

- Expand release readiness into a matrix that distinguishes implemented, blocked by credentials, and future automation work.
- Document exactly what Apple credentials unlock and which local commands prove readiness before a public release.
- Keep GitHub artifact generation and verification as the current baseline.

提升:

- Evaluate Sparkle or another signed update installation flow after Developer ID signing and notarization are available.

### Cycle I: Internal Product Operating System

审视:

- Productized tools need maintainable support paths, privacy language, release notes, and a backlog that prevents random feature accretion.
- The repo has diagnostics and documentation, but the operating model is spread across README, release checklist, release notes, and product review.

执行:

- Add a productization backlog with explicit priorities, owners as "local app" or "release process", and verification gates.
- Keep MAGI logs as the durable narrative for why a change exists.

提升:

- Future MAGI loops can add issue templates, support bundle structure, and more formal beta/release channels.

## First Implementation Slice

The first shippable slice should be a productization documentation and planning slice, followed by one product feature slice.

### Slice 1: Productization Route

Files:

- `docs/superpowers/specs/2026-05-20-magi-productization-design.md`
- `docs/PRODUCT_REVIEW.md`
- `docs/RELEASE_CHECKLIST.md`
- `README.md`

Expected outcome:

- A clear MAGI roadmap exists in the repo.
- Release readiness is expressed as a matrix.
- The current product promise reflects menu bar maturity work already present in the codebase.
- The next feature slice is explicit: local budget and quota alerts.

Verification:

- Documentation has no placeholders.
- MAGI cycles have concrete 审视, 执行, 提升 entries.
- Release readiness separates completed work from Apple-credential blockers and future update-installation work.

### Slice 2: Local Alert Rules

Files likely to change:

- `Sources/Sub2APIStatusCore/AppConfig.swift`
- `Sources/Sub2APIStatusCore/Models.swift`
- `Sources/Sub2APIStatusCore/DiagnosticReport.swift`
- `Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift`
- `Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift`
- README and release notes

Expected outcome:

- Users can configure local warning thresholds for daily spend, daily tokens, and highest quota usage.
- Alert state is reflected in status labels, tooltips, diagnostics, and the popover without requiring backend changes.
- Tests cover default config decoding, persistence, alert evaluation, and diagnostics output.

Verification:

- `swift test`
- `swift build`
- Existing package and release verification commands still pass when run in a release pass.

## Architecture Notes For Future Work

The current executable file contains app lifecycle, view model, settings, dashboard views, cards, charts, and utility views in one file. Future UI work should avoid making that file harder to navigate. When implementing alert rules, prefer extracting focused SwiftUI views if a touched section becomes larger or more conditional.

Core rules and formatting should remain in `Sub2APIStatusCore` so they are testable without launching the app. The app target should bind controls, render state, and call the model.

## Reference Links

- iStat Menus 7: https://bjango.com/help/istatmenus7/global/
- iStat Menus rules and notifications: https://bjango.com/help/istatmenus7/rules/
- Stats: https://github.com/exelban/stats
- SwiftBar: https://github.com/swiftbar/SwiftBar
- Langfuse token and cost tracking: https://langfuse.com/docs/observability/features/token-and-cost-tracking
- Helicone alerts: https://docs.helicone.ai/features/alerts
- Portkey AI Gateway budget and rate limits: https://portkey.ai/docs/product/ai-gateway
- LiteLLM spend tracking and budgets: https://docs.litellm.ai/
- Apple Developer ID: https://developer.apple.com/support/developer-id/
- Apple notarization: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- Sparkle documentation: https://sparkle-project.org/documentation/
- Homebrew Cask Cookbook: https://docs.brew.sh/Cask-Cookbook

## Approval Gate

This design is ready for review when:

- It gives a concrete comparison against mature products.
- It turns the comparison into MAGI loops.
- It identifies one documentation/planning slice and one product feature slice.
- It preserves the larger objective instead of declaring productization finished after one document.

After approval, the next step is an implementation plan for Slice 1, then Slice 2.
