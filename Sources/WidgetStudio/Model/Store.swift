import AppKit
import Foundation

/// Application-wide preferences.
struct AppSettings: Codable, Equatable {
    var language: AppLanguage = .ru
    var showDockIcon: Bool = false
    var snapToGrid: Bool = true
    var gridSize: Double = 16
    var showHoverControls: Bool = true
    var defaultLevel: WidgetLevel = .desktop
}

/// The whole persisted state of the app.
struct AppConfiguration: Codable {
    var version: Int = 1
    var app: AppSettings = AppSettings()
    var widgets: [WidgetRecord] = []
}

/// Reads and writes `~/Library/Application Support/WidgetStudio/config.json`.
enum Store {
    static let folderName = "WidgetStudio"

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    /// The `WIDGETSTUDIO_CONFIG` environment variable allows running several
    /// isolated instances (handy while developing).
    static var configURL: URL {
        if let override = ProcessInfo.processInfo.environment["WIDGETSTUDIO_CONFIG"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return directory.appendingPathComponent("config.json")
    }

    static func load() -> AppConfiguration {
        guard let data = try? Data(contentsOf: configURL) else { return AppConfiguration() }
        do {
            return try JSONDecoder().decode(AppConfiguration.self, from: data)
        } catch {
            NSLog("[WidgetStudio] Failed to read config: \(error)")
            // Keep a copy of the broken file so nothing is silently lost.
            let backup = configURL.appendingPathExtension("broken")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: configURL, to: backup)
            return AppConfiguration()
        }
    }

    static func save(_ configuration: AppConfiguration) {
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configuration)
            try data.write(to: configURL, options: .atomic)
        } catch {
            NSLog("[WidgetStudio] Failed to write config: \(error)")
        }
    }

    static func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }
}
