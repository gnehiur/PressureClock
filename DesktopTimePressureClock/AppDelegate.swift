import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settingsStore = AppSettingsStore()
    private lazy var clockEngine = ClockEngine(settingsStore: settingsStore)

    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var floatingMenuItem: NSMenuItem?
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        createMainWindow()
        bindSettings()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === mainWindow else { return }
        settingsStore.saveWindowFrame(window.frame)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === mainWindow else { return }
        settingsStore.saveWindowFrame(window.frame)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === settingsWindow {
            if let parent = window.parent {
                parent.removeChildWindow(window)
            }
            settingsWindow = nil
        }
    }

    @objc
    private func openPreferences(_ sender: Any?) {
        showSettingsWindow()
    }

    @objc
    private func toggleFloatingMode(_ sender: Any?) {
        settingsStore.toggleWindowMode()
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(title: "设置…", action: #selector(openPreferences(_:)), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出桌面时间进度钟", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)

        let viewMenu = NSMenu(title: "视图")
        let floatingItem = NSMenuItem(title: "悬浮在其他 App 之上", action: #selector(toggleFloatingMode(_:)), keyEquivalent: "f")
        floatingItem.keyEquivalentModifierMask = [.command, .option]
        floatingItem.target = self
        viewMenu.addItem(floatingItem)
        viewMenuItem.submenu = viewMenu

        floatingMenuItem = floatingItem
        NSApp.mainMenu = mainMenu
        updateFloatingMenuState()
    }

    private func createMainWindow() {
        let defaultFrame = NSRect(x: 0, y: 0, width: 760, height: 560)
        let frame = settingsStore.restoredWindowFrame ?? defaultFrame

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "桌面时间进度钟"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 520, height: 380)
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]

        let rootView = ClockDashboardView { [weak self] in
            self?.showSettingsWindow()
        }
        .environmentObject(settingsStore)
        .environmentObject(clockEngine)

        window.contentView = NSHostingView(rootView: rootView)
        applyWindowMode(settingsStore.windowMode, to: window)

        if settingsStore.restoredWindowFrame == nil {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
        mainWindow = window
    }

    private func bindSettings() {
        settingsStore.$windowMode
            .sink { [weak self] mode in
                guard let self else { return }
                if let mainWindow {
                    applyWindowMode(mode, to: mainWindow)
                }
                updateFloatingMenuState()
            }
            .store(in: &subscriptions)
    }

    private func applyWindowMode(_ mode: WindowMode, to window: NSWindow) {
        window.level = mode == .floating ? .floating : .normal
        if mode == .floating {
            window.orderFrontRegardless()
        }
    }

    private func updateFloatingMenuState() {
        floatingMenuItem?.state = settingsStore.windowMode == .floating ? .on : .off
    }

    private func showSettingsWindow() {
        if let settingsWindow {
            attachSettingsWindowIfNeeded(settingsWindow)
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "设置"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.minSize = NSSize(width: 680, height: 620)
        window.level = .normal
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]

        let rootView = SettingsView {
            window.performClose(nil)
        }
        .environmentObject(settingsStore)

        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        attachSettingsWindowIfNeeded(window)
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    private func attachSettingsWindowIfNeeded(_ window: NSWindow) {
        guard let mainWindow else { return }
        if window.parent !== mainWindow {
            window.parent?.removeChildWindow(window)
            mainWindow.addChildWindow(window, ordered: .above)
        }
    }
}
