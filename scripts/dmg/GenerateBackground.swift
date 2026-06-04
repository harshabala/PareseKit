#!/usr/bin/env swift
// ParseKit DMG background @2x (1280×880) — Cocoa bitmap coords: origin bottom-left, y ↑
import AppKit
import CoreGraphics

let width: CGFloat = 1280
let height: CGFloat = 880

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

// Gradient (bottom → top)
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

func drawSingleLine(
  _ text: String,
  in rect: CGRect,
  size: CGFloat,
  weight: NSFont.Weight,
  color: NSColor,
  align: NSTextAlignment
) {
  let para = NSMutableParagraphStyle()
  para.alignment = align
  para.lineBreakMode = .byTruncatingTail
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

// --- Layout (y = distance from bottom of image) ---
let marginX: CGFloat = 100
let centerX = width / 2

// Top title pill (near top of window → high y)
let title = "Drag ParseKit to Applications"
let pillW: CGFloat = 960
let pillH: CGFloat = 76
let pillX = centerX - pillW / 2
let pillY: CGFloat = height - 56 - pillH
fillRoundedRect(
  CGRect(x: pillX, y: pillY, width: pillW, height: pillH),
  radius: pillH / 2,
  fill: CGColor(red: 1, green: 1, blue: 1, alpha: 0.82),
  stroke: CGColor(red: 1, green: 1, blue: 1, alpha: 0.95)
)
drawSingleLine(
  title,
  in: CGRect(x: pillX + 28, y: pillY + 20, width: pillW - 56, height: pillH - 28),
  size: 32,
  weight: .semibold,
  color: NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.14, alpha: 1),
  align: .center
)

drawSingleLine(
  "Eject this disk, then open ParseKit from Applications",
  in: CGRect(x: marginX, y: pillY - 52, width: width - marginX * 2, height: 40),
  size: 21,
  weight: .regular,
  color: NSColor(calibratedRed: 0.34, green: 0.30, blue: 0.26, alpha: 0.95),
  align: .center
)

// Center card (icon drop zone)
let cardW: CGFloat = 1040
let cardH: CGFloat = 380
let cardX = centerX - cardW / 2
let cardY: CGFloat = 200
fillRoundedRect(
  CGRect(x: cardX, y: cardY, width: cardW, height: cardH),
  radius: 36,
  fill: CGColor(red: 1, green: 1, blue: 1, alpha: 0.52),
  stroke: CGColor(red: 1, green: 1, blue: 1, alpha: 0.72)
)

// Chevrons — centered between icon columns (155 & 465 @1x → 310 & 930 @2x)
let chevronAttrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 48, weight: .bold),
  .foregroundColor: NSColor(calibratedRed: 0.40, green: 0.36, blue: 0.32, alpha: 0.42),
  .kern: 10,
]
let chevrons = NSAttributedString(string: "›   ›   ›", attributes: chevronAttrs)
let chevronSize = chevrons.size()
let chevronCenterY = cardY + cardH * 0.52
chevrons.draw(at: CGPoint(x: centerX - chevronSize.width / 2, y: chevronCenterY - chevronSize.height / 2))

// Footer (bottom of window → low y)
drawSingleLine(
  "Opens from the menu bar — look for ParseKit (top-right)",
  in: CGRect(x: marginX, y: 44, width: width - marginX * 2, height: 32),
  size: 18,
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
print("Wrote \(outURL.path)")