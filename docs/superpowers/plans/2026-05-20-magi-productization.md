# MAGI Productization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the MAGI productization design into a release-ready documentation slice, then ship local budget and quota alerts as the next product feature slice.

**Architecture:** Keep product strategy and release readiness in Markdown docs. Keep alert configuration and evaluation inside `Sub2APIStatusCore` so it is covered by unit tests, then bind the tested state into the existing SwiftUI settings and popover surfaces.

**Tech Stack:** Swift 6.1, SwiftUI, Swift Testing, macOS menu bar app, Markdown docs, existing shell release scripts.

---

## File Structure

- Modify `README.md`: describe the MAGI productization direction and local alert controls once implemented.
- Modify `docs/PRODUCT_REVIEW.md`: add new MAGI cycles for productization route planning and alert rules.
- Modify `docs/RELEASE_CHECKLIST.md`: replace the loose release list with a readiness matrix that distinguishes completed, credential-blocked, and future automation work.
- Create `docs/RELEASE_NOTES_v0.1.6.md`: summarize productization route, compact menu bar maturity already in progress, and local alert rules.
- Modify `Sources/Sub2APIStatusCore/AppConfig.swift`: add persisted local alert preferences with legacy-safe defaults and normalization.
- Modify `Sources/Sub2APIStatusCore/Models.swift`: add alert evaluation types and connect them to `MonitorSnapshot` status/severity/detail.
- Modify `Sources/Sub2APIStatusCore/DiagnosticReport.swift`: include local alert preference and active alert state without leaking tokens.
- Modify `Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift`: add Settings controls and popover display for alert thresholds using existing view patterns.
- Modify `Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift`: add tests for config persistence, legacy defaults, alert evaluation, status labels, menu bar behavior, and diagnostics.

Existing uncommitted work already touches these files. Preserve those edits and layer this plan on top of the current state.

## Task 1: Productization Route Documents

**Files:**
- Modify: `docs/PRODUCT_REVIEW.md`
- Modify: `docs/RELEASE_CHECKLIST.md`
- Modify: `README.md`
- Create: `docs/RELEASE_NOTES_v0.1.6.md`

- [ ] **Step 1: Update `docs/RELEASE_CHECKLIST.md` with a readiness matrix**

Replace the current "Before Public Distribution" section with this structure, keeping the existing completed checklist above it:

```markdown
## Productization Readiness Matrix

| Area | Current Status | Verification | Next Gate |
| --- | --- | --- | --- |
| App identity | Ready | `Resources/AppIcon.icns`, bundle metadata from `scripts/build-app.sh` | Keep screenshots current for each public release |
| User dashboard | Ready | `swift test` covers dashboard decoding, quota progress, status labels, and menu bar summaries | Add local alert coverage in v0.1.6 |
| Local configuration | Ready | `swift test` covers config persistence, legacy decoding, and multi-account token storage | Revisit Keychain only if the product promise changes |
| Menu bar maturity | In progress | Summary modes, section visibility, compact density, and stale detection are covered by unit tests and README copy | Verify compact layout manually before release |
| Release archive | Ready | `VERSION=v0.1.5 ./scripts/package-release.sh` and `VERSION=v0.1.5 ./scripts/verify-release.sh` | Update the version for each tag |
| Public trust | Blocked by Apple credentials | Developer ID signing and notarization scripts exist | Provide `SIGN_IDENTITY`, `APPLE_ID`, `TEAM_ID`, and `APP_SPECIFIC_PASSWORD` |
| Update delivery | Partial | GitHub Releases latest-version detection exists | Evaluate Sparkle-style signed update installation after notarization |
| Distribution channels | Planned | GitHub Release zip and checksum are produced by CI | Consider Homebrew Cask after a notarized public release exists |
| Support | In progress | Copy Diagnostics and Show Config exist | Add issue templates or support bundle structure after v0.1.6 |
```

- [ ] **Step 2: Add a v0.1.6 release readiness command block**

Append this under the existing release commands:

````markdown
For the v0.1.6 productization pass:

```bash
swift test
swift build
VERSION=v0.1.6 ./scripts/package-release.sh
VERSION=v0.1.6 ./scripts/verify-release.sh
```
````

