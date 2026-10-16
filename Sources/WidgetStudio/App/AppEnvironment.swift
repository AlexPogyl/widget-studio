import AppKit

/// Tiny service locator that ties the app together. Widget windows, the menu bar
/// item and the settings window all need to reach each other, and passing these
/// references around every view would be far more code than it is worth.
final class AppEnvironment {
    static let shared = AppEnvironment()

    private(set) var state: AppState!
    private(set) var windowManager: WidgetWindowManager!
    private(set) var settingsWindow: SettingsWindowController?
    private(set) var statusItem: StatusItemController!

    private init() {}

    func bootstrap() {
        let state = AppState()
        self.state = state
        self.windowManager = WidgetWindowManager(state: state)
        self.settingsWindow = SettingsWindowController(state: state)
        self.statusItem = StatusItemController(state: state)

        // Development helper: open the settings window right away.
        // `WIDGETSTUDIO_SHOW_SETTINGS=inspector` also selects the first widget.
        if let mode = ProcessInfo.processInfo.environment["WIDGETSTUDIO_SHOW_SETTINGS"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if mode == "inspector", let first = state.widgets.first {
                    self.settingsWindow?.show(selecting: first.id)
                } else {
                    self.settingsWindow?.show()
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppEnvironment.shared.bootstrap()
        MainMenu.install()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
