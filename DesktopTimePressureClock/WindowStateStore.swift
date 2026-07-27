import Foundation

@MainActor
final class WindowStateStore: ObservableObject {
    @Published var isMainWindowActive = false
}
