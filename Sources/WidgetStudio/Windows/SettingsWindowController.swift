import Cocoa
import SwiftUI

/// Hosts the SwiftUI settings window: widget list, live previews and the
/// customization inspector.
final class SettingsWindowController: NSWindowController {

    private let state: AppState

    init(state: AppState) {
        self.state = state

        let root = SettingsRootView()
            .environmentObject(state)
            .environmentObject(Localization.shared)
        let hosting = NSHostingController(rootView: root)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Widget Studio"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 1060, height: 720))
        window.minSize = NSSize(width: 880, height: 560)
        window.isReleasedWhenClosed = false
        window.center()
        window.titlebarSeparatorStyle = .automatic

        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(selecting kind: String? = nil) {
        if let kind { state.selection = .widget(kind) }
        activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Opens the window on the "how to add a widget" instructions.
    func showHowToAddWidget() {
        state.selection = .overview
        activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func activate() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
