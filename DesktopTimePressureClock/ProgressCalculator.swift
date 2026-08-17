import Foundation

enum ProgressCalculator {
    static func snapshot(
        for item: ProgressItem,
        at now: Date,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = DisplayFormatting.interfaceLocale,
        sleepSchedule: SleepScheduleConfig? = nil
    ) -> ProgressSnapshot? {
        guard item.isEnabled else { return nil }

        switch item.kind {
        case .tenMinute:
            guard let interval = tenMinuteInterval(containing: now, calendar: calendar) else { return nil }
            let tenMinuteValue = tenMinuteProgress(at: now, interval: interval)
            return makeSnapshot(
                item: item,
                progress: tenMinuteValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: tenMinuteValue, remaining: interval.end.timeIntervalSince(now), kind: .tenMinute),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: formatHourMinute(interval.start, calendar: calendar),
                rightLabel: formatHourMinute(interval.end, calendar: calendar),
                ticks: tenMinuteTicks(),
                axisLabels: tenMinuteAxisLabels(in: interval, calendar: calendar),
                axisLabelDisplayMode: .all
            )

        case .hour:
            guard let interval = calendar.dateInterval(of: .hour, for: now) else { return nil }
            let hourValue = hourProgress(at: now, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: hourValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: hourValue, remaining: interval.end.timeIntervalSince(now), kind: .hour),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: formatHourMinute(interval.start, calendar: calendar),
                rightLabel: formatHourMinute(interval.end, calendar: calendar),
                ticks: hourTicks(),
                axisLabels: hourAxisLabels(in: interval, calendar: calendar)
            )