- [ ] **Step 3: Add a MAGI Cycle M entry to `docs/PRODUCT_REVIEW.md`**

Append this entry after the existing Cycle L:

```markdown
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
```

- [ ] **Step 4: Update `README.md` highlights for alerts and product maturity**

Add these bullets to the Highlights list after the stale-data bullet:

```markdown
- Local alert thresholds for daily spend, daily tokens, and subscription quota pressure
- MAGI productization roadmap with release-readiness gates and maturity backlog
```

Add this subsection after "Updates":

```markdown
## Productization Roadmap

The project uses a MAGI spiral for product work:

- 审视: compare the current app with mature menu bar, AI observability, and macOS distribution products.
- 执行: ship one small, verifiable product improvement.
- 提升: record the next quality bar in `docs/PRODUCT_REVIEW.md`.

The current roadmap lives in `docs/superpowers/specs/2026-05-20-magi-productization-design.md`.
```

- [ ] **Step 5: Create `docs/RELEASE_NOTES_v0.1.6.md`**

Write:

```markdown
# Release Notes v0.1.6

This release continues the MAGI productization pass. It makes usage pressure more actionable while keeping the menu bar experience compact and quiet.

## Added

- Local warning thresholds for daily spend, daily tokens, and highest subscription quota usage.
- Alert-aware status text, diagnostics, and menu bar detail.
- Productization roadmap documentation and release-readiness matrix.

## Verification

- `swift test`
- `swift build`
- `VERSION=v0.1.6 ./scripts/package-release.sh`
- `VERSION=v0.1.6 ./scripts/verify-release.sh`
```

- [ ] **Step 6: Review the documentation diff**

Run:

```bash
git diff -- README.md docs/PRODUCT_REVIEW.md docs/RELEASE_CHECKLIST.md docs/RELEASE_NOTES_v0.1.6.md
```

Expected: the diff contains only roadmap, release readiness, and v0.1.6 release-note content.

- [ ] **Step 7: Commit Task 1**

```bash
git add README.md docs/PRODUCT_REVIEW.md docs/RELEASE_CHECKLIST.md docs/RELEASE_NOTES_v0.1.6.md
git commit -m "docs: add productization readiness route"
```

## Task 2: Alert Preferences In Core Config

**Files:**
- Modify: `Sources/Sub2APIStatusCore/AppConfig.swift`
- Modify: `Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift`

- [ ] **Step 1: Write failing config tests**

Add these tests near the existing config persistence tests:

```swift
@Test func appConfigPersistsLocalAlertPreferences() throws {
    let configURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("config.json")
    let store = ConfigStore(configURL: configURL)
    let config = AppConfig(
        baseURL: "http://127.0.0.1:8080",
        alertRules: LocalAlertRules(
            dailySpendUSD: 25,
            dailyTokens: 1_000_000,
            quotaProgress: 0.72
        )
    )

    try store.save(config)
    let loaded = store.load()

    #expect(loaded.alertRules.dailySpendUSD == 25)
    #expect(loaded.alertRules.dailyTokens == 1_000_000)
    #expect(loaded.alertRules.quotaProgress == 0.72)
}

@Test func appConfigDefaultsAlertPreferencesForLegacyConfigs() throws {
    let data = """
    {
      "baseURL": "http://127.0.0.1:8080"
    }
    """.data(using: .utf8)!

    let config = try JSONDecoder.sub2api.decode(AppConfig.self, from: data)

    #expect(config.alertRules.dailySpendUSD == nil)
    #expect(config.alertRules.dailyTokens == nil)
    #expect(config.alertRules.quotaProgress == 0.85)
}

@Test func appConfigNormalizesAlertPreferences() {
    var config = AppConfig(
        baseURL: "http://127.0.0.1:8080",
        alertRules: LocalAlertRules(
            dailySpendUSD: -1,
            dailyTokens: -20,
            quotaProgress: 3
        )
    )

    config.normalize()

    #expect(config.alertRules.dailySpendUSD == nil)
    #expect(config.alertRules.dailyTokens == nil)
    #expect(config.alertRules.quotaProgress == 1)
}
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
swift test --filter appConfigPersistsLocalAlertPreferences
```

Expected: fail because `LocalAlertRules` and `AppConfig.alertRules` do not exist.

