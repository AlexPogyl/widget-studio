import AppKit
import Foundation

/// App-side half of the "open an application on click" action: launching the
/// chosen app and showing it in the inspector.
enum WidgetLauncher {

    @discardableResult
    static func open(applicationAt path: String) -> Bool {
        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return false }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { NSLog("[WidgetStudio] Failed to open \(path): \(error)") }
        }
        return true
    }

    static func displayName(for path: String) -> String {
        guard !path.isEmpty else { return "" }
        return FileManager.default.displayName(atPath: path)
    }

    static func icon(for path: String) -> NSImage? {
        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
