import AppKit
import SwiftUI
import Sub2APIStatusCore

struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
            content
                .padding(12)
                .background(PanelColors.surface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PanelColors.border, lineWidth: 1)
                )
        }
    }
}

enum PanelColors {
    static let backgroundTop = Color(nsColor: .windowBackgroundColor)
    static let backgroundMid = Color(
        light: Color(red: 0.96, green: 0.98, blue: 1.0),
        dark: Color(red: 0.14, green: 0.15, blue: 0.17)
    )
    static let backgroundBottom = Color(
        light: Color(red: 0.91, green: 0.94, blue: 0.98),
        dark: Color(red: 0.09, green: 0.10, blue: 0.12)
    )
    static let surface = Color(
        light: Color(nsColor: .controlBackgroundColor).opacity(0.86),
        dark: Color(red: 0.18, green: 0.19, blue: 0.21).opacity(0.94)
    )
    static let elevatedSurface = Color(
        light: Color(nsColor: .windowBackgroundColor).opacity(0.94),
        dark: Color(red: 0.13, green: 0.14, blue: 0.16).opacity(0.98)
    )
    static let heroSurfaceStart = Color(
        light: Color(nsColor: .controlBackgroundColor).opacity(0.96),
        dark: Color(red: 0.20, green: 0.21, blue: 0.23)
    )
    static let heroSurfaceEnd = Color(
        light: Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.64),
        dark: Color(red: 0.12, green: 0.15, blue: 0.18)
    )
    static let softFill = Color(
        light: Color.primary.opacity(0.035),
        dark: Color.white.opacity(0.055)
    )
    static let border = Color(
        light: Color.primary.opacity(0.08),
        dark: Color.white.opacity(0.10)
    )
    static let mutedBorder = Color(
        light: Color.primary.opacity(0.05),
        dark: Color.white.opacity(0.07)
    )
}

struct PanelBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                PanelColors.backgroundTop,
                PanelColors.backgroundMid,
                PanelColors.backgroundBottom,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            switch bestMatch {
            case .darkAqua:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.13), in: Capsule())
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}

struct MessageRow: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(PanelColors.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PanelColors.border, lineWidth: 1)
        )
    }
}

struct RecoverySuggestionCard: View {
    let suggestion: RecoverySuggestion
    let perform: (RecoveryActionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.callout.weight(.semibold))
                    Text(suggestion.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                ForEach(suggestion.actions) { action in
                    Button {
                        perform(action.kind)
                    } label: {
                        Label(action.label, systemImage: action.systemImage)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(10)
        .background(PanelColors.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PanelColors.border, lineWidth: 1)
        )
    }
}
