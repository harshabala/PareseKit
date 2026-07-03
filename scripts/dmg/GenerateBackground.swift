#!/usr/bin/env swift
// ParseKit DMG backgrounds — locked coordinate contract (720×460 logical @1x).
//
// Window (logical):     720 × 460
// Icon size:            128
// ParseKit center:      (190, 172)
// Applications center:  (530, 172)
// Dead zone per icon:   160×160 centered on each position (no art — Finder draws labels)
// Top text zone:        y 20–75
// Terminal zone:        y 290–415, x 40–680
//
// Exports:
//   background.png     720×460   (1×)
//   background@2x.png  1440×920  (2× Retina)

import AppKit
import CoreGraphics

let windowW: CGFloat = 720
let windowH: CGFloat = 460

// Locked icon centers (1× logical points) — must match build-dmg.sh / tauri.conf.json
let parseKitCenter = CGPoint(x: 190, y: 172)
let applicationsCenter = CGPoint(x: 530, y: 172)
let iconDeadRadius: CGFloat = 80 // 160×160 box

// Design palette
let navy = NSColor(calibratedRed: 0.071, green: 0.090, blue: 0.169, alpha: 1)      // #12172B
let plum = NSColor(calibratedRed: 0.141, green: 0.102, blue: 0.208, alpha: 1)     // #241A35
let ivory = NSColor(calibratedRed: 0.961, green: 0.945, blue: 0.910, alpha: 1)    // #F5F1E8
let warmGray = NSColor(calibratedRed: 0.690, green: 0.659, blue: 0.612, alpha: 1) // #B0A89C
let gold = NSColor(calibratedRed: 0.851, green: 0.659, blue: 0.424, alpha: 1)      // #D9A86C
let termBg = NSColor(calibratedRed: 0.043, green: 0.055, blue: 0.102, alpha: 1) // #0B0E1A
let termBorder = NSColor(calibratedRed: 0.227, green: 0.208, blue: 0.314, alpha: 1) // #3A3550
let termGreen = NSColor(calibratedRed: 0.561, green: 0.890, blue: 0.639, alpha: 1) // #8FE3A3

/// Convert top-left layout Y (y grows downward) to Cocoa bottom-left Y for a top edge.
func topY(_ yFromTop: CGFloat, scale: CGFloat) -> CGFloat {
  (windowH - yFromTop) * scale
}

func rectFromTop(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, scale: CGFloat) -> NSRect {
  NSRect(x: x * scale, y: topY(y + h, scale: 1) * scale, width: w * scale, height: h * scale)
}

