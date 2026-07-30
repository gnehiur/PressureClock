import SwiftUI
import WidgetKit

struct PressureEntry: TimelineEntry {
    let date: Date
    let snapshots: [ProgressKind: ProgressSnapshot]
}

enum PressureEntryBuilder {
    static let kinds: [ProgressKind] = [.day, .week, .month, .year]

    static func entry(at date: Date) -> PressureEntry {
        var snapshots: [ProgressKind: ProgressSnapshot] = [:]
        for kind in kinds {
            let item = ProgressItem.builtIn(kind: kind, isEnabled: true, sortOrder: 0)
            if let snapshot = ProgressCalculator.snapshot(for: item, at: date) {
                snapshots[kind] = snapshot
            }
        }
        return PressureEntry(date: date, snapshots: snapshots)
    }
}

struct PressureProvider: TimelineProvider {
    func placeholder(in context: Context) -> PressureEntry {
        PressureEntryBuilder.entry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PressureEntry) -> Void) {
        completion(PressureEntryBuilder.entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PressureEntry>) -> Void) {
        // 小组件不是常驻进程:一次交出未来 90 分钟、每分钟一页的快照,系统到点翻页。
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        var entries: [PressureEntry] = [PressureEntryBuilder.entry(at: now)]
        if let nextMinute = calendar.nextDate(
            after: now,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) {
            for offset in 0..<90 {
                entries.append(PressureEntryBuilder.entry(at: nextMinute.addingTimeInterval(TimeInterval(offset * 60))))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct PressureClockWidget: Widget {
    let kind = "PressureClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PressureProvider()) { entry in
            PressureWidgetRootView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("时间压力钟")
        .description("在桌面一眼看到今日、本周、本月、今年已流逝的比例。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
