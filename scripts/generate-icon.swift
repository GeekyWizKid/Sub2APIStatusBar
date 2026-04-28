#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appending(path: "Resources", directoryHint: .isDirectory)
let iconset = resources.appending(path: "AppIcon.iconset", directoryHint: .isDirectory)
let icns = resources.appending(path: "AppIcon.icns")

try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func drawIcon(size: Int) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let scale = CGFloat(size)
    let canvas = CGRect(x: 0, y: 0, width: scale, height: scale)
    context.clear(canvas)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let backgroundRect = canvas.insetBy(dx: scale * 0.035, dy: scale * 0.035)
    let backgroundPath = CGPath(roundedRect: backgroundRect, cornerWidth: scale * 0.22, cornerHeight: scale * 0.22, transform: nil)
    context.addPath(backgroundPath)
    context.clip()

    let gradientColors = [
        CGColor(red: 0.02, green: 0.16, blue: 0.22, alpha: 1),
        CGColor(red: 0.03, green: 0.39, blue: 0.35, alpha: 1),
        CGColor(red: 0.10, green: 0.60, blue: 0.45, alpha: 1),
    ] as CFArray
    let locations: [CGFloat] = [0, 0.55, 1]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations)!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: scale),
        end: CGPoint(x: scale, y: 0),
        options: []
    )
    context.resetClip()

    context.addPath(backgroundPath)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
    context.setLineWidth(scale * 0.025)
    context.strokePath()

    let ringInset = scale * 0.16
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.16))
    context.setLineWidth(scale * 0.045)
    context.strokeEllipse(in: canvas.insetBy(dx: ringInset, dy: ringInset))

    context.setStrokeColor(CGColor(red: 0.18, green: 0.92, blue: 0.55, alpha: 1))
    context.setLineWidth(scale * 0.11)
    context.setLineCap(.round)
    context.addArc(
        center: CGPoint(x: canvas.midX, y: canvas.midY),
        radius: scale * 0.28,
        startAngle: 220 * .pi / 180,
        endAngle: 520 * .pi / 180,
        clockwise: false
    )
    context.strokePath()

    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: scale * 0.55, y: scale * 0.72))
    bolt.addLine(to: CGPoint(x: scale * 0.34, y: scale * 0.47))
    bolt.addLine(to: CGPoint(x: scale * 0.51, y: scale * 0.47))
    bolt.addLine(to: CGPoint(x: scale * 0.44, y: scale * 0.25))
    bolt.addLine(to: CGPoint(x: scale * 0.68, y: scale * 0.55))
    bolt.addLine(to: CGPoint(x: scale * 0.50, y: scale * 0.55))
    bolt.closeSubpath()
    context.addPath(bolt)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    guard let image = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return png
}

for variant in variants {
    let data = try drawIcon(size: variant.pixels)
    try data.write(to: iconset.appending(path: variant.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", "-o", icns.path, iconset.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw CocoaError(.fileWriteUnknown)
}

print(icns.path)
