#!/usr/bin/env swift

import AppKit
import Foundation
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let htmlURL = root.appending(path: "docs/assets/product-preview.html")
let outputURL = root.appending(path: "docs/assets/product-preview.png")
let size = CGSize(width: 1_200, height: 820)

guard FileManager.default.fileExists(atPath: htmlURL.path) else {
    FileHandle.standardError.write(Data("Missing preview HTML: \(htmlURL.path)\n".utf8))
    exit(1)
}

final class PreviewCapture: NSObject, WKNavigationDelegate {
    private let htmlURL: URL
    private let outputURL: URL
    private let size: CGSize
    private let webView: WKWebView

    init(htmlURL: URL, outputURL: URL, size: CGSize) {
        self.htmlURL = htmlURL
        self.outputURL = outputURL
        self.size = size
        webView = WKWebView(frame: CGRect(origin: .zero, size: size))
        super.init()
        webView.navigationDelegate = self
    }

    func start() {
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.capture()
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        fail(error)
    }

    private func capture() {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(origin: .zero, size: size)
        webView.takeSnapshot(with: configuration) { image, error in
            if let error {
                self.fail(error)
            }

            guard let image,
                  let bitmap = self.bitmap(from: image),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                self.fail(CocoaError(.fileWriteUnknown))
                return
            }

            do {
                try png.write(to: self.outputURL, options: .atomic)
                print(self.outputURL.path)
                exit(0)
            } catch {
                self.fail(error)
            }
        }
    }

    private func bitmap(from image: NSImage) -> NSBitmapImageRep? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return bitmap
    }

    private func fail(_ error: Error) -> Never {
        FileHandle.standardError.write(Data("Preview capture failed: \(error.localizedDescription)\n".utf8))
        exit(1)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let capture = PreviewCapture(htmlURL: htmlURL, outputURL: outputURL, size: size)
capture.start()
app.run()
