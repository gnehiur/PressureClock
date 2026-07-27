import Foundation

enum WindowMode: String, Codable, CaseIterable, Identifiable {
    case normal
    case floating

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:
            return "普通窗口"
        case .floating:
            return "悬浮在其他 App 之上"
        }
    }
}

enum TimePrecision: String, Codable, CaseIterable, Identifiable {
    case second
    case tenth
    case hundredth
    case millisecond

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .second:
            return "秒"
        case .tenth:
            return "1 位小数秒"
        case .hundredth:
            return "2 位小数秒"
        case .millisecond:
            return "3 位小数秒"
        }
    }

    var formatPattern: String {
        switch self {
        case .second:
            return "HH:mm:ss"
        case .tenth:
            return "HH:mm:ss.S"
        case .hundredth:
            return "HH:mm:ss.SS"
        case .millisecond:
            return "HH:mm:ss.SSS"
        }
    }

    var refreshInterval: TimeInterval {
        switch self {
        case .second:
            return 1.0
        case .tenth:
            return 0.1
        case .hundredth:
            return 0.01
        case .millisecond:
            return 1.0 / 60.0
        }
    }

    var tolerance: TimeInterval {
        switch self {
        case .second:
            return 0.08
        case .tenth:
            return 0.01
        case .hundredth:
            return 0.002
        case .millisecond:
            return 0.001
        }
    }
}

enum ProgressKind: String, Codable, CaseIterable, Identifiable {
    case tenMinute
    case hour
    case day
    case week
    case month
    case year
    case century
    case customFixed
    case customRecurring

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .tenMinute:
            return "本10分钟"
        case .hour:
            return "本小时"
        case .day:
            return "今日"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .year:
            return "今年"
        case .century:
            return "本世纪"
        case .customFixed, .customRecurring:
            return "自定义"
        }
    }

    var defaultID: UUID {
        switch self {
        case .tenMinute:
            return UUID(uuidString: "C66F8CB3-979D-4A1C-A4E6-6730213B5402")!
        case .hour:
            return UUID(uuidString: "37463340-C2B3-4BD6-BE64-E8B015FB032B")!
        case .day:
            return UUID(uuidString: "E443E6B2-D5A6-4FD5-AE79-D91B09E49F11")!
        case .week:
            return UUID(uuidString: "785D1E08-66B4-4757-8844-8AA2C837D0C7")!
        case .month:
            return UUID(uuidString: "A6857B24-F2A7-4458-9319-DCA3C3FDC18D")!
        case .year:
            return UUID(uuidString: "91D6BF1C-5B33-49EA-BD50-160B9D7904B1")!
        case .century:
            return UUID(uuidString: "7E9859EB-A160-49F5-91B1-C876BEE3AE2F")!
        case .customFixed, .customRecurring:
            return UUID()
        }
    }

    var isBuiltIn: Bool {
        switch self {
        case .customFixed, .customRecurring:
            return false
        default:
            return true
        }
    }
}

enum CustomProgressMode: String, Codable, Equatable {
    case fixed
    case recurring
}

enum CustomProgressRecurrence: String, Codable, Equatable, CaseIterable {
    case quarter
    case halfYear
    case decade
}

struct CustomProgressConfig: Codable, Equatable {
    var mode: CustomProgressMode
    var startDate: Date
    var endDate: Date
    var recurrence: CustomProgressRecurrence?
    var leftLabelOverride: String?
    var rightLabelOverride: String?
    var keepVisibleAfterCompletion: Bool
    var usesTimePrecision: Bool

