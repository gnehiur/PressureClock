import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @State private var draggedProgressItemID: UUID?
    @State private var dropTargetItemID: UUID?
    @State private var dropTargetEdge: ProgressOrderDropEdge?

    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("设置")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text("默认 1 位小数秒会让时间更像在持续滑走，而不是每秒跳一下。下面的自定义进度条则把长期目标直接压缩成一根会不断被填满的线。")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GroupBox(label: sectionTitle("窗口")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("悬浮在其他 App 之上", isOn: floatingBinding)
                        Toggle("启动时恢复上次窗口位置与大小", isOn: restoreWindowBinding)
                    }
                    .padding(.top, 4)
                }

                GroupBox(label: sectionTitle("时间")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("显示精度")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))

                        Picker("显示精度", selection: timePrecisionBinding) {
                            ForEach(TimePrecision.allCases) { precision in
                                Text(precision.displayName).tag(precision)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("技术上 1 位小数秒其实是 100ms 一跳。它比纯秒级更有流逝感，但不会像 2-3 位小数秒那样制造过强噪声。")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }

                GroupBox(label: sectionTitle("睡眠")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("在“今日”条上标记睡眠时段", isOn: sleepEnabledBinding)

                        if settingsStore.sleepSchedule.isEnabled {
                            HStack(spacing: 18) {
                                DatePicker("入睡", selection: sleepTimeBinding(\.startMinutes), displayedComponents: .hourAndMinute)
                                DatePicker("起床", selection: sleepTimeBinding(\.endMinutes), displayedComponents: .hourAndMinute)
                            }
                            .fixedSize()
                        }

                        Text("睡眠区间在今日刻度条上压暗显示，跨午夜自动拆成条头和条尾两段，边界记号标出入睡与起床时刻——醒着的时间一眼可见。")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }

                GroupBox(label: sectionTitle("外观")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("背景不透明度")
                            Spacer()
                            Text(backgroundOpacityLabel)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: backgroundOpacityBinding, in: 0.55...1.0)
                    }
                    .padding(.top, 4)
                }

                GroupBox(label: sectionTitle("显示顺序与显隐")) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(settingsStore.orderedProgressItems) { item in
                            ProgressOrderRow(
                                itemID: item.id,
                                draggedItemID: $draggedProgressItemID,
                                dropTargetItemID: $dropTargetItemID,
                                dropTargetEdge: $dropTargetEdge
                            )
                        }
                    }
                    .padding(.top, 4)
                    .animation(.spring(response: 0.24, dampingFraction: 0.86), value: settingsStore.orderedProgressItems.map(\.id))
                    .animation(.spring(response: 0.2, dampingFraction: 0.9), value: draggedProgressItemID)
                    .animation(.spring(response: 0.2, dampingFraction: 0.9), value: dropTargetItemID)
                    .animation(.spring(response: 0.2, dampingFraction: 0.9), value: dropTargetEdge)
                }

                GroupBox(label: sectionTitle("自定义进度条")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("第一版先支持固定区间。你可以把任何长期目标、年龄阶段、年度计划或冲刺周期直接定义成一条进度。")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if settingsStore.customProgressItems.isEmpty {
                            Text("还没有自定义进度条。新增一条之后，它会和 TODAY / WEEK / MONTH / YEAR 一样直接出现在主窗口里。")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 6)
                        } else {
                            ForEach(settingsStore.customProgressItems) { item in
                                CustomProgressEditorCard(itemID: item.id)
                            }
                        }

                        Button("新增自定义进度条") {
                            settingsStore.addCustomFixedProgress()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 4)
                }

                HStack {
                    Spacer()
                    Button("完成") {
                        onClose()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 720, minHeight: 700)
    }

    private var floatingBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.windowMode == .floating },
            set: { settingsStore.windowMode = $0 ? .floating : .normal }
        )
    }

    private var restoreWindowBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.restoreWindowOnLaunch },
            set: { settingsStore.restoreWindowOnLaunch = $0 }
        )
    }

    private var timePrecisionBinding: Binding<TimePrecision> {
        Binding(
            get: { settingsStore.timePrecision },
            set: { settingsStore.timePrecision = $0 }
        )
    }

    private var backgroundOpacityBinding: Binding<Double> {
        Binding(
            get: { settingsStore.backgroundOpacity },
            set: { settingsStore.backgroundOpacity = $0 }
        )
    }

    private var backgroundOpacityLabel: String {
        String(format: "%.0f%%", settingsStore.backgroundOpacity * 100)
    }

    private var sleepEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.sleepSchedule.isEnabled },
            set: { settingsStore.sleepSchedule.isEnabled = $0 }
        )
    }

    /// 分钟数 ↔ 当天时刻 Date 的桥,DatePicker 只认 Date
    private func sleepTimeBinding(_ keyPath: WritableKeyPath<SleepScheduleConfig, Int>) -> Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.autoupdatingCurrent
                let minutes = settingsStore.sleepSchedule[keyPath: keyPath]
                return calendar.date(
                    bySettingHour: (minutes / 60) % 24,
                    minute: minutes % 60,
                    second: 0,
                    of: calendar.startOfDay(for: Date())
                ) ?? Date()
            },
            set: { date in
                let calendar = Calendar.autoupdatingCurrent
                let components = calendar.dateComponents([.hour, .minute], from: date)
                settingsStore.sleepSchedule[keyPath: keyPath] = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .rounded))
    }
}

