import XCTest
@testable import DesktopTimePressureClock

final class ProgressCalculatorTests: XCTestCase {
    private var calendar: Calendar!
    private var locale: Locale!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        locale = Locale(identifier: "zh_CN")
    }

    func testTenMinuteProgressUsesCurrentNaturalWindow() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 21, minute: 22, second: 30)
        let item = ProgressItem.builtIn(kind: .tenMinute, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.title, "本10分钟")
        XCTAssertEqual(snapshot.leftLabel, "21:20")
        XCTAssertEqual(snapshot.rightLabel, "21:30")
        XCTAssertEqual(snapshot.statusText, "已25% · 剩7分30秒")
        XCTAssertEqual(snapshot.progress, 150.0 / 600.0, accuracy: 0.00001)
        XCTAssertEqual(snapshot.axisLabels.map(\.text), ["20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30"])
        XCTAssertEqual(snapshot.axisLabelDisplayMode, .all)
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "25" && $0.prominence == .highlight }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - 0.5) < 0.00001 && $0.prominence == .highlight }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - 0.1) < 0.00001 && $0.prominence == .major }))
    }

    func testHourProgressUsesDecimalMinuteMarkers() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 21, minute: 3, second: 20)
        let item = ProgressItem.builtIn(kind: .hour, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.title, "本小时")
        XCTAssertEqual(snapshot.leftLabel, "21:00")
        XCTAssertEqual(snapshot.rightLabel, "22:00")
        XCTAssertEqual(snapshot.statusText, "已5% · 剩56分")
        XCTAssertEqual(snapshot.progress, 200.0 / 3_600.0, accuracy: 0.00001)
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "21:30" && $0.prominence == .highlight }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "21:10" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "21:20" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "21:40" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "21:50" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - 0.5) < 0.00001 && $0.prominence == .highlight }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - (10.0 / 60.0)) < 0.00001 && $0.prominence == .major }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - (20.0 / 60.0)) < 0.00001 && $0.prominence == .major }))
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - (5.0 / 60.0)) < 0.00001 && $0.prominence == .minor }))
    }

    func testDayProgressAtNoonIsHalf() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 12, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .day, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.leftLabel, "0.00")
        XCTAssertEqual(snapshot.rightLabel, "24.00")
        XCTAssertEqual(snapshot.progress, 0.5, accuracy: 0.00001)
        XCTAssertEqual(snapshot.title, "今日")
        XCTAssertEqual(snapshot.statusText, "已50% · 剩12小时")
        XCTAssertEqual(snapshot.ticks.count, 23)
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "12:00" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.ticks.contains(where: { $0.prominence == .major && abs($0.position - 0.5) < 0.00001 }))
    }

    func testMonthUsesRealMonthLength() throws {
        let now = makeDate(year: 2024, month: 2, day: 15, hour: 0, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .month, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.rightLabel, "29日")
        XCTAssertEqual(snapshot.title, "本月")
        XCTAssertEqual(snapshot.statusText, "已48% · 剩15天(2周零1天)")
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "5日" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "10日" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "15日" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "25日" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "29日" && $0.prominence == .major }))
        XCTAssertTrue(snapshot.ticks.contains(where: { $0.prominence == .major }))
    }

    func testMonthDoesNotMislabelEndBoundaryAs31st() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 0, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .month, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertFalse(snapshot.axisLabels.contains(where: { $0.text == "31日" }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "30日" && abs($0.position - (29.5 / 31.0)) < 0.00001 }))
    }

    func testWeekAxisUsesEqualDailySlots() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 18, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .week, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        let labels = snapshot.axisLabels.sorted { $0.position < $1.position }
        XCTAssertEqual(labels.count, 7)
        XCTAssertEqual(try XCTUnwrap(labels.first).position, 0.5 / 7.0, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(labels.last).position, 6.5 / 7.0, accuracy: 0.00001)
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - (1.0 / 7.0)) < 0.00001 }))
    }

    func testYearAxisUsesEqualMonthSlots() throws {
        let now = makeDate(year: 2026, month: 3, day: 23, hour: 12, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .year, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        let labels = snapshot.axisLabels.sorted { $0.position < $1.position }
        XCTAssertEqual(labels.count, 12)
        XCTAssertEqual(labels[0].text, "1月")
        XCTAssertEqual(labels[0].position, 0.5 / 12.0, accuracy: 0.00001)
        XCTAssertEqual(labels[11].text, "12月")
        XCTAssertEqual(labels[11].position, 11.5 / 12.0, accuracy: 0.00001)
        XCTAssertTrue(snapshot.ticks.contains(where: { abs($0.position - (10.0 / 12.0)) < 0.00001 }))
    }

    func testCenturyUsesStrictGregorianCentury() throws {
        let now = makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .century, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.leftLabel, "2001")
        XCTAssertEqual(snapshot.rightLabel, "2100")
        XCTAssertEqual(snapshot.progress, 0.25, accuracy: 0.00001)
        XCTAssertEqual(snapshot.statusText, "已25% · 剩75年")
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "2001" && $0.prominence == .boundary }))
    }

    func testCustomFixedProgressClampsAfterEnd() throws {
        let start = makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let end = makeDate(year: 2026, month: 1, day: 11, hour: 0, minute: 0, second: 0)
        let now = makeDate(year: 2026, month: 1, day: 20, hour: 0, minute: 0, second: 0)

        let item = ProgressItem(
            id: UUID(),
            kind: .customFixed,
            title: "十日冲刺",
            isEnabled: true,
            sortOrder: 0,
            customConfig: CustomProgressConfig(
                mode: .fixed,
                startDate: start,
                endDate: end,
                recurrence: nil,
                leftLabelOverride: "START",
                rightLabelOverride: "END",
                keepVisibleAfterCompletion: true,
                usesTimePrecision: false
            )
        )

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.leftLabel, "START")
        XCTAssertEqual(snapshot.rightLabel, "END")
        XCTAssertEqual(snapshot.progress, 1.0, accuracy: 0.00001)
        XCTAssertEqual(snapshot.statusText, "100% · 已结束")
        XCTAssertEqual(snapshot.footerLeftText, "2026年1月1日")
        XCTAssertEqual(snapshot.footerRightText, "2026年1月11日")
    }

    func testCustomFixedUsesTenPercentScale() throws {
        let start = makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let end = makeDate(year: 2026, month: 1, day: 11, hour: 0, minute: 0, second: 0)
        let now = makeDate(year: 2026, month: 1, day: 4, hour: 0, minute: 0, second: 0)

        let item = ProgressItem(
            id: UUID(),
            kind: .customFixed,
            title: "十日冲刺",
            isEnabled: true,
            sortOrder: 0,
            customConfig: CustomProgressConfig(
                mode: .fixed,
                startDate: start,
                endDate: end,
                recurrence: nil,
                leftLabelOverride: nil,
                rightLabelOverride: nil,
                keepVisibleAfterCompletion: true,
                usesTimePrecision: false
            )
        )

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.statusText, "27% · 剩余 8 天")
        XCTAssertEqual(snapshot.footerLeftText, "2026年1月1日")
        XCTAssertEqual(snapshot.footerRightText, "2026年1月11日")
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "0%" && $0.position == 0.0 && $0.prominence == .boundary }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "100%" && $0.position == 1.0 && $0.prominence == .boundary }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "10%" && abs($0.position - 0.1) < 0.00001 }))
        XCTAssertTrue(snapshot.axisLabels.contains(where: { $0.text == "90%" && abs($0.position - 0.9) < 0.00001 }))
        XCTAssertEqual(snapshot.ticks.filter { $0.prominence == .major }.count, 9)
    }

    func testCustomFixedCanShowExplicitTimeInFooter() throws {
        let start = makeDate(year: 2026, month: 1, day: 1, hour: 9, minute: 30, second: 0)
        let end = makeDate(year: 2026, month: 1, day: 11, hour: 18, minute: 45, second: 0)
        let now = makeDate(year: 2026, month: 1, day: 4, hour: 12, minute: 0, second: 0)

        let item = ProgressItem(
            id: UUID(),
            kind: .customFixed,
            title: "精确冲刺",
            isEnabled: true,
            sortOrder: 0,
            customConfig: CustomProgressConfig(
                mode: .fixed,
                startDate: start,
                endDate: end,
                recurrence: nil,
                leftLabelOverride: nil,
                rightLabelOverride: nil,
                keepVisibleAfterCompletion: true,
                usesTimePrecision: true
            )
        )

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale)
        )

        XCTAssertEqual(snapshot.footerLeftText, "2026年1月1日 09:30")
        XCTAssertEqual(snapshot.footerRightText, "2026年1月11日 18:45")
    }

    func testLegacyCustomProgressConfigDecodesWithoutModeAndKeepVisibleFlag() throws {
        let legacyJSON = """
        {
          "id":"A4EC6124-2D4D-4305-BF6C-18337368E7A2",
          "kind":"customFixed",
          "title":"旧版自定义",
          "isEnabled":true,
          "sortOrder":7,
          "customConfig":{
            "startDate":757382400,
            "endDate":757468800,
            "leftLabelOverride":"START",
            "rightLabelOverride":"END"
          }
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(ProgressItem.self, from: legacyJSON)

        XCTAssertEqual(item.kind, .customFixed)
        XCTAssertEqual(item.customConfig?.mode, .fixed)
        XCTAssertEqual(item.customConfig?.keepVisibleAfterCompletion, true)
        XCTAssertEqual(item.customConfig?.usesTimePrecision, false)
    }

    @MainActor
    func testSettingsStoreMoveItemToIndexReordersItems() {
        let suiteName = "DesktopTimePressureClockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppSettingsStore(defaults: defaults)
        store.moveItem(id: ProgressKind.year.defaultID, to: 0)

        XCTAssertEqual(store.orderedProgressItems.prefix(3).map(\.kind), [.year, .tenMinute, .hour])
    }

    @MainActor
    func testSettingsStoreMigratesMissingHourToFront() throws {
        let suiteName = "DesktopTimePressureClockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyItems = [
            ProgressItem.builtIn(kind: .day, isEnabled: true, sortOrder: 0),
            ProgressItem.builtIn(kind: .week, isEnabled: true, sortOrder: 1),
            ProgressItem.builtIn(kind: .month, isEnabled: true, sortOrder: 2),
            ProgressItem.builtIn(kind: .year, isEnabled: true, sortOrder: 3),
            ProgressItem.builtIn(kind: .century, isEnabled: false, sortOrder: 4)
        ]

        let legacySnapshot = TestPersistedSettings(
            windowMode: .normal,
            timePrecision: .tenth,
            backgroundOpacity: 0.96,
            restoreWindowOnLaunch: true,
            progressItems: legacyItems,
            storedWindowFrameString: nil
        )

        let data = try JSONEncoder().encode(legacySnapshot)
        defaults.set(data, forKey: "DesktopTimePressureClock.Settings")

        let store = AppSettingsStore(defaults: defaults)

        XCTAssertEqual(store.orderedProgressItems.first?.kind, .tenMinute)
        XCTAssertEqual(store.orderedProgressItems.prefix(4).map(\.kind), [.tenMinute, .hour, .day, .week])
    }

    @MainActor
    func testSettingsStorePreservesUnreadablePayloadInsteadOfOverwritingIt() throws {
        let suiteName = "DesktopTimePressureClockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let unreadableData = Data("not valid json".utf8)
        defaults.set(unreadableData, forKey: "DesktopTimePressureClock.Settings")

        let store = AppSettingsStore(defaults: defaults)

        XCTAssertEqual(store.orderedProgressItems.first?.kind, .tenMinute)
        XCTAssertEqual(defaults.data(forKey: "DesktopTimePressureClock.Settings"), unreadableData)
        XCTAssertEqual(defaults.data(forKey: "DesktopTimePressureClock.SettingsUnreadableBackup"), unreadableData)
    }

    func testSleepScheduleCrossingMidnightSplitsIntoTwoRegions() throws {
        let schedule = SleepScheduleConfig(isEnabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60)
        let now = makeDate(year: 2026, month: 8, day: 17, hour: 12, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .day, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale, sleepSchedule: schedule)
        )

        XCTAssertEqual(snapshot.shadedRegions.count, 2)
        XCTAssertEqual(snapshot.shadedRegions[0].lowerBound, 22.0 / 24.0, accuracy: 0.00001)
        XCTAssertEqual(snapshot.shadedRegions[0].upperBound, 1.0, accuracy: 0.00001)
        XCTAssertEqual(snapshot.shadedRegions[1].lowerBound, 0.0, accuracy: 0.00001)
        XCTAssertEqual(snapshot.shadedRegions[1].upperBound, 7.0 / 24.0, accuracy: 0.00001)
    }

    func testSleepScheduleWithinSameDayIsSingleRegion() {
        let schedule = SleepScheduleConfig(isEnabled: true, startMinutes: 1 * 60, endMinutes: 9 * 60)

        let regions = ProgressCalculator.sleepShadedRegions(for: schedule)

        XCTAssertEqual(regions.count, 1)
        XCTAssertEqual(regions[0].lowerBound, 1.0 / 24.0, accuracy: 0.00001)
        XCTAssertEqual(regions[0].upperBound, 9.0 / 24.0, accuracy: 0.00001)
    }

    func testSleepScheduleDisabledOrMissingYieldsNoRegions() {
        let disabled = SleepScheduleConfig(isEnabled: false, startMinutes: 22 * 60, endMinutes: 7 * 60)

        XCTAssertTrue(ProgressCalculator.sleepShadedRegions(for: disabled).isEmpty)
        XCTAssertTrue(ProgressCalculator.sleepShadedRegions(for: nil).isEmpty)
    }

    func testSleepScheduleDoesNotShadeNonDayKinds() throws {
        let schedule = SleepScheduleConfig(isEnabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60)
        let now = makeDate(year: 2026, month: 8, day: 17, hour: 12, minute: 0, second: 0)
        let item = ProgressItem.builtIn(kind: .week, isEnabled: true, sortOrder: 0)

        let snapshot = try XCTUnwrap(
            ProgressCalculator.snapshot(for: item, at: now, calendar: calendar, locale: locale, sleepSchedule: schedule)
        )

        XCTAssertTrue(snapshot.shadedRegions.isEmpty)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }
}

private struct TestPersistedSettings: Codable {
    var windowMode: WindowMode
    var timePrecision: TimePrecision
    var backgroundOpacity: Double
    var restoreWindowOnLaunch: Bool
    var progressItems: [ProgressItem]
    var storedWindowFrameString: String?
}
