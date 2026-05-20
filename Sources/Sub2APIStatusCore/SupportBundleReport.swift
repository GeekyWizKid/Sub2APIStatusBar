import Foundation

public enum SupportBundleReport {
    public static func make(
        config: AppConfig,
        snapshot: MonitorSnapshot,
        appVersion: String,
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        installSource: String = "GitHub Release / Homebrew Cask draft / built from source"
    ) -> String {
        let diagnostics = DiagnosticReport.make(
            config: config,
            snapshot: snapshot,
            appVersion: appVersion,
            osVersion: osVersion
        )

        let lines = [
            "# Sub2API Status Bar Support Bundle",
            "",
            "Review this bundle for secrets before posting it to a GitHub issue.",
            "",
            "Do not attach `config.json`, access tokens, refresh tokens, passwords, private server logs, full Application Support directories, release archives, or crash dumps that have not been reviewed for secrets.",
            "",
            "## Diagnostics",
            "",
            "```text",
            diagnostics,
            "```",
            "",
            "## Environment",
            "",
            "- App version: \(appVersion)",
            "- macOS version: \(osVersion)",
            "- Sub2API server version or commit, if known:",
            "- Install source: \(installSource)",
            "- Release asset name, if applicable:",
            "- Release asset SHA-256 verification result, if applicable:",
            "",
            "## Reproduction",
            "",
            "1.",
            "2.",
            "3.",
            "",
            "## Expected Behavior",
            "",
            "What did you expect to happen?",
            "",
            "## Actual Behavior",
            "",
            "What happened instead?",
            "",
            "## Recent Changes",
            "",
            "- Did login, manual token setup, refresh, update checking, or installation work before?",
            "- Did this begin after changing Sub2API server version, app version, account, network, or macOS settings?",
            "",
            "## Local Checks",
            "",
            "- [ ] Diagnostics report contains token presence only, not token values.",
            "- [ ] No `config.json` content is included.",
            "- [ ] No access token, refresh token, password, private server URL, or private log is included.",
            "- [ ] Release archive checksums were verified before reporting an installation issue.",
        ]

        return lines.joined(separator: "\n")
    }
}