private struct ProgressOrderRow: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let itemID: UUID
    @Binding var draggedItemID: UUID?
    @Binding var dropTargetItemID: UUID?
    @Binding var dropTargetEdge: ProgressOrderDropEdge?

    private var item: ProgressItem? {
        settingsStore.item(withID: itemID)
    }

    var body: some View {
        if let item {
            HStack(spacing: 12) {
                reorderHandle(for: item)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))

                    Text(item.isBuiltIn ? "内置条目" : "自定义固定区间")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Toggle("", isOn: enabledBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(backgroundShape(for: item))
            .overlay(borderOverlay)
            .overlay(alignment: .top) {
                if isDropTarget, dropTargetEdge == .before {
                    insertionIndicator
                        .offset(y: -7)
                }
            }
            .overlay(alignment: .bottom) {
                if isDropTarget, dropTargetEdge == .after {
                    insertionIndicator
                        .offset(y: 7)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isDraggedSource ? 0.28 : 1.0)
            .scaleEffect(isDraggedSource ? 0.985 : 1.0)
            .onDrop(
                of: [UTType.text],
                delegate: ProgressOrderDropDelegate(
                    itemID: itemID,
                    draggedItemID: $draggedItemID,
                    dropTargetItemID: $dropTargetItemID,
                    dropTargetEdge: $dropTargetEdge,
                    settingsStore: settingsStore
                )
            )
        }
    }

    private var isDraggedSource: Bool {
        draggedItemID == itemID
    }

    private var isDropTarget: Bool {
        dropTargetItemID == itemID && draggedItemID != itemID
    }

    private func reorderHandle(for item: ProgressItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDraggedSource ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06))
                .frame(width: 34, height: 34)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDraggedSource ? Color.accentColor : Color.secondary)
        }
        .help("拖动调整顺序")
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onDrag {
            draggedItemID = itemID
            dropTargetItemID = nil
            dropTargetEdge = nil
            return NSItemProvider(object: itemID.uuidString as NSString)
        } preview: {
            dragPreview(for: item)
        }
    }

    private func dragPreview(for item: ProgressItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 34, height: 34)

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text(item.isBuiltIn ? "内置条目" : "自定义固定区间")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 24)

            Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(item.isEnabled ? Color.accentColor : Color.secondary.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, y: 10)
    }

    private func backgroundShape(for item: ProgressItem) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isDropTarget ? Color.accentColor.opacity(0.07) : Color.primary.opacity(0.04))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isDropTarget ? Color.accentColor.opacity(0.42) : Color.primary.opacity(0.06), lineWidth: isDropTarget ? 1.2 : 1)
    }

    private var insertionIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 7, height: 7)

            Capsule()
                .fill(Color.accentColor)
                .frame(height: 2.5)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .shadow(color: Color.accentColor.opacity(0.22), radius: 6, y: 1)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.isEnabled ?? false },
            set: { settingsStore.setItemEnabled($0, id: itemID) }
        )
    }
}

private enum ProgressOrderDropEdge {
    case before
    case after
}

private struct ProgressOrderDropDelegate: DropDelegate {
    let itemID: UUID
    @Binding var draggedItemID: UUID?
    @Binding var dropTargetItemID: UUID?
    @Binding var dropTargetEdge: ProgressOrderDropEdge?
    let settingsStore: AppSettingsStore

