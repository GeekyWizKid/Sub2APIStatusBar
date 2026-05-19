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
    static let backgroundBottom = Color(red: 0.91, green: 0.94, blue: 0.98)
    static let surface = Color(nsColor: .controlBackgroundColor).opacity(0.86)
    static let elevatedSurface = Color(nsColor: .windowBackgroundColor).opacity(0.94)
    static let border = Color.primary.opacity(0.08)
    static let mutedBorder = Color.primary.opacity(0.05)
}

struct PanelBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                PanelColors.backgroundTop,
                Color(red: 0.95, green: 0.97, blue: 0.99),
                PanelColors.backgroundBottom,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
