import AppKit

/// Menu bar (status bar) item: quick access to the settings, the widget gallery
/// and the global visibility switch.
final class StatusItemController: NSObject, NSMenuDelegate {

    private let state: AppState
    private let statusItem: NSStatusItem

    init(state: AppState) {
        self.state = state
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "square.grid.2x2.fill",
                                accessibilityDescription: "Widget Studio")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Widget Studio"
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuilt on every open so that the language and the widget list are current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = NSMenuItem(title: L("Открыть Widget Studio…", "Open Widget Studio…"),
                              action: #selector(openSettings), keyEquivalent: ",")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let visibility = NSMenuItem(title: state.widgetsHidden
                                    ? L("Показать виджеты", "Show widgets")
                                    : L("Скрыть виджеты", "Hide widgets"),
                                    action: #selector(toggleVisibility), keyEquivalent: "")
        visibility.target = self
        menu.addItem(visibility)

        let addItem = NSMenuItem(title: L("Добавить виджет", "Add widget"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for definition in WidgetCatalog.all {
            let item = NSMenuItem(title: definition.name.value,
                                  action: #selector(addWidget(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = definition.id
            item.image = NSImage(systemSymbolName: definition.symbol, accessibilityDescription: nil)
            submenu.addItem(item)
        }
        addItem.submenu = submenu
        menu.addItem(addItem)

        if !state.widgets.isEmpty {
            let listItem = NSMenuItem(title: L("Виджеты на рабочем столе", "Widgets on the desktop"),
                                      action: nil, keyEquivalent: "")
            let listMenu = NSMenu()
            for instance in state.widgets {
                let title = "\(instance.definition.name.value)\(instance.hidden ? L(" (скрыт)", " (hidden)") : "")"
                let item = NSMenuItem(title: title, action: #selector(showWidget(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = instance.id
                listMenu.addItem(item)
            }
            listItem.submenu = listMenu
            menu.addItem(listItem)
        }

        menu.addItem(.separator())

        let quit = NSMenuItem(title: L("Выход", "Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    // MARK: - Actions

    @objc private func openSettings() {
        AppEnvironment.shared.settingsWindow?.show()
    }

    @objc private func toggleVisibility() {
        state.widgetsHidden.toggle()
    }

    @objc private func addWidget(_ sender: NSMenuItem) {
        guard let kind = sender.representedObject as? String else { return }
        state.addWidget(kind: kind)
    }

    @objc private func showWidget(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        AppEnvironment.shared.settingsWindow?.show(selecting: id)
    }
}
