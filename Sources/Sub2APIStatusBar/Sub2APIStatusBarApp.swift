import AppKit
import ServiceManagement
import SwiftUI
import Sub2APIStatusCore

@main
struct Sub2APIStatusBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let model = MonitorViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "Sub2API")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 680)
        popover.contentViewController = NSHostingController(rootView: MonitorPanel(model: model))

        model.onSnapshotChange = { [weak self] snapshot in
            self?.updateStatusItem(snapshot)
        }
        model.start()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateStatusItem(_ snapshot: MonitorSnapshot) {
        guard let button = statusItem.button else {
            return
        }

        let severity = snapshot.severity(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds)
        let statusLabel = snapshot.statusLabel(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds)

        switch severity {
        case .healthy:
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Sub2API OK")
        case .warning:
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Sub2API Warning")
        case .error:
            button.image = NSImage(systemSymbolName: "xmark.octagon", accessibilityDescription: "Sub2API Error")
        }
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.title = snapshot.connected && model.config.showsMenuBarText
            ? " \(snapshot.menuBarSummary(now: model.now, refreshIntervalSeconds: model.config.refreshIntervalSeconds))"
            : ""

        if let stats = snapshot.stats, snapshot.connected {
            button.toolTip = "Sub2API \(statusLabel) - Today \(StatusFormatters.currency(stats.todayActualCost)), RPM \(String(format: "%.1f", stats.rpm))"
        } else {
            button.toolTip = "Sub2API \(statusLabel)"
        }
    }
}
