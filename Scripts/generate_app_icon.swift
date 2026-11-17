import AppKit
import Foundation

let canvas = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()

let bounds = NSRect(x: 0, y: 0, width: canvas, height: canvas)
NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.085, blue: 0.045, alpha: 1),
    NSColor(calibratedRed: 0.045, green: 0.035, blue: 0.03, alpha: 1),
    NSColor(calibratedRed: 0.018, green: 0.018, blue: 0.02, alpha: 1)
])!.draw(in: bounds, angle: 90)

let warmGlow = NSBezierPath(ovalIn: NSRect(x: 170, y: 170, width: 684, height: 684))
NSColor(calibratedRed: 0.95, green: 0.43, blue: 0.12, alpha: 0.12).setFill()
warmGlow.fill()

let gold = NSColor(calibratedRed: 1.0, green: 0.68, blue: 0.30, alpha: 1)
let goldLight = NSColor(calibratedRed: 1.0, green: 0.83, blue: 0.56, alpha: 1)

// Chimney
let chimney = NSBezierPath(roundedRect: NSRect(x: 690, y: 570, width: 105, height: 225), xRadius: 26, yRadius: 26)
NSGradient(colors: [goldLight, gold, NSColor(calibratedRed: 0.68, green: 0.29, blue: 0.09, alpha: 1)])!.draw(in: chimney, angle: 90)

// House silhouette and roof
let house = NSBezierPath()
house.move(to: NSPoint(x: 250, y: 310))
house.line(to: NSPoint(x: 250, y: 540))
house.line(to: NSPoint(x: 512, y: 790))
house.line(to: NSPoint(x: 774, y: 540))
house.line(to: NSPoint(x: 774, y: 310))
house.lineWidth = 38
house.lineCapStyle = .round
house.lineJoinStyle = .round
gold.setStroke()
house.stroke()

// Warm window glow
let glow = NSBezierPath(roundedRect: NSRect(x: 380, y: 385, width: 264, height: 264), xRadius: 42, yRadius: 42)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedRed: 1, green: 0.48, blue: 0.12, alpha: 0.8)
shadow.shadowBlurRadius = 65
shadow.set()
NSColor(calibratedRed: 1, green: 0.55, blue: 0.19, alpha: 0.28).setFill()
glow.fill()
NSGraphicsContext.restoreGraphicsState()

let paneSize: CGFloat = 100
for x in [405.0, 525.0] {
    for y in [410.0, 530.0] {
        let pane = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: paneSize, height: paneSize), xRadius: 15, yRadius: 15)
        NSGradient(colors: [goldLight, NSColor(calibratedRed: 1, green: 0.59, blue: 0.20, alpha: 1)])!.draw(in: pane, angle: 90)
    }
}

// Subtle warm horizon line
let horizon = NSBezierPath()
horizon.move(to: NSPoint(x: 100, y: 170))
horizon.curve(to: NSPoint(x: 924, y: 170), controlPoint1: NSPoint(x: 330, y: 250), controlPoint2: NSPoint(x: 700, y: 90))
horizon.lineWidth = 5
gold.setStroke()
horizon.stroke()

image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = bitmap.representation(using: .png, properties: [:])!
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "HEMMA/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
try FileManager.default.createDirectory(at: URL(fileURLWithPath: output).deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: output))
print("Generated \(output) (\(png.count) bytes)")
