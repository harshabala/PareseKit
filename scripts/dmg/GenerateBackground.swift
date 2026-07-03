#!/usr/bin/env swift
// ParseKit DMG background — logical window 640×440 (tauri.conf + create-dmg).
// 1× on purpose: the background PNG's point size MUST equal the create-dmg
// window size (640×440). At 2× the PNG reports as 1280×880 pt, and Retina Finder
// anchors it top-left without fitting, cropping the text to "Drag ParseKit t…".
// At 1×, pixels == points == window, so the instruction line is always centered.
import AppKit
import CoreGraphics

let scale: CGFloat = 1
let windowW: CGFloat = 640
let windowH: CGFloat = 440
let width = windowW * scale
let height = windowH * scale
let margin: CGFloat = 36 * scale

guard
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )
else {
  fputs("Failed to create bitmap\n", stderr)
  exit(1)
}
rep.size = NSSize(width: width, height: height)

guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
  fputs("No graphics context\n", stderr)
  exit(1)
}
ctx.interpolationQuality = .high
ctx.setShouldAntialias(true)
ctx.setAllowsFontSmoothing(true)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

let space = CGColorSpaceCreateDeviceRGB()
let colors = [
  CGColor(red: 0.86, green: 0.80, blue: 0.74, alpha: 1),
  CGColor(red: 0.94, green: 0.90, blue: 0.86, alpha: 1),
  CGColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1),
] as CFArray
if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.5, 1]) {
  ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: 0, y: height),
    options: []
  )
}

func drawCenteredLine(
  _ text: String,
  y: CGFloat,
  font: NSFont,
  color: NSColor,
  maxWidth: CGFloat
) {
  let paragraph = NSMutableParagraphStyle()
  paragraph.alignment = .center
  paragraph.lineBreakMode = .byWordWrapping
  let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: color,
    .paragraphStyle: paragraph,
  ]
  let rect = CGRect(x: margin, y: y, width: maxWidth, height: 200)
  (text as NSString).draw(
    with: rect,
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: attrs
  )
}

let titleFont = NSFont.systemFont(ofSize: 22 * scale, weight: .semibold)
let bodyFont = NSFont.systemFont(ofSize: 12 * scale, weight: .regular)
let monoFont = NSFont.monospacedSystemFont(ofSize: 10.5 * scale, weight: .regular)
let titleColor = NSColor(calibratedRed: 0.20, green: 0.17, blue: 0.14, alpha: 1)
let bodyColor = NSColor(calibratedRed: 0.32, green: 0.28, blue: 0.24, alpha: 1)
let monoColor = NSColor(calibratedRed: 0.22, green: 0.18, blue: 0.15, alpha: 1)
let contentW = width - margin * 2

// Top: drag instruction (above icon row ~y 198)
drawCenteredLine(
  "Drag ParseKit to Applications",
  y: height - margin - 28,
  font: titleFont,
  color: titleColor,
  maxWidth: contentW
)

// Bottom: Gatekeeper note + terminal command (below icon row)
let gatekeeperNote =
  "If macOS blocks first launch, paste this in Terminal after installing:"
let gatekeeperCmd =
  "xattr -cr /Applications/ParseKit.app && xattr -d com.apple.FinderInfo /Applications/ParseKit.app 2>/dev/null || true"

drawCenteredLine(
  gatekeeperNote,
  y: 118,
  font: bodyFont,
  color: bodyColor,
  maxWidth: contentW
)

// Command on a subtle pill
let cmdAttrs: [NSAttributedString.Key: Any] = [
  .font: monoFont,
  .foregroundColor: monoColor,
]
let cmdSize = (gatekeeperCmd as NSString).size(withAttributes: cmdAttrs)
let pillPadH: CGFloat = 12
let pillPadV: CGFloat = 6
let pillW = min(cmdSize.width + pillPadH * 2, contentW)
let pillH = cmdSize.height + pillPadV * 2
let pillX = (width - pillW) / 2
let pillY: CGFloat = 72

let pillPath = NSBezierPath(roundedRect: NSRect(x: pillX, y: pillY, width: pillW, height: pillH), xRadius: 8, yRadius: 8)
NSColor(calibratedWhite: 1, alpha: 0.72).setFill()
pillPath.fill()
NSColor(calibratedRed: 0.55, green: 0.48, blue: 0.42, alpha: 0.55).setStroke()
pillPath.lineWidth = 0.5
pillPath.stroke()

(gatekeeperCmd as NSString).draw(
  at: CGPoint(x: pillX + pillPadH, y: pillY + pillPadV),
  withAttributes: cmdAttrs
)

drawCenteredLine(
  "PDF works out of the box · Word/Excel/images need converters (Settings → File Support)",
  y: 36,
  font: NSFont.systemFont(ofSize: 10.5 * scale, weight: .medium),
  color: bodyColor,
  maxWidth: contentW
)

NSGraphicsContext.restoreGraphicsState()

let outURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  .appendingPathComponent("dmg-background.png")

guard let png = rep.representation(using: .png, properties: [:]) else {
  fputs("Failed to encode PNG\n", stderr)
  exit(1)
}
try png.write(to: outURL)
print("Wrote \(outURL.path) (\(Int(width))×\(Int(height)) px, \(Int(windowW))×\(Int(windowH)) pt window)")