- [ ] **Step 3: Add `LocalAlertRules` to `AppConfig.swift`**

Add this after `PanelDensity`:

```swift
public struct LocalAlertRules: Codable, Equatable, Sendable {
    public var dailySpendUSD: Double?
    public var dailyTokens: Int64?
    public var quotaProgress: Double

    public init(
        dailySpendUSD: Double? = nil,
        dailyTokens: Int64? = nil,
        quotaProgress: Double = 0.85
    ) {
        self.dailySpendUSD = dailySpendUSD
        self.dailyTokens = dailyTokens
        self.quotaProgress = quotaProgress
        normalize()
    }

    public mutating func normalize() {
        if let dailySpendUSD, dailySpendUSD <= 0 {
            self.dailySpendUSD = nil
        }
        if let dailyTokens, dailyTokens <= 0 {
            self.dailyTokens = nil
        }
        quotaProgress = min(max(quotaProgress, 0.5), 1)
    }
}
```

- [ ] **Step 4: Persist alert rules in `AppConfig`**

Add:

```swift
public var alertRules: LocalAlertRules
```

Add an init parameter:

```swift
alertRules: LocalAlertRules = LocalAlertRules(),
```

Assign it:

```swift
self.alertRules = alertRules
```

Add the coding key:

```swift
case alertRules
```

Decode it:

```swift
alertRules = try container.decodeIfPresent(LocalAlertRules.self, forKey: .alertRules) ?? LocalAlertRules()
```

Encode it:

```swift
try container.encode(alertRules, forKey: .alertRules)
```

Pass it in `defaults()`:

```swift
alertRules: LocalAlertRules()
```

Normalize it inside `normalize()`:

```swift
alertRules.normalize()
```

- [ ] **Step 5: Run config tests**

Run:

```bash
swift test --filter appConfig
```

Expected: PASS for config tests, including the new alert preference tests.

- [ ] **Step 6: Commit Task 2**

```bash
git add Sources/Sub2APIStatusCore/AppConfig.swift Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift
git commit -m "feat: persist local alert preferences"
```

## Task 3: Alert Evaluation In Core Models

**Files:**
- Modify: `Sources/Sub2APIStatusCore/Models.swift`
- Modify: `Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift`

- [ ] **Step 1: Write failing alert evaluation tests**

Add these tests near the existing `MonitorSnapshot` status tests:

```swift
@Test func localAlertEvaluationDetectsSpendTokenAndQuotaPressure() {
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayTokens: 1_500, todayActualCost: 12.5),
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: SubscriptionSummary(
            activeCount: 1,
            subscriptions: [
                SubscriptionSummaryItem(
                    id: 1,
                    groupName: "Team",
                    status: "active",
                    dailyProgress: 0.91,
                    weeklyProgress: nil,
                    monthlyProgress: nil,
                    expiresAt: nil,
                    daysRemaining: nil
                )
            ]
        ),
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )
    let alerts = snapshot.localAlerts(using: LocalAlertRules(
        dailySpendUSD: 10,
        dailyTokens: 1_000,
        quotaProgress: 0.9
    ))

    #expect(alerts.count == 3)
    #expect(alerts.map(\.kind) == [.dailySpend, .dailyTokens, .quotaProgress])
    #expect(alerts.first?.title == "Daily spend alert")
}

@Test func monitorSnapshotUsesLocalAlertsInStatusDetail() {
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayTokens: 1_500, todayActualCost: 12.5),
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )
    let rules = LocalAlertRules(dailySpendUSD: 10, dailyTokens: nil, quotaProgress: 0.9)

    #expect(snapshot.severity(using: rules) == .warning)
    #expect(snapshot.statusLabel(using: rules, refreshIntervalSeconds: 30) == "Budget Alert")
    #expect(snapshot.statusDetail(using: rules, refreshIntervalSeconds: 30) == "Daily spend is $12.50, above the $10.00 alert.")
}

@Test func monitorSnapshotIgnoresDisabledSpendAndTokenAlerts() {
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayTokens: 1_500, todayActualCost: 12.5),
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )
    let alerts = snapshot.localAlerts(using: LocalAlertRules(
        dailySpendUSD: nil,
        dailyTokens: nil,
        quotaProgress: 0.9
    ))

    #expect(alerts.isEmpty)
    #expect(snapshot.statusLabel(using: LocalAlertRules(), refreshIntervalSeconds: 30) == "OK")
}
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
swift test --filter localAlertEvaluationDetectsSpendTokenAndQuotaPressure
```

