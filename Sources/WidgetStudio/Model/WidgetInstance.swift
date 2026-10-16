import AppKit
import SwiftUI

/// Stacking behaviour of a widget window.
enum WidgetLevel: String, Codable, CaseIterable, Identifiable {
    /// Lies on the desktop, below ordinary windows, exactly like the iPhone
    /// widgets that macOS mirrors onto the wallpaper.
    case desktop
    /// Ordinary window that can be covered by other applications.
    case normal
    /// Always in front of everything.
    case floating

    var id: String { rawValue }

    var title: LText {
        switch self {
        case .desktop: return LText("На рабочем столе", "On the desktop")
        case .normal: return LText("Обычное окно", "Normal window")
        case .floating: return LText("Поверх всех окон", "Always on top")
        }
    }

    var symbol: String {
        switch self {
        case .desktop: return "menubar.dock.rectangle"
        case .normal: return "macwindow"
        case .floating: return "pin.fill"
        }
    }

    var windowLevel: NSWindow.Level {
        switch self {
        case .desktop: return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        case .normal: return .normal
        case .floating: return .floating
        }
    }
}

/// A widget placed on the desktop by the user.
///
/// It owns the geometry and the stacking behaviour and forwards them to its
/// window; `WidgetWindowManager` listens to the published values.
final class WidgetInstance: ObservableObject, Identifiable {
    let id: UUID
    let kind: String

    @Published var settings: [String: SettingValue]
    /// Centre of the card in screen coordinates (AppKit origin, bottom-left).
    @Published var center: CGPoint
    @Published var size: CGSize
    @Published var level: WidgetLevel
    @Published var locked: Bool
    @Published var clickThrough: Bool
    @Published var hidden: Bool
    @Published var presetID: String?

    var definition: WidgetDefinition {
        WidgetCatalog.definition(kind) ?? WidgetCatalog.all[0]
    }

    var bag: SettingsBag { definition.bag(settings) }

    init(id: UUID = UUID(),
         kind: String,
         settings: [String: SettingValue]? = nil,
         center: CGPoint,
         size: CGSize? = nil,
         level: WidgetLevel = .desktop,
         locked: Bool = false,
         clickThrough: Bool = false,
         hidden: Bool = false,
         presetID: String? = nil) {
        self.id = id
        self.kind = kind
        self.settings = settings ?? WidgetCatalog.definition(kind)?.defaultSettings ?? [:]
        self.center = center
        self.size = size ?? WidgetCatalog.definition(kind)?.defaultSize ?? CGSize(width: 158, height: 158)
        self.level = level
        self.locked = locked
        self.clickThrough = clickThrough
        self.hidden = hidden
        self.presetID = presetID
    }

    // MARK: - Settings

    func set(_ key: String, _ value: SettingValue) {
        guard settings[key] != value else { return }
        settings[key] = value
    }

    func applyDefaultSettings() {
        settings = definition.defaultSettings
        size = definition.defaultSize
        presetID = nil
    }

    func apply(_ preset: WidgetPreset) {
        for (key, value) in preset.values { settings[key] = value }
        if let size = preset.size { self.size = size }
        presetID = preset.id
    }

    /// A preset is considered active while every one of its values matches.
    func matches(_ preset: WidgetPreset) -> Bool {
        let bag = definition.bag(settings)
        for (key, value) in preset.values where bag.value(key) != value { return false }
        return true
    }

    // MARK: - Geometry

    var frame: CGRect {
        CGRect(x: center.x - size.width / 2,
               y: center.y - size.height / 2,
               width: size.width,
               height: size.height)
    }

    // MARK: - Persistence

    var record: WidgetRecord {
        WidgetRecord(id: id,
                     kind: kind,
                     centerX: center.x,
                     centerY: center.y,
                     width: size.width,
                     height: size.height,
                     level: level,
                     locked: locked,
                     clickThrough: clickThrough,
                     hidden: hidden,
                     presetID: presetID,
                     settings: settings)
    }

    convenience init(record: WidgetRecord) {
        self.init(id: record.id,
                  kind: record.kind,
                  settings: record.settings,
                  center: CGPoint(x: record.centerX, y: record.centerY),
                  size: CGSize(width: record.width, height: record.height),
                  level: record.level,
                  locked: record.locked,
                  clickThrough: record.clickThrough,
                  hidden: record.hidden,
                  presetID: record.presetID)
        // Drop options that no longer exist and fill in newly added ones.
        settings = settings.filter { definition.settingsByID[$0.key] != nil }
    }
}

/// Plain-data representation of a widget, used for the JSON configuration file.
struct WidgetRecord: Codable {
    var id: UUID
    var kind: String
    var centerX: Double
    var centerY: Double
    var width: Double
    var height: Double
    var level: WidgetLevel
    var locked: Bool
    var clickThrough: Bool
    var hidden: Bool
    var presetID: String?
    var settings: [String: SettingValue]
}
