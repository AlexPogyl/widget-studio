// Generates Resources/AppIcon.icns for Widget Studio.
//
//     swift tools/MakeIcon.swift
//
// The icon mirrors the app itself: a dark squircle with the clock widget card
// (light ring + big oblique digits) in the middle.

import AppKit
import CoreGraphics
import CoreText
import Foundation

// MARK: - Drawing

func drawIcon(size: CGFloat, into context: CGContext) {
    let canvas = CGRect(x: 0, y: 0, width: size, height: size)

    // macOS icons keep a margin around the squircle.
    let contentInset = size * 0.098
    let content = canvas.insetBy(dx: contentInset, dy: contentInset)
    let corner = content.width * 0.2237

    let squircle = CGPath(roundedRect: content, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Soft drop shadow under the squircle, like the system icons have.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.015),
                      blur: size * 0.035,
                      color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45))
    context.addPath(squircle)
    context.setFillColor(CGColor(srgbRed: 0.05, green: 0.05, blue: 0.06, alpha: 1))
    context.fillPath()
    context.restoreGState()

    // Background of the icon.
    context.saveGState()
    context.addPath(squircle)
    context.clip()
    let background = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                               colors: [CGColor(srgbRed: 0.22, green: 0.22, blue: 0.25, alpha: 1),
                                        CGColor(srgbRed: 0.05, green: 0.05, blue: 0.06, alpha: 1)] as CFArray,
                               locations: [0, 1])!
    context.drawLinearGradient(background,
                               start: CGPoint(x: content.midX, y: content.maxY),
                               end: CGPoint(x: content.midX, y: content.minY),
                               options: [])
    context.restoreGState()

    // Specular edge, like the system icons have.
    context.saveGState()
    context.addPath(squircle)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18))
    context.setLineWidth(max(size * 0.006, 1))
    context.strokePath()
    context.restoreGState()

    // The widget card.
    let cardSize = content.width * 0.70
    let card = CGRect(x: content.midX - cardSize / 2,
                      y: content.midY - cardSize / 2,
                      width: cardSize,
                      height: cardSize)
    let cardRadius = cardSize * 0.2237
    let cardPath = CGPath(roundedRect: card, cornerWidth: cardRadius, cornerHeight: cardRadius, transform: nil)

    context.saveGState()
    context.addPath(cardPath)
    context.clip()
    let cardGradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  colors: [CGColor(srgbRed: 0.106, green: 0.114, blue: 0.129, alpha: 1),
                                           CGColor(srgbRed: 0.063, green: 0.063, blue: 0.063, alpha: 1)] as CFArray,
                                  locations: [0, 1])!
    context.drawLinearGradient(cardGradient,
                               start: CGPoint(x: card.midX, y: card.maxY),
                               end: CGPoint(x: card.midX, y: card.minY),
                               options: [])
    context.restoreGState()

    // Card ring.
    context.saveGState()
    context.addPath(cardPath)
    context.setStrokeColor(CGColor(srgbRed: 0.81, green: 0.81, blue: 0.82, alpha: 1))
    context.setLineWidth(cardSize * 0.0506)
    context.strokePath()
    context.restoreGState()

    // Digits, rendered exactly like the widget: SF Pro Black, oblique.
    let capHeight = cardSize * 0.310
    let fontSize = capHeight / 0.70
    let gap = cardSize * 0.022
    let font = NSFont.systemFont(ofSize: fontSize, weight: .black)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 0.80, green: 0.80, blue: 0.81, alpha: 1)
    ]

    let lines = ["17", "45"]
    let blockHeight = capHeight * CGFloat(lines.count) + gap
    let blockBottom = card.midY - blockHeight / 2

    for (index, text) in lines.enumerated() {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let row = lines.count - 1 - index
        let baseline = blockBottom + CGFloat(row) * (capHeight + gap)

        context.saveGState()
        context.translateBy(x: card.midX - width / 2, y: baseline)
        // y grows upwards here, so a positive shear leans the digits to the right.
        context.concatenate(CGAffineTransform(a: 1, b: 0, c: tan(10 * .pi / 180), d: 1, tx: 0, ty: 0))
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }
}

func renderIcon(size: CGFloat) -> CGImage? {
    let pixels = Int(size)
    guard let context = CGContext(data: nil,
                                  width: pixels,
                                  height: pixels,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)
    drawIcon(size: size, into: context)
    return context.makeImage()
}

// MARK: - Icon set

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
let output = root.appendingPathComponent("Resources/AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for variant in variants {
    guard let image = renderIcon(size: variant.size) else {
        FileHandle.standardError.write("failed to render \(variant.name)\n".data(using: .utf8)!)
        exit(1)
    }
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
    try data.write(to: iconset.appendingPathComponent("\(variant.name).png"))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
try FileManager.default.createDirectory(at: root.appendingPathComponent("Resources"), withIntermediateDirectories: true)
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try process.run()
process.waitUntilExit()
print(process.terminationStatus == 0 ? "wrote \(output.path)" : "iconutil failed")