Expected: fail because alert evaluation APIs do not exist.

- [ ] **Step 3: Add alert model types**

Add this before `MonitorSeverity` in `Models.swift`:

```swift
public enum LocalAlertKind: String, Equatable, Sendable {
    case dailySpend
    case dailyTokens
    case quotaProgress
}

public struct LocalAlert: Equatable, Sendable {
    public let kind: LocalAlertKind
    public let title: String
    public let message: String

    public init(kind: LocalAlertKind, title: String, message: String) {
        self.kind = kind
        self.title = title
        self.message = message
    }
}
```

- [ ] **Step 4: Add alert evaluation methods to `MonitorSnapshot`**

Add this inside `MonitorSnapshot` before `public var severity`:

```swift
public func localAlerts(using rules: LocalAlertRules) -> [LocalAlert] {
    guard connected else {
        return []
    }

    var normalized = rules
    normalized.normalize()
    var alerts: [LocalAlert] = []

    if let limit = normalized.dailySpendUSD,
       let actual = stats?.todayActualCost,
       actual >= limit {
        alerts.append(LocalAlert(
            kind: .dailySpend,
            title: "Daily spend alert",
            message: "Daily spend is \(StatusFormatters.preciseCurrency(actual)), above the \(StatusFormatters.preciseCurrency(limit)) alert."
        ))
    }

    if let limit = normalized.dailyTokens,
       let actual = stats?.todayTokens,
       actual >= limit {
        alerts.append(LocalAlert(
            kind: .dailyTokens,
            title: "Daily token alert",
            message: "Daily tokens are \(StatusFormatters.compactNumber(actual)), above the \(StatusFormatters.compactNumber(limit)) alert."
        ))
    }

    if let progress = subscriptionSummary?.highestProgress,
       progress >= normalized.quotaProgress {
        alerts.append(LocalAlert(
            kind: .quotaProgress,
            title: "Quota alert",
            message: "Highest subscription quota is \(StatusFormatters.percent(progress)), above the \(StatusFormatters.percent(normalized.quotaProgress)) alert."
        ))
    }

    return alerts
}

public func severity(using rules: LocalAlertRules) -> MonitorSeverity {
    let base = severity
    if base == .error {
        return .error
    }
    if !localAlerts(using: rules).isEmpty {
        return .warning
    }
    return base
}
```

- [ ] **Step 5: Add alert-aware label and detail overloads**

Add these after the existing `statusLabel(referenceDate:refreshIntervalSeconds:)` and `statusDetail(referenceDate:refreshIntervalSeconds:)` methods:

```swift
public func statusLabel(
    using rules: LocalAlertRules,
    referenceDate: Date = .now,
    refreshIntervalSeconds: Double
) -> String {
    if isStale(referenceDate: referenceDate, refreshIntervalSeconds: refreshIntervalSeconds) {
        return "Needs Refresh"
    }
    if !localAlerts(using: rules).isEmpty {
        return "Budget Alert"
    }
    return baseStatusLabel
}

public func statusDetail(
    using rules: LocalAlertRules,
    referenceDate: Date = .now,
    refreshIntervalSeconds: Double
) -> String {
    if isStale(referenceDate: referenceDate, refreshIntervalSeconds: refreshIntervalSeconds),
       let lastUpdatedAt {
        let age = StatusFormatters.relativeAge(seconds: referenceDate.timeIntervalSince(lastUpdatedAt))
        return "Last successful update was \(age) ago."
    }
    if let alert = localAlerts(using: rules).first {
        return alert.message
    }
    return statusDetail(referenceDate: referenceDate, refreshIntervalSeconds: refreshIntervalSeconds)
}
```

- [ ] **Step 6: Run alert model tests**

Run:

```bash
swift test --filter localAlert
swift test --filter monitorSnapshotUsesLocalAlertsInStatusDetail
```

Expected: PASS.

- [ ] **Step 7: Commit Task 3**

