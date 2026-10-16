import AppKit

// Widget Studio — customizable desktop widgets for macOS.
//
// The app lives in the menu bar and draws every placed widget in its own
// borderless window on the desktop, exactly like the iPhone widgets that macOS
// mirrors onto the wallpaper.

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
