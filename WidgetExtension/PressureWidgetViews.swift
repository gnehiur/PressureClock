import AppKit
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

// MARK: - 小尺寸:今日为主角(带刻度),周/月/年迷你条

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
                        .font(.system(size: 30, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.96))
                    Text("%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                    Spacer(minLength: 0)
                    Text(WidgetStyle.remainingText(from: day))
                        .font(.system(size: 10, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                WidgetAxisBar(snapshot: day, metrics: .compact)
                    .padding(.top, 4)
            }

            Spacer(minLength: 5)

            VStack(alignment: .leading, spacing: 5) {
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

                WidgetPlainBar(progress: snapshot.progress, height: 3.5)

                Text("\(WidgetStyle.percent(snapshot.progress))%")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
}

// MARK: - 中尺寸:四行刻度条,首尾标签同行夹轴

private struct MediumPressureView: View {
    private static let kinds: [ProgressKind] = [.day, .week, .month, .year]

    let entry: PressureEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Self.kinds, id: \.self) { kind in
                if let snapshot = entry.snapshots[kind] {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(snapshot.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.94))

                            Spacer(minLength: 8)

                            Text(snapshot.statusText)
                                .font(.system(size: 10.5, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.60))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }

                        HStack(spacing: 6) {
                            Text(snapshot.leftLabel)
                                .font(.system(size: 8.5, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.40))
                                .lineLimit(1)

                            WidgetAxisBar(snapshot: snapshot, metrics: .compact)

                            Text(snapshot.rightLabel)
                                .font(.system(size: 8.5, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.40))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

// MARK: - 大尺寸:日期抬头 + 四行完整版(轴标签行+刻度轴)

private struct LargePressureView: View {
    private static let kinds: [ProgressKind] = [.day, .week, .month, .year]

    let entry: PressureEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

                        WidgetLabeledAxis(snapshot: snapshot, metrics: .large)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

// MARK: - 刻度轴渲染(移植自主 App ProgressBarRowView,按小组件尺寸缩小)

struct WidgetAxisMetrics {
    var labelFontSize: CGFloat = 9.5
    var labelLineHeight: CGFloat = 12
    var labelToAxisSpacing: CGFloat = 2
    var minimumLabelGap: CGFloat = 8
    var axisHeight: CGFloat
    var trackHeight: CGFloat
    var highlightTickWidth: CGFloat = 1.7
    var majorTickWidth: CGFloat = 1.3
    var minorTickWidth: CGFloat = 1.0
    var boundaryTickHeight: CGFloat
    var highlightTickHeight: CGFloat
    var majorTickHeight: CGFloat
    var minorTickHeight: CGFloat
    var markerWidth: CGFloat

    var trackVerticalOffset: CGFloat {
        (axisHeight - trackHeight) / 2
    }

    static let large = WidgetAxisMetrics(
        axisHeight: 15,
        trackHeight: 5,
        boundaryTickHeight: 15,
        highlightTickHeight: 13,
        majorTickHeight: 11,
        minorTickHeight: 7,
        markerWidth: 2.2
    )

    static let compact = WidgetAxisMetrics(
        axisHeight: 11,
        trackHeight: 4.5,
        boundaryTickHeight: 11,
        highlightTickHeight: 9.5,
        majorTickHeight: 8.5,
        minorTickHeight: 5.5,
        markerWidth: 2.0
    )
}

/// 轴标签行 + 刻度轴(大尺寸用),与主 App 同一套碰撞避让布局。
struct WidgetLabeledAxis: View {
    let snapshot: ProgressSnapshot
    let metrics: WidgetAxisMetrics

    var body: some View {
        GeometryReader { geometry in
            let labels = WidgetAxisLayout.laidOutLabels(
                snapshot.axisLabels,
                width: geometry.size.width,
                metrics: metrics
            )

            VStack(alignment: .leading, spacing: metrics.labelToAxisSpacing) {
                ZStack(alignment: .topLeading) {
                    ForEach(labels) { item in
                        Text(item.label.text)
                            .font(.system(
                                size: metrics.labelFontSize,
                                weight: item.label.prominence == .boundary || item.label.prominence == .highlight ? .semibold : .medium
                            ))
                            .monospacedDigit()
                            .foregroundStyle(WidgetStyle.labelColor(item.label.prominence))
                            .frame(width: item.frame.width, height: metrics.labelLineHeight, alignment: item.alignment)
                            .position(x: item.frame.midX, y: metrics.labelLineHeight / 2)
                    }
                }
                .frame(height: metrics.labelLineHeight)

                WidgetAxisBar(snapshot: snapshot, metrics: metrics)
            }
        }
        .frame(height: metrics.labelLineHeight + metrics.labelToAxisSpacing + metrics.axisHeight)
    }
}

/// 刻度轴本体:轨道 + 进度填充 + 首尾界碑 + 自适应刻度 + 当前位置游标。
struct WidgetAxisBar: View {
    let snapshot: ProgressSnapshot
    let metrics: WidgetAxisMetrics

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let ticks = WidgetAxisLayout.adaptiveTicks(snapshot.ticks, width: width)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: metrics.trackHeight)
                    .offset(y: metrics.trackVerticalOffset)

                Rectangle()
                    .fill(Color.white.opacity(0.82))
                    .frame(
                        width: max(width * min(max(snapshot.progress, 0), 1), 0),
                        height: metrics.trackHeight
                    )
                    .offset(y: metrics.trackVerticalOffset)

                ForEach(WidgetAxisLayout.boundaryTickPositions(snapshot.axisLabels), id: \.self) { position in
                    tick(
                        at: position,
                        width: metrics.majorTickWidth,
                        height: metrics.boundaryTickHeight,
                        color: .white.opacity(0.30),
                        totalWidth: width
                    )
                }

                ForEach(ticks) { item in
                    tick(
                        at: item.position,
                        width: WidgetStyle.tickWidth(item.prominence, metrics: metrics),
                        height: WidgetStyle.tickHeight(item.prominence, metrics: metrics),
                        color: WidgetStyle.tickColor(item.prominence),
                        totalWidth: width
                    )
                }

                Rectangle()
                    .fill(Color.white.opacity(0.98))
                    .frame(width: metrics.markerWidth, height: metrics.axisHeight)
                    .offset(x: WidgetAxisLayout.horizontalOffset(
                        for: snapshot.progress,
                        itemWidth: metrics.markerWidth,
                        totalWidth: width
                    ))
            }
        }
        .frame(height: metrics.axisHeight)
    }

    private func tick(
        at position: Double,
        width: CGFloat,
        height: CGFloat,
        color: Color,
        totalWidth: CGFloat
    ) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .offset(
                x: WidgetAxisLayout.horizontalOffset(for: position, itemWidth: width, totalWidth: totalWidth),
                y: (metrics.axisHeight - height) / 2
            )
    }
}

