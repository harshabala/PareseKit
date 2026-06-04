#!/usr/bin/env swift
// ParseKit DMG background @2x — must match bundle.macOS.dmg windowSize 640×440 (→ 1280×880).
import AppKit
import CoreGraphics

// Keep in sync with src-tauri/tauri.conf.json → bundle.macOS.dmg.windowSize
let windowW: CGFloat = 640
let windowH: CGFloat = 440
let scale: CGFloat = 2
let width = windowW * scale
let height = windowH * scale
let marginX = scale * 32 // 32px inset at 1x (≥24px)

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
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

let space = CGColorSpaceCreateDeviceRGB()
let colors = [
  CGColor(red: 0.84, green: 0.78, blue: 0.72, alpha: 1),
  CGColor(red: 0.91, green: 0.87, blue: 0.81, alpha: 1),
  CGColor(red: 0.97, green: 0.94, blue: 0.90, alpha: 1),
] as CFArray
if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.45, 1]) {
  ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: 0, y: height),
    options: []
  )
}

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, fill: CGColor, stroke: CGColor?) {
  let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
  ctx.addPath(path)
  ctx.setFillColor(fill)
  ctx.fillPath()
  if let stroke {
    ctx.addPath(path)
    ctx.setStrokeColor(stroke)
    ctx.setLineWidth(2)
    ctx.strokePath()
  }
}

func drawWrapped(
  _ text: String,
  in rect: CGRect,
  size: CGFloat,
  weight: NSFont.Weight,
  color: NSColor,
  align: NSTextAlignment
) {
  let para = NSMutableParagraphStyle()
  para.alignment = align
  para.lineBreakMode = .byWordWrapping
  let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: size, weight: weight),
    .foregroundColor: color,
    .paragraphStyle: para,
  ]
  (text as NSString).draw(
    with: rect,
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: attrs
  )
}

let centerX = width / 2
let contentW = width - marginX * 2

// Title pill (top)
let title = "Drag ParseKit to Applications"
let pillW = min(contentW, scale * 520)
let pillH: CGFloat = scale * 44
let pillX = centerX - pillW / 2
let pillY: CGFloat = height - scale * 28 - pillH
fillRoundedRect(
  CGRect(x: pillX, y: pillY, width: pillW, height: pillH),
  radius: pillH / 2,
  fill: CGColor(red: 1, green: 1, blue: 1, alpha: 0.82),
  stroke: CGColor(red: 1, green: 1, blue: 1, alpha: 0.95)
)
drawWrapped(
  title,
  in: CGRect(x: pillX + scale * 16, y: pillY + scale * 8, width: pillW - scale * 32, height: pillH - scale * 12),
  size: scale * 15,
  weight: .semibold,
  color: NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.14, alpha: 1),
  align: .center
)

// Instruction (below title, wrapped — no truncation)
let instruction = "Eject this disk, then open ParseKit from Applications"
let instructionH: CGFloat = scale * 44
drawWrapped(
  instruction,
  in: CGRect(x: marginX, y: pillY - instructionH - scale * 8, width: contentW, height: instructionH),
  size: scale * 11,
  weight: .regular,
  color: NSColor(calibratedRed: 0.34, green: 0.30, blue: 0.26, alpha: 0.95),
  align: .center
)

// Center card (icon drop zone) — aligns with --icon 178 & --app-drop-link 478 @1x
let cardW: CGFloat = scale * 520
let cardH: CGFloat = scale * 190
let cardX = centerX - cardW / 2
let cardY: CGFloat = scale * 100
fillRoundedRect(
  CGRect(x: cardX, y: cardY, width: cardW, height: cardH),
  radius: scale * 18,
  fill: CGColor(red: 1, green: 1, blue: 1, alpha: 0.52),
  stroke: CGColor(red: 1, green: 1, blue: 1, alpha: 0.72)
)

let chevronAttrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: scale * 24, weight: .bold),
  .foregroundColor: NSColor(calibratedRed: 0.40, green: 0.36, blue: 0.32, alpha: 0.42),
  .kern: scale * 5,
]
let chevrons = NSAttributedString(string: "›   ›   ›", attributes: chevronAttrs)
let chevronSize = chevrons.size()
let chevronCenterY = cardY + cardH * 0.52
chevrons.draw(at: CGPoint(x: centerX - chevronSize.width / 2, y: chevronCenterY - chevronSize.height / 2))

// Footer
let footer = "Opens from the menu bar — look for ParseKit (top-right)"
drawWrapped(
  footer,
  in: CGRect(x: marginX, y: scale * 22, width: contentW, height: scale * 36),
  size: scale * 10,
  weight: .regular,
  color: NSColor(calibratedRed: 0.38, green: 0.34, blue: 0.30, alpha: 0.85),
  align: .center
)

NSGraphicsContext.restoreGraphicsState()

let outURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  .appendingPathComponent("dmg-background.png")

guard let png = rep.representation(using: .png, properties: [:]) else {
  fputs("Failed to encode PNG\n", stderr)
  exit(1)
}
try png.write(to: outURL)
print("Wrote \(outURL.path) (\(Int(width))×\(Int(height)) @2x for \(Int(windowW))×\(Int(windowH)) window)")