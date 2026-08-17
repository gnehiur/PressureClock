import Foundation

@MainActor
enum DisplayFormatting {
    nonisolated static let interfaceLocale = Locale(identifier: "zh_Hans_CN")

    struct TimeDisplayParts: Equatable {
        let primaryText: String
        let fractionalText: String?
    }

    private static var timeFormatterCache: [String: DateFormatter] = [:]
    private static var dateFormatterCache: [String: DateFormatter] = [:]

    static func timeString(from date: Date, precision: TimePrecision, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = formatterForTime(precision: precision, timeZone: timeZone)
        return formatter.string(from: date)
    }

    static func timeDisplayParts(from date: Date, precision: TimePrecision, timeZone: TimeZone = .autoupdatingCurrent) -> TimeDisplayParts {
        let fullText = timeString(from: date, precision: precision, timeZone: timeZone)
        guard let separatorIndex = fullText.firstIndex(of: ".") else {
            return TimeDisplayParts(primaryText: fullText, fractionalText: nil)
        }

        return TimeDisplayParts(
            primaryText: String(fullText[..<separatorIndex]),
            fractionalText: String(fullText[separatorIndex...])
        )
    }

    static func yearContextString(from date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let week = calendar.component(.weekOfYear, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let dayInWeek = ((weekday - calendar.firstWeekday + 7) % 7) + 1
        return "今年第\(dayOfYear)天 · 第\(week)周第\(dayInWeek)天"
    }

    static func dateString(from date: Date, locale: Locale = interfaceLocale, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = formatterForDate(locale: locale, timeZone: timeZone)
        return formatter.string(from: date)
    }

    static func boundaryString(
        from date: Date,
        showsTime: Bool,
        locale: Locale = interfaceLocale
    ) -> String {
        let formatter = formatterForBoundary(locale: locale, showsTime: showsTime)
        return formatter.string(from: date)
    }

    private static func formatterForTime(precision: TimePrecision, timeZone: TimeZone) -> DateFormatter {
        let key = "\(precision.formatPattern)-\(timeZone.identifier)"
        if let formatter = timeFormatterCache[key] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = precision.formatPattern
        timeFormatterCache[key] = formatter
        return formatter
    }

    private static func formatterForDate(locale: Locale, timeZone: TimeZone = .autoupdatingCurrent) -> DateFormatter {
        let key = "\(locale.identifier)-\(timeZone.identifier)"
        if let formatter = dateFormatterCache[key] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone

        if locale.identifier.hasPrefix("zh") {
            formatter.dateFormat = "M月d日 EEE"
        } else {
            formatter.setLocalizedDateFormatFromTemplate("MMM d, EEE")
        }

        dateFormatterCache[key] = formatter
        return formatter
    }

    private static func formatterForBoundary(locale: Locale, showsTime: Bool) -> DateFormatter {
        let key = "\(locale.identifier)-boundary-\(showsTime)"
        if let formatter = dateFormatterCache[key] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = showsTime ? "yyyy年M月d日 HH:mm" : "yyyy年M月d日"
        dateFormatterCache[key] = formatter
        return formatter
    }
}
