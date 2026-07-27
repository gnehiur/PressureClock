import Combine
import Foundation

@MainActor
final class ClockEngine: ObservableObject {
    @Published private(set) var now: Date = Date()
    @Published private(set) var progressNow: Date = Date()
    @Published private(set) var smoothNow: Date = Date()

    private var subscriptions = Set<AnyCancellable>()
    private var precisionTicker: AnyCancellable?
    private var progressTicker: AnyCancellable?
    private var smoothTicker: AnyCancellable?

    init(settingsStore: AppSettingsStore) {
        settingsStore.$timePrecision
            .removeDuplicates()
            .sink { [weak self] precision in
                self?.configurePrecisionTicker(for: precision)
            }
            .store(in: &subscriptions)

        configurePrecisionTicker(for: settingsStore.timePrecision)
        configureProgressTicker()
        configureSmoothTicker()
    }

    private func configurePrecisionTicker(for precision: TimePrecision) {
        precisionTicker?.cancel()
        now = Date()

        precisionTicker = Timer.publish(
            every: precision.refreshInterval,
            tolerance: precision.tolerance,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.now = Date()
        }
    }

    private func configureProgressTicker() {
        progressTicker?.cancel()
        progressNow = Date()

        progressTicker = Timer.publish(
            every: 1.0,
            tolerance: 0.1,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.progressNow = Date()
        }
    }

    private func configureSmoothTicker() {
        smoothTicker?.cancel()
        smoothNow = Date()

        // Progress markers need a higher visual sample rate than the textual clock.
        // This keeps lines moving smoothly without forcing the full time display to reformat at 60fps.
        smoothTicker = Timer.publish(
            every: 1.0 / 60.0,
            tolerance: 1.0 / 300.0,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.smoothNow = Date()
        }
    }
}