func drawBackground(scale: CGFloat) -> NSBitmapImageRep? {
  let width = windowW * scale
  let height = windowH * scale

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
  else { return nil }

  rep.size = NSSize(width: width, height: height)
  guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else { return nil }
  ctx.interpolationQuality = .high
  ctx.setShouldAntialias(true)
  ctx.setAllowsFontSmoothing(true)

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

  // Diagonal gradient: navy (top-left) → plum (bottom-right)
  let space = CGColorSpaceCreateDeviceRGB()
  let colors = [navy.cgColor, plum.cgColor] as CFArray
  if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
    ctx.drawLinearGradient(
      gradient,
      start: CGPoint(x: 0, y: height),
      end: CGPoint(x: width, y: 0),
      options: []
    )
  }

  func drawCenteredText(
    _ text: String,
    yFromTop: CGFloat,
    font: NSFont,
    color: NSColor,
    maxWidth: CGFloat,
    height: CGFloat = 60
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: paragraph,
    ]
    let margin: CGFloat = 40 * scale
    let rect = NSRect(
      x: margin,
      y: topY(yFromTop + height, scale: 1) * scale,
      width: maxWidth * scale,
      height: height * scale
    )
    (text as NSString).draw(
      with: rect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attrs
    )
  }

  let primaryFont = NSFont.systemFont(ofSize: 19 * scale, weight: .semibold)
  let secondaryFont = NSFont.systemFont(ofSize: 12 * scale, weight: .regular)
  let footerFont = NSFont.systemFont(ofSize: 11 * scale, weight: .medium)
  let monoFont = NSFont.monospacedSystemFont(ofSize: 12 * scale, weight: .regular)
  let contentW = windowW - 80 // 40px margins each side

  // --- Top instruction zone (y 20–75) ---
  drawCenteredText(
    "Drag ParseKit to Applications to install",
    yFromTop: 28,
    font: primaryFont,
    color: ivory,
    maxWidth: contentW,
    height: 28
  )

  // --- Gold drag chevrons between icon dead zones (no art inside dead zones) ---
  let chevronY = topY(parseKitCenter.y, scale: 1) * scale
  let chevronStartX = (parseKitCenter.x + iconDeadRadius + 12) * scale
  let chevronEndX = (applicationsCenter.x - iconDeadRadius - 12) * scale
  let chevronMidX = (chevronStartX + chevronEndX) / 2
  gold.setStroke()
  let chevron = NSBezierPath()
  chevron.lineWidth = 2.5 * scale
  chevron.lineCapStyle = .round
  chevron.lineJoinStyle = .round
  chevron.move(to: NSPoint(x: chevronStartX, y: chevronY))
  chevron.line(to: NSPoint(x: chevronMidX - 10 * scale, y: chevronY))
  chevron.move(to: NSPoint(x: chevronMidX - 16 * scale, y: chevronY + 10 * scale))
  chevron.line(to: NSPoint(x: chevronMidX, y: chevronY))
  chevron.line(to: NSPoint(x: chevronMidX - 16 * scale, y: chevronY - 10 * scale))
  chevron.move(to: NSPoint(x: chevronMidX + 10 * scale, y: chevronY))
  chevron.line(to: NSPoint(x: chevronEndX, y: chevronY))
  chevron.stroke()

  // --- Terminal helper zone (y 290–415, x 40–680) ---
  drawCenteredText(
    "If macOS blocks first launch, paste this in Terminal after installing:",
    yFromTop: 292,
    font: secondaryFont,
    color: warmGray,
    maxWidth: 640,
    height: 18
  )

  // Terminal window box
  let termRect = rectFromTop(x: 40, y: 312, w: 640, h: 78, scale: scale)
  let termPath = NSBezierPath(roundedRect: termRect, xRadius: 8 * scale, yRadius: 8 * scale)
  termBg.setFill()
  termPath.fill()
  termBorder.setStroke()
  termPath.lineWidth = 1 * scale
  termPath.stroke()

  // Traffic-light dots
  let dotY = termRect.maxY - 14 * scale
  let dotR: CGFloat = 4.5 * scale
  for (i, color) in [
    NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.32, alpha: 1),
    NSColor(calibratedRed: 0.98, green: 0.75, blue: 0.22, alpha: 1),
    NSColor(calibratedRed: 0.32, green: 0.78, blue: 0.36, alpha: 1),
  ].enumerated() {
    let dot = NSBezierPath(ovalIn: NSRect(
      x: termRect.minX + (14 + CGFloat(i) * 14) * scale,
      y: dotY - dotR,
      width: dotR * 2,
      height: dotR * 2
    ))
    color.setFill()
    dot.fill()
  }

  // Two-line wrapped terminal command (12px mono, 640px box)
  let cmdLine1 = "$ xattr -cr /Applications/ParseKit.app && \\"
  let cmdLine2 = "  xattr -d com.apple.FinderInfo /Applications/ParseKit.app"
  let cmdAttrs: [NSAttributedString.Key: Any] = [
    .font: monoFont,
    .foregroundColor: termGreen,
  ]
  let cmdX = termRect.minX + 14 * scale
  let cmdY1 = termRect.minY + 28 * scale
  (cmdLine1 as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1), withAttributes: cmdAttrs)
  (cmdLine2 as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1 - 16 * scale), withAttributes: cmdAttrs)

  drawCenteredText(
    "PDF works out of the box · Word/Excel/images need converters (Settings → File Support)",
    yFromTop: 400,
    font: footerFont,
    color: warmGray,
    maxWidth: 640,
    height: 16
  )

  NSGraphicsContext.restoreGraphicsState()
  return rep
}

func writePNG(_ rep: NSBitmapImageRep, filename: String, directory: URL) throws {
  guard let png = rep.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "GenerateBackground", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
  }
  let out = directory.appendingPathComponent(filename)
  try png.write(to: out)
  print("Wrote \(out.path) (\(rep.pixelsWide)×\(rep.pixelsHigh) px)")
}

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

guard let rep1x = drawBackground(scale: 1),
      let rep2x = drawBackground(scale: 2)
else {
  fputs("Failed to render backgrounds\n", stderr)
  exit(1)
}

do {
  try writePNG(rep1x, filename: "background.png", directory: outDir)
  try writePNG(rep2x, filename: "background@2x.png", directory: outDir)
  // Legacy alias for tauri.conf reference during transition
  try writePNG(rep2x, filename: "dmg-background.png", directory: outDir)
} catch {
  fputs("Write error: \(error)\n", stderr)
  exit(1)
}

print("DMG background contract: window \(Int(windowW))×\(Int(windowH)), icons at (\(Int(parseKitCenter.x)),\(Int(parseKitCenter.y))) and (\(Int(applicationsCenter.x)),\(Int(applicationsCenter.y)))")