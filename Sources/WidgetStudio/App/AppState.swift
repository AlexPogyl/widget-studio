import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

/// What is selected in the settings window sidebar.
enum SidebarSelection: Hashable {
    case gallery
    case widget(UUID)
    case application
}

/// The document of the app: the list of widgets on the desktop plus the
/// application preferences. Every change is written to disk (debounced).
final class AppState: ObservableObject {

    @Published var widgets: [WidgetInstance]
    @Published var app: AppSettings
    /// Global "hide all widgets" switch from the menu bar.
    @Published var widgetsHidden: Bool = false
    @Published var selection: SidebarSelection? = .gallery

    private var saveWorkItem: DispatchWorkItem?
    private var cancellables: Set<AnyCancellable> = []

    init(configuration: AppConfiguration = Store.load()) {
        self.app = configuration.app
        self.widgets = configuration.widgets.map { WidgetInstance(record: $0) }
        Localization.shared.language = configuration.app.language

        if widgets.isEmpty && !FileManager.default.fileExists(atPath: Store.configURL.path) {
            widgets = [Self.makeFirstLaunchWidget(level: configuration.app.defaultLevel)]
        }

        observeInstances()
        applyDockPolicy()
        // Persist the initial layout, so a fresh install restores the same widget.
        scheduleSave()
    }

    // MARK: - First launch

    /// Mirrors the iPhone widget that ships with macOS: a large clock card in the
    /// top-left corner of the desktop.
    static func makeFirstLaunchWidget(level: WidgetLevel) -> WidgetInstance {
        let size = ClockWidget.definition.defaultSize
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let center = CGPoint(x: screen.minX + size.width / 2 + 14,
                             y: screen.maxY - size.height / 2 - 14)
        return WidgetInstance(kind: ClockWidget.definition.id,
                              center: center,
                              size: size,
                              level: level)
    }

    // MARK: - Widgets

    @discardableResult
    func addWidget(kind: String, at point: CGPoint? = nil) -> WidgetInstance? {
        guard let definition = WidgetCatalog.definition(kind) else { return nil }
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let center = point ?? CGPoint(x: screen.midX, y: screen.midY)
        let instance = WidgetInstance(kind: kind,
                                      center: center,
                                      size: definition.defaultSize,
                                      level: app.defaultLevel)
        widgets.append(instance)
        selection = .widget(instance.id)
        scheduleSave()
        return instance
    }

    func remove(_ instance: WidgetInstance) {
        widgets.removeAll { $0.id == instance.id }
        if selection == .widget(instance.id) { selection = .gallery }
        scheduleSave()
    }

    func duplicate(_ instance: WidgetInstance) {
        let copy = WidgetInstance(kind: instance.kind,
                                  settings: instance.settings,
                                  center: CGPoint(x: instance.center.x + 24, y: instance.center.y - 24),
                                  size: instance.size,
                                  level: instance.level,
                                  presetID: instance.presetID)
        widgets.append(copy)
        selection = .widget(copy.id)
        scheduleSave()
    }

    func centerOnScreen(_ instance: WidgetInstance) {
        let screen = screen(containing: instance.center) ?? NSScreen.main
        guard let frame = screen?.visibleFrame else { return }
        instance.center = CGPoint(x: frame.midX, y: frame.midY)
    }

    func instance(with id: UUID) -> WidgetInstance? {
        widgets.first { $0.id == id }
    }

    // MARK: - Appearance policy

    func applyDockPolicy() {
        NSApp.setActivationPolicy(app.showDockIcon ? .regular : .accessory)
    }

    // MARK: - Persistence

    private func observeInstances() {
        // Any change of an instance (settings, position, level…) schedules a save.
        $widgets
            .flatMap { widgets -> AnyPublisher<Void, Never> in
                let publishers = widgets.map { $0.objectWillChange.map { _ in () }.eraseToAnyPublisher() }
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

        $widgets
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
    }

    var configuration: AppConfiguration {
        AppConfiguration(version: 1,
                         app: app,
                         widgets: widgets.map { $0.record })
    }

    // MARK: - Import / export

    func exportConfiguration() {
        let panel = NSSavePanel()
        panel.title = L("Экспорт виджетов", "Export widgets")
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
        panel.title = L("Импорт виджетов", "Import widgets")
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url),
              let configuration = try? JSONDecoder().decode(AppConfiguration.self, from: data) else { return }
        widgets = configuration.widgets.map { WidgetInstance(record: $0) }
        app = configuration.app
        Localization.shared.language = configuration.app.language
        saveNow()
    }

    func resetEverything() {
        widgets = [Self.makeFirstLaunchWidget(level: .desktop)]
        app = AppSettings()
        Localization.shared.language = app.language
        applyDockPolicy()
        saveNow()
    }

    // MARK: - Helpers

    func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }
}
