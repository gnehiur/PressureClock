import SwiftUI

struct MobileSettingsView: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("标记睡眠时段", isOn: sleepEnabledBinding)

                    if settingsStore.sleepSchedule.isEnabled {
                        DatePicker("入睡", selection: sleepTimeBinding(\.startMinutes), displayedComponents: .hourAndMinute)
                        DatePicker("起床", selection: sleepTimeBinding(\.endMinutes), displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("睡眠")
                } footer: {
                    Text("睡眠时段会在“今日”刻度条上压暗显示，跨午夜会自动拆成条头和条尾两段，边界处有记号标出入睡与起床时刻。")
                }

                Section {
                    Picker("显示精度", selection: timePrecisionBinding) {
                        ForEach(TimePrecision.allCases) { precision in
                            Text(precision.displayName).tag(precision)
                        }
                    }
                } header: {
                    Text("时间")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var sleepEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.sleepSchedule.isEnabled },
            set: { settingsStore.sleepSchedule.isEnabled = $0 }
        )
    }

    private var timePrecisionBinding: Binding<TimePrecision> {
        Binding(
            get: { settingsStore.timePrecision },
            set: { settingsStore.timePrecision = $0 }
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
}
