import SwiftUI

/// The clock widget: a faithful copy of the big iPhone clock widget that macOS
/// mirrors onto the desktop, with a full set of customization options.
enum ClockWidget {

    static let group = LText("Часы", "Clock")

    /// Height of the capital letters of SF Pro relative to the font size.
    /// Measured against the original iPhone widget so that the digits of the
    /// default preset land on exactly the same pixels.
    static let capHeightRatio: Double = 0.726

    // MARK: - Definition

    static let definition = WidgetDefinition(
        id: "clock",
        name: LText("Часы", "Clock"),
        summary: LText("Крупные цифровые часы — точная копия виджета с iPhone",
                       "Large digital clock — an exact copy of the iPhone widget"),
        symbol: "clock.fill",
        defaultSize: CGSize(width: 158, height: 158),
        settings: settings,
        presets: presets,
        content: { context in AnyView(ClockContentView(context: context)) }
    )

    // MARK: - Settings

    private static let settings: [SettingDescriptor] = [
        .picker("clock.layout", LText("Расположение", "Layout"), group: group,
                options: [
                    SettingOption("twoLines", LText("Две строки", "Two lines")),
                    SettingOption("oneLine", LText("Одна строка", "One line"))
                ],
                default: "twoLines"),

        .toggle("clock.use24h", LText("24-часовой формат", "24-hour format"), group: group, default: true),

        .toggle("clock.leadingZero", LText("Ведущий ноль", "Leading zero"), group: group,
                caption: LText("Показывать 09:05 вместо 9:05", "Show 09:05 instead of 9:05"), default: true),

        .toggle("clock.showMeridiem", LText("Показывать AM/PM", "Show AM/PM"), group: group, default: true,
                visibleIf: { !$0.bool("clock.use24h") }),

        .toggle("clock.showSeconds", LText("Показывать секунды", "Show seconds"), group: group, default: false),

        .toggle("clock.blinkSeparator", LText("Мигающее двоеточие", "Blinking colon"), group: group, default: true,
                visibleIf: { $0.string("clock.layout") == "oneLine" }),

        .toggle("clock.showDate", LText("Показывать дату", "Show date"), group: group, default: false),

        .picker("clock.dateFormat", LText("Формат даты", "Date format"), group: group,
                options: [
                    SettingOption("dayMonth", LText("17 октября", "17 October")),
                    SettingOption("dayMonthShort", LText("17 окт", "17 Oct")),
                    SettingOption("weekdayLong", LText("пятница, 17 октября", "Friday, 17 October")),
                    SettingOption("weekdayShort", LText("пт, 17 окт", "Fri, 17 Oct")),
                    SettingOption("numeric", LText("17.10.2025", "17.10.2025"))
                ],
                default: "dayMonth",
                visibleIf: { $0.bool("clock.showDate") }),

        .picker("clock.timeZone", LText("Часовой пояс", "Time zone"), group: group,
                options: timeZoneOptions, default: "local",
                caption: LText("Можно показывать время другого города", "Can show the time of another city"))
    ]

    private static let timeZoneOptions: [SettingOption] = [
        SettingOption("local", LText("Локальный", "Local")),
        SettingOption("UTC", .both("UTC")),
        SettingOption("Europe/Moscow", LText("Москва", "Moscow")),
        SettingOption("Europe/Kyiv", LText("Киев", "Kyiv")),
        SettingOption("Europe/Minsk", LText("Минск", "Minsk")),
        SettingOption("Asia/Tbilisi", LText("Тбилиси", "Tbilisi")),
        SettingOption("Asia/Yerevan", LText("Ереван", "Yerevan")),
        SettingOption("Asia/Almaty", LText("Алматы", "Almaty")),
        SettingOption("Asia/Dubai", LText("Дубай", "Dubai")),
        SettingOption("Europe/Istanbul", LText("Стамбул", "Istanbul")),
        SettingOption("Europe/Berlin", LText("Берлин", "Berlin")),
        SettingOption("Europe/London", LText("Лондон", "London")),
        SettingOption("Europe/Lisbon", LText("Лиссабон", "Lisbon")),
        SettingOption("America/New_York", LText("Нью-Йорк", "New York")),
        SettingOption("America/Los_Angeles", LText("Лос-Анджелес", "Los Angeles")),
        SettingOption("Asia/Tokyo", LText("Токио", "Tokyo")),
        SettingOption("Asia/Shanghai", LText("Пекин", "Beijing")),
        SettingOption("Asia/Seoul", LText("Сеул", "Seoul")),
        SettingOption("Asia/Bangkok", LText("Бангкок", "Bangkok")),
        SettingOption("Australia/Sydney", LText("Сидней", "Sydney"))
    ]

