import AppKit

// Рисует мастер-иконку RosettaBB 1024×1024: CPU-чип на градиентном squircle.
// Использование: swift make-icon.swift <output.png>

let size: CGFloat = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("Не удалось создать bitmap") }

NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let cg = gctx.cgContext

// Squircle с прозрачным полем по краям (как в макосных иконках)
let margin = size * 0.085
let rectSize = size - margin * 2
let bg = CGRect(x: margin, y: margin, width: rectSize, height: rectSize)
let radius = rectSize * 0.2237
let squircle = NSBezierPath(roundedRect: NSRect(x: bg.minX, y: bg.minY, width: bg.width, height: bg.height),
                            xRadius: radius, yRadius: radius)

// Диагональный градиент: оранжевый → фиолетовый
cg.saveGState()
squircle.addClip()
let colors = [
    NSColor(srgbRed: 1.00, green: 0.46, blue: 0.06, alpha: 1).cgColor,
    NSColor(srgbRed: 0.53, green: 0.21, blue: 0.93, alpha: 1).cgColor,
]
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: colors as CFArray, locations: [0, 1])!
cg.drawLinearGradient(grad, start: CGPoint(x: bg.minX, y: bg.maxY),
                      end: CGPoint(x: bg.maxX, y: bg.minY), options: [])
cg.restoreGState()

let center = CGPoint(x: size / 2, y: size / 2)
NSColor.white.setStroke()
NSColor.white.setFill()

// Корпус чипа (внешний контур)
let chip = rectSize * 0.42
let chipRect = CGRect(x: center.x - chip / 2, y: center.y - chip / 2, width: chip, height: chip)
let chipPath = NSBezierPath(roundedRect: NSRect(x: chipRect.minX, y: chipRect.minY, width: chip, height: chip),
                            xRadius: chip * 0.16, yRadius: chip * 0.16)
chipPath.lineWidth = size * 0.024
chipPath.stroke()

// Внутренний квадрат «ядра»
let inner = chip * 0.46
let innerRect = CGRect(x: center.x - inner / 2, y: center.y - inner / 2, width: inner, height: inner)
let innerPath = NSBezierPath(roundedRect: NSRect(x: innerRect.minX, y: innerRect.minY, width: inner, height: inner),
                             xRadius: inner * 0.14, yRadius: inner * 0.14)
innerPath.lineWidth = size * 0.018
innerPath.stroke()

// Ножки чипа (по 3 с каждой стороны)
let pinLen = rectSize * 0.062
let pinW = size * 0.022
func pin(_ r: CGRect) {
    NSBezierPath(roundedRect: NSRect(x: r.minX, y: r.minY, width: r.width, height: r.height),
                 xRadius: pinW / 2, yRadius: pinW / 2).fill()
}
for o in [-chip * 0.27, 0, chip * 0.27] as [CGFloat] {
    pin(CGRect(x: center.x + o - pinW / 2, y: chipRect.maxY, width: pinW, height: pinLen))            // верх
    pin(CGRect(x: center.x + o - pinW / 2, y: chipRect.minY - pinLen, width: pinW, height: pinLen))   // низ
    pin(CGRect(x: chipRect.minX - pinLen, y: center.y + o - pinW / 2, width: pinLen, height: pinW))   // лево
    pin(CGRect(x: chipRect.maxX, y: center.y + o - pinW / 2, width: pinLen, height: pinW))            // право
}

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("Не удалось закодировать PNG") }
try! data.write(to: URL(fileURLWithPath: outPath))
print("Иконка записана: \(outPath)")
