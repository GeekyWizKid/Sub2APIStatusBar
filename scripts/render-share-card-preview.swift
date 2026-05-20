#!/usr/bin/env swift

import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appending(path: "dist/share-card-preview.png")

let size = CGSize(width: 900, height: 1_125)
let scale: CGFloat = 2
let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(pixelSize.width),
    pixelsHigh: Int(pixelSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("Could not allocate preview bitmap.\n".utf8))
    exit(1)
}

bitmap.size = size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
PreviewCanvas(size: size).draw()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not encode preview PNG.\n".utf8))
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL, options: .atomic)
print(outputURL.path)

private struct PreviewCanvas {
    let size: CGSize

    private let margin: CGFloat = 56
    private var contentWidth: CGFloat { size.width - margin * 2 }

    func draw() {
        drawPaper()
        drawPattern()
        drawHeader()
        drawHero()
        drawTrendSticker()
        drawReceiptRows()
        drawFooter()
    }

    private func drawPaper() {
        let bounds = CGRect(origin: .zero, size: size)
        NSGradient(colors: [
            NSColor(red: 1.000, green: 0.957, blue: 0.820, alpha: 1),
            NSColor(red: 0.965, green: 0.860, blue: 0.690, alpha: 1),
        ])?.draw(in: bounds, angle: -42)

        drawRadialGlow(center: CGPoint(x: 760, y: 168), radius: 260, color: .coral.withAlphaComponent(0.22))
        drawRadialGlow(center: CGPoint(x: 170, y: 105), radius: 210, color: .sun.withAlphaComponent(0.18))
        drawRoundedRect(
            CGRect(x: 26, y: 26, width: size.width - 52, height: size.height - 52),
            radius: 24,
            fill: .clear,
            stroke: .ink.withAlphaComponent(0.18),
            lineWidth: 1.5
        )
    }

    private func drawPattern() {
        NSColor.sun.withAlphaComponent(0.62).setFill()
        for y in stride(from: CGFloat(76), through: size.height - 92, by: 54) {
            for x in stride(from: CGFloat(52), through: size.width - 52, by: 54) {
                let offset = Int(y / 48).isMultiple(of: 2) ? CGFloat(0) : CGFloat(24)
                NSBezierPath(ovalIn: topRect(CGRect(x: x + offset, y: y, width: 7, height: 7))).fill()
            }
        }

        NSColor.ink.withAlphaComponent(0.035).setFill()
        for y in stride(from: CGFloat(0), through: size.height, by: 28) {
            CGRect(x: 0, y: size.height - y, width: size.width, height: 1).fill()
        }
    }

    private func drawHeader() {
        drawText(
            "Sub2API",
            in: CGRect(x: margin, y: 58, width: 180, height: 34),
            font: .rounded(size: 22, weight: .heavy),
            color: .ink
        )

        let pill = CGRect(x: size.width - margin - 152, y: 54, width: 152, height: 38)
        drawCapsule(rect: pill, fill: .clear, stroke: .ink, lineWidth: 2)
        drawText(
            "BUILD LOG",
            in: pill.insetBy(dx: 16, dy: 10),
            font: .rounded(size: 12, weight: .heavy),
            color: .ink,
            alignment: .center,
            letterSpacing: 0.6
        )
    }

    private func drawHero() {
        drawText(
            "126.4M",
            in: CGRect(x: margin, y: 170, width: contentWidth * 0.86, height: 146),
            font: .rounded(size: 142, weight: .heavy),
            color: .ink,
            fitWidth: true
        )
        drawText(
            "The AI work counter for today.",
            in: CGRect(x: margin + 2, y: 342, width: 540, height: 72),
            font: .rounded(size: 32, weight: .bold),
            color: .ink,
            lineBreakMode: .byWordWrapping
        )
    }