    init(
        mode: CustomProgressMode,
        startDate: Date,
        endDate: Date,
        recurrence: CustomProgressRecurrence?,
        leftLabelOverride: String?,
        rightLabelOverride: String?,
        keepVisibleAfterCompletion: Bool,
        usesTimePrecision: Bool = false
    ) {
        self.mode = mode
        self.startDate = startDate
        self.endDate = endDate
        self.recurrence = recurrence
        self.leftLabelOverride = leftLabelOverride
        self.rightLabelOverride = rightLabelOverride
        self.keepVisibleAfterCompletion = keepVisibleAfterCompletion
        self.usesTimePrecision = usesTimePrecision
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case startDate
        case endDate
        case recurrence
        case leftLabelOverride
        case rightLabelOverride
        case keepVisibleAfterCompletion
        case usesTimePrecision
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(CustomProgressMode.self, forKey: .mode) ?? .fixed
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        recurrence = try container.decodeIfPresent(CustomProgressRecurrence.self, forKey: .recurrence)
        leftLabelOverride = try container.decodeIfPresent(String.self, forKey: .leftLabelOverride)
        rightLabelOverride = try container.decodeIfPresent(String.self, forKey: .rightLabelOverride)
        keepVisibleAfterCompletion = try container.decodeIfPresent(Bool.self, forKey: .keepVisibleAfterCompletion) ?? true
        usesTimePrecision = try container.decodeIfPresent(Bool.self, forKey: .usesTimePrecision) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encodeIfPresent(recurrence, forKey: .recurrence)
        try container.encodeIfPresent(leftLabelOverride, forKey: .leftLabelOverride)
        try container.encodeIfPresent(rightLabelOverride, forKey: .rightLabelOverride)
        try container.encode(keepVisibleAfterCompletion, forKey: .keepVisibleAfterCompletion)
        try container.encode(usesTimePrecision, forKey: .usesTimePrecision)
    }
}

struct ProgressItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ProgressKind
    var title: String
    var isEnabled: Bool
    var sortOrder: Int
    var customConfig: CustomProgressConfig?

    var isBuiltIn: Bool {
        kind.isBuiltIn
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if isBuiltIn {
            return kind.defaultTitle
        }
        return "自定义进度"
    }

    var prefersHighFrequencyProgressUpdates: Bool {
        if kind == .tenMinute {
            return true
        }

        if kind == .hour {
            return true
        }

        guard
            kind == .customFixed,
            let customConfig,
            customConfig.endDate > customConfig.startDate
        else {
            return false
        }
        return customConfig.endDate.timeIntervalSince(customConfig.startDate) <= 86_400
    }

    static func builtIn(kind: ProgressKind, isEnabled: Bool, sortOrder: Int) -> ProgressItem {
        ProgressItem(
            id: kind.defaultID,
            kind: kind,
            title: kind.defaultTitle,
            isEnabled: isEnabled,
            sortOrder: sortOrder,
            customConfig: nil
        )
    }

    static func defaultItems() -> [ProgressItem] {
        [
            .builtIn(kind: .tenMinute, isEnabled: true, sortOrder: 0),
            .builtIn(kind: .hour, isEnabled: true, sortOrder: 1),
            .builtIn(kind: .day, isEnabled: true, sortOrder: 2),
            .builtIn(kind: .week, isEnabled: true, sortOrder: 3),
            .builtIn(kind: .month, isEnabled: true, sortOrder: 4),
            .builtIn(kind: .year, isEnabled: true, sortOrder: 5),
            .builtIn(kind: .century, isEnabled: false, sortOrder: 6)
        ]
    }
}

struct ProgressSnapshot: Identifiable, Equatable {
    var id: UUID
    var title: String
    var statusText: String
    var footerLeftText: String?
    var footerRightText: String?
    var leftLabel: String
    var rightLabel: String
    var progress: Double
    var ticks: [ProgressTick]
    var axisLabels: [ProgressAxisLabel]
    var axisLabelDisplayMode: ProgressAxisLabelDisplayMode = .adaptive
    var kind: ProgressKind? = nil
}

enum ProgressAxisLabelDisplayMode: Equatable {
    case adaptive
    case all
}

enum ProgressTickProminence: Int, Equatable {
    case minor
    case major
    case highlight
}

struct ProgressTick: Identifiable, Equatable {
    var position: Double
    var prominence: ProgressTickProminence

    var id: String {
        "\(prominence.rawValue)-\(position)"
    }
}

enum ProgressAxisLabelProminence: Int, Equatable {
    case minor
    case major
    case highlight
    case boundary
}

struct ProgressAxisLabel: Identifiable, Equatable {
    var position: Double
    var text: String
    var prominence: ProgressAxisLabelProminence

    var id: String {
        "\(prominence.rawValue)-\(position)-\(text)"
    }
}
