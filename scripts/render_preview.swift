import SwiftUI
import AppKit

@main
@MainActor
struct PreviewMain {
    static func main() {
        let calendar = Calendar.autoupdatingCurrent
        // 复刻用户截图的时刻:16:47,睡眠 22:00→07:00
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 16; comps.minute = 47
        let now = calendar.date(from: comps)!
        let schedule = SleepScheduleConfig(isEnabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60)
        let item = ProgressItem.builtIn(kind: .day, isEnabled: true, sortOrder: 0)
        guard let snap = ProgressCalculator.snapshot(for: item, at: now, sleepSchedule: schedule) else {
            fatalError("no snapshot")
        }

        let view = VStack(alignment: .leading, spacing: 0) {
            ProgressBarRowView(snapshot: snap)
        }
        .padding(48)
        .frame(width: 1750)
        .background(Color.black)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard let img = renderer.nsImage,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            fatalError("render failed")
        }
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "preview.png"
        try! png.write(to: URL(fileURLWithPath: out))
        print("written:", out)
    }
}
