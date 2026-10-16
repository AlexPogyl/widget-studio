import AppKit
import Combine

/// Tiny service locator that ties the app together: the document, the menu bar
/// item and the settings window, plus the URL entry point used by the widgets.
final class AppEnvironment {
    static let shared = AppEnvironment()

    private var cancellables: Set<AnyCancellable> = []

    private(set) var state: AppState!
    private(set) var settingsWindow: SettingsWindowController?
    private(set) var statusItem: StatusItemController!

    private init() {}

    func bootstrap() {
        let state = AppState()
        self.state = state
        self.settingsWindow = SettingsWindowController(state: state)
        self.statusItem = StatusItemController(state: state)

        state.$app
            .map(\.showStatusItem)
            .removeDuplicates()
            .sink { [weak self] visible in self?.statusItem?.setVisible(visible) }
            .store(in: &cancellables)

        if state.app.windowOnLaunch {
            self.settingsWindow?.show()
        }

        // Development helper: open the settings window right away.
        // `WIDGETSTUDIO_SHOW_SETTINGS=inspector` also selects the first widget.
        if let mode = ProcessInfo.processInfo.environment["WIDGETSTUDIO_SHOW_SETTINGS"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if mode == "inspector", let first = WidgetCatalog.all.first {
                    self.settingsWindow?.show(selecting: first.id)
                } else {
                    self.settingsWindow?.show()
                }
            }
        }
    }

    /// Called by the system when a widget opens a `widgetstudio://` URL.
    func handle(_ url: URL) {
        guard let path = WidgetAction.applicationPath(from: url) else { return }
        WidgetLauncher.open(applicationAt: path)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppEnvironment.shared.bootstrap()
        MainMenu.install()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Clicking the Dock icon brings the main window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { AppEnvironment.shared.settingsWindow?.show() }
        return true
    }

    /// Widgets open applications through this entry point.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { AppEnvironment.shared.handle(url) }
    }
}
