#!/usr/bin/env swift
// ARCHIVED — do not run for release builds.
// Frozen static artwork lives in packaging/dmg/assets/{background.png,background@2x.png}.
// Emergency regeneration only: FORCE_DMG_BACKGROUND_REGEN=1 bash scripts/dmg/build-dmg.sh …
//
// ParseKit DMG background — premium light installer (master @ 2880×1840).
// Logical canvas: 720×460 (36:23). Master scale: 4×.

import AppKit
import CoreGraphics
import CoreText

let windowW: CGFloat = 720
let windowH: CGFloat = 460
let masterScale: CGFloat = 4 // 2880 × 1840

// Finder icon contract (144 px) — glows only, no placeholder boxes.
let finderIconSize: CGFloat = 144
let parseKitIconTL = CGPoint(x: 176, y: 152)   // lowered 42 px
let applicationsIconTL = CGPoint(x: 440, y: 132) // lowered 34 px
let parseKitIconCenter = CGPoint(x: parseKitIconTL.x + finderIconSize / 2, y: parseKitIconTL.y + finderIconSize / 2)
let applicationsIconCenter = CGPoint(x: applicationsIconTL.x + finderIconSize / 2, y: applicationsIconTL.y + finderIconSize / 2)

// Vertical rhythm (y from top)
let headlineY: CGFloat = 22
let headlineH: CGFloat = 34
let subtitleY: CGFloat = headlineY + headlineH + 18 // 74
let subtitleH: CGFloat = 16
// Icons at fixed Finder positions; subtitle → icon gap ≈ 42 px to icon top (110)

// Arrow — through icon centerline, lowered 8 px, extended ~22%
let arrowY: CGFloat = (parseKitIconCenter.y + applicationsIconCenter.y) / 2 + 8
let arrowLen: CGFloat = 118 * 1.12 * 1.22
let arrowMidX: CGFloat = (parseKitIconCenter.x + applicationsIconCenter.x) / 2
let arrowStartX: CGFloat = arrowMidX - arrowLen / 2
let arrowEndX: CGFloat = arrowMidX + arrowLen / 2

let warningCardY: CGFloat = 264 // moved up 22 px
let warningCardH: CGFloat = 48
let terminalCardY: CGFloat = warningCardY + warningCardH + 22
let terminalCardH: CGFloat = 70 // reduced ~18 px from prior 88
let pdfCardY: CGFloat = terminalCardY + terminalCardH + 22
let pdfCardH: CGFloat = 44

// Palette — ParseKit icon derived (no unrelated orange)
let espresso = NSColor(calibratedRed: 0.184, green: 0.141, blue: 0.106, alpha: 1)       // #2F241B
let leatherBrown = NSColor(calibratedRed: 0.235, green: 0.165, blue: 0.118, alpha: 1)  // #3C2A1E
let warmIvory = NSColor(calibratedRed: 0.961, green: 0.941, blue: 0.902, alpha: 1)     // #F5F0E6
let softCream = NSColor(calibratedRed: 0.980, green: 0.965, blue: 0.945, alpha: 1)     // #FAF6F1
let creamDeep = NSColor(calibratedRed: 0.945, green: 0.918, blue: 0.878, alpha: 1)     // #F1EAD8
let champagne = NSColor(calibratedRed: 0.831, green: 0.737, blue: 0.541, alpha: 1)      // #D4BC8A
let champagneLight = NSColor(calibratedRed: 0.902, green: 0.831, blue: 0.667, alpha: 1)
let mutedTaupe = NSColor(calibratedRed: 0.420, green: 0.380, blue: 0.333, alpha: 1)
let cardFill = NSColor(calibratedRed: 0.973, green: 0.957, blue: 0.933, alpha: 0.92)
let cardStroke = NSColor(calibratedRed: 0.878, green: 0.847, blue: 0.804, alpha: 0.55)
let termBg = NSColor(calibratedRed: 0.118, green: 0.118, blue: 0.118, alpha: 1)      // native terminal
let termHeader = NSColor(calibratedRed: 0.165, green: 0.165, blue: 0.165, alpha: 1)
let termBorder = NSColor(calibratedRed: 0.28, green: 0.28, blue: 0.28, alpha: 1)
let termPrompt = NSColor(calibratedRed: 0.55, green: 0.55, blue: 0.55, alpha: 1)
let termCmd = NSColor(calibratedRed: 0.831, green: 0.737, blue: 0.541, alpha: 1)

func topY(_ yFromTop: CGFloat) -> CGFloat { windowH - yFromTop }

