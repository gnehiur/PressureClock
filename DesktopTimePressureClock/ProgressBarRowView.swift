#if canImport(AppKit)
import AppKit
private typealias PlatformFont = NSFont
#else
import UIKit
private typealias PlatformFont = UIFont
#endif
import SwiftUI

struct ProgressBarRowView: View {
    let snapshot: ProgressSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(snapshot.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))

                Spacer(minLength: 12)

                Text(snapshot.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            GeometryReader { geometry in
                let metrics = axisMetrics(for: geometry.size.width)
                let labels = laidOutLabels(for: geometry.size.width, metrics: metrics)
                let ticks = adaptiveTicks(for: geometry.size.width)

                VStack(alignment: .leading, spacing: metrics.labelToAxisSpacing) {
                    ZStack(alignment: .topLeading) {
                        ForEach(labels) { item in
                            Text(item.label.text)
                                .font(labelFont(for: item.label, metrics: metrics))
                                .monospacedDigit()
                                .foregroundStyle(labelColor(for: item.label))
                                .frame(width: item.frame.width, height: metrics.labelLineHeight, alignment: item.alignment)
                                .position(x: item.frame.midX, y: metrics.labelLineHeight / 2)
                        }
                    }
                    .frame(height: metrics.labelLineHeight)

                    ZStack(alignment: .leading) {
                        trackBackground(metrics: metrics)

                        progressFill(width: geometry.size.width, metrics: metrics)

                        ForEach(Array(snapshot.shadedRegions.enumerated()), id: \.offset) { _, region in
                            shadedRegionView(region: region, width: geometry.size.width, metrics: metrics)
                        }

                        ForEach(boundaryTickPositions, id: \.self) { position in
                            tickView(
                                x: horizontalOffset(for: position, itemWidth: metrics.majorTickWidth, totalWidth: geometry.size.width),
                                width: metrics.majorTickWidth,
                                height: metrics.boundaryTickHeight,
                                color: Color.white.opacity(0.30),
                                metrics: metrics
                            )
                        }

                        ForEach(ticks) { tick in
                            let tickWidth = width(for: tick.prominence, metrics: metrics)
                            let tickHeight = height(for: tick.prominence, metrics: metrics)
                            tickView(
                                x: horizontalOffset(
                                    for: tick.position,
                                    itemWidth: tickWidth,
                                    totalWidth: geometry.size.width
                                ),
                                width: tickWidth,
                                height: tickHeight,
                                color: color(for: tick.prominence),
                                metrics: metrics
                            )
                        }

                        markerView(width: geometry.size.width, metrics: metrics)
                    }
                    .frame(height: metrics.axisHeight)

                    if showsFooterBoundaryLabels {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(snapshot.footerLeftText ?? "")
                                .font(.system(size: 10.5, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Spacer(minLength: 12)

                            Text(snapshot.footerRightText ?? "")
                                .font(.system(size: 10.5, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                }
            }
            .frame(height: showsFooterBoundaryLabels ? 66 : 50)
        }
    }

    private var showsFooterBoundaryLabels: Bool {
        snapshot.footerLeftText != nil || snapshot.footerRightText != nil
    }

    private var boundaryTickPositions: [Double] {
        let epsilon = 0.0001
        let positions = snapshot.axisLabels
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

    private func trackBackground(metrics: AxisMetrics) -> some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.10))
            .frame(height: metrics.trackHeight)
            .offset(y: metrics.trackVerticalOffset)
    }

    private func progressFill(width: CGFloat, metrics: AxisMetrics) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.82))
            .frame(width: max(snapped(width * snapshot.progress), 0), height: metrics.trackHeight)
            .offset(y: metrics.trackVerticalOffset)
    }

    /// 睡眠区间压暗:黑色半透明罩在轨道与填充之上、刻度之下;区间边界(非条头条尾)立一根记号
    private func shadedRegionView(region: ClosedRange<Double>, width: CGFloat, metrics: AxisMetrics) -> some View {
        let epsilon = 0.0001
        let startX = snapped(width * CGFloat(region.lowerBound))
        let regionWidth = max(snapped(width * CGFloat(region.upperBound - region.lowerBound)), 0)
        let edges = [region.lowerBound, region.upperBound].filter { $0 > epsilon && $0 < 1.0 - epsilon }

        return ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(width: regionWidth, height: metrics.trackHeight)
                .offset(x: startX, y: metrics.trackVerticalOffset)

            ForEach(edges, id: \.self) { edge in
                Rectangle()
                    .fill(Color.white.opacity(0.46))
                    .frame(width: metrics.majorTickWidth, height: metrics.boundaryTickHeight)
                    .offset(
                        x: snappedHorizontalOffset(for: edge, itemWidth: metrics.majorTickWidth, totalWidth: width),
                        y: (metrics.axisHeight - metrics.boundaryTickHeight) / 2
                    )
            }
        }
    }

    private func markerView(width: CGFloat, metrics: AxisMetrics) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.98))
            .frame(width: metrics.markerWidth, height: metrics.axisHeight)
            .offset(
                x: snappedHorizontalOffset(for: snapshot.progress, itemWidth: metrics.markerWidth, totalWidth: width),
                y: 0
            )
    }

    private func tickView(
        x: CGFloat,
        width: CGFloat,
        height: CGFloat,
        color: Color,
        metrics: AxisMetrics
    ) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .offset(x: snapped(x), y: (metrics.axisHeight - height) / 2)
    }

    private func adaptiveTicks(for width: CGFloat) -> [ProgressTick] {
        let sortedTicks = snapshot.ticks.sorted { $0.position < $1.position }
        let highlightTicks = sortedTicks.filter { $0.prominence == .highlight }
        let majorTicks = sortedTicks.filter { $0.prominence == .major }
        let minorTicks = sortedTicks.filter { $0.prominence == .minor }

        let keptHighlights = filterTicks(
            highlightTicks,
            width: width,
            minSpacing: width < 320 ? 52 : width < 520 ? 40 : width < 900 ? 32 : 24
        )

        let keptMajor = filterTicks(
            majorTicks,
            width: width,
            minSpacing: width < 320 ? 46 : width < 520 ? 34 : width < 900 ? 28 : 22,
            avoiding: keptHighlights
        )

        let keptMinor = filterTicks(
            minorTicks,
            width: width,
            minSpacing: width < 320 ? 20 : width < 520 ? 16 : width < 900 ? 12 : 10,
            avoiding: keptHighlights + keptMajor
        )

        return (keptHighlights + keptMajor + keptMinor).sorted { $0.position < $1.position }
    }

    private func filterTicks(
        _ ticks: [ProgressTick],
        width: CGFloat,
        minSpacing: CGFloat,
        avoiding existingTicks: [ProgressTick] = []
    ) -> [ProgressTick] {
        let minimumDelta = Double(minSpacing / max(width, 1))
        var keptPositions = existingTicks.map(\.position)
        var result: [ProgressTick] = []

        for tick in ticks {
            if keptPositions.allSatisfy({ abs($0 - tick.position) >= minimumDelta }) {
                result.append(tick)
                keptPositions.append(tick.position)
            }
        }

        return result
    }

    private func laidOutLabels(for width: CGFloat, metrics: AxisMetrics) -> [LaidOutAxisLabel] {
        if snapshot.axisLabelDisplayMode == .all {
            return snapshot.axisLabels
                .sorted { $0.position < $1.position }
                .map { label in
                    let measuredWidth = min(
                        measuredLabelWidth(for: label, metrics: metrics),
                        max(width - 2, 0)
                    )
                    let originX = labelOriginX(for: label.position, itemWidth: measuredWidth, totalWidth: width)
                    return LaidOutAxisLabel(
                        label: label,
                        frame: CGRect(x: originX, y: 0, width: measuredWidth, height: metrics.labelLineHeight),
                        alignment: textAlignment(for: label.position)
                    )
                }
        }

        let candidates = prioritizedLabels()
        var occupiedFrames: [CGRect] = []
        var result: [LaidOutAxisLabel] = []

        for label in candidates {
            let measuredWidth = min(
                measuredLabelWidth(for: label, metrics: metrics),
                max(width - 4, 0)
            )
            let originX = labelOriginX(for: label.position, itemWidth: measuredWidth, totalWidth: width)
            let frame = CGRect(x: originX, y: 0, width: measuredWidth, height: metrics.labelLineHeight)

            let overlaps = occupiedFrames.contains { existing in
                !(frame.maxX + metrics.minimumLabelGap <= existing.minX || existing.maxX + metrics.minimumLabelGap <= frame.minX)
            }

            if !overlaps {
                result.append(
                    LaidOutAxisLabel(
                        label: label,
                        frame: frame,
                        alignment: textAlignment(for: label.position)
                    )
                )
                occupiedFrames.append(frame)
            }
        }

        return result.sorted { $0.label.position < $1.label.position }
    }

    private func prioritizedLabels() -> [ProgressAxisLabel] {
        snapshot.axisLabels.sorted { lhs, rhs in
            if lhs.prominence != rhs.prominence {
                return lhs.prominence.rawValue > rhs.prominence.rawValue
            }

            return lhs.position < rhs.position
        }
    }

    private func horizontalOffset(for position: Double, itemWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let ideal = (totalWidth * CGFloat(position)) - (itemWidth / 2)
        return min(max(ideal, 0), max(totalWidth - itemWidth, 0))
    }

    private func snappedHorizontalOffset(for position: Double, itemWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        snapped(horizontalOffset(for: position, itemWidth: itemWidth, totalWidth: totalWidth))
    }

    private func snapped(_ value: CGFloat) -> CGFloat {
        #if os(macOS)
        let scale = CGFloat(NSScreen.main?.backingScaleFactor ?? 2.0)
        #else
        let scale = UIScreen.main.scale
        #endif
        guard scale > 0 else { return value }
        return (value * scale).rounded() / scale
    }

    private func labelOriginX(for position: Double, itemWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let epsilon = 0.0001

        if position <= epsilon {
            return 0
        }

        if position >= 1.0 - epsilon {
            return max(totalWidth - itemWidth, 0)
        }

        return horizontalOffset(for: position, itemWidth: itemWidth, totalWidth: totalWidth)
    }

    private func textAlignment(for position: Double) -> Alignment {
        let epsilon = 0.0001

        if position <= epsilon {
            return .leading
        }

        if position >= 1.0 - epsilon {
            return .trailing
        }

        return .center
    }

    private func measuredLabelWidth(for label: ProgressAxisLabel, metrics: AxisMetrics) -> CGFloat {
        let fontSize = snapshot.axisLabelDisplayMode == .all ? max(metrics.labelFontSize - 1.5, 9) : metrics.labelFontSize
        let font = PlatformFont.systemFont(
            ofSize: fontSize,
            weight: nsFontWeight(for: label.prominence)
        )
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let horizontalPadding: CGFloat = snapshot.axisLabelDisplayMode == .all ? 4 : 8
        return ceil((label.text as NSString).size(withAttributes: attributes).width) + horizontalPadding
    }

    private func labelFont(for label: ProgressAxisLabel, metrics: AxisMetrics) -> Font {
        if snapshot.axisLabelDisplayMode == .all {
            return .system(
                size: max(metrics.labelFontSize - 1.5, 9),
                weight: label.prominence == .boundary || label.prominence == .highlight ? .semibold : .medium
            )
        }

        return .system(
            size: metrics.labelFontSize,
            weight: label.prominence == .boundary || label.prominence == .highlight ? .semibold : .medium
        )
    }

    private func labelColor(for label: ProgressAxisLabel) -> Color {
        switch label.prominence {
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

    private func nsFontWeight(for prominence: ProgressAxisLabelProminence) -> PlatformFont.Weight {
        switch prominence {
        case .boundary:
            return .semibold
        case .highlight:
            return .semibold
        case .major:
            return .medium
        case .minor:
            return .regular
        }
    }

    private func width(for prominence: ProgressTickProminence, metrics: AxisMetrics) -> CGFloat {
        switch prominence {
        case .highlight:
            return metrics.highlightTickWidth
        case .major:
            return metrics.majorTickWidth
        case .minor:
            return metrics.minorTickWidth
        }
    }

    private func height(for prominence: ProgressTickProminence, metrics: AxisMetrics) -> CGFloat {
        switch prominence {
        case .highlight:
            return metrics.highlightTickHeight
        case .major:
            return metrics.majorTickHeight
        case .minor:
            return metrics.minorTickHeight
        }
    }

    private func color(for prominence: ProgressTickProminence) -> Color {
        switch prominence {
        case .highlight:
            return .white.opacity(0.42)
        case .major:
            return .white.opacity(0.22)
        case .minor:
            return .white.opacity(0.12)
        }
    }

    private func axisMetrics(for width: CGFloat) -> AxisMetrics {
        switch width {
        case ..<320:
            return AxisMetrics(
                labelFontSize: 10,
                labelLineHeight: 14,
                labelToAxisSpacing: 4,
                minimumLabelGap: 10,
                axisHeight: 18,
                trackHeight: 6,
                highlightTickWidth: 1.8,
                majorTickWidth: 1.4,
                minorTickWidth: 1.0,
                boundaryTickHeight: 18,
                highlightTickHeight: 16,
                majorTickHeight: 14,
                minorTickHeight: 8,
                markerWidth: 2.2
            )
        case ..<560:
            return AxisMetrics(
                labelFontSize: 11,
                labelLineHeight: 16,
                labelToAxisSpacing: 5,
                minimumLabelGap: 14,
                axisHeight: 20,
                trackHeight: 6.5,
                highlightTickWidth: 1.9,
                majorTickWidth: 1.5,
                minorTickWidth: 1.0,
                boundaryTickHeight: 20,
                highlightTickHeight: 17,
                majorTickHeight: 15,
                minorTickHeight: 9,
                markerWidth: 2.4
            )
        case ..<900:
            return AxisMetrics(
                labelFontSize: 11.5,
                labelLineHeight: 17,
                labelToAxisSpacing: 5,
                minimumLabelGap: 18,
                axisHeight: 22,
                trackHeight: 7,
                highlightTickWidth: 2.0,
                majorTickWidth: 1.6,
                minorTickWidth: 1.0,
                boundaryTickHeight: 22,
                highlightTickHeight: 18,
                majorTickHeight: 16,
                minorTickHeight: 10,
                markerWidth: 2.6
            )
        default:
            return AxisMetrics(
                labelFontSize: 12,
                labelLineHeight: 18,
                labelToAxisSpacing: 6,
                minimumLabelGap: 24,
                axisHeight: 24,
                trackHeight: 7.5,
                highlightTickWidth: 2.1,
                majorTickWidth: 1.7,
                minorTickWidth: 1.0,
                boundaryTickHeight: 24,
                highlightTickHeight: 20,
                majorTickHeight: 18,
                minorTickHeight: 10,
                markerWidth: 2.8
            )
        }
    }
}

private struct AxisMetrics {
    let labelFontSize: CGFloat
    let labelLineHeight: CGFloat
    let labelToAxisSpacing: CGFloat
    let minimumLabelGap: CGFloat
    let axisHeight: CGFloat
    let trackHeight: CGFloat
    let highlightTickWidth: CGFloat
    let majorTickWidth: CGFloat
    let minorTickWidth: CGFloat
    let boundaryTickHeight: CGFloat
    let highlightTickHeight: CGFloat
    let majorTickHeight: CGFloat
    let minorTickHeight: CGFloat
    let markerWidth: CGFloat

    var trackVerticalOffset: CGFloat {
        (axisHeight - trackHeight) / 2
    }
}

private struct LaidOutAxisLabel: Identifiable {
    let label: ProgressAxisLabel
    let frame: CGRect
    let alignment: Alignment

    var id: String {
        label.id
    }
}