/// 布局纯函数:刻度按可用宽度取舍、轴标签碰撞避让,算法与主 App 一致。
enum WidgetAxisLayout {
    struct LaidOutLabel: Identifiable {
        let label: ProgressAxisLabel
        let frame: CGRect
        let alignment: Alignment

        var id: String {
            label.id
        }
    }

    static func adaptiveTicks(_ ticks: [ProgressTick], width: CGFloat) -> [ProgressTick] {
        let sorted = ticks.sorted { $0.position < $1.position }
        let highlights = filterTicks(
            sorted.filter { $0.prominence == .highlight },
            width: width,
            minSpacing: 40
        )
        let majors = filterTicks(
            sorted.filter { $0.prominence == .major },
            width: width,
            minSpacing: 30,
            avoiding: highlights
        )
        let minors = filterTicks(
            sorted.filter { $0.prominence == .minor },
            width: width,
            minSpacing: 12,
            avoiding: highlights + majors
        )
        return (highlights + majors + minors).sorted { $0.position < $1.position }
    }

    private static func filterTicks(
        _ ticks: [ProgressTick],
        width: CGFloat,
        minSpacing: CGFloat,
        avoiding existing: [ProgressTick] = []
    ) -> [ProgressTick] {
        let minimumDelta = Double(minSpacing / max(width, 1))
        var keptPositions = existing.map(\.position)
        var result: [ProgressTick] = []

        for tick in ticks {
            if keptPositions.allSatisfy({ abs($0 - tick.position) >= minimumDelta }) {
                result.append(tick)
                keptPositions.append(tick.position)
            }
        }
        return result
    }

