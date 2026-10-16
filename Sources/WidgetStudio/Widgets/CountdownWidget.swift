import SwiftUI

/// The countdown widget: how many days are left until a date you care about.
enum CountdownWidget {

    static let group = LText("Отсчёт", "Countdown")

    static let definition = WidgetDefinition(
        id: "countdown",
        name: LText("Отсчёт", "Countdown"),
        summary: LText("Сколько дней осталось до важной даты", "How many days are left until a date"),
        symbol: "calendar.badge.clock",
        defaultSize: CGSize(width: 158, height: 158),
        settings: settings,
        presets: presets,
        content: { context in AnyView(CountdownContentView(context: context)) },
        overrides: [
            "common.fontSize": .number(64),
            "common.lineSpacing": .number(2),
            "common.cornerRadius": .number(26)
        ]
    )

    private static let settings: [SettingDescriptor] = [
        .text("countdown.title", LText("Подпись", "Caption"), group: group,
              default: L("До отпуска", "Until the holiday")),

        .date("countdown.date", LText("Дата", "Date"), group: group, default: 30),

        .picker("countdown.style", LText("Что показывать", "What to show"), group: group,
                options: [
                    SettingOption("days", LText("Только дни", "Days only")),
                    SettingOption("detailed", LText("Дни, часы и минуты", "Days, hours and minutes"))
                ],
                default: "days"),

        .text("countdown.suffix", LText("Подпись под числом", "Caption under the number"), group: group,
              default: L("дней", "days")),

        .toggle("countdown.hideSuffix", LText("Скрыть подпись под числом", "Hide the caption under the number"),
                group: group, default: false),

        .toggle("countdown.countUp", LText("Считать вперёд после наступления", "Count up once the date has passed"),
                group: group, default: false)
    ]

    private static let presets: [WidgetPreset] = [
        WidgetPreset(id: "default",
                     name: LText("Как на iPhone", "iPhone style"),
                     values: defaultLook,
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "big",
                     name: LText("Гигантские цифры", "Big numbers"),
                     values: defaultLook.merging([
                        "common.fontSize": .number(112),
                        "common.lineSpacing": .number(0),
                        "countdown.hideSuffix": .bool(true)
                     ]) { _, new in new },
                     size: CGSize(width: 344, height: 344)),

        WidgetPreset(id: "paper",
                     name: LText("Бумага", "Paper"),
                     values: defaultLook.merging([
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#F7F4EE")),
                        "common.textColor": .color(RGBA(hex: "#1B1A17")),
                        "common.borderWidth": .number(0),
                        "common.secondaryOpacity": .number(0.55)
                     ]) { _, new in new },
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "glass",
                     name: LText("Стекло", "Glass"),
                     values: defaultLook.merging([
                        "common.cardStyle": .text("glass"),
                        "common.background": .color(RGBA(1, 1, 1, 0.10)),
                        "common.cornerRadius": .number(38),
                        "common.borderWidth": .number(1),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.32))
                     ]) { _, new in new },
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "accent",
                     name: LText("Акцент", "Accent"),
                     values: defaultLook.merging([
                        "common.cardStyle": .text("gradient"),
                        "common.background": .color(RGBA(hex: "#3B1E7A")),
                        "common.background2": .color(RGBA(hex: "#12081F")),
                        "common.gradientAngle": .number(300),
                        "common.borderWidth": .number(0),
                        "common.textColor": .color(RGBA(hex: "#F2E9FF")),
                        "common.cornerRadius": .number(30)
                     ]) { _, new in new },
                     size: CGSize(width: 158, height: 158))
    ]

    private static var defaultLook: [String: SettingValue] {
        [
            "common.cardStyle": .text("gradient"),
            "common.background": .color(RGBA(hex: "#1B1D21")),
            "common.background2": .color(RGBA(hex: "#101010")),
            "common.gradientAngle": .number(270),
            "common.cornerRadius": .number(26),
            "common.borderWidth": .number(8),
            "common.borderColor": .color(RGBA(hex: "#CECECF")),
            "common.padding": .number(10),
            "common.fontWeight": .text("black"),
            "common.fontSize": .number(64),
            "common.italic": .bool(true),
            "common.tracking": .number(1),
            "common.lineSpacing": .number(2),
            "common.textColor": .color(RGBA(hex: "#CCCCCE")),
            "countdown.style": .text("days"),
            "countdown.hideSuffix": .bool(false),
            "countdown.countUp": .bool(false)
        ]
    }

    // MARK: - Model

    struct Remaining {
        var days: Int
        var hours: Int
        var minutes: Int
        var isPast: Bool
    }

    static func targetDate(_ settings: SettingsBag) -> Date {
        let raw = settings.string("countdown.date")
        return ISO8601DateFormatter().date(from: raw)
            ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())
            ?? Date()
    }

    static func remaining(_ settings: SettingsBag, from now: Date) -> Remaining {
        let target = targetDate(settings)
        let past = target < now
        let interval = abs(target.timeIntervalSince(now))
        let total = Int(interval)
        return Remaining(days: total / 86_400,
                         hours: (total % 86_400) / 3600,
                         minutes: (total % 3600) / 60,
                         isPast: past)
    }
}

// MARK: - View

private struct CountdownContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let remaining = CountdownWidget.remaining(settings, from: context.date)
        let countUp = settings.bool("countdown.countUp")
        let number = remaining.isPast && !countUp ? 0 : remaining.days
        let fontSize = settings.double("common.fontSize")


        VStack(spacing: settings.double("common.lineSpacing")) {
            StyledText(text: "\(number)", size: fontSize, settings: settings)

            if !settings.bool("countdown.hideSuffix") {
                Text(settings.string("countdown.suffix"))
                    .font(.system(size: max(fontSize * 0.22, 9), weight: .semibold))
                    .foregroundStyle(settings.color("common.textColor")
                        .opacity(settings.double("common.secondaryOpacity")))
                    .lineLimit(1)
            }

            if settings.string("countdown.style") == "detailed" {
                Text(String(format: "%02d:%02d", remaining.hours, remaining.minutes))
                    .font(.system(size: max(fontSize * 0.2, 10),
                                  weight: .medium,
                                  design: .monospaced))
                    .foregroundStyle(settings.color("common.textColor")
                        .opacity(settings.double("common.secondaryOpacity")))
                    .lineLimit(1)
            }

            if !settings.string("countdown.title").isEmpty {
                Text(settings.string("countdown.title"))
                    .font(.system(size: max(fontSize * 0.2, 9), weight: .medium))
                    .foregroundStyle(settings.color("common.textColor")
                        .opacity(settings.double("common.secondaryOpacity") * 0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
