import SwiftUI

/// Read-only view over the settings of a single widget, with defaults applied.
struct SettingsBag {
    private let values: [String: SettingValue]
    private let defaults: [String: SettingValue]

    init(values: [String: SettingValue], descriptors: [SettingDescriptor]) {
        self.values = values
        var defaults: [String: SettingValue] = [:]
        for descriptor in descriptors { defaults[descriptor.id] = descriptor.defaultValue }
        self.defaults = defaults
    }

    func value(_ id: String) -> SettingValue {
        values[id] ?? defaults[id] ?? .number(0)
    }

    func bool(_ id: String) -> Bool {
        if case .bool(let value) = value(id) { return value }
        return false
    }

    func double(_ id: String) -> Double { value(id).doubleValue }
    func int(_ id: String) -> Int { value(id).intValue }
    func string(_ id: String) -> String { value(id).stringValue }
    func list(_ id: String) -> [String] { value(id).listValue }
    func rgba(_ id: String) -> RGBA { value(id).colorValue }
    func color(_ id: String) -> Color { rgba(id).color }
}
