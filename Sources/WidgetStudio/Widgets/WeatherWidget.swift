import SwiftUI

/// The weather widget: current conditions for a chosen city (Open-Meteo, no key).
enum WeatherWidget {

    static let group = LText("Погода", "Weather")

    static let definition = WidgetDefinition(
        id: "weather",
        name: LText("Погода", "Weather"),
        summary: LText("Текущая погода в выбранном городе", "Current conditions in a chosen city"),
        symbol: "cloud.sun.fill",
        defaultSize: CGSize(width: 338, height: 158),
        settings: settings,
        presets: presets,
        content: { context in AnyView(WeatherContentView(context: context)) },
        overrides: [
            "common.fontSize": .number(56),
            "common.fontWeight": .text("semibold"),
            "common.italic": .bool(false),
            "common.tracking": .number(0),
            "common.cornerRadius": .number(26),
            "common.background": .color(RGBA(hex: "#12325E", alpha: 1)),
            "common.background2": .color(RGBA(hex: "#0B1B33", alpha: 1)),
            "common.gradientAngle": .number(300),
            "common.cardStyle": .text("gradient"),
            "common.borderWidth": .number(0),
            "common.textColor": .color(RGBA(1, 1, 1, 0.96)),
            "common.secondaryOpacity": .number(0.75)
        ]
    )

    private static let settings: [SettingDescriptor] = [
        .picker("weather.city", LText("Город", "City"), group: group,
                options: WeatherCity.all.map { SettingOption($0.id, $0.name) },
                default: "moscow"),

        .picker("weather.units", LText("Температура", "Temperature"), group: group,
                options: [
                    SettingOption("c", LText("Цельсий", "Celsius")),
                    SettingOption("f", LText("Фаренгейт", "Fahrenheit"))
                ],
                default: "c"),

        .toggle("weather.showCity", LText("Название города", "City name"), group: group, default: true),

        .toggle("weather.showCondition", LText("Описание погоды", "Conditions"), group: group, default: true),

        .toggle("weather.showDetails", LText("Ощущается и ветер", "Feels like and wind"),
                group: group, default: true),

        .toggle("weather.showUpdated", LText("Время обновления", "Updated at"), group: group, default: false)
    ]

    private static let presets: [WidgetPreset] = [
        WidgetPreset(id: "blue",
                     name: LText("Небо", "Sky"),
                     values: skyLook,
                     size: CGSize(width: 338, height: 158)),

        WidgetPreset(id: "dark",
                     name: LText("Тёмная", "Dark"),
                     values: skyLook.merging([
                        "common.background": .color(RGBA(hex: "#1B1D21")),
                        "common.background2": .color(RGBA(hex: "#101010")),
                        "common.borderWidth": .number(8),
                        "common.borderColor": .color(RGBA(hex: "#CECECF")),
                        "common.textColor": .color(RGBA(hex: "#CCCCCE"))
                     ]) { _, new in new },
                     size: CGSize(width: 338, height: 158)),

        WidgetPreset(id: "sunset",
                     name: LText("Закат", "Sunset"),
                     values: skyLook.merging([
                        "common.background": .color(RGBA(hex: "#B84A2A")),
                        "common.background2": .color(RGBA(hex: "#3A1030")),
                        "common.gradientAngle": .number(320)
                     ]) { _, new in new },
                     size: CGSize(width: 338, height: 158)),

        WidgetPreset(id: "paper",
                     name: LText("Бумага", "Paper"),
                     values: skyLook.merging([
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#F7F4EE")),
                        "common.textColor": .color(RGBA(hex: "#1B1A17")),
                        "common.secondaryOpacity": .number(0.55),
                        "common.borderWidth": .number(0)
                     ]) { _, new in new },
                     size: CGSize(width: 338, height: 158)),

        WidgetPreset(id: "glass",
                     name: LText("Стекло", "Glass"),
                     values: skyLook.merging([
                        "common.cardStyle": .text("glass"),
                        "common.background": .color(RGBA(1, 1, 1, 0.12)),
                        "common.borderWidth": .number(1),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.34)),
                        "common.cornerRadius": .number(38)
                     ]) { _, new in new },
                     size: CGSize(width: 338, height: 158))
    ]

    private static var skyLook: [String: SettingValue] {
        [
            "common.cardStyle": .text("gradient"),
            "common.background": .color(RGBA(hex: "#12325E")),
            "common.background2": .color(RGBA(hex: "#0B1B33")),
            "common.gradientAngle": .number(300),
            "common.cornerRadius": .number(26),
            "common.borderWidth": .number(0),
            "common.padding": .number(12),
            "common.fontWeight": .text("semibold"),
            "common.fontSize": .number(56),
            "common.italic": .bool(false),
            "common.textColor": .color(RGBA(1, 1, 1, 0.96)),
            "common.secondaryOpacity": .number(0.75),
            "weather.showCity": .bool(true),
            "weather.showCondition": .bool(true),
            "weather.showDetails": .bool(true),
            "weather.showUpdated": .bool(false)
        ]
    }

    static func snapshot(_ settings: SettingsBag) -> WeatherSnapshot? {
        WeatherService.cached(cityID: settings.string("weather.city"))
    }
}

// MARK: - View

private struct WeatherContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let city = WeatherCity.city(settings.string("weather.city"))
        let snapshot = WeatherWidget.snapshot(settings)
        let unit = settings.string("weather.units")
        let fontSize = settings.double("common.fontSize")
        let textColor = settings.color("common.textColor")
        let secondary = settings.double("common.secondaryOpacity")
        let compact = context.size.width < 220

        let condition = WeatherService.description(code: snapshot?.code ?? -1)
        let degrees = snapshot.map { Int($0.temperature(unit: unit).rounded()) }

        VStack(alignment: .leading, spacing: compact ? 2 : 6) {
            if settings.bool("weather.showCity") {
                Text(city.name.value)
                    .font(.system(size: max(fontSize * 0.22, 10), weight: .semibold))
                    .foregroundStyle(textColor.opacity(secondary))
                    .lineLimit(1)
            }

            HStack(alignment: .center, spacing: compact ? 6 : 12) {
                Text(degrees.map { "\($0)°" } ?? "—")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Image(systemName: snapshot == nil ? "cloud.fill" : condition.symbol)
                    .font(.system(size: fontSize * 0.55))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(textColor.opacity(0.9))
            }

            if settings.bool("weather.showCondition") && !compact {
                Text(snapshot == nil ? L("Нет данных", "No data") : condition.text.value)
                    .font(.system(size: max(fontSize * 0.2, 10), weight: .medium))
                    .foregroundStyle(textColor.opacity(secondary))
                    .lineLimit(1)
            }

            if settings.bool("weather.showDetails"), let snapshot {
                HStack(spacing: 10) {
                    Text(L("Ощущается \(Int(snapshot.apparent(unit: unit).rounded()))°",
                           "Feels \(Int(snapshot.apparent(unit: unit).rounded()))°"))
                    Text(L("Ветер \(String(format: "%.0f", snapshot.windSpeed)) м/с",
                           "Wind \(String(format: "%.0f", snapshot.windSpeed)) m/s"))
                }
                .font(.system(size: max(fontSize * 0.17, 9), weight: .medium))
                .foregroundStyle(textColor.opacity(secondary * 0.9))
                .lineLimit(1)
            }

            if settings.bool("weather.showUpdated"), let snapshot {
                Text(snapshot.updated.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: max(fontSize * 0.15, 8), weight: .regular))
                    .foregroundStyle(textColor.opacity(secondary * 0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}
