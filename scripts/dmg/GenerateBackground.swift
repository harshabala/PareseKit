#!/usr/bin/env swift
// Procedural DMG backgrounds — source of truth when design PNG exports are mis-cropped.
// Regenerate: REGENERATE_DMG_BACKGROUND=1 bash scripts/dmg/build-dmg.sh <ParseKit.app>
//
// ParseKit DMG backgrounds — locked coordinate contract (720×460 logical @1x).
//
// Window (logical):     720 × 460
// Icon size (Finder):   128
// Icon centers:         (190, 172) and (530, 172)
// Finder top-left:      (126, 108) and (466, 108)  — center − iconSize/2
// Target wells:         144×144 at (118, 100) and (458, 100)
//
// Exports:
//   background.png     720×460   (1×)
//   background@2x.png  1440×920  (2× Retina)

import AppKit
import CoreGraphics

let windowW: CGFloat = 720
let windowH: CGFloat = 460

let parseKitCenter = CGPoint(x: 190, y: 172)
let applicationsCenter = CGPoint(x: 530, y: 172)

// Design palette
let navy = NSColor(calibratedRed: 0.071, green: 0.090, blue: 0.169, alpha: 1)      // #12172B
let plum = NSColor(calibratedRed: 0.141, green: 0.102, blue: 0.208, alpha: 1)     // #241A35
let ivory = NSColor(calibratedRed: 0.961, green: 0.945, blue: 0.910, alpha: 1)    // #F5F1E8
let warmGray = NSColor(calibratedRed: 0.690, green: 0.659, blue: 0.612, alpha: 1) // #B0A89C
let gold = NSColor(calibratedRed: 0.851, green: 0.659, blue: 0.424, alpha: 1)      // #D9A86C
let termBg = NSColor(calibratedRed: 0.043, green: 0.055, blue: 0.102, alpha: 1) // #0B0E1A
let termBorder = NSColor(calibratedRed: 0.227, green: 0.208, blue: 0.314, alpha: 1) // #3A3550
let termHeader = NSColor(calibratedRed: 0.075, green: 0.090, blue: 0.157, alpha: 1) // #131728
let termGreen = NSColor(calibratedRed: 0.561, green: 0.890, blue: 0.639, alpha: 1) // #8FE3A3
let promptGray = NSColor(calibratedRed: 0.424, green: 0.478, blue: 0.612, alpha: 1) // #6C7A9C

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

  let space = CGColorSpaceCreateDeviceRGB()
  let baseColors = [navy.cgColor, plum.cgColor] as CFArray
  if let gradient = CGGradient(colorsSpace: space, colors: baseColors, locations: [0, 1]) {
    ctx.drawLinearGradient(
      gradient,
      start: CGPoint(x: 0, y: height),
      end: CGPoint(x: width, y: 0),
      options: []
    )
  }

  func radialGlow(center: CGPoint, color: NSColor, alpha: CGFloat, radius: CGFloat) {
    let glowColors = [
      color.withAlphaComponent(alpha).cgColor,
      color.withAlphaComponent(0).cgColor,
    ] as CFArray
    if let glow = CGGradient(colorsSpace: space, colors: glowColors, locations: [0, 1]) {
      ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: center.x * scale, y: topY(center.y, scale: 1) * scale),
        startRadius: 0,
        endCenter: CGPoint(x: center.x * scale, y: topY(center.y, scale: 1) * scale),
        endRadius: radius * scale,
        options: []
      )
    }
  }

  radialGlow(center: parseKitCenter, color: ivory, alpha: 0.07, radius: 210)
  radialGlow(center: applicationsCenter, color: gold, alpha: 0.07, radius: 210)
  radialGlow(center: CGPoint(x: windowW / 2, y: 37), color: gold, alpha: 0.04, radius: 175)

  func drawCenteredText(
    _ text: String,
    yFromTop: CGFloat,
    font: NSFont,
    color: NSColor,
    maxWidth: CGFloat,
    height: CGFloat = 60,
    opacity: CGFloat = 1
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color.withAlphaComponent(opacity),
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

  func drawIconLabel(_ text: String, centerX: CGFloat, yFromTop: CGFloat) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let font = NSFont.systemFont(ofSize: 13 * scale, weight: .medium)
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: ivory,
      .paragraphStyle: paragraph,
    ]
    let w: CGFloat = 140 * scale
    let h: CGFloat = 18 * scale
    let rect = NSRect(
      x: (centerX * scale) - (w / 2),
      y: topY(yFromTop + 18, scale: 1) * scale,
      width: w,
      height: h
    )
    (text as NSString).draw(
      with: rect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attrs
    )
  }

  func drawDragChevron(at x: CGFloat, y: CGFloat, opacity: CGFloat) {
    let s = scale
    let cx = x * s
    let cy = topY(y, scale: 1) * scale
    gold.withAlphaComponent(opacity).setStroke()
    let path = NSBezierPath()
    path.lineWidth = 3 * s
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: NSPoint(x: cx - 9 * s, y: cy + 9 * s))
    path.line(to: NSPoint(x: cx, y: cy))
    path.line(to: NSPoint(x: cx - 9 * s, y: cy - 9 * s))
    path.stroke()
  }

  func drawDragCueBetweenIcons() {
    // Icon top-left (126,108), size 128 → centers (190,172) and (530,172).
    let iconSize: CGFloat = 128
    let gapStart = parseKitCenter.x + iconSize / 2 + 10
    let gapEnd = applicationsCenter.x - iconSize / 2 - 10
    let chevronY = parseKitCenter.y
    let chevronXs: [CGFloat] = [0.12, 0.32, 0.5, 0.68, 0.88].map {
      gapStart + (gapEnd - gapStart) * $0
    }
    let opacities: [CGFloat] = [0.45, 0.62, 0.78, 0.9, 1.0]
    for (x, opacity) in zip(chevronXs, opacities) {
      drawDragChevron(at: x, y: chevronY, opacity: opacity)
    }
  }

  let primaryFont = NSFont.systemFont(ofSize: 19 * scale, weight: .semibold)
  let secondaryFont = NSFont.systemFont(ofSize: 12 * scale, weight: .regular)
  let footerFont = NSFont.systemFont(ofSize: 11 * scale, weight: .regular)
  let monoFont = NSFont.monospacedSystemFont(ofSize: 12 * scale, weight: .regular)
  let contentW = windowW - 80

  drawCenteredText(
    "Drag ParseKit to Applications to install",
    yFromTop: 26,
    font: primaryFont,
    color: ivory,
    maxWidth: contentW,
    height: 28
  )

  // Finder draws icons only (shows item info = false); labels baked in white below.
  drawDragCueBetweenIcons()
  drawIconLabel("ParseKit", centerX: parseKitCenter.x, yFromTop: 242)
  drawIconLabel("Applications", centerX: applicationsCenter.x, yFromTop: 242)

  drawCenteredText(
    "If macOS blocks first launch, paste this in Terminal after installing:",
    yFromTop: 268,
    font: secondaryFont,
    color: warmGray,
    maxWidth: 640,
    height: 18
  )

  let termRect = rectFromTop(x: 40, y: 296, w: 640, h: 88, scale: scale)
  let termPath = NSBezierPath(roundedRect: termRect, xRadius: 8 * scale, yRadius: 8 * scale)
  termBg.setFill()
  termPath.fill()
  termBorder.setStroke()
  termPath.lineWidth = 1 * scale
  termPath.stroke()

  let headerRect = NSRect(
    x: termRect.minX,
    y: termRect.maxY - 24 * scale,
    width: termRect.width,
    height: 24 * scale
  )
  let headerPath = NSBezierPath(
    roundedRect: headerRect,
    xRadius: 8 * scale,
    yRadius: 8 * scale
  )
  termHeader.setFill()
  headerPath.fill()

  let dotY = headerRect.minY + 8 * scale
  let dotR: CGFloat = 4 * scale
  for (i, color) in [
    NSColor(calibratedRed: 1.0, green: 0.373, blue: 0.337, alpha: 1),
    NSColor(calibratedRed: 1.0, green: 0.741, blue: 0.180, alpha: 1),
    NSColor(calibratedRed: 0.153, green: 0.788, blue: 0.251, alpha: 1),
  ].enumerated() {
    let dot = NSBezierPath(ovalIn: NSRect(
      x: headerRect.minX + (12 + CGFloat(i) * 14) * scale,
      y: dotY,
      width: dotR * 2,
      height: dotR * 2
    ))
    color.setFill()
    dot.fill()
  }

  let cmdLine1 = "xattr -cr /Applications/ParseKit.app && \\"
  let cmdLine2 = "xattr -d com.apple.FinderInfo /Applications/ParseKit.app"
  let promptAttrs: [NSAttributedString.Key: Any] = [
    .font: monoFont,
    .foregroundColor: promptGray,
  ]
  let cmdAttrs: [NSAttributedString.Key: Any] = [
    .font: monoFont,
    .foregroundColor: termGreen,
  ]
  let cmdX = termRect.minX + 14 * scale
  let cmdY1 = termRect.minY + 34 * scale
  ("$" as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1), withAttributes: promptAttrs)
  (cmdLine1 as NSString).draw(at: NSPoint(x: cmdX + 18 * scale, y: cmdY1), withAttributes: cmdAttrs)
  (" " as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1 - 17 * scale), withAttributes: promptAttrs)
  (cmdLine2 as NSString).draw(at: NSPoint(x: cmdX + 18 * scale, y: cmdY1 - 17 * scale), withAttributes: cmdAttrs)

  drawCenteredText(
    "PDF works out of the box · Word/Excel/images need converters (Settings → File Support)",
    yFromTop: 398,
    font: footerFont,
    color: warmGray,
    maxWidth: 640,
    height: 16,
    opacity: 0.85
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
} catch {
  fputs("Write error: \(error)\n", stderr)
  exit(1)
}

print("DMG background: \(Int(windowW))×\(Int(windowH)); icon centers (\(Int(parseKitCenter.x)),\(Int(parseKitCenter.y))) (\(Int(applicationsCenter.x)),\(Int(applicationsCenter.y)))")