```bash
git add Sources/Sub2APIStatusCore/Models.swift Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift
git commit -m "feat: evaluate local usage alerts"
```

## Task 4: Diagnostics And Menu Bar Status

**Files:**
- Modify: `Sources/Sub2APIStatusCore/DiagnosticReport.swift`
- Modify: `Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift`
- Modify: `Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift`

- [ ] **Step 1: Write failing diagnostics test**

Add this after `diagnosticReportRedactsStoredTokenValues`:

```swift
@Test func diagnosticReportIncludesLocalAlertState() {
    let config = AppConfig(
        baseURL: "https://sub2api.example.com",
        alertRules: LocalAlertRules(dailySpendUSD: 5, dailyTokens: 1_000, quotaProgress: 0.9)
    )
    let snapshot = MonitorSnapshot(
        mode: .user,
        connected: true,
        stats: DashboardStats(todayTokens: 2_000, todayActualCost: 9),
        realtime: nil,
        accountHealth: nil,
        subscriptionSummary: nil,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        message: nil
    )

    let report = DiagnosticReport.make(
        config: config,
        snapshot: snapshot,
        appVersion: "0.1.6",
        osVersion: "macOS 15.0"
    )

    #expect(report.contains("Daily Spend Alert: $5.00"))
    #expect(report.contains("Daily Token Alert: 1000"))
    #expect(report.contains("Quota Alert: 90%"))
    #expect(report.contains("Active Alerts: Daily spend alert, Daily token alert"))
}
```

- [ ] **Step 2: Run diagnostics test and verify it fails**

Run:

```bash
swift test --filter diagnosticReportIncludesLocalAlertState
```

Expected: fail because diagnostics do not include alert state.

- [ ] **Step 3: Update `DiagnosticReport.make`**

After `"Refresh Interval: ..."` add:

```swift
"Daily Spend Alert: \(config.alertRules.dailySpendUSD.map(StatusFormatters.preciseCurrency) ?? "off")",
"Daily Token Alert: \(config.alertRules.dailyTokens.map { String($0) } ?? "off")",
"Quota Alert: \(StatusFormatters.percent(config.alertRules.quotaProgress))",
```

After the token lines, append:

```swift
let alerts = snapshot.localAlerts(using: config.alertRules)
if alerts.isEmpty {
    lines.append("Active Alerts: none")
} else {
    lines.append("Active Alerts: \(alerts.map(\.title).joined(separator: ", "))")
}
```

- [ ] **Step 4: Update menu bar status logic**

In `Sub2APIStatusBarApp.swift`, update `updateStatusItem(_:)` to use alert-aware status:

```swift
switch snapshot.severity(using: model.config.alertRules) {
case .healthy:
    button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Sub2API OK")
case .warning:
    button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Sub2API Warning")
case .error:
    button.image = NSImage(systemSymbolName: "xmark.octagon", accessibilityDescription: "Sub2API Error")
}
```

Replace both `snapshot.statusLabel(refreshIntervalSeconds:)` calls with:

```swift
snapshot.statusLabel(using: model.config.alertRules, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
```

Replace both `snapshot.statusDetail(refreshIntervalSeconds:)` calls with:

```swift
snapshot.statusDetail(using: model.config.alertRules, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
```

- [ ] **Step 5: Run diagnostics and build checks**

Run:

```bash
swift test --filter diagnosticReportIncludesLocalAlertState
swift build
```

Expected: both PASS.

- [ ] **Step 6: Commit Task 4**

```bash
git add Sources/Sub2APIStatusCore/DiagnosticReport.swift Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift Tests/Sub2APIStatusCoreTests/Sub2APIStatusCoreTests.swift
git commit -m "feat: surface alerts in status and diagnostics"
```

## Task 5: Settings And Popover UI For Alerts

**Files:**
- Modify: `Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift`

- [ ] **Step 1: Add an alert section to `SettingsView`**

Insert `AlertSettingsSection(model: model)` between `GeneralSettingsSection(model: model)` and `LayoutSettingsSection(model: model)`.

- [ ] **Step 2: Add `AlertSettingsSection`**

Add after `GeneralSettingsSection`:

