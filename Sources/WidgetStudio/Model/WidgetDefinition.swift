import SwiftUI

/// Everything a widget needs to draw itself.
///
/// A widget is a pure function of its settings and the current date, which makes
/// it trivial to preview in the gallery and in the inspector.
struct WidgetContext {
    let settings: SettingsBag
    var date: Date
    /// Size of the widget in points — widgets use it to scale their content
    /// down when extra lines (seconds, date…) would not fit.
    var size: CGSize = CGSize(width: 158, height: 158)
}

/// A ready-made look that can be applied to a widget with one click.
struct WidgetPreset: Identifiable {
    let id: String
    let name: LText
    let values: [String: SettingValue]
    /// Optional size that the preset also applies.
    var size: CGSize?

    init(id: String, name: LText, values: [String: SettingValue], size: CGSize? = nil) {
        self.id = id
        self.name = name
        self.values = values
        self.size = size
    }
}

/// A widget type: metadata, its customization schema, presets and its renderer.
///
/// Adding a new widget to the app means creating one file with a `WidgetDefinition`
/// and appending it to `WidgetCatalog.all` — nothing else has to change.
struct WidgetDefinition: Identifiable {
    let id: String
    let name: LText
    let summary: LText
    /// SF Symbol shown in the gallery and the menu.
    let symbol: String
    let defaultSize: CGSize
    /// Widget specific options (rendered before the shared ones).
    let settings: [SettingDescriptor]
    let presets: [WidgetPreset]
    let content: (WidgetContext) -> AnyView
    /// Different defaults for the shared appearance options, so that a calendar
    /// and a clock can both use "font size" meaningfully.
    var overrides: [String: SettingValue] = [:]

    /// Widget specific options followed by the shared appearance options,
    /// with the shared defaults adjusted for this widget.
    var allSettings: [SettingDescriptor] {
        (settings + CommonSettings.definitions).map { descriptor in
            guard let value = overrides[descriptor.id] else { return descriptor }
            return descriptor.withDefault(value)
        }
    }

    var settingsByID: [String: SettingDescriptor] {
        Dictionary(uniqueKeysWithValues: allSettings.map { ($0.id, $0) })
    }

    /// Default values for every setting of this widget.
    var defaultSettings: [String: SettingValue] {
        Dictionary(uniqueKeysWithValues: allSettings.map { ($0.id, $0.defaultValue) })
    }

    func bag(_ values: [String: SettingValue]) -> SettingsBag {
        SettingsBag(values: values, descriptors: allSettings)
    }

    /// Groups in the order they should appear in the inspector.
    var groups: [LText] {
        var result: [LText] = []
        for descriptor in allSettings where !result.contains(descriptor.group) {
            result.append(descriptor.group)
        }
        return result
    }

    func settings(in group: LText) -> [SettingDescriptor] {
        allSettings.filter { $0.group == group }
    }
}

/// Every widget the app knows about.
///
/// To add a new one: create `FooWidget.swift` with a `WidgetDefinition` and put
/// it into `all` below. The gallery, the menu, persistence and the whole
/// customization UI pick it up automatically.
enum WidgetCatalog {
    static let all: [WidgetDefinition] = [
        ClockWidget.definition,
        CalendarWidget.definition,
        NoteWidget.definition
    ]

    static func definition(_ id: String) -> WidgetDefinition? {
        all.first { $0.id == id }
    }
}
