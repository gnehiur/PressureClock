import SwiftUI
import WidgetKit

struct PressureWidgetRootView: View {
    @Environment(\.widgetFamily) private var family

    let entry: PressureEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPressureView(entry: entry)
        case .systemLarge:
            LargePressureView(entry: entry)
        default:
            MediumPressureView(entry: entry)
        }
    }
}

// MARK: - 小尺寸:今日为主角,周/月/年迷你条

private struct SmallPressureView: View {
    let entry: PressureEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let day = entry.snapshots[.day] {
                Text(day.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(WidgetStyle.percent(day.progress))")
                        .font(.system(size: 34, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.96))
                    Text("%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                    Spacer(minLength: 0)
                }
                .padding(.top, 1)

                Text(WidgetStyle.remainingText(from: day))
                    .font(.system(size: 10.5, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 1)

                WidgetProgressBar(progress: day.progress, height: 5)
                    .padding(.top, 5)
            }

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 6) {
                MicroRow(label: "周", snapshot: entry.snapshots[.week])
                MicroRow(label: "月", snapshot: entry.snapshots[.month])
                MicroRow(label: "年", snapshot: entry.snapshots[.year])
            }
        }
    }
}

private struct MicroRow: View {
    let label: String
    let snapshot: ProgressSnapshot?

    var body: some View {
        if let snapshot {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))

                WidgetProgressBar(progress: snapshot.progress, height: 3.5)

                Text("\(WidgetStyle.percent(snapshot.progress))%")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
}

// MARK: - 中尺寸:今日/本周/本月/今年四行

private struct MediumPressureView: View {
    private static let kinds: [ProgressKind] = [.day, .week, .month, .year]

    let entry: PressureEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Self.kinds, id: \.self) { kind in
                if let snapshot = entry.snapshots[kind] {
                    WidgetProgressRow(snapshot: snapshot, barHeight: 5)
                }
            }
        }
    }
}

// MARK: - 大尺寸:日期抬头 + 本小时到今年五行(带首尾刻度)

private struct LargePressureView: View {
    private static let kinds: [ProgressKind] = [.hour, .day, .week, .month, .year]

    let entry: PressureEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 2) {
                Text(DisplayFormatting.dateString(from: entry.date))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(DisplayFormatting.yearContextString(from: entry.date))
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.42))
            }

            ForEach(Self.kinds, id: \.self) { kind in
                if let snapshot = entry.snapshots[kind] {
                    WidgetProgressRow(snapshot: snapshot, barHeight: 6, showsEdgeLabels: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 共享部件

private struct WidgetProgressRow: View {
    let snapshot: ProgressSnapshot
    var barHeight: CGFloat = 5
    var showsEdgeLabels = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(snapshot.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))

                Spacer(minLength: 8)

                Text(snapshot.statusText)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            WidgetProgressBar(progress: snapshot.progress, height: barHeight)

            if showsEdgeLabels {
                HStack {
                    Text(snapshot.leftLabel)
                    Spacer(minLength: 8)
                    Text(snapshot.rightLabel)
                }
                .font(.system(size: 9, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.34))
                .lineLimit(1)
            }
        }
    }
}

private struct WidgetProgressBar: View {
    let progress: Double
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: max(height, geometry.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

enum WidgetStyle {
    static func percent(_ progress: Double) -> Int {
        Int((min(max(progress, 0), 1) * 100).rounded(.down))
    }

    /// 从 "已63% · 剩8小时22分" 中取 "剩8小时22分",避免重算一遍剩余口径。
    static func remainingText(from snapshot: ProgressSnapshot) -> String {
        snapshot.statusText.components(separatedBy: " · ").last ?? snapshot.statusText
    }
}