    static func boundaryTickPositions(_ labels: [ProgressAxisLabel]) -> [Double] {
        let epsilon = 0.0001
        let positions = labels
            .filter { $0.prominence == .boundary }
            .map(\.position)
            .filter { abs($0) <= epsilon || abs($0 - 1.0) <= epsilon }
            .sorted()

        var deduplicated: [Double] = []
        for position in positions {
            if deduplicated.last.map({ abs($0 - position) <= epsilon }) != true {
                deduplicated.append(position)
            }
        }
        return deduplicated
    }

    static func laidOutLabels(
        _ labels: [ProgressAxisLabel],
        width: CGFloat,
        metrics: WidgetAxisMetrics
    ) -> [LaidOutLabel] {
        let prioritized = labels.sorted { lhs, rhs in
            if lhs.prominence != rhs.prominence {
                return lhs.prominence.rawValue > rhs.prominence.rawValue
            }
            return lhs.position < rhs.position
        }

        var occupiedFrames: [CGRect] = []
        var result: [LaidOutLabel] = []

        for label in prioritized {
            let measuredWidth = min(measuredLabelWidth(for: label, metrics: metrics), max(width - 4, 0))
            let originX = labelOriginX(for: label.position, itemWidth: measuredWidth, totalWidth: width)
            let frame = CGRect(x: originX, y: 0, width: measuredWidth, height: metrics.labelLineHeight)

            let overlaps = occupiedFrames.contains { existing in
                !(frame.maxX + metrics.minimumLabelGap <= existing.minX || existing.maxX + metrics.minimumLabelGap <= frame.minX)
            }

            if !overlaps {
                result.append(
                    LaidOutLabel(label: label, frame: frame, alignment: alignment(for: label.position))
                )
                occupiedFrames.append(frame)
            }
        }

        return result.sorted { $0.label.position < $1.label.position }
    }

    static func horizontalOffset(for position: Double, itemWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let ideal = (totalWidth * CGFloat(position)) - (itemWidth / 2)
        return min(max(ideal, 0), max(totalWidth - itemWidth, 0))
    }

    private static func labelOriginX(for position: Double, itemWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let epsilon = 0.0001
        if position <= epsilon {
            return 0
        }
        if position >= 1.0 - epsilon {
            return max(totalWidth - itemWidth, 0)
        }
        return horizontalOffset(for: position, itemWidth: itemWidth, totalWidth: totalWidth)
    }

    private static func alignment(for position: Double) -> Alignment {
        let epsilon = 0.0001
        if position <= epsilon {
            return .leading
        }
        if position >= 1.0 - epsilon {
            return .trailing
        }
        return .center
    }

    private static func measuredLabelWidth(for label: ProgressAxisLabel, metrics: WidgetAxisMetrics) -> CGFloat {
        let weight: NSFont.Weight = label.prominence == .boundary || label.prominence == .highlight ? .semibold : .medium
        let font = NSFont.systemFont(ofSize: metrics.labelFontSize, weight: weight)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((label.text as NSString).size(withAttributes: attributes).width) + 6
    }
}

// MARK: - 共享部件

private struct WidgetPlainBar: View {
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

    static func labelColor(_ prominence: ProgressAxisLabelProminence) -> Color {
        switch prominence {
        case .boundary:
            return .white.opacity(0.70)
        case .highlight:
            return .white.opacity(0.74)
        case .major:
            return .white.opacity(0.45)
        case .minor:
            return .white.opacity(0.26)
        }
    }

    static func tickColor(_ prominence: ProgressTickProminence) -> Color {
        switch prominence {
        case .highlight:
            return .white.opacity(0.42)
        case .major:
            return .white.opacity(0.22)
        case .minor:
            return .white.opacity(0.12)
        }
    }

    static func tickWidth(_ prominence: ProgressTickProminence, metrics: WidgetAxisMetrics) -> CGFloat {
        switch prominence {
        case .highlight:
            return metrics.highlightTickWidth
        case .major:
            return metrics.majorTickWidth
        case .minor:
            return metrics.minorTickWidth
        }
    }

    static func tickHeight(_ prominence: ProgressTickProminence, metrics: WidgetAxisMetrics) -> CGFloat {
        switch prominence {
        case .highlight:
            return metrics.highlightTickHeight
        case .major:
            return metrics.majorTickHeight
        case .minor:
            return metrics.minorTickHeight
        }
    }
}