    func dropEntered(info: DropInfo) {
        updateDropState(with: info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateDropState(with: info)
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        resetState()
        return true
    }

    func dropExited(info: DropInfo) {
        if dropTargetItemID == itemID {
            dropTargetItemID = nil
            dropTargetEdge = nil
        }
    }

    private func updateDropState(with info: DropInfo) {
        guard
            let draggedItemID,
            draggedItemID != itemID
        else {
            return
        }

        let edge: ProgressOrderDropEdge = info.location.y < 34 ? .before : .after
        dropTargetItemID = itemID
        dropTargetEdge = edge

        let items = settingsStore.orderedProgressItems
        guard
            let fromIndex = items.firstIndex(where: { $0.id == draggedItemID }),
            let toIndex = items.firstIndex(where: { $0.id == itemID })
        else {
            return
        }

        var destinationIndex = toIndex + (edge == .after ? 1 : 0)
        if fromIndex < destinationIndex {
            destinationIndex -= 1
        }

        guard destinationIndex != fromIndex else {
            return
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.88)) {
            settingsStore.moveItem(id: draggedItemID, to: destinationIndex)
        }
    }

    private func resetState() {
        draggedItemID = nil
        dropTargetItemID = nil
        dropTargetEdge = nil
    }
}

private struct CustomProgressEditorCard: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let itemID: UUID

    private var item: ProgressItem? {
        settingsStore.item(withID: itemID)
    }

    var body: some View {
        if let item, let config = item.customConfig {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Spacer()

                    Button("删除") {
                        settingsStore.removeCustomProgress(id: itemID)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }

                TextField("标题", text: titleBinding)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    DatePicker(
                        "开始",
                        selection: startDateBinding,
                        displayedComponents: datePickerComponents
                    )

                    DatePicker(
                        "结束",
                        selection: endDateBinding,
                        displayedComponents: datePickerComponents
                    )
                }

                Toggle("精确到时间", isOn: usesTimePrecisionBinding)

                HStack(spacing: 12) {
                    TextField("左端标签（可选）", text: leftLabelBinding)
                        .textFieldStyle(.roundedBorder)

                    TextField("右端标签（可选）", text: rightLabelBinding)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("结束后保持显示为 100%", isOn: keepVisibleBinding)

                Text("当前区间：\(DisplayFormatting.boundaryString(from: config.startDate, showsTime: config.usesTimePrecision)) 到 \(DisplayFormatting.boundaryString(from: config.endDate, showsTime: config.usesTimePrecision))。关闭“精确到时间”后，这条进度会按整天来算，结束日期会被理解成那一天结束。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.title ?? "" },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    item.title = newValue
                }
            }
        )
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.startDate ?? Date() },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    let calendar = Calendar.autoupdatingCurrent
                    config.startDate = config.usesTimePrecision ? newValue : calendar.startOfDay(for: newValue)
                    if config.usesTimePrecision {
                        if config.endDate <= config.startDate {
                            config.endDate = config.startDate.addingTimeInterval(3_600)
                        }
                    } else if config.endDate < config.startDate {
                        config.endDate = config.startDate
                    }
                    item.customConfig = config
                }
            }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.endDate ?? Date().addingTimeInterval(3_600) },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    let calendar = Calendar.autoupdatingCurrent
                    if config.usesTimePrecision {
                        let minimumEndDate = config.startDate.addingTimeInterval(60)
                        config.endDate = max(newValue, minimumEndDate)
                    } else {
                        let normalizedEndDate = calendar.startOfDay(for: newValue)
                        config.endDate = max(normalizedEndDate, calendar.startOfDay(for: config.startDate))
                    }
                    item.customConfig = config
                }
            }
        )
    }

    private var usesTimePrecisionBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.usesTimePrecision ?? false },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    let calendar = Calendar.autoupdatingCurrent
                    config.usesTimePrecision = newValue
                    if newValue {
                        if config.endDate <= config.startDate {
                            config.endDate = config.startDate.addingTimeInterval(3_600)
                        }
                    } else {
                        config.startDate = calendar.startOfDay(for: config.startDate)
                        config.endDate = max(
                            calendar.startOfDay(for: config.endDate),
                            config.startDate
                        )
                    }
                    item.customConfig = config
                }
            }
        )
    }

    private var datePickerComponents: DatePickerComponents {
        (settingsStore.item(withID: itemID)?.customConfig?.usesTimePrecision ?? false) ? [.date, .hourAndMinute] : [.date]
    }

    private var leftLabelBinding: Binding<String> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.leftLabelOverride ?? "" },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    config.leftLabelOverride = newValue
                    item.customConfig = config
                }
            }
        )
    }

    private var rightLabelBinding: Binding<String> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.rightLabelOverride ?? "" },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    config.rightLabelOverride = newValue
                    item.customConfig = config
                }
            }
        )
    }

    private var keepVisibleBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.item(withID: itemID)?.customConfig?.keepVisibleAfterCompletion ?? true },
            set: { newValue in
                settingsStore.updateProgressItem(id: itemID) { item in
                    guard var config = item.customConfig else { return }
                    config.keepVisibleAfterCompletion = newValue
                    item.customConfig = config
                }
            }
        )
    }
}
