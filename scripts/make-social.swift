import AppKit

// Рисует social-preview (Open Graph) 1280×640: логотип + название + слоган.
// Использование: swift make-social.swift <logo.png> <output.png>

let W: CGFloat = 1280, H: CGFloat = 640
let logoPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/icon-master.png"
let outPath  = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "Assets/social-preview.png"

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("bitmap") }

NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let cg = gctx.cgContext

// Тёмный фон с лёгким брендовым отливом
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
    NSColor(srgbRed: 0.13, green: 0.09, blue: 0.16, alpha: 1).cgColor,
    NSColor(srgbRed: 0.07, green: 0.07, blue: 0.09, alpha: 1).cgColor,
] as CFArray, locations: [0, 1])!
cg.drawLinearGradient(bg, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0), options: [])

// Логотип сверху по центру
let logoSize: CGFloat = 200
if let logo = NSImage(contentsOfFile: logoPath) {
    logo.draw(in: NSRect(x: (W - logoSize) / 2, y: H - logoSize - 70, width: logoSize, height: logoSize))
}

func draw(_ text: String, font: NSFont, color: NSColor, centerY: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
    let s = NSAttributedString(string: text, attributes: attrs)
    let size = s.size()
    s.draw(in: NSRect(x: 0, y: centerY - size.height / 2, width: W, height: size.height))
}

draw("RosettaBB",
     font: .systemFont(ofSize: 84, weight: .bold),
     color: .white, centerY: 250)
draw("Find Intel-only apps that still need Rosetta",
     font: .systemFont(ofSize: 32, weight: .regular),
     color: NSColor(white: 0.72, alpha: 1), centerY: 165)
draw("macOS · SwiftUI · open source",
     font: .systemFont(ofSize: 24, weight: .medium),
     color: NSColor(srgbRed: 0.85, green: 0.55, blue: 0.95, alpha: 1), centerY: 95)

NSGraphicsContext.restoreGraphicsState()
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! data.write(to: URL(fileURLWithPath: outPath))
print("Social preview: \(outPath)")
