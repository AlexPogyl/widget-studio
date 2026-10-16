import AppKit
import Foundation

/// Application-wide preferences.
///
/// Decoding is written by hand so that a configuration file created by an older
/// version keeps working after new options are added.
struct AppSettings: Codable, Equatable {
    var language: AppLanguage = .ru
    var showDockIcon: Bool = true
    var showStatusItem: Bool = true
    var windowOnLaunch: Bool = true

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        language = (try? container.decodeIfPresent(AppLanguage.self, forKey: .language)) ?? defaults.language
        showDockIcon = (try? container.decodeIfPresent(Bool.self, forKey: .showDockIcon)) ?? defaults.showDockIcon
        showStatusItem = (try? container.decodeIfPresent(Bool.self, forKey: .showStatusItem)) ?? defaults.showStatusItem
        windowOnLaunch = (try? container.decodeIfPresent(Bool.self, forKey: .windowOnLaunch)) ?? defaults.windowOnLaunch
    }
}

/// The whole persisted state of the app.
///
/// `widgets` holds one entry per widget kind; the WidgetKit extension reads the
/// same file to render the widgets with the user's settings.
struct AppConfiguration: Codable {
    var version: Int = 2
    var app: AppSettings = AppSettings()
    var widgets: [WidgetProfileRecord] = []
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
            // Keep a copy of the unreadable file, then start from scratch so the
            // app never comes up empty-handed.
            let backup = configURL.appendingPathExtension("broken")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: configURL, to: backup)
            try? FileManager.default.removeItem(at: configURL)
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
