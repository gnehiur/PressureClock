import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fputs("Usage: swift generate_dmg_background.swift <output-path>\n", stderr)
    exit(1)
}

let outputPath = arguments[1]
let outputURL = URL(fileURLWithPath: outputPath)
let size = NSSize(width: 640, height: 420)

let image = NSImage(size: size)
image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)

let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedWhite: 0.97, alpha: 1.0),
    NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.99, alpha: 1.0)
])!
backgroundGradient.draw(in: bounds, angle: -90)

let panelRect = NSRect(x: 24, y: 24, width: size.width - 48, height: size.height - 48)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 28, yRadius: 28)
NSColor(calibratedWhite: 1.0, alpha: 0.72).setFill()
panelPath.fill()

let innerStroke = NSBezierPath(roundedRect: panelRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 28, yRadius: 28)
NSColor(calibratedWhite: 1.0, alpha: 0.5).setStroke()
innerStroke.lineWidth = 1
innerStroke.stroke()

let title = "安装 PressureClock"
let subtitle = "把左侧应用拖到右侧 Applications"
let footnote = "如果首次打开被系统拦截：右键应用 -> 打开"

let centeredParagraph = NSMutableParagraphStyle()
centeredParagraph.alignment = .center

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 34, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1.0),
    .paragraphStyle: centeredParagraph
]

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.25, alpha: 1.0),
    .paragraphStyle: centeredParagraph
]

let footnoteAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.35, alpha: 1.0),
    .paragraphStyle: centeredParagraph
]

let titleRect = NSRect(x: 70, y: 332, width: 500, height: 44)
let subtitleRect = NSRect(x: 70, y: 292, width: 500, height: 30)
let footnoteRect = NSRect(x: 90, y: 48, width: 460, height: 24)

(title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
(subtitle as NSString).draw(in: subtitleRect, withAttributes: subtitleAttributes)
(footnote as NSString).draw(in: footnoteRect, withAttributes: footnoteAttributes)

let arrowPath = NSBezierPath()
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.lineWidth = 10
arrowPath.move(to: NSPoint(x: 250, y: 190))
arrowPath.curve(
    to: NSPoint(x: 415, y: 190),
    controlPoint1: NSPoint(x: 305, y: 190),
    controlPoint2: NSPoint(x: 365, y: 190)
)
NSColor(calibratedRed: 0.17, green: 0.49, blue: 0.97, alpha: 0.95).setStroke()
arrowPath.stroke()

let arrowHead = NSBezierPath()
arrowHead.lineCapStyle = .round
arrowHead.lineJoinStyle = .round
arrowHead.lineWidth = 10
arrowHead.move(to: NSPoint(x: 392, y: 214))
arrowHead.line(to: NSPoint(x: 420, y: 190))
arrowHead.line(to: NSPoint(x: 392, y: 166))
NSColor(calibratedRed: 0.17, green: 0.49, blue: 0.97, alpha: 0.95).setStroke()
arrowHead.stroke()

let leftHintRect = NSBezierPath(roundedRect: NSRect(x: 86, y: 120, width: 138, height: 118), xRadius: 24, yRadius: 24)
NSColor(calibratedWhite: 0.0, alpha: 0.05).setFill()
leftHintRect.fill()

let rightHintRect = NSBezierPath(roundedRect: NSRect(x: 418, y: 120, width: 138, height: 118), xRadius: 24, yRadius: 24)
NSColor(calibratedWhite: 0.0, alpha: 0.05).setFill()
rightHintRect.fill()

let dropText = "拖进去"
let dropAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.17, green: 0.49, blue: 0.97, alpha: 1.0),
    .paragraphStyle: centeredParagraph
]
(dropText as NSString).draw(in: NSRect(x: 258, y: 220, width: 124, height: 24), withAttributes: dropAttributes)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to generate background image data\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)
