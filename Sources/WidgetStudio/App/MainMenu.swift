import AppKit

/// Minimal main menu.
///
/// The app runs as an accessory (menu bar only), but a main menu is still needed
/// for the standard key equivalents — ⌘Q, ⌘W, ⌘C/⌘V in text fields and so on.
enum MainMenu {

    static func install() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("О Widget Studio", "About Widget Studio"),
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())

        let settings = NSMenuItem(title: L("Настройки…", "Settings…"),
                                  action: #selector(MenuActions.showSettings(_:)),
                                  keyEquivalent: ",")
        settings.target = MenuActions.shared
        appMenu.addItem(settings)

        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Скрыть Widget Studio", "Hide Widget Studio"),
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Выход", "Quit"),
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit menu — needed for standard shortcuts in the text fields.
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: L("Правка", "Edit"))
        editMenu.addItem(withTitle: L("Отменить", "Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: L("Повторить", "Redo"), action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: L("Вырезать", "Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: L("Копировать", "Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: L("Вставить", "Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: L("Выбрать всё", "Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: L("Окно", "Window"))
        windowMenu.addItem(withTitle: L("Закрыть", "Close"),
                           action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: L("Свернуть", "Minimize"),
                           action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }
}

/// Target for menu items that are not handled by the responder chain.
final class MenuActions: NSObject {
    static let shared = MenuActions()

    @objc func showSettings(_ sender: Any?) {
        AppEnvironment.shared.settingsWindow?.show()
    }
}
