import SwiftUI

struct ClockDashboardView: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @EnvironmentObject private var clockEngine: ClockEngine

    let openSettings: () -> Void

    init(openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
    }

    var body: some View {
        GeometryReader { geometry in
            let timeFontSize = max(52, min(geometry.size.width * 0.17, geometry.size.height * 0.26))
            let timeParts = DisplayFormatting.timeDisplayParts(from: clockEngine.now, precision: settingsStore.timePrecision, timeZone: settingsStore.effectiveTimeZone)
            let dateFontSize = max(18, timeFontSize * 0.20)
            let snapshots = buildSnapshots()

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(settingsStore.backgroundOpacity))

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: max(18, geometry.size.height * 0.028)) {
                        VStack(alignment: .leading, spacing: 10) {
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

                            HStack(alignment: .firstTextBaseline, spacing: 10) {
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
                            Text("当前没有启用任何进度条。去设置里打开内置条目，或者新增一个自定义区间。")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.60))
                                .padding(.vertical, 16)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                                    ProgressBarRowView(snapshot: snapshot)
                                        .padding(.top, extraGroupGap(at: index, in: snapshots))
                                }
                            }
                        }

                    }
                    .padding(.horizontal, max(26, geometry.size.width * 0.05))
                    .padding(.vertical, max(24, geometry.size.height * 0.05))
                }
            }
            .padding(1)
            .contextMenu {
                Button(settingsStore.windowMode == .floating ? "切回普通窗口" : "悬浮在其他 App 之上") {
                    settingsStore.toggleWindowMode()
                }
                Button("打开设置") {
                    openSettings()
                }
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

    /// 微观组(10分钟/小时/今日)与宏观组(周/月/年/世纪)之间加一道呼吸位,形成视觉节奏。
    private func extraGroupGap(at index: Int, in snapshots: [ProgressSnapshot]) -> CGFloat {
        guard index > 0,
              let previousKind = snapshots[index - 1].kind,
              let currentKind = snapshots[index].kind else { return 0 }

        let subDayKinds: Set<ProgressKind> = [.tenMinute, .hour, .day]
        return subDayKinds.contains(previousKind) && !subDayKinds.contains(currentKind) ? 14 : 0
    }
}
