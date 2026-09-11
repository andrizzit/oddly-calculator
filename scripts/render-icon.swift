#!/usr/bin/env swift
// Original code-drawn artwork, MIT licensed. Run from the repository root on macOS.
import AppKit

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func roundRect(_ rect: NSRect, _ radius: CGFloat, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                        bytesPerRow: 4096, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
let ink = color(0x202522), cream = color(0xF5F1E8), orange = color(0xF26B38)
cream.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
// A pocket calculator with a very small agenda.
roundRect(NSRect(x: 198, y: 112, width: 640, height: 782), 116, color(0xDDD8CE))
roundRect(NSRect(x: 182, y: 132, width: 640, height: 782), 116, ink)
roundRect(NSRect(x: 240, y: 579, width: 524, height: 270), 65, color(0xD9E7D8))
roundRect(NSRect(x: 332, y: 701, width: 50, height: 68), 25, ink)
roundRect(NSRect(x: 622, y: 701, width: 50, height: 68), 25, ink)
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 455, y: 686))
smile.curve(to: NSPoint(x: 551, y: 686), controlPoint1: NSPoint(x: 477, y: 649), controlPoint2: NSPoint(x: 529, y: 649))
smile.lineWidth = 16
smile.lineCapStyle = .round
ink.setStroke()
smile.stroke()
for x in [CGFloat(242), 425] {
    roundRect(NSRect(x: x, y: 391, width: 158, height: 139), 42, cream)
    roundRect(NSRect(x: x, y: 215, width: 158, height: 139), 42, color(0xDCD5F6))
}
roundRect(NSRect(x: 607, y: 215, width: 158, height: 315), 42, orange)
roundRect(NSRect(x: 645, y: 391, width: 82, height: 20), 10, ink)
roundRect(NSRect(x: 645, y: 337, width: 82, height: 20), 10, ink)
// One raised eyebrow: restrained nonsense.
let brow = NSBezierPath()
brow.move(to: NSPoint(x: 612, y: 796))
brow.line(to: NSPoint(x: 676, y: 812))
brow.lineWidth = 14
brow.lineCapStyle = .round
brow.stroke()
NSGraphicsContext.restoreGraphicsState()
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Oddly/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
let contents = """
{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
"""
try contents.write(to: output.deletingLastPathComponent().appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print(output.path)