func rectFromTop(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, scale: CGFloat) -> NSRect {
  NSRect(x: x * scale, y: topY(y + h) * scale, width: w * scale, height: h * scale)
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

  let rgb = CGColorSpaceCreateDeviceRGB()

  // Flat cream base — prevents corner crop artifacts
  ctx.setFillColor(softCream.cgColor)
  ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

  // Base wallpaper gradient (center-weighted, no dark corners)
  let baseColors = [softCream.cgColor, warmIvory.cgColor, softCream.cgColor] as CFArray
  if let g = CGGradient(colorsSpace: rgb, colors: baseColors, locations: [0, 0.5, 1]) {
    ctx.drawLinearGradient(
      g,
      start: CGPoint(x: width * 0.5, y: height),
      end: CGPoint(x: width * 0.5, y: 0),
      options: []
    )
  }

  // Soft large wave accents — few, low opacity, avoid text zone
  func drawSoftWave(
    start: CGPoint, cp1: CGPoint, cp2: CGPoint, end: CGPoint,
    color: NSColor, alpha: CGFloat, lineWidth: CGFloat
  ) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: start.x * scale, y: topY(start.y) * scale))
    path.addCurve(
      to: CGPoint(x: end.x * scale, y: topY(end.y) * scale),
      control1: CGPoint(x: cp1.x * scale, y: topY(cp1.y) * scale),
      control2: CGPoint(x: cp2.x * scale, y: topY(cp2.y) * scale)
    )
    ctx.saveGState()
    ctx.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
    ctx.setLineWidth(lineWidth * scale)
    ctx.setLineCap(.round)
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()
  }

  drawSoftWave(start: CGPoint(x: 40, y: 130), cp1: CGPoint(x: 200, y: 80), cp2: CGPoint(x: 400, y: 190), end: CGPoint(x: 680, y: 100), color: champagne, alpha: 0.05, lineWidth: 110)
  drawSoftWave(start: CGPoint(x: 680, y: 300), cp1: CGPoint(x: 500, y: 340), cp2: CGPoint(x: 300, y: 310), end: CGPoint(x: 80, y: 330), color: champagne, alpha: 0.03, lineWidth: 100)

  // Finder icon radial glows (no placeholder boxes)
  func iconGlow(center: CGPoint, inner: NSColor, alpha: CGFloat, radius: CGFloat) {
    let colors = [inner.withAlphaComponent(alpha).cgColor, inner.withAlphaComponent(0).cgColor] as CFArray
    if let glow = CGGradient(colorsSpace: rgb, colors: colors, locations: [0, 1]) {
      let c = CGPoint(x: center.x * scale, y: topY(center.y) * scale)
      ctx.drawRadialGradient(glow, startCenter: c, startRadius: 0, endCenter: c, endRadius: radius * scale, options: [])
    }
  }
  iconGlow(center: parseKitIconCenter, inner: warmIvory, alpha: 0.14, radius: 200)
  iconGlow(center: applicationsIconCenter, inner: champagneLight, alpha: 0.13, radius: 200)

  // Headline: espresso "Drag to" + champagne gradient clipped to "install" glyph shapes only
  func clipToGlyphText(_ text: String, font: NSFont, at origin: CGPoint) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs) as CFAttributedString)
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
    for run in runs {
      let count = CTRunGetGlyphCount(run)
      for i in 0..<count {
        var glyph = CGGlyph()
        var pos = CGPoint.zero
        CTRunGetGlyphs(run, CFRange(location: i, length: 1), &glyph)
        CTRunGetPositions(run, CFRange(location: i, length: 1), &pos)
        if let path = CTFontCreatePathForGlyph(ctFont, glyph, nil) {
          var t = CGAffineTransform(translationX: origin.x + pos.x, y: origin.y + pos.y)
          if let p = path.copy(using: &t) { ctx.addPath(p) }
        }
      }
    }
    ctx.clip()
  }

  func drawHeadline() {
    let fontSize: CGFloat = 28 * scale
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let part1 = "Drag to "
    let part2 = "install"
    let attrs1: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: espresso,
      .kern: -0.28 * scale,
    ]
    let size1 = (part1 as NSString).size(withAttributes: attrs1)
    let size2 = (part2 as NSString).size(withAttributes: [.font: font])
    let totalW = size1.width + size2.width
    let x = (width - totalW) / 2
    let y = topY(headlineY + headlineH) * scale + 4 * scale
    (part1 as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attrs1)

    let installX = x + size1.width
    ctx.saveGState()
    clipToGlyphText(part2, font: font, at: CGPoint(x: installX, y: y))
    if let grad = CGGradient(
      colorsSpace: rgb,
      colors: [champagne.cgColor, champagneLight.cgColor] as CFArray,
      locations: [0, 1]
    ) {
      ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: installX, y: y + size2.height / 2),
        end: CGPoint(x: installX + size2.width, y: y + size2.height / 2),
        options: []
      )
    }
    ctx.restoreGState()
  }
  drawHeadline()

  // Subtitle
  let subtitleFont = NSFont.systemFont(ofSize: 13 * scale, weight: .regular)
  let subtitlePara = NSMutableParagraphStyle()
  subtitlePara.alignment = .center
  let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: subtitleFont,
    .foregroundColor: mutedTaupe.withAlphaComponent(0.72),
    .paragraphStyle: subtitlePara,
  ]
  let subtitleRect = NSRect(x: 40 * scale, y: topY(subtitleY + subtitleH) * scale, width: (windowW - 80) * scale, height: subtitleH * scale)
  ("Simply drag and drop to install" as NSString).draw(with: subtitleRect, options: [.usesLineFragmentOrigin], attributes: subtitleAttrs)

  // Champagne arrow with subtle glow
  func drawArrow() {
    let s = scale
    let cy = topY(arrowY) * s
    let sx = arrowStartX * s
    let ex = arrowEndX * s

    // Soft glow under arrow (reduced blur)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 4 * s, color: champagne.withAlphaComponent(0.12).cgColor)
    champagne.withAlphaComponent(0.70).setStroke()
    let glowShaft = NSBezierPath()
    glowShaft.lineWidth = 4 * s
    glowShaft.lineCapStyle = .round
    glowShaft.move(to: NSPoint(x: sx, y: cy))
    glowShaft.line(to: NSPoint(x: ex - 12 * s, y: cy))
    glowShaft.stroke()
    ctx.restoreGState()

    // Gradient shaft — ~70% opacity, extended length
    ctx.saveGState()
    let shaftPath = NSBezierPath()
    shaftPath.lineWidth = 2.8 * s
    shaftPath.lineCapStyle = .round
    shaftPath.move(to: NSPoint(x: sx, y: cy))
    shaftPath.line(to: NSPoint(x: ex - 10 * s, y: cy))
    ctx.addPath(shaftPath.cgPath)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    if let grad = CGGradient(colorsSpace: rgb, colors: [champagneLight.cgColor, champagne.cgColor] as CFArray, locations: [0, 1]) {
      ctx.setAlpha(0.70)
      ctx.drawLinearGradient(grad, start: CGPoint(x: sx, y: cy), end: CGPoint(x: ex, y: cy), options: [])
    }
    ctx.restoreGState()

    let head = NSBezierPath()
    head.lineWidth = 2.8 * s
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    champagne.withAlphaComponent(0.70).setStroke()
    head.move(to: NSPoint(x: ex - 20 * s, y: cy + 8 * s))
    head.line(to: NSPoint(x: ex, y: cy))
    head.line(to: NSPoint(x: ex - 20 * s, y: cy - 8 * s))
    head.stroke()
  }
  drawArrow()

  func drawCard(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, radius: CGFloat) -> NSRect {
    let rect = rectFromTop(x: x, y: y, w: w, h: h, scale: scale)
    let path = NSBezierPath(roundedRect: rect, xRadius: radius * scale, yRadius: radius * scale)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -1 * scale), blur: 10 * scale, color: NSColor.black.withAlphaComponent(0.06).cgColor)
    cardFill.setFill()
    path.fill()
    ctx.restoreGState()
    cardStroke.setStroke()
    path.lineWidth = 0.5 * scale
    path.stroke()
    return rect
  }

  func drawSymbol(_ name: String, in rect: NSRect, color: NSColor, pointSize: CGFloat, leftInset: CGFloat = 14) {
    if let img = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
      let cfg = NSImage.SymbolConfiguration(pointSize: pointSize * scale, weight: .medium)
      let configured = img.withSymbolConfiguration(cfg) ?? img
      configured.isTemplate = true
      color.set()
      let sz: CGFloat = pointSize * 1.45 * scale
      let origin = NSPoint(x: rect.minX + leftInset * scale, y: rect.midY - sz / 2)
      configured.draw(in: NSRect(origin: origin, size: NSSize(width: sz, height: sz)))
    }
  }

  // Warning card — +10 px left padding, larger icon
  let cardW: CGFloat = 640
  let cardX: CGFloat = 40
  let warnRect = drawCard(x: cardX, y: warningCardY, w: cardW, h: warningCardH, radius: 12)
  drawSymbol("shield.fill", in: warnRect, color: champagne, pointSize: 16.1, leftInset: 24)
  let warnTitleFont = NSFont.systemFont(ofSize: 12.5 * scale, weight: .bold)
  let warnSubFont = NSFont.systemFont(ofSize: 12 * scale, weight: .regular)
  let warnX = warnRect.minX + 50 * scale
  let warnY1 = warnRect.minY + warnRect.height - 28 * scale
  ("If macOS blocks first launch" as NSString).draw(at: NSPoint(x: warnX, y: warnY1), withAttributes: [
    .font: warnTitleFont, .foregroundColor: espresso,
  ])
  ("Enter this in Terminal after installing:" as NSString).draw(at: NSPoint(x: warnX, y: warnY1 - 16 * scale), withAttributes: [
    .font: warnSubFont, .foregroundColor: mutedTaupe.withAlphaComponent(0.70),
  ])

  // Terminal card
  let termRect = rectFromTop(x: cardX, y: terminalCardY, w: cardW, h: terminalCardH, scale: scale)
  let termPath = NSBezierPath(roundedRect: termRect, xRadius: 10 * scale, yRadius: 10 * scale)
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -1 * scale), blur: 8 * scale, color: NSColor.black.withAlphaComponent(0.12).cgColor)
  termBg.setFill()
  termPath.fill()
  ctx.restoreGState()
  termBorder.setStroke()
  termPath.lineWidth = 0.5 * scale
  termPath.stroke()

  let headerH: CGFloat = 22 * scale
  let headerRect = NSRect(x: termRect.minX, y: termRect.maxY - headerH, width: termRect.width, height: headerH)
  let headerPath = NSBezierPath(roundedRect: headerRect, xRadius: 10 * scale, yRadius: 10 * scale)
  termHeader.setFill()
  headerPath.fill()
  let dotY = headerRect.minY + 7 * scale
  for (i, c) in [
    NSColor(calibratedRed: 1, green: 0.37, blue: 0.34, alpha: 1),
    NSColor(calibratedRed: 1, green: 0.74, blue: 0.18, alpha: 1),
    NSColor(calibratedRed: 0.15, green: 0.79, blue: 0.25, alpha: 1),
  ].enumerated() {
    let dot = NSBezierPath(ovalIn: NSRect(x: headerRect.minX + (12 + CGFloat(i) * 14) * scale, y: dotY, width: 8 * scale, height: 8 * scale))
    c.setFill()
    dot.fill()
  }

  let monoFont = NSFont.monospacedSystemFont(ofSize: 12.5 * scale, weight: .regular)
  let cmdLine1 = "xattr -cr /Applications/ParseKit.app && \\"
  let cmdLine2 = "xattr -d com.apple.FinderInfo /Applications/ParseKit.app"
  let cmdX = termRect.minX + 32 * scale
  let lineH: CGFloat = 19 * scale
  let cmdY1 = termRect.minY + 20 * scale
  ("$" as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1), withAttributes: [.font: monoFont, .foregroundColor: termPrompt])
  (cmdLine1 as NSString).draw(at: NSPoint(x: cmdX + 16 * scale, y: cmdY1), withAttributes: [.font: monoFont, .foregroundColor: termCmd])
  ("$" as NSString).draw(at: NSPoint(x: cmdX, y: cmdY1 - lineH), withAttributes: [.font: monoFont, .foregroundColor: termPrompt])
  (cmdLine2 as NSString).draw(at: NSPoint(x: cmdX + 16 * scale, y: cmdY1 - lineH), withAttributes: [.font: monoFont, .foregroundColor: termCmd])

  // PDF info card
  let pdfRect = drawCard(x: cardX, y: pdfCardY, w: cardW, h: pdfCardH, radius: 12)
  drawSymbol("doc.fill", in: pdfRect, color: champagne, pointSize: 14)
  let pdfTitleFont = NSFont.systemFont(ofSize: 16 * scale, weight: .semibold)
  let pdfDescFont = NSFont.systemFont(ofSize: 13 * scale, weight: .regular)
  let pdfX = pdfRect.minX + 40 * scale
  let pdfY = pdfRect.midY + 4 * scale
  ("PDF works out of the box" as NSString).draw(at: NSPoint(x: pdfX, y: pdfY), withAttributes: [
    .font: pdfTitleFont, .foregroundColor: espresso,
  ])
  ("Word/Excel/images need converters (Settings → File Support)" as NSString).draw(at: NSPoint(x: pdfX, y: pdfY - 18 * scale), withAttributes: [
    .font: pdfDescFont, .foregroundColor: mutedTaupe.withAlphaComponent(0.65),
  ])

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

guard let repMaster = drawBackground(scale: masterScale) else {
  fputs("Failed to render master background\n", stderr)
  exit(1)
}

do {
  try writePNG(repMaster, filename: "background-master.png", directory: outDir)
} catch {
  fputs("Write error: \(error)\n", stderr)
  exit(1)
}

print("DMG master: \(Int(windowW * masterScale))×\(Int(windowH * masterScale))")
print("Finder icons: ParseKit @ (\(Int(parseKitIconTL.x)),\(Int(parseKitIconTL.y)))  Applications @ (\(Int(applicationsIconTL.x)),\(Int(applicationsIconTL.y)))")