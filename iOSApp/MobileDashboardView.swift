import SwiftUI

struct MobileDashboardView: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @EnvironmentObject private var clockEngine: ClockEngine
    @State private var showsSettings = false

    var body: some View {
        GeometryReader { geometry in
            let timeFontSize = max(44, min(geometry.size.width * 0.21, geometry.size.height * 0.26))
            let timeParts = DisplayFormatting.timeDisplayParts(from: clockEngine.now, precision: settingsStore.timePrecision, timeZone: settingsStore.effectiveTimeZone)
            let dateFontSize = max(16, timeFontSize * 0.20)
            let snapshots = buildSnapshots()

            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: max(16, geometry.size.height * 0.024)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text(timeParts.primaryText)
                                    .font(.system(size: timeFontSize, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.58)

                                if let fractionalText = timeParts.fractionalText {
                                    Text(fractionalText)
                                        .font(.system(size: timeFontSize * 0.5, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.34))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .monospacedDigit()

                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(DisplayFormatting.dateString(from: clockEngine.progressNow, timeZone: settingsStore.effectiveTimeZone))
                                    .font(.system(size: dateFontSize, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.62))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text(DisplayFormatting.yearContextString(from: clockEngine.progressNow, calendar: settingsStore.effectiveCalendar))
                                    .font(.system(size: dateFontSize * 0.78, weight: .medium))
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.36))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }

                        if snapshots.isEmpty {
                            Text("当前没有启用任何进度条。")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.60))
                                .padding(.vertical, 16)
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                                    ProgressBarRowView(snapshot: snapshot)
                                        .padding(.top, extraGroupGap(at: index, in: snapshots))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, max(20, geometry.size.width * 0.05))
                    .padding(.top, max(18, geometry.size.height * 0.03))
                    .padding(.bottom, 24)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.30))
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, max(6, geometry.size.height * 0.015))
                .padding(.trailing, 8)
            }
            .sheet(isPresented: $showsSettings) {
                MobileSettingsView()
                    .environmentObject(settingsStore)
            }
        }
    }

    private func buildSnapshots() -> [ProgressSnapshot] {
        settingsStore.orderedProgressItems.compactMap { item in
            ProgressCalculator.snapshot(for: item, at: referenceDate(for: item), calendar: settingsStore.effectiveCalendar, sleepSchedule: settingsStore.sleepSchedule)
        }
    }

    private func referenceDate(for item: ProgressItem) -> Date {
        item.prefersHighFrequencyProgressUpdates ? clockEngine.smoothNow : clockEngine.progressNow
    }

    /// 微观组(10分钟/小时/今日)与宏观组(周/月/年)之间加一道呼吸位。
    private func extraGroupGap(at index: Int, in snapshots: [ProgressSnapshot]) -> CGFloat {
        guard index > 0,
              let previousKind = snapshots[index - 1].kind,
              let currentKind = snapshots[index].kind else { return 0 }

        let subDayKinds: Set<ProgressKind> = [.tenMinute, .hour, .day]
        return subDayKinds.contains(previousKind) && !subDayKinds.contains(currentKind) ? 12 : 0
    }
}
