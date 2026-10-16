import SwiftUI
import WidgetKit

// WidgetKit extension of Widget Studio.
//
// It reuses the exact rendering code of the customization previews, so a widget
// placed from the system gallery ("Изменить виджеты…" on the desktop) looks
// exactly like the preview in the app. The user's settings are read from the
// shared configuration file; dragging, resizing and removal are handled by macOS.

// MARK: - Shared configuration

enum SharedConfig {

    struct File: Decodable {
        struct App: Decodable { var language: AppLanguage? }
        var app: App?
        var widgets: [Widget]
    }

    struct Widget: Decodable {
        var kind: String
        var settings: [String: SettingValue]?
    }

    static func load() -> File? {
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        return try? JSONDecoder().decode(File.self, from: data)
    }

    /// Inside the sandbox the home directory is the container, but macOS still
    /// lets a widget read the shared container of its containing app; the app
    /// group is emulated by the identical bundle prefix.
    static var configURL: URL {
        if let override = ProcessInfo.processInfo.environment["WIDGETSTUDIO_CONFIG"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Application Support/WidgetStudio/config.json")
    }

    static func settings(for kind: String) -> [String: SettingValue] {
        load()?.widgets.first { $0.kind == kind }?.settings ?? [:]
    }

    static var language: AppLanguage {
        load()?.app?.language ?? .ru
    }
}

// MARK: - Timeline

struct StudioEntry: TimelineEntry {
    let date: Date
    let kind: String
    let settings: SettingsBag
}

struct StudioProvider: TimelineProvider {
    let kind: String

    private var definition: WidgetDefinition {
        WidgetCatalog.definition(kind) ?? WidgetCatalog.all[0]
    }

    private var bag: SettingsBag {
        definition.bag(SharedConfig.settings(for: kind))
    }

    func placeholder(in context: Context) -> StudioEntry {
        StudioEntry(date: Date(), kind: kind, settings: definition.bag([:]))
    }

    func getSnapshot(in context: Context, completion: @escaping (StudioEntry) -> Void) {
        Localization.shared.language = SharedConfig.language
        completion(StudioEntry(date: Date(), kind: kind, settings: bag))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudioEntry>) -> Void) {
        Localization.shared.language = SharedConfig.language
        let settings = bag
        let now = Date()

        // A second hand cannot be animated by WidgetKit, so a widget that shows
        // seconds gets one entry per second for a few minutes; everything else
        // only needs one entry per minute. The first entry must be "now",
        // otherwise macOS shows its empty placeholder.
        let showsSeconds = kind == ClockWidget.definition.id && settings.bool("clock.showSeconds")
        let step: Calendar.Component = showsSeconds ? .second : .minute
        let count = showsSeconds ? 180 : 90

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ClockWidget.resolvedTimeZone(settings.string("clock.timeZone"))
        let anchor: Date
        if showsSeconds {
            anchor = calendar.date(bySetting: .nanosecond, value: 0, of: now) ?? now
        } else {
            anchor = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        }

        var entries = [StudioEntry(date: now, kind: kind, settings: settings)]
        for offset in 1..<count {
            guard let date = calendar.date(byAdding: step, value: offset, to: anchor) else { continue }
            entries.append(StudioEntry(date: date, kind: kind, settings: settings))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct StudioWidgetView: View {
    var entry: StudioEntry

    private var definition: WidgetDefinition {
        WidgetCatalog.definition(entry.kind) ?? WidgetCatalog.all[0]
    }

    /// "Open an application on click" is implemented through the app: the widget
    /// opens a URL, macOS launches Widget Studio with it.
    private var clickURL: URL? {
        guard entry.settings.string("common.clickAction") == "application" else { return nil }
        return WidgetAction.launchURL(applicationPath: entry.settings.string("common.clickApplication"))
    }

    var body: some View {
        GeometryReader { proxy in
            WidgetSurface(definition: definition,
                          settings: entry.settings,
                          date: entry.date,
                          size: proxy.size)
        }
        // An explicit container background keeps the widget readable when the
        // desktop is not the active layer (otherwise the system paints its own
        // light placeholder background behind the card).
        .containerBackground(for: .widget) {
            entry.settings.color("common.background")
        }
        .widgetURL(clickURL)
    }
}

// MARK: - Widgets

struct StudioClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ClockWidget.definition.id,
                            provider: StudioProvider(kind: ClockWidget.definition.id)) { entry in
            StudioWidgetView(entry: entry)
        }
        .configurationDisplayName(ClockWidget.definition.name.value)
        .description(ClockWidget.definition.summary.value)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct StudioCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CalendarWidget.definition.id,
                            provider: StudioProvider(kind: CalendarWidget.definition.id)) { entry in
            StudioWidgetView(entry: entry)
        }
        .configurationDisplayName(CalendarWidget.definition.name.value)
        .description(CalendarWidget.definition.summary.value)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct StudioNoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NoteWidget.definition.id,
                            provider: StudioProvider(kind: NoteWidget.definition.id)) { entry in
            StudioWidgetView(entry: entry)
        }
        .configurationDisplayName(NoteWidget.definition.name.value)
        .description(NoteWidget.definition.summary.value)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Bundle

@main
struct WidgetStudioWidgets: WidgetBundle {
    var body: some Widget {
        StudioClockWidget()
        StudioCalendarWidget()
        StudioNoteWidget()
    }
}
