import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

/// Executable name inside WidgetStudioWidgets.appex; used to restart it.
let WidgetExtensionProcessName = "WidgetStudioWidgets"

/// What is selected in the settings window sidebar.
enum SidebarSelection: Hashable {
    case overview
    case widget(String)
    case application
}

/// The document of the app: the saved look of every widget kind plus the
/// application preferences. Every change is written to disk and pushed to the
/// system widgets (debounced).
final class AppState: ObservableObject {

    @Published var profiles: [WidgetProfile]
    @Published var app: AppSettings
    @Published var selection: SidebarSelection? = .overview

    private var saveWorkItem: DispatchWorkItem?
    private var reloadWorkItem: DispatchWorkItem?
    private var cancellables: Set<AnyCancellable> = []

    init(configuration: AppConfiguration = Store.load()) {
        self.app = configuration.app
        self.profiles = configuration.widgets.map { WidgetProfile(record: $0) }
        Localization.shared.language = configuration.app.language

        // Every widget kind gets a profile, so the extension always finds settings.
        for definition in WidgetCatalog.all where !profiles.contains(where: { $0.kind == definition.id }) {
            profiles.append(WidgetProfile(kind: definition.id))
        }

        observeProfiles()
        applyDockPolicy()
        restartWidgetsAfterUpdate()
        // Diagnostics: which of our widgets are currently placed on the desktop.
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let infos):
                NSLog("[WidgetStudio] placed widgets: %d", infos.count)
                for info in infos {
                    NSLog("[WidgetStudio]   kind=%@ family=%d", info.kind, info.family.rawValue)
                }
            case .failure(let error):
                NSLog("[WidgetStudio] configurations error: %@", String(describing: error))
            }
        }
        // Persist the initial set of profiles, so a fresh install is complete.
        scheduleSave()
        refreshWeatherIfNeeded()
    }

    // MARK: - Profiles

    func profile(for kind: String) -> WidgetProfile {
        if let existing = profiles.first(where: { $0.kind == kind }) { return existing }
        let profile = WidgetProfile(kind: kind)
        profiles.append(profile)
        scheduleSave()
        return profile
    }

    func existingProfile(for kind: String) -> WidgetProfile? {
        profiles.first { $0.kind == kind }
    }

    func reset(_ profile: WidgetProfile) {
        profile.applyDefaultSettings()
        scheduleSave()
    }

    // MARK: - Appearance policy

    func applyDockPolicy() {
        // Never let the user hide both the Dock icon and the menu bar item.
        let dockIcon = app.showDockIcon || !app.showStatusItem
        NSApp.setActivationPolicy(dockIcon ? .regular : .accessory)
    }

    // MARK: - Persistence

    private func observeProfiles() {
        $profiles
            .flatMap { profiles -> AnyPublisher<Void, Never> in
                let publishers = profiles.map { $0.objectWillChange.map { _ in () }.eraseToAnyPublisher() }
                return Publishers.MergeMany(publishers).eraseToAnyPublisher()
            }
            .sink { [weak self] _ in self?.scheduleSave() }
            .store(in: &cancellables)

        $app
            .dropFirst()
            .sink { [weak self] settings in
                Localization.shared.language = settings.language
                self?.applyDockPolicy()
                self?.scheduleSave()
            }
            .store(in: &cancellables)

        $profiles
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleSave() }
            .store(in: &cancellables)
    }

    func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }

    func saveNow() {
        Store.save(configuration)
        scheduleWidgetReload()
    }

    /// Asks the system to redraw the widgets, but not more often than once a
    /// second or so: WidgetKit budgets timeline reloads and ignores a flood of
    /// them, and a killed extension means an empty placeholder on the desktop.
    func scheduleWidgetReload() {
        reloadWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.reloadSystemWidgets() }
        reloadWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    // MARK: - Weather

    private var lastWeatherRequest: Date?

    /// Downloads the forecast when the cache is stale (the widget itself only
    /// reads the cache, so the app keeps it warm).
    func refreshWeatherIfNeeded(force: Bool = false) {
        guard let profile = existingProfile(for: WeatherWidget.definition.id) else { return }
        let cityID = profile.bag.string("weather.city")
        let cached = WeatherService.cached(cityID: cityID)
        if !force, let cached, Date().timeIntervalSince(cached.updated) < 900 { return }
        if !force, let last = lastWeatherRequest, Date().timeIntervalSince(last) < 60 { return }
        lastWeatherRequest = Date()
        WeatherService.fetch(cityID: cityID) { [weak self] _ in
            self?.scheduleWidgetReload()
        }
    }

    /// Asks the system to redraw the widgets with the current settings.
    ///
    /// The extension process is deliberately *not* restarted here: while it is
    /// down macOS draws its empty placeholder, which is what made the desktop
    /// widget look white most of the time. The process is only restarted once
    /// per app version (see `restartWidgetsAfterUpdate`), because an extension
    /// keeps running the code it loaded at launch.
    func reloadSystemWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func restartWidgetExtension() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = [WidgetExtensionProcessName]
        try? task.run()
        task.waitUntilExit()
    }

    /// Called once per app version: extensions started by a previous build must
    /// not keep rendering the old widget.
    private func restartWidgetsAfterUpdate() {
        let key = "WidgetStudioLastLaunchedVersion"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let defaults = UserDefaults.standard
        let previous = defaults.string(forKey: key)
        defaults.set(version, forKey: key)
        guard previous != version else { return }
        Self.restartWidgetExtension()
    }

    var configuration: AppConfiguration {
        AppConfiguration(version: 2,
                         app: app,
                         widgets: profiles.map { $0.record })
    }

    // MARK: - Import / export

    func exportConfiguration() {
        let panel = NSSavePanel()
        panel.title = L("Экспорт настроек виджетов", "Export widget settings")
        panel.nameFieldStringValue = "WidgetStudio.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(configuration) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func importConfiguration() {
        let panel = NSOpenPanel()
        panel.title = L("Импорт настроек виджетов", "Import widget settings")
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url),
              let configuration = try? JSONDecoder().decode(AppConfiguration.self, from: data) else { return }
        profiles = configuration.widgets.map { WidgetProfile(record: $0) }
        app = configuration.app
        Localization.shared.language = configuration.app.language
        saveNow()
    }

    func resetEverything() {
        profiles = []
        app = AppSettings()
        Localization.shared.language = app.language
        applyDockPolicy()
        saveNow()
    }
}