    private func drawTrendSticker() {
        let sticker = CGRect(x: 658, y: 332, width: 168, height: 118)
        drawRoundedRect(sticker.offsetBy(dx: 8, dy: 8), radius: 19, fill: .ink, stroke: nil)
        drawRoundedRect(sticker, radius: 19, fill: .mint, stroke: .ink, lineWidth: 2.5)
        drawText(
            "+33%",
            in: CGRect(x: sticker.minX + 18, y: sticker.minY + 20, width: sticker.width - 36, height: 42),
            font: .rounded(size: 32, weight: .heavy),
            color: .ink,
            alignment: .center,
            fitWidth: true
        )
        drawText(
            "vs 6-day avg",
            in: CGRect(x: sticker.minX + 14, y: sticker.minY + 66, width: sticker.width - 28, height: 34),
            font: .rounded(size: 13, weight: .bold),
            color: .ink.withAlphaComponent(0.66),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
    }

    private func drawReceiptRows() {
        let top: CGFloat = 704
        let rows = [
            ("Spend", "$117.57"),
            ("Model", "gpt-5.5"),
            ("Requests", "1186"),
            ("Quota", "93% quota"),
        ]

        for (index, row) in rows.enumerated() {
            drawReceiptRow(
                label: row.0,
                value: row.1,
                rect: CGRect(x: margin, y: top + CGFloat(index) * 64, width: contentWidth, height: 48)
            )
        }
    }

    private func drawReceiptRow(label: String, value: String, rect: CGRect) {
        drawDashedRule(y: rect.maxY, from: rect.minX, to: rect.maxX)
        drawText(
            label,
            in: CGRect(x: rect.minX, y: rect.minY + 4, width: rect.width * 0.42, height: 30),
            font: .rounded(size: 22, weight: .bold),
            color: .ink.withAlphaComponent(0.58)
        )
        drawText(
            value,
            in: CGRect(x: rect.minX + rect.width * 0.42, y: rect.minY + 2, width: rect.width * 0.58, height: 34),
            font: .rounded(size: 24, weight: .heavy),
            color: .ink,
            alignment: .right,
            fitWidth: true
        )
    }

    private func drawFooter() {
        drawText(
            "No prompts. No keys.",
            in: CGRect(x: margin, y: 1_018, width: contentWidth * 0.48, height: 22),
            font: .rounded(size: 14, weight: .bold),
            color: .ink.withAlphaComponent(0.56)
        )
        drawText(
            "May 20, 2026 at 9:14 PM",
            in: CGRect(x: margin + contentWidth * 0.48, y: 1_018, width: contentWidth * 0.52, height: 22),
            font: .rounded(size: 14, weight: .bold),
            color: .ink.withAlphaComponent(0.56),
            alignment: .right
        )
        drawText(
            "#AIUsage  #BuildInPublic",
            in: CGRect(x: margin, y: 1_058, width: contentWidth, height: 24),
            font: .rounded(size: 18, weight: .heavy),
            color: .ink
        )
    }

    private func drawDashedRule(y: CGFloat, from minX: CGFloat, to maxX: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = 2
        path.setLineDash([8, 8], count: 2, phase: 0)
        path.move(to: topPoint(CGPoint(x: minX, y: y)))
        path.line(to: topPoint(CGPoint(x: maxX, y: y)))
        NSColor.ink.withAlphaComponent(0.24).setStroke()
        path.stroke()
    }

    private func drawRadialGlow(center: CGPoint, radius: CGFloat, color: NSColor) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        let actualCenter = CGPoint(x: center.x, y: size.height - center.y)
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
            locations: [0, 1]
        )
        guard let gradient else {
            return
        }
        context.saveGState()
        context.drawRadialGradient(
            gradient,
            startCenter: actualCenter,
            startRadius: 0,
            endCenter: actualCenter,
            endRadius: radius,
            options: []
        )
        context.restoreGState()
    }

    private func drawText(
        _ text: String,
        in rect: CGRect,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment = .left,
        letterSpacing: CGFloat = 0,
        lineBreakMode: NSLineBreakMode = .byTruncatingTail,
        fitWidth: Bool = false
    ) {
        let font = fitWidth ? fittedFont(font, text: text, width: rect.width) : font
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = lineBreakMode
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
                .kern: letterSpacing,
            ]
        ).draw(with: topRect(rect), options: [.usesLineFragmentOrigin, .usesFontLeading])
    }

    private func fittedFont(_ font: NSFont, text: String, width: CGFloat) -> NSFont {
        var size = font.pointSize
        while size > 10 {
            let candidate = NSFont.rounded(size: size, weight: font.weight)
            let textWidth = (text as NSString).size(withAttributes: [.font: candidate]).width
            if textWidth <= width {
                return candidate
            }
            size -= 1
        }
        return NSFont.rounded(size: size, weight: font.weight)
    }

    private func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor?, lineWidth: CGFloat = 1) {
        let path = NSBezierPath(roundedRect: topRect(rect), xRadius: radius, yRadius: radius)
        if fill.alphaComponent > 0 {
            fill.setFill()
            path.fill()
        }
        if let stroke {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    private func drawCapsule(rect: CGRect, fill: NSColor, stroke: NSColor?, lineWidth: CGFloat = 1) {
        drawRoundedRect(rect, radius: rect.height / 2, fill: fill, stroke: stroke, lineWidth: lineWidth)
    }

    private func topRect(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: size.height - rect.maxY, width: rect.width, height: rect.height)
    }

    private func topPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: size.height - point.y)
    }
}

private extension NSFont {
    static func rounded(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return NSFont(descriptor: descriptor, size: size) ?? base
    }

    var weight: NSFont.Weight {
        let traits = fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any]
        let value = traits?[.weight] as? CGFloat ?? NSFont.Weight.regular.rawValue
        return NSFont.Weight(value)
    }
}

private extension NSColor {
    static let ink = NSColor(red: 0.082, green: 0.071, blue: 0.059, alpha: 1)
    static let sun = NSColor(red: 1.000, green: 0.898, blue: 0.345, alpha: 1)
    static let mint = NSColor(red: 0.482, green: 1.000, blue: 0.824, alpha: 1)
    static let coral = NSColor(red: 1.000, green: 0.305, blue: 0.184, alpha: 1)
}
