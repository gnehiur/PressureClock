#if canImport(AppKit)
import AppKit
#endif
import Combine
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var windowMode: WindowMode {
        didSet { persistIfReady() }
    }

    @Published var timePrecision: TimePrecision {
        didSet { persistIfReady() }
    }

    @Published var backgroundOpacity: Double {
        didSet { persistIfReady() }
    }

    @Published var restoreWindowOnLaunch: Bool {
        didSet { persistIfReady() }
    }

    @Published private(set) var progressItems: [ProgressItem] {
        didSet { persistIfReady() }
    }

    @Published private(set) var storedWindowFrameString: String? {
        didSet { persistIfReady() }
    }

    private let defaults: UserDefaults
    private let storageKey = "DesktopTimePressureClock.Settings"
    private let unreadableBackupKey = "DesktopTimePressureClock.SettingsUnreadableBackup"
    private var isReadyToPersist = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let loadResult = Self.loadSnapshot(from: defaults, key: storageKey)
        let snapshot: PersistedSettings

        switch loadResult {
        case .success(let loadedSnapshot):
            snapshot = loadedSnapshot
        case .missing:
            snapshot = Self.defaultSnapshot()
        case .failure(let data, let errorDescription):
            defaults.set(data, forKey: unreadableBackupKey)
            NSLog("PressureClock: unreadable settings payload preserved at backup key. Error: %@", errorDescription)
            snapshot = Self.defaultSnapshot()
        }

        self.windowMode = snapshot.windowMode
        self.timePrecision = snapshot.timePrecision
        self.backgroundOpacity = min(max(snapshot.backgroundOpacity, 0.55), 1.0)
        self.restoreWindowOnLaunch = snapshot.restoreWindowOnLaunch
        self.progressItems = Self.normalized(snapshot.progressItems)
        self.storedWindowFrameString = snapshot.storedWindowFrameString

        self.isReadyToPersist = true

        if case .failure = loadResult {
            return
        }

        persist()
    }

    var orderedProgressItems: [ProgressItem] {
        progressItems.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.displayTitle.localizedStandardCompare(rhs.displayTitle) == .orderedAscending
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    var customProgressItems: [ProgressItem] {
        orderedProgressItems.filter { !$0.isBuiltIn }
    }

    #if os(macOS)
    var restoredWindowFrame: NSRect? {
        guard
            restoreWindowOnLaunch,
            let storedWindowFrameString,
            !storedWindowFrameString.isEmpty
        else {
            return nil
        }
        return NSRectFromString(storedWindowFrameString)
    }

    func saveWindowFrame(_ frame: NSRect) {
        storedWindowFrameString = NSStringFromRect(frame)
    }
    #endif

    func toggleWindowMode() {
        windowMode = windowMode == .floating ? .normal : .floating
    }

    func item(withID id: UUID) -> ProgressItem? {
        progressItems.first { $0.id == id }
    }

    func setItemEnabled(_ enabled: Bool, id: UUID) {
        updateProgressItem(id: id) { item in
            item.isEnabled = enabled
        }
    }

    func moveItemUp(id: UUID) {
        var items = orderedProgressItems
        guard let index = items.firstIndex(where: { $0.id == id }), index > 0 else { return }
        items.swapAt(index, index - 1)
        setProgressItems(items)
    }

    func moveItemDown(id: UUID) {
        var items = orderedProgressItems
        guard let index = items.firstIndex(where: { $0.id == id }), index < items.count - 1 else { return }
        items.swapAt(index, index + 1)
        setProgressItems(items)
    }

    func moveItem(id: UUID, to destinationIndex: Int) {
        var items = orderedProgressItems
        guard let sourceIndex = items.firstIndex(where: { $0.id == id }) else { return }

        let item = items.remove(at: sourceIndex)
        let clampedDestination = min(max(destinationIndex, 0), items.count)
        items.insert(item, at: clampedDestination)
        setProgressItems(items)
    }

    func canMoveUp(id: UUID) -> Bool {
        guard let index = orderedProgressItems.firstIndex(where: { $0.id == id }) else { return false }
        return index > 0
    }

    func canMoveDown(id: UUID) -> Bool {
        guard let index = orderedProgressItems.firstIndex(where: { $0.id == id }) else { return false }
        return index < orderedProgressItems.count - 1
    }

    func addCustomFixedProgress() {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 30, to: start) ?? start.addingTimeInterval(30 * 86_400)
        let nextOrder = (orderedProgressItems.last?.sortOrder ?? -1) + 1

        let item = ProgressItem(
            id: UUID(),
            kind: .customFixed,
            title: "自定义进度",
            isEnabled: true,
            sortOrder: nextOrder,
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

        setProgressItems(progressItems + [item])
    }

    func removeCustomProgress(id: UUID) {
        guard let item = item(withID: id), !item.isBuiltIn else { return }
        setProgressItems(progressItems.filter { $0.id != id })
    }

    func updateProgressItem(id: UUID, mutate: (inout ProgressItem) -> Void) {
        guard let index = progressItems.firstIndex(where: { $0.id == id }) else { return }
        var updatedItems = progressItems
        mutate(&updatedItems[index])
        updatedItems[index] = Self.normalized(updatedItems[index])
        setProgressItems(updatedItems)
    }

    private func setProgressItems(_ items: [ProgressItem]) {
        progressItems = Self.normalized(Self.reordered(items))
    }

    private func persistIfReady() {
        guard isReadyToPersist else { return }
        persist()
    }

    private func persist() {
        let snapshot = PersistedSettings(
            windowMode: windowMode,
            timePrecision: timePrecision,
            backgroundOpacity: backgroundOpacity,
            restoreWindowOnLaunch: restoreWindowOnLaunch,
            progressItems: progressItems,
            storedWindowFrameString: storedWindowFrameString
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to persist settings: \(error)")
        }
    }

    private static func loadSnapshot(from defaults: UserDefaults, key: String) -> SnapshotLoadResult {
        guard let data = defaults.data(forKey: key) else {
            return .missing
        }

        do {
            return .success(try JSONDecoder().decode(PersistedSettings.self, from: data))
        } catch {
            return .failure(data, String(describing: error))
        }
    }

    private static func defaultSnapshot() -> PersistedSettings {
        PersistedSettings(
            windowMode: .normal,
            timePrecision: .tenth,
            backgroundOpacity: 0.96,
            restoreWindowOnLaunch: true,
            progressItems: ProgressItem.defaultItems(),
            storedWindowFrameString: nil
        )
    }

    private static func normalized(_ item: ProgressItem) -> ProgressItem {
        var item = item
        if item.isBuiltIn {
            item.title = item.kind.defaultTitle
            item.customConfig = nil
            return item
        }

        if var customConfig = item.customConfig {
            let calendar = Calendar.autoupdatingCurrent

            if customConfig.usesTimePrecision {
                if customConfig.endDate <= customConfig.startDate {
                    customConfig.endDate = customConfig.startDate.addingTimeInterval(3_600)
                }
            } else {
                customConfig.startDate = calendar.startOfDay(for: customConfig.startDate)
                customConfig.endDate = calendar.startOfDay(for: customConfig.endDate)
                if customConfig.endDate < customConfig.startDate {
                    customConfig.endDate = customConfig.startDate
                }
            }

            customConfig.leftLabelOverride = customConfig.leftLabelOverride?.trimmedNilIfEmpty
            customConfig.rightLabelOverride = customConfig.rightLabelOverride?.trimmedNilIfEmpty
            item.customConfig = customConfig
        }

        return item
    }

    private static func normalized(_ items: [ProgressItem]) -> [ProgressItem] {
        var normalizedItems = items.map(Self.normalized)

        if !normalizedItems.contains(where: { $0.kind == .tenMinute }) {
            normalizedItems.insert(.builtIn(kind: .tenMinute, isEnabled: true, sortOrder: -2), at: 0)
        }

        if !normalizedItems.contains(where: { $0.kind == .hour }) {
            let insertionIndex = min(normalizedItems.count, 1)
            normalizedItems.insert(.builtIn(kind: .hour, isEnabled: true, sortOrder: -1), at: insertionIndex)
        }

        let existingBuiltInKinds = Set(normalizedItems.filter(\.isBuiltIn).map(\.kind))
        let missingBuiltIns = ProgressItem.defaultItems().filter {
            $0.kind != .tenMinute && $0.kind != .hour && !existingBuiltInKinds.contains($0.kind)
        }
        normalizedItems.append(contentsOf: missingBuiltIns)

        normalizedItems.sort { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.displayTitle.localizedStandardCompare(rhs.displayTitle) == .orderedAscending
            }
            return lhs.sortOrder < rhs.sortOrder
        }

        for index in normalizedItems.indices {
            normalizedItems[index].sortOrder = index
        }

        return normalizedItems
    }

    private static func reordered(_ items: [ProgressItem]) -> [ProgressItem] {
        var reorderedItems = items
        for index in reorderedItems.indices {
            reorderedItems[index].sortOrder = index
        }
        return reorderedItems
    }
}

private enum SnapshotLoadResult {
    case success(PersistedSettings)
    case missing
    case failure(Data, String)
}

private struct PersistedSettings: Codable {
    var windowMode: WindowMode
    var timePrecision: TimePrecision
    var backgroundOpacity: Double
    var restoreWindowOnLaunch: Bool
    var progressItems: [ProgressItem]
    var storedWindowFrameString: String?
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
