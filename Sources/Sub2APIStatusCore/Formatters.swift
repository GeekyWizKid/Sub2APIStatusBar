import Foundation

public enum StatusFormatters {
    public static func compactNumber(_ value: Int64) -> String {
        let number = Double(value)
        if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        }
        if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        }
        return String(value)
    }

    public static func menuBarCount(_ value: Int64) -> String {
        if value < 10_000 {
            return String(value)
        }
        return compactNumber(value)
    }

    public static func menuBarRate(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    public static func currency(_ value: Double) -> String {
        if value < 0.01, value > 0 {
            return String(format: "$%.4f", value)
        }
        return String(format: "$%.2f", value)
    }

    public static func preciseCurrency(_ value: Double) -> String {
        String(format: "$%.4f", value)
    }

    public static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", min(max(value, 0), 1) * 100)
    }

    public static func duration(seconds: Double) -> String {
        let seconds = Int(seconds)
        if seconds >= 86_400 {
            return "\(seconds / 86_400)d"
        }
        if seconds >= 3_600 {
            return "\(seconds / 3_600)h"
        }
        if seconds >= 60 {
            return "\(seconds / 60)m"
        }
        return "\(seconds)s"
    }
}
