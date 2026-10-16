import SwiftUI

/// A saved look for one widget kind.
///
/// macOS renders the widgets with WidgetKit, so the app configures *kinds* — all
/// system widgets of the same kind share this look, and dragging, resizing and
/// removal are handled entirely by the system.
final class WidgetProfile: ObservableObject, Identifiable {
    let kind: String

    @Published var settings: [String: SettingValue]
    @Published var presetID: String?

    var id: String { kind }

    var definition: WidgetDefinition {
        WidgetCatalog.definition(kind) ?? WidgetCatalog.all[0]
    }

    var bag: SettingsBag { definition.bag(settings) }

    init(kind: String, settings: [String: SettingValue]? = nil, presetID: String? = nil) {
        self.kind = kind
        self.settings = settings ?? WidgetCatalog.definition(kind)?.defaultSettings ?? [:]
        self.presetID = presetID
    }

    // MARK: - Settings

    func set(_ key: String, _ value: SettingValue) {
        guard settings[key] != value else { return }
        settings[key] = value
    }

    func applyDefaultSettings() {
        settings = definition.defaultSettings
        presetID = nil
    }

    func apply(_ preset: WidgetPreset) {
        for (key, value) in preset.values { settings[key] = value }
        presetID = preset.id
    }

    /// A preset is considered active while every one of its values matches.
    func matches(_ preset: WidgetPreset) -> Bool {
        let bag = definition.bag(settings)
        for (key, value) in preset.values where bag.value(key) != value { return false }
        return true
    }

    // MARK: - Persistence

    var record: WidgetProfileRecord {
        WidgetProfileRecord(kind: kind, settings: settings, presetID: presetID)
    }

    convenience init(record: WidgetProfileRecord) {
        self.init(kind: record.kind, settings: record.settings, presetID: record.presetID)
        // Drop options that no longer exist.
        settings = settings.filter { definition.settingsByID[$0.key] != nil }
    }
}

/// Plain-data representation of a profile inside the configuration file.
struct WidgetProfileRecord: Codable {
    var kind: String
    var settings: [String: SettingValue]
    var presetID: String?
}