```swift
struct AlertSettingsSection: View {
    @ObservedObject var model: MonitorViewModel

    private var dailySpendBinding: Binding<Double> {
        Binding(
            get: { model.settingsDraft.alertRules.dailySpendUSD ?? 0 },
            set: { value in
                model.settingsDraft.alertRules.dailySpendUSD = value > 0 ? value : nil
            }
        )
    }

    private var dailyTokensBinding: Binding<Double> {
        Binding(
            get: { Double(model.settingsDraft.alertRules.dailyTokens ?? 0) },
            set: { value in
                model.settingsDraft.alertRules.dailyTokens = value > 0 ? Int64(value) : nil
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alerts")
                .font(.headline)

            VStack(spacing: 8) {
                SettingsControlRow(title: "Spend") {
                    TextField("Off", value: dailySpendBinding, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                    Text("USD/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsControlRow(title: "Tokens") {
                    TextField("Off", value: dailyTokensBinding, format: .number.precision(.fractionLength(0)))
                        .textFieldStyle(.roundedBorder)
                    Text("per day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsControlRow(title: "Quota") {
                    Slider(value: $model.settingsDraft.alertRules.quotaProgress, in: 0.5...1, step: 0.05)
                    Text(StatusFormatters.percent(model.settingsDraft.alertRules.quotaProgress))
                        .font(.callout.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Add alert banner in the popover**

In `MonitorPanel.userSection`, before the account overview card, add:

```swift
let alerts = model.snapshot.localAlerts(using: model.config.alertRules)
if !alerts.isEmpty {
    AlertSummaryView(alerts: alerts, density: density)
}
```

Use this complete `userSection` shape so the alert array is computed once and the existing section order is preserved:

```swift
private var userSection: some View {
    let alerts = model.snapshot.localAlerts(using: model.config.alertRules)
    return VStack(alignment: .leading, spacing: sectionSpacing) {
        if !alerts.isEmpty {
            AlertSummaryView(alerts: alerts, density: density)
        }

        if model.config.dashboardSections.accountOverview, let user = model.snapshot.currentUser {
            UserAccountCard(user: user, density: density)
        }

        if model.config.dashboardSections.usageMetrics, let stats = model.snapshot.stats {
            MetricGrid(items: [
                MetricItem(title: "Balance", value: balanceText, caption: "Available", systemImage: "banknote", tint: .green),
                MetricItem(title: "API Keys", value: "\(stats.totalAPIKeys)", caption: "\(stats.activeAPIKeys) active", systemImage: "key", tint: .blue),
                MetricItem(title: "Today Requests", value: StatusFormatters.menuBarCount(stats.todayRequests), caption: "Total \(StatusFormatters.compactNumber(stats.totalRequests))", systemImage: "chart.bar", tint: .green),
                MetricItem(title: "Today Cost", value: StatusFormatters.preciseCurrency(stats.todayActualCost), caption: "Total \(StatusFormatters.preciseCurrency(stats.totalActualCost))", systemImage: "dollarsign.circle", tint: .purple),
                MetricItem(title: "Today Tokens", value: StatusFormatters.compactNumber(stats.todayTokens), caption: tokenBreakdown(input: stats.todayInputTokens, output: stats.todayOutputTokens), systemImage: "cube", tint: .orange),
                MetricItem(title: "Total Tokens", value: StatusFormatters.compactNumber(stats.totalTokens), caption: tokenBreakdown(input: stats.totalInputTokens, output: stats.totalOutputTokens), systemImage: "archivebox.fill", tint: .indigo),
                MetricItem(title: "Performance", value: "\(StatusFormatters.menuBarRate(stats.rpm)) RPM", caption: "\(StatusFormatters.compactNumber(Int64(stats.tpm))) TPM", systemImage: "bolt", tint: .purple),
                MetricItem(title: "Avg Response", value: latencyText(milliseconds: stats.averageDurationMs), caption: "Average time", systemImage: "clock", tint: .pink),
            ], density: density)
        }

        if let summary = model.snapshot.subscriptionSummary {
            if model.config.dashboardSections.usageMetrics, model.snapshot.stats == nil {
                MetricGrid(items: [
                    MetricItem(title: "Balance", value: balanceText, systemImage: "banknote", tint: .green),
                    MetricItem(title: "Active Subs", value: "\(summary.activeCount)", systemImage: "checkmark.seal", tint: .green),
                    MetricItem(title: "Peak Usage", value: StatusFormatters.percent(summary.highestProgress), systemImage: "gauge.with.dots.needle.67percent", tint: .orange),
                    MetricItem(title: "Total Used", value: StatusFormatters.preciseCurrency(summary.totalUsedUSD), systemImage: "dollarsign.circle", tint: .purple),
                ], density: density)
            }

            if model.config.dashboardSections.subscriptions {
                SectionBlock(title: "Subscriptions", density: density) {
                    VStack(spacing: 10) {
                        ForEach(summary.subscriptions.prefix(5)) { item in
                            SubscriptionQuotaCard(item: item)
                        }
                    }
                }
            }
        }

        if model.config.dashboardSections.modelDistribution,
           let models = model.snapshot.modelDistribution,
           !models.isEmpty {
            ModelDistributionView(models: models, density: density)
        }

        if model.config.dashboardSections.tokenTrend {
            SectionBlock(title: "Token Trend", density: density) {
                TokenTrendSection(state: TokenTrendDisplayState.make(points: model.snapshot.trend))
            }
        }
    }
}
```

- [ ] **Step 4: Add `AlertSummaryView`**

Add near other small dashboard views:

```swift
struct AlertSummaryView: View {
    let alerts: [LocalAlert]
    let density: PanelDensity