        case .day:
            guard let interval = calendar.dateInterval(of: .day, for: now) else { return nil }
            let dayValue = dayProgress(at: now, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: dayValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: dayValue, remaining: interval.end.timeIntervalSince(now), kind: .day),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: "0.00",
                rightLabel: "24.00",
                ticks: dayTicks(),
                axisLabels: dayAxisLabels(),
                shadedRegions: sleepShadedRegions(for: sleepSchedule)
            )

        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
            let lastDay = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            let weekValue = weekProgress(at: now, in: interval, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: weekValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: weekValue, remaining: interval.end.timeIntervalSince(now), kind: .week),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: formatWeekday(interval.start, locale: locale),
                rightLabel: formatWeekday(lastDay, locale: locale),
                ticks: weekTicks(),
                axisLabels: weekAxisLabels(in: interval, locale: locale, calendar: calendar)
            )

        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return nil }
            let lastDay = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            let endDay = calendar.component(.day, from: lastDay)
            let monthValue = monthProgress(at: now, dayCount: endDay, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: monthValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: monthValue, remaining: interval.end.timeIntervalSince(now), kind: .month),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: "1日",
                rightLabel: "\(endDay)日",
                ticks: monthTicks(dayCount: endDay),
                axisLabels: monthAxisLabels(dayCount: endDay)
            )

        case .year:
            guard let interval = calendar.dateInterval(of: .year, for: now) else { return nil }
            let lastMonth = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            let yearValue = yearProgress(at: now, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: yearValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: yearValue, remaining: interval.end.timeIntervalSince(now), kind: .year),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: formatMonth(interval.start, locale: locale, calendar: calendar),
                rightLabel: formatMonth(lastMonth, locale: locale, calendar: calendar),
                ticks: yearTicks(),
                axisLabels: yearAxisLabels(locale: locale)
            )

        case .century:
            guard let interval = centuryInterval(containing: now, calendar: calendar) else { return nil }
            let startYear = calendar.component(.year, from: interval.start)
            let centuryValue = centuryProgress(at: now, interval: interval, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: centuryValue,
                title: item.displayTitle,
                statusText: pressureStatusText(progress: centuryValue, remaining: interval.end.timeIntervalSince(now), kind: .century),
                footerLeftText: nil,
                footerRightText: nil,
                leftLabel: "\(startYear)",
                rightLabel: "\(startYear + 99)",
                ticks: centuryTicks(),
                axisLabels: centuryAxisLabels(in: interval, calendar: calendar)
            )

        case .customFixed:
            guard
                let customConfig = item.customConfig,
                let interval = resolvedCustomInterval(for: customConfig, calendar: calendar)
            else {
                return nil
            }

            if now > interval.end, !customConfig.keepVisibleAfterCompletion {
                return nil
            }

            let progress = clampedProgress(for: now, in: interval)
            let footerBoundaryTexts = customFooterBoundaryTexts(for: customConfig, locale: locale, calendar: calendar)
            return makeSnapshot(
                item: item,
                progress: progress,
                title: item.displayTitle,
                statusText: customStatusText(for: interval, now: now, progress: progress),
                footerLeftText: footerBoundaryTexts.left,
                footerRightText: footerBoundaryTexts.right,
                leftLabel: customConfig.leftLabelOverride ?? formatBoundary(customConfig.startDate, now: now, locale: locale, calendar: calendar, usesTimePrecision: customConfig.usesTimePrecision),
                rightLabel: customConfig.rightLabelOverride ?? formatBoundary(customConfig.endDate, now: now, locale: locale, calendar: calendar, usesTimePrecision: customConfig.usesTimePrecision),
                ticks: customFixedTicks(),
                axisLabels: customFixedAxisLabels()
            )

        case .customRecurring:
            return nil
        }
    }

    private static func makeSnapshot(
        item: ProgressItem,
        progress: Double,
        title: String,
        statusText: String,
        footerLeftText: String?,
        footerRightText: String?,
        leftLabel: String,
        rightLabel: String,
        ticks: [ProgressTick],
        axisLabels: [ProgressAxisLabel],
        axisLabelDisplayMode: ProgressAxisLabelDisplayMode = .adaptive,
        shadedRegions: [ClosedRange<Double>] = []
    ) -> ProgressSnapshot {
        ProgressSnapshot(
            id: item.id,
            title: title,
            statusText: statusText,
            footerLeftText: footerLeftText,
            footerRightText: footerRightText,
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            progress: min(max(progress, 0.0), 1.0),
            ticks: ticks,
            axisLabels: axisLabels,
            axisLabelDisplayMode: axisLabelDisplayMode,
            kind: item.kind,
            shadedRegions: shadedRegions
        )
    }

    /// 睡眠时段 → 今日条上的归一化压暗区间;跨午夜拆成条尾+条头两段
    static func sleepShadedRegions(for schedule: SleepScheduleConfig?) -> [ClosedRange<Double>] {
        guard let schedule, schedule.isEnabled else { return [] }
        let dayMinutes = 1440.0
        let start = Double(((schedule.startMinutes % 1440) + 1440) % 1440) / dayMinutes
        let end = Double(((schedule.endMinutes % 1440) + 1440) % 1440) / dayMinutes

        if abs(start - end) < 0.0001 {
            return []
        }
        if start < end {
            return [start...end]
        }

        var regions: [ClosedRange<Double>] = []
        if start < 1.0 {
            regions.append(start...1.0)
        }
        if end > 0.0 {
            regions.append(0.0...end)
        }
        return regions
    }

    static func pressureStatusText(progress: Double, remaining: TimeInterval, kind: ProgressKind) -> String {
        let percent = Int((min(max(progress, 0.0), 1.0) * 100).rounded(.down))
        return "已\(percent)% · 剩\(remainingText(remaining, kind: kind))"
    }

    private static func remainingText(_ remaining: TimeInterval, kind: ProgressKind) -> String {
        let seconds = max(Int(remaining.rounded()), 0)
        switch kind {
        case .tenMinute:
            return String(format: "%d分%02d秒", seconds / 60, seconds % 60)
        case .hour:
            return "\(seconds / 60)分"
        case .day:
            let minutes = seconds / 60
            guard minutes >= 60 else { return "\(minutes)分" }
            let remainderMinutes = minutes % 60
            return remainderMinutes == 0 ? "\(minutes / 60)小时" : "\(minutes / 60)小时\(remainderMinutes)分"
        case .week, .month:
            let days = Double(seconds) / 86_400.0
            guard days >= 1 else { return remainingText(remaining, kind: .day) }
            return dayCountText(Int(days.rounded()))
        case .year, .customFixed, .customRecurring:
            return dayCountText(Int((Double(seconds) / 86_400.0).rounded()))
        case .century:
            let years = Double(seconds) / (86_400.0 * 365.2425)
            guard years >= 1 else { return remainingText(remaining, kind: .year) }
            return "\(Int(years.rounded()))年"
        }
    }

    /// 超过一周的天数,追加"X周零Y天"表达,如 "158天(22周零4天)"
    private static func dayCountText(_ days: Int) -> String {
        guard days > 7 else { return "\(days)天" }
        let weeks = days / 7
        let remainder = days % 7
        return remainder == 0 ? "\(days)天(\(weeks)周)" : "\(days)天(\(weeks)周零\(remainder)天)"
    }

    private static func clampedProgress(for now: Date, in interval: DateInterval) -> Double {
        let total = interval.duration
        guard total > 0 else { return 1.0 }
        let elapsed = now.timeIntervalSince(interval.start)
        return min(max(elapsed / total, 0.0), 1.0)
    }

    private static func resolvedCustomInterval(
        for customConfig: CustomProgressConfig,
        calendar: Calendar
    ) -> DateInterval? {
        if customConfig.usesTimePrecision {
            guard customConfig.endDate > customConfig.startDate else { return nil }
            return DateInterval(start: customConfig.startDate, end: customConfig.endDate)
        }

        let start = calendar.startOfDay(for: customConfig.startDate)
        let endDayStart = calendar.startOfDay(for: customConfig.endDate)
        guard endDayStart >= start else { return nil }
        guard let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: endDayStart) else {
            return nil
        }
        return DateInterval(start: start, end: exclusiveEnd)
    }

    private static func tenMinuteInterval(containing date: Date, calendar: Calendar) -> DateInterval? {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let minute = components.minute else { return nil }

        var startComponents = components
        startComponents.minute = (minute / 10) * 10
        startComponents.second = 0
        startComponents.nanosecond = 0

        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(byAdding: .minute, value: 10, to: start) else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }

    private static func centuryInterval(containing date: Date, calendar: Calendar) -> DateInterval? {
        let year = calendar.component(.year, from: date)
        let startYear = ((year - 1) / 100) * 100 + 1
        var components = DateComponents()
        components.year = startYear
        components.month = 1
        components.day = 1

        guard let start = calendar.date(from: components) else {
            return nil
        }

        guard let end = calendar.date(byAdding: .year, value: 100, to: start) else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }

    private static func dayTicks() -> [ProgressTick] {
        (1..<24).map { hour in
            ProgressTick(
                position: unitBoundaryPosition(index: hour, total: 24),
                prominence: hour.isMultiple(of: 6) ? .major : .minor
            )
        }
    }

    private static func tenMinuteTicks() -> [ProgressTick] {
        (1..<10).map { minute in
            ProgressTick(
                position: unitBoundaryPosition(index: minute, total: 10),
                prominence: minute == 5 ? .highlight : .major
            )
        }
    }

    private static func hourTicks() -> [ProgressTick] {
        stride(from: 5, to: 60, by: 5).map { minute in
            let prominence: ProgressTickProminence
            switch minute {
            case 30:
                prominence = .highlight
            case let value where value.isMultiple(of: 10):
                prominence = .major
            default:
                prominence = .minor
            }

            return ProgressTick(
                position: unitBoundaryPosition(index: minute, total: 60),
                prominence: prominence
            )
        }
    }

    private static func weekTicks() -> [ProgressTick] {
        (1..<14).map { halfDay in
            ProgressTick(
                position: unitBoundaryPosition(index: halfDay, total: 14),
                prominence: halfDay.isMultiple(of: 2) ? .major : .minor
            )
        }
    }

    private static func monthTicks(dayCount: Int) -> [ProgressTick] {
        guard dayCount > 1 else { return [] }

        var ticks = (1..<dayCount).map { dayOffset in
            ProgressTick(
                position: unitBoundaryPosition(index: dayOffset, total: dayCount),
                prominence: .minor
            )
        }

        ticks.append(contentsOf: monthDisplayDays(dayCount: dayCount).map { day in
            ProgressTick(
                position: unitDayCenterPosition(day: day, total: dayCount),
                prominence: .major
            )
        })

        return ticks.sorted { $0.position < $1.position }
    }

    private static func yearTicks() -> [ProgressTick] {
        (1..<12).map { monthIndex in
            ProgressTick(
                position: unitBoundaryPosition(index: monthIndex, total: 12),
                prominence: monthIndex.isMultiple(of: 3) ? .major : .minor
            )
        }
    }

    private static func centuryTicks() -> [ProgressTick] {
        stride(from: 5, to: 100, by: 5).map { yearOffset in
            ProgressTick(
                position: unitBoundaryPosition(index: yearOffset, total: 100),
                prominence: yearOffset.isMultiple(of: 10) ? .major : .minor
            )
        }
    }

    private static func customFixedTicks() -> [ProgressTick] {
        stride(from: 10, through: 90, by: 10).map { percent in
            ProgressTick(
                position: Double(percent) / 100.0,
                prominence: .major
            )
        }
    }

    private static func dayAxisLabels() -> [ProgressAxisLabel] {
        var labels: [ProgressAxisLabel] = [
            ProgressAxisLabel(position: 0.0, text: "00:00", prominence: .boundary),
            ProgressAxisLabel(position: 1.0, text: "24:00", prominence: .boundary)
        ]

        for hour in [6, 12, 18] {
            labels.append(
                ProgressAxisLabel(
                    position: unitBoundaryPosition(index: hour, total: 24),
                    text: String(format: "%02d:00", hour),
                    prominence: .major
                )
            )
        }

        for hour in [3, 9, 15, 21] {
            labels.append(
                ProgressAxisLabel(
                    position: unitBoundaryPosition(index: hour, total: 24),
                    text: String(format: "%02d:00", hour),
                    prominence: .minor
                )
            )
        }

        return labels.sorted { $0.position < $1.position }
    }

    private static func tenMinuteAxisLabels(in interval: DateInterval, calendar: Calendar) -> [ProgressAxisLabel] {
        (0...10).compactMap { minute in
            guard let date = calendar.date(byAdding: .minute, value: minute, to: interval.start) else {
                return nil
            }

            let prominence: ProgressAxisLabelProminence
            switch minute {
            case 0, 10:
                prominence = .boundary
            case 5:
                prominence = .highlight
            default:
                prominence = .major
            }

            return ProgressAxisLabel(
                position: Double(minute) / 10.0,
                text: String(format: "%02d", calendar.component(.minute, from: date)),
                prominence: prominence
            )
        }
    }

    private static func hourAxisLabels(in interval: DateInterval, calendar: Calendar) -> [ProgressAxisLabel] {
        let startHour = calendar.component(.hour, from: interval.start)
        let tenMinuteMarkers = [10, 20, 30, 40, 50]
        var labels: [ProgressAxisLabel] = [
            ProgressAxisLabel(position: 0.0, text: hourTimeLabel(hour: startHour, minute: 0), prominence: .boundary),
            ProgressAxisLabel(
                position: 1.0,
                text: hourTimeLabel(hour: (startHour + 1) % 24, minute: 0),
                prominence: .boundary
            )
        ]

        labels.append(contentsOf: tenMinuteMarkers.map { minute in
            ProgressAxisLabel(
                position: unitBoundaryPosition(index: minute, total: 60),
                text: hourTimeLabel(hour: startHour, minute: minute),
                prominence: minute == 30 ? .highlight : .major
            )
        })

        return labels.sorted { $0.position < $1.position }
    }

    private static func weekAxisLabels(in interval: DateInterval, locale: Locale, calendar: Calendar) -> [ProgressAxisLabel] {
        var labels: [ProgressAxisLabel] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: interval.start) else { continue }
            labels.append(
                ProgressAxisLabel(
                    position: unitCenterPosition(index: dayOffset, total: 7),
                    text: formatWeekday(date, locale: locale),
                    prominence: dayOffset == 0 || dayOffset == 6 ? .boundary : .major
                )
            )
        }

        return labels.sorted { $0.position < $1.position }
    }

    private static func monthAxisLabels(dayCount: Int) -> [ProgressAxisLabel] {
        guard dayCount >= 2 else {
            return [ProgressAxisLabel(position: 0.5, text: "1日", prominence: .major)]
        }

        return monthDisplayDays(dayCount: dayCount).map { day in
            ProgressAxisLabel(
                position: unitDayCenterPosition(day: day, total: dayCount),
                text: "\(day)日",
                prominence: .major
            )
        }
    }

    private static func yearAxisLabels(locale: Locale) -> [ProgressAxisLabel] {
        (1...12).map { month in
            ProgressAxisLabel(
                position: unitCenterPosition(index: month - 1, total: 12),
                text: locale.identifier.hasPrefix("zh") ? "\(month)月" : "\(month)",
                prominence: month == 1 || month == 12 ? .boundary : month == 4 || month == 7 || month == 10 ? .major : .minor
            )
        }
    }

    private static func centuryAxisLabels(in interval: DateInterval, calendar: Calendar) -> [ProgressAxisLabel] {
        let startYear = calendar.component(.year, from: interval.start)
        var labels: [ProgressAxisLabel] = [
            ProgressAxisLabel(position: 0.0, text: "\(startYear)", prominence: .boundary),
            ProgressAxisLabel(position: 1.0, text: "\(startYear + 99)", prominence: .boundary)
        ]

        for yearOffset in stride(from: 10, to: 100, by: 10) {
            labels.append(
                ProgressAxisLabel(
                    position: unitBoundaryPosition(index: yearOffset, total: 100),
                    text: "\(startYear + yearOffset)",
                    prominence: .major
                )
            )
        }

        for yearOffset in stride(from: 5, to: 100, by: 10) {
            labels.append(
                ProgressAxisLabel(
                    position: unitBoundaryPosition(index: yearOffset, total: 100),
                    text: "\(startYear + yearOffset)",
                    prominence: .minor
                )
            )
        }

        return labels.sorted { $0.position < $1.position }
    }

    private static func customFixedAxisLabels() -> [ProgressAxisLabel] {
        var labels: [ProgressAxisLabel] = [
            ProgressAxisLabel(position: 0.0, text: "0%", prominence: .boundary),
            ProgressAxisLabel(position: 1.0, text: "100%", prominence: .boundary)
        ]

        labels.append(contentsOf: stride(from: 10, through: 90, by: 10).map { percent in
            ProgressAxisLabel(
                position: Double(percent) / 100.0,
                text: "\(percent)%",
                prominence: .major
            )
        })

        return labels
    }

    private static func dayProgress(at date: Date, calendar: Calendar) -> Double {
        timeOfDayFraction(for: date, calendar: calendar)
    }

    private static func tenMinuteProgress(at date: Date, interval: DateInterval) -> Double {
        clampedProgress(for: date, in: interval)
    }

    private static func hourProgress(at date: Date, calendar: Calendar) -> Double {
        let components = calendar.dateComponents([.minute, .second, .nanosecond], from: date)
        let seconds =
            Double(components.minute ?? 0) * 60 +
            Double(components.second ?? 0) +
            Double(components.nanosecond ?? 0) / 1_000_000_000
        return min(max(seconds / 3_600, 0.0), 1.0)
    }

    private static func weekProgress(at date: Date, in interval: DateInterval, calendar: Calendar) -> Double {
        let currentDayStart = calendar.startOfDay(for: date)
        let dayIndex = calendar.dateComponents([.day], from: interval.start, to: currentDayStart).day ?? 0
        return (Double(dayIndex) + timeOfDayFraction(for: date, calendar: calendar)) / 7.0
    }

    private static func monthProgress(at date: Date, dayCount: Int, calendar: Calendar) -> Double {
        guard dayCount > 0 else { return 1.0 }
        let dayIndex = max(calendar.component(.day, from: date) - 1, 0)
        return (Double(dayIndex) + timeOfDayFraction(for: date, calendar: calendar)) / Double(dayCount)
    }

    private static func yearProgress(at date: Date, calendar: Calendar) -> Double {
        let monthIndex = max(calendar.component(.month, from: date) - 1, 0)
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let dayIndex = max(calendar.component(.day, from: date) - 1, 0)
        let monthFraction = (Double(dayIndex) + timeOfDayFraction(for: date, calendar: calendar)) / Double(daysInMonth)
        return (Double(monthIndex) + monthFraction) / 12.0
    }

    private static func centuryProgress(at date: Date, interval: DateInterval, calendar: Calendar) -> Double {
        let startYear = calendar.component(.year, from: interval.start)
        let yearOffset = max(calendar.component(.year, from: date) - startYear, 0)
        return (Double(yearOffset) + yearProgress(at: date, calendar: calendar)) / 100.0
    }

    private static func timeOfDayFraction(for date: Date, calendar: Calendar) -> Double {
        let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let seconds =
            Double(components.hour ?? 0) * 3_600 +
            Double(components.minute ?? 0) * 60 +
            Double(components.second ?? 0) +
            Double(components.nanosecond ?? 0) / 1_000_000_000
        return min(max(seconds / 86_400, 0.0), 1.0)
    }

    private static func unitBoundaryPosition(index: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(max(Double(index) / Double(total), 0.0), 1.0)
    }

    private static func unitDayCenterPosition(day: Int, total: Int) -> Double {
        unitCenterPosition(index: max(day - 1, 0), total: total)
    }

    private static func unitCenterPosition(index: Int, total: Int) -> Double {
        guard total > 0 else { return 0.5 }
        return min(max((Double(index) + 0.5) / Double(total), 0.0), 1.0)
    }

    private static func monthDisplayDays(dayCount: Int) -> [Int] {
        guard dayCount > 0 else { return [] }

        var days = [1]

        for day in stride(from: 5, through: min(dayCount, 30), by: 5) {
            if !days.contains(day) {
                days.append(day)
            }
        }

        if let last = days.last, dayCount - last >= 3 {
            days.append(dayCount)
        }

        return days
    }

    private static func customStatusText(
        for interval: DateInterval,
        now: Date,
        progress: Double
    ) -> String {
        let percentText = "\(Int((progress * 100).rounded()))%"

        if now <= interval.start {
            return "\(percentText) · 尚未开始"
        }

        if now >= interval.end {
            return "\(percentText) · 已结束"
        }

        let remaining = interval.end.timeIntervalSince(now)
        if remaining >= 2 * 86_400 {
            let days = Int(ceil(remaining / 86_400))
            return "\(percentText) · 剩余 \(days) 天"
        }

        if remaining >= 3_600 {
            let hours = Int(ceil(remaining / 3_600))
            return "\(percentText) · 剩余 \(hours) 小时"
        }

        if remaining >= 60 {
            let minutes = Int(ceil(remaining / 60))
            return "\(percentText) · 剩余 \(minutes) 分钟"
        }

        let seconds = max(Int(ceil(remaining)), 0)
        return "\(percentText) · 剩余 \(seconds) 秒"
    }

    private static func customFooterBoundaryTexts(
        for customConfig: CustomProgressConfig,
        locale: Locale,
        calendar: Calendar
    ) -> (left: String, right: String) {
        return (
            formatCustomRangeBoundary(
                customConfig.startDate,
                locale: locale,
                calendar: calendar,
                includeTime: customConfig.usesTimePrecision
            ),
            formatCustomRangeBoundary(
                customConfig.endDate,
                locale: locale,
                calendar: calendar,
                includeTime: customConfig.usesTimePrecision
            )
        )
    }

    private static func formatCustomRangeBoundary(
        _ date: Date,
        locale: Locale,
        calendar: Calendar,
        includeTime: Bool
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = includeTime ? "yyyy年M月d日 HH:mm" : "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private static func formatWeekday(_ date: Date, locale: Locale) -> String {
        date.formatted(
            Date.FormatStyle()
                .weekday(.abbreviated)
                .locale(locale)
        )
    }

    private static func formatMonth(_ date: Date, locale: Locale, calendar: Calendar) -> String {
        if locale.identifier.hasPrefix("zh") {
            return "\(calendar.component(.month, from: date))月"
        }

        return date.formatted(
            Date.FormatStyle()
                .month(.abbreviated)
                .locale(locale)
        )
    }

    private static func hourTimeLabel(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private static func formatHourMinute(_ date: Date, calendar: Calendar) -> String {
        String(
            format: "%02d:%02d",
            calendar.component(.hour, from: date),
            calendar.component(.minute, from: date)
        )
    }

    private static func formatBoundary(
        _ date: Date,
        now: Date,
        locale: Locale,
        calendar: Calendar,
        usesTimePrecision: Bool
    ) -> String {
        if usesTimePrecision, calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return formatHourMinute(date, calendar: calendar)
        }

        let currentYear = calendar.component(.year, from: now)
        let boundaryYear = calendar.component(.year, from: date)

        if currentYear == boundaryYear {
            return date.formatted(
                Date.FormatStyle()
                    .month(.abbreviated)
                    .day()
                    .locale(locale)
            )
        }

        return date.formatted(
            Date.FormatStyle()
                .year()
                .month(.abbreviated)
                .day()
                .locale(locale)
        )
    }
}
