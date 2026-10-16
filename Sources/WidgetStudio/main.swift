import AppKit

// Widget Studio — customizable desktop widgets for macOS.
//
// The app lives in the menu bar and draws every placed widget in its own
// borderless window on the desktop, exactly like the iPhone widgets that macOS
// mirrors onto the wallpaper.

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
// Widget Studio is an ordinary app with a Dock icon; the appearance can be
// adjusted from the settings (a menu bar only mode is available as well).
application.setActivationPolicy(.regular)
application.run()