    var body: some View {
        SectionBlock(title: "Alerts", density: density) {
            VStack(alignment: .leading, spacing: density == .compact ? 6 : 8) {
                ForEach(Array(alerts.enumerated()), id: \.offset) { _, alert in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title)
                                .font(.callout.weight(.medium))
                            Text(alert.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 5: Build the app**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 6: Commit Task 5**

```bash
git add Sources/Sub2APIStatusBar/Sub2APIStatusBarApp.swift
git commit -m "feat: add local alert controls"
```

## Task 6: Full Verification And MAGI Log

**Files:**
- Modify: `docs/PRODUCT_REVIEW.md`
- Modify: `README.md`
- Modify: `docs/RELEASE_NOTES_v0.1.6.md`

- [ ] **Step 1: Run the focused tests**

```bash
swift test --filter appConfigPersistsLocalAlertPreferences
swift test --filter localAlert
swift test --filter diagnosticReportIncludesLocalAlertState
```

Expected: all PASS.

- [ ] **Step 2: Run the full Swift checks**

```bash
swift test
swift build
```

Expected: both PASS.

- [ ] **Step 3: Run release package verification**

```bash
VERSION=v0.1.6 ./scripts/package-release.sh
VERSION=v0.1.6 ./scripts/verify-release.sh
```

Expected: package script emits `dist/Sub2APIStatusBar-0.1.6-macOS.zip` and `.sha256`; verification reports valid checksum, zip, plist, and signature from a clean extraction.

- [ ] **Step 4: Add a final MAGI cycle entry**

Append to `docs/PRODUCT_REVIEW.md`:

```markdown
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
```

- [ ] **Step 5: Update release notes verification results**

In `docs/RELEASE_NOTES_v0.1.6.md`, keep the command list and add:

```markdown
All commands passed during the v0.1.6 productization verification pass.
```

Only add that sentence after the commands actually pass.

- [ ] **Step 6: Commit final docs**

```bash
git add README.md docs/PRODUCT_REVIEW.md docs/RELEASE_NOTES_v0.1.6.md
git commit -m "docs: record alert productization pass"
```

## Final Completion Criteria

The productization pass is complete when all of these are true:

- The MAGI roadmap spec exists and is committed.
- This implementation plan exists and is committed.
- Release readiness is documented as a matrix.
- Local alert preferences persist through `AppConfig`.
- Alert evaluation is covered by tests in `Sub2APIStatusCoreTests`.
- Alerts affect status labels, details, diagnostics, Settings, and the popover.
- `swift test` passes.
- `swift build` passes.
- `VERSION=v0.1.6 ./scripts/package-release.sh` passes.
- `VERSION=v0.1.6 ./scripts/verify-release.sh` passes.
- `docs/PRODUCT_REVIEW.md` contains MAGI entries for the route and alert implementation.