    // MARK: - Presets

    private static let presets: [WidgetPreset] = [
        // Pixel-calibrated against the original widget mirrored from the iPhone:
        // 8 pt ring, 26 pt radius, digits 79 pt, 3 pt gap between the rows.
        WidgetPreset(id: "iphone",
                     name: LText("Как на iPhone", "iPhone style"),
                     values: [
                        "common.cardStyle": .text("gradient"),
                        "common.background": .color(RGBA(hex: "#1B1D21")),
                        "common.background2": .color(RGBA(hex: "#101010")),
                        "common.gradientAngle": .number(270),
                        "common.cornerRadius": .number(26),
                        "common.borderWidth": .number(8),
                        "common.borderColor": .color(RGBA(hex: "#CECECF")),
                        "common.padding": .number(10),
                        "common.fontDesign": .text("default"),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(79),
                        "common.italic": .bool(true),
                        "common.slant": .number(0),
                        "common.tracking": .number(1),
                        "common.lineSpacing": .number(3),
                        "common.textColor": .color(RGBA(hex: "#CCCCCE")),
                        "common.opacity": .number(1),
                        "clock.layout": .text("twoLines")
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "minimal",
                     name: LText("Минимализм", "Minimal"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.borderWidth": .number(0),
                        "common.padding": .number(0),
                        "common.fontWeight": .text("heavy"),
                        "common.fontSize": .number(96),
                        "common.italic": .bool(true),
                        "common.tracking": .number(1),
                        "common.lineSpacing": .number(4),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.92))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "glass",
                     name: LText("Стекло", "Glass"),
                     values: [
                        "common.cardStyle": .text("glass"),
                        "common.background": .color(RGBA(1, 1, 1, 0.10)),
                        "common.cornerRadius": .number(38),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.35)),
                        "common.fontWeight": .text("bold"),
                        "common.fontSize": .number(74),
                        "common.italic": .bool(true),
                        "common.tracking": .number(2),
                        "common.lineSpacing": .number(4),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.95))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "neon",
                     name: LText("Неон", "Neon"),
                     values: [
                        "common.cardStyle": .text("gradient"),
                        "common.background": .color(RGBA(hex: "#05070F")),
                        "common.background2": .color(RGBA(hex: "#0B2340")),
                        "common.gradientAngle": .number(140),
                        "common.cornerRadius": .number(40),
                        "common.borderWidth": .number(4),
                        "common.borderColor": .color(RGBA(hex: "#35E6FF")),
                        "common.fontWeight": .text("heavy"),
                        "common.fontSize": .number(76),
                        "common.italic": .bool(true),
                        "common.slant": .number(3),
                        "common.tracking": .number(2),
                        "common.lineSpacing": .number(4),
                        "common.textColor": .color(RGBA(hex: "#7DF9FF"))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "giant",
                     name: LText("Гигантские", "Giant"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(0, 0, 0, 0.88)),
                        "common.cornerRadius": .number(56),
                        "common.borderWidth": .number(6),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.9)),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(150),
                        "common.italic": .bool(true),
                        "common.tracking": .number(2),
                        "common.lineSpacing": .number(8),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.94))
                     ],
                     size: CGSize(width: 340, height: 340)),

        WidgetPreset(id: "classic",
                     name: LText("Классика", "Classic"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(0.96, 0.96, 0.97, 1)),
                        "common.cornerRadius": .number(22),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(0, 0, 0, 0.12)),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(76),
                        "common.italic": .bool(false),
                        "common.tracking": .number(0),
                        "common.lineSpacing": .number(3),
                        "common.textColor": .color(RGBA(hex: "#111114"))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "terminal",
                     name: LText("Терминал", "Terminal"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#050805")),
                        "common.cornerRadius": .number(18),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(hex: "#2BE07A", alpha: 0.65)),
                        "common.fontDesign": .text("monospaced"),
                        "common.fontWeight": .text("bold"),
                        "common.fontSize": .number(64),
                        "common.italic": .bool(false),
                        "common.tracking": .number(-1),
                        "common.lineSpacing": .number(2),
                        "common.textColor": .color(RGBA(hex: "#2BE07A"))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "light",
                     name: LText("Светлая", "Light"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#F2F2F4")),
                        "common.cornerRadius": .number(26),
                        "common.borderWidth": .number(0),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(72),
                        "common.italic": .bool(true),
                        "common.lineSpacing": .number(0),
                        "common.textColor": .color(RGBA(hex: "#16171A"))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "midnight",
                     name: LText("Полночь", "Midnight"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(0, 0, 0, 1)),
                        "common.cornerRadius": .number(30),
                        "common.borderWidth": .number(1),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.18)),
                        "common.fontWeight": .text("heavy"),
                        "common.fontSize": .number(76),
                        "common.italic": .bool(false),
                        "common.tracking": .number(2),
                        "common.lineSpacing": .number(2),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.92))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "amber",
                     name: LText("Янтарь", "Amber"),
                     values: [
                        "common.cardStyle": .text("gradient"),
                        "common.background": .color(RGBA(hex: "#2A1704")),
                        "common.background2": .color(RGBA(hex: "#0B0602")),
                        "common.gradientAngle": .number(270),
                        "common.cornerRadius": .number(28),
                        "common.borderWidth": .number(3),
                        "common.borderColor": .color(RGBA(hex: "#FFB347", alpha: 0.75)),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(70),
                        "common.italic": .bool(true),
                        "common.lineSpacing": .number(1),
                        "common.textColor": .color(RGBA(hex: "#FFC773"))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "wide",
                     name: LText("Широкие", "Wide"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#0B0B0D", alpha: 0.94)),
                        "common.cornerRadius": .number(30),
                        "common.borderWidth": .number(6),
                        "common.borderColor": .color(RGBA(hex: "#CECECF")),
                        "common.fontWeight": .text("black"),
                        "common.fontSize": .number(92),
                        "common.italic": .bool(true),
                        "common.lineSpacing": .number(0),
                        "common.textColor": .color(RGBA(hex: "#CCCCCE"))
                     ],
                     size: CGSize(width: 338, height: 158))
    ]

    // MARK: - Time formatting

    struct Parts {
        var hour: String
        var minute: String
        var second: String
        var meridiem: String
    }

    static func parts(date: Date, timeZone: TimeZone, use24h: Bool, leadingZero: Bool) -> Parts {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour24 = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0

        var hour = hour24
        var meridiem = ""
        if !use24h {
            hour = hour24 % 12
            if hour == 0 { hour = 12 }
            meridiem = hour24 < 12
                ? L("ДП", "AM")
                : L("ПП", "PM")
        }

        func pad(_ value: Int) -> String {
            leadingZero ? String(format: "%02d", value) : String(value)
        }

        return Parts(hour: pad(hour),
                     minute: String(format: "%02d", minute),
                     second: String(format: "%02d", second),
                     meridiem: meridiem)
    }

    static func resolvedTimeZone(_ identifier: String) -> TimeZone {
        identifier == "local" ? .current : (TimeZone(identifier: identifier) ?? .current)
    }

    static func formattedDate(_ date: Date, format: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Localization.shared.language.locale
        switch format {
        case "dayMonthShort": formatter.dateFormat = L("d MMM", "d MMM")
        case "weekdayLong": formatter.dateFormat = L("EEEE, d MMMM", "EEEE, d MMMM")
        case "weekdayShort": formatter.dateFormat = L("EEE, d MMM", "EEE, d MMM")
        case "numeric": formatter.dateFormat = "dd.MM.yyyy"
        default: formatter.dateFormat = L("d MMMM", "d MMMM")
        }
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "")
    }
}

