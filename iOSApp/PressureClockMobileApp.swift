import SwiftUI

@main
@MainActor
struct PressureClockMobileApp: App {
    @StateObject private var settingsStore: AppSettingsStore
    @StateObject private var clockEngine: ClockEngine

    init() {
        let store = AppSettingsStore()
        _settingsStore = StateObject(wrappedValue: store)
        _clockEngine = StateObject(wrappedValue: ClockEngine(settingsStore: store))
    }

    var body: some Scene {
        WindowGroup {
            MobileDashboardView()
                .environmentObject(settingsStore)
                .environmentObject(clockEngine)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .onAppear {
                    // 床头钟场景:插电常亮,不自动锁屏
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
