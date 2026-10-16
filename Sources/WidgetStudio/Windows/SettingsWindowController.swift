import AppKit
import SwiftUI

/// Hosts the SwiftUI settings window: widget gallery, live preview and the
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
        window.setContentSize(NSSize(width: 1000, height: 680))
        window.minSize = NSSize(width: 840, height: 560)
        window.isReleasedWhenClosed = false
        window.center()
        window.titlebarSeparatorStyle = .automatic

        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(selecting id: UUID? = nil) {
        if let id { state.selection = .widget(id) }
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