// MARK: - View

private struct ClockContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let timeZone = ClockWidget.resolvedTimeZone(settings.string("clock.timeZone"))
        let parts = ClockWidget.parts(date: context.date,
                                      timeZone: timeZone,
                                      use24h: settings.bool("clock.use24h"),
                                      leadingZero: settings.bool("clock.leadingZero"))
        let fontSize = fittedFontSize(settings)
        let oneLine = settings.string("clock.layout") == "oneLine"

        return Group {
            if oneLine {
                oneLineLayout(settings: settings, parts: parts, fontSize: fontSize, timeZone: timeZone)
            } else {
                twoLinesLayout(settings: settings, parts: parts, fontSize: fontSize, timeZone: timeZone)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Shrinks the digits just enough for the extra lines (seconds, date) to fit
    /// inside the card, so nothing is ever clipped by the rounded corners.
    private func fittedFontSize(_ settings: SettingsBag) -> Double {
        let requested = settings.double("common.fontSize")
        let gap = settings.double("common.lineSpacing")
        let available = max(context.size.height - 2 * settings.double("common.padding"), 24)
        let oneLine = settings.string("clock.layout") == "oneLine"

        var needed = oneLine
            ? requested * 1.25
            : 2 * requested * ClockWidget.capHeightRatio + gap

        if settings.bool("clock.showSeconds") && !oneLine {
            needed += requested * 0.42 * ClockWidget.capHeightRatio + gap
        }
        if settings.bool("clock.showDate") {
            needed += requested * 0.25 + gap
        }

        guard needed > available else { return requested }
        return requested * (available / needed)
    }

    // MARK: Layouts

    @ViewBuilder
    private func twoLinesLayout(settings: SettingsBag,
                                parts: ClockWidget.Parts,
                                fontSize: Double,
                                timeZone: TimeZone) -> some View {
        VStack(spacing: settings.double("common.lineSpacing")) {
            HStack(alignment: .top, spacing: fontSize * 0.06) {
                capLine(parts.hour, size: fontSize, settings: settings)
                if !parts.meridiem.isEmpty && settings.bool("clock.showMeridiem") {
                    StyledText(text: parts.meridiem,
                               size: fontSize * 0.26,
                               opacity: 0.75,
                               settings: settings)
                        .frame(height: fontSize * ClockWidget.capHeightRatio, alignment: .top)
                        .padding(.top, fontSize * 0.02)
                }
            }

            capLine(parts.minute, size: fontSize, settings: settings)

            if settings.bool("clock.showSeconds") {
                capLine(parts.second,
                        size: fontSize * 0.42,
                        opacity: settings.double("common.secondaryOpacity"),
                        settings: settings)
            }

            if settings.bool("clock.showDate") {
                dateLine(settings: settings, fontSize: fontSize, timeZone: timeZone)
            }
        }
    }

    /// One line of digits inside a box exactly as tall as the capital letters,
    /// so `lineSpacing` is the real visual gap between the lines.
    @ViewBuilder
    private func capLine(_ text: String, size: Double, opacity: Double = 1, settings: SettingsBag) -> some View {
        StyledText(text: text, size: size, opacity: opacity, settings: settings)
            .frame(height: size * ClockWidget.capHeightRatio)
    }

    @ViewBuilder
    private func oneLineLayout(settings: SettingsBag,
                               parts: ClockWidget.Parts,
                               fontSize: Double,
                               timeZone: TimeZone) -> some View {
        let blink = settings.bool("clock.blinkSeparator") && blinkingOff(context.date)

        VStack(spacing: settings.double("common.lineSpacing")) {
            HStack(spacing: fontSize * 0.02) {
                StyledText(text: parts.hour, size: fontSize, settings: settings, fixed: false)
                StyledText(text: ":", size: fontSize, settings: settings, fixed: false)
                    .opacity(blink ? 0.25 : 1)
                StyledText(text: parts.minute, size: fontSize, settings: settings, fixed: false)
                if settings.bool("clock.showSeconds") {
                    StyledText(text: parts.second,
                               size: fontSize * 0.42,
                               opacity: settings.double("common.secondaryOpacity"),
                               settings: settings,
                               fixed: false)
                        .padding(.leading, fontSize * 0.06)
                }
                if !parts.meridiem.isEmpty && settings.bool("clock.showMeridiem") {
                    StyledText(text: parts.meridiem,
                               size: fontSize * 0.26,
                               opacity: 0.75,
                               settings: settings,
                               fixed: false)
                        .padding(.leading, fontSize * 0.04)
                }
            }

            if settings.bool("clock.showDate") {
                dateLine(settings: settings, fontSize: fontSize, timeZone: timeZone)
            }
        }
    }

    @ViewBuilder
    private func dateLine(settings: SettingsBag, fontSize: Double, timeZone: TimeZone) -> some View {
        Text(ClockWidget.formattedDate(context.date,
                                       format: settings.string("clock.dateFormat"),
                                       timeZone: timeZone))
            .font(.system(size: max(fontSize * 0.2, 8),
                          weight: .semibold,
                          design: WidgetStyle.design(settings.string("common.fontDesign"))))
            .foregroundStyle(settings.color("common.textColor")
                .opacity(settings.double("common.secondaryOpacity")))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func blinkingOff(_ date: Date) -> Bool {
        Calendar.current.component(.second, from: date) % 2 == 1
    }
}

/// A single piece of text styled with the shared typography settings.
struct StyledText: View {
    let text: String
    var size: Double
    var opacity: Double = 1
    let settings: SettingsBag
    /// When `true` the text keeps its exact glyph metrics and never shrinks —
    /// used for the big digits so that the letter spacing stays predictable.
    var fixed: Bool = true

    var body: some View {
        Text(text)
            .font(.system(size: size,
                          weight: WidgetStyle.weight(settings.string("common.fontWeight")),
                          design: WidgetStyle.design(settings.string("common.fontDesign"))))
            .italic(settings.bool("common.italic"))
            .tracking(settings.double("common.tracking"))
            .foregroundStyle(settings.color("common.textColor").opacity(opacity))
            .lineLimit(1)
            .minimumScaleFactor(0.25)
            .fixedSize(horizontal: fixed, vertical: fixed)
            .transformEffect(WidgetStyle.shear(degrees: settings.double("common.slant"),
                                               height: size * 1.2))
    }
}
