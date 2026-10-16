import AppKit

/// Menu bar (status bar) item: quick access to the settings and to the widget
/// reload. Can be switched off in the preferences.
final class StatusItemController: NSObject, NSMenuDelegate {

    private let state: AppState
    private var statusItem: NSStatusItem?

    init(state: AppState) {
        self.state = state
        super.init()
        setVisible(state.app.showStatusItem)
    }

    func setVisible(_ visible: Bool) {
        if visible {
            guard statusItem == nil else { return }
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let button = item.button {
                let image = NSImage(systemSymbolName: "square.grid.2x2.fill",
                                    accessibilityDescription: "Widget Studio")
                image?.isTemplate = true
                button.image = image
                button.toolTip = "Widget Studio"
            }
            let menu = NSMenu()
            menu.delegate = self
            item.menu = menu
            statusItem = item
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // Rebuilt on every open so that the language is current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = NSMenuItem(title: L("Открыть Widget Studio…", "Open Widget Studio…"),
                              action: #selector(openSettings), keyEquivalent: ",")
        open.target = self
        menu.addItem(open)

        let add = NSMenuItem(title: L("Как добавить виджет на рабочий стол…", "How to add a widget…"),
                             action: #selector(showHowTo), keyEquivalent: "")
        add.target = self
        menu.addItem(add)

        menu.addItem(.separator())

        let reload = NSMenuItem(title: L("Обновить виджеты", "Reload widgets"),
                                action: #selector(reloadWidgets), keyEquivalent: "r")
        reload.target = self
        menu.addItem(reload)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: L("Выход", "Quit"),
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    // MARK: - Actions

    @objc private func openSettings() {
        AppEnvironment.shared.settingsWindow?.show()
    }

    @objc private func showHowTo() {
        AppEnvironment.shared.settingsWindow?.showHowToAddWidget()
    }

    @objc private func reloadWidgets() {
        state.reloadSystemWidgets()
    }
}
