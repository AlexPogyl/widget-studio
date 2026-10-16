import SwiftUI

/// A month calendar widget, styled like the iPhone calendar widget.
enum CalendarWidget {

    static let group = LText("Календарь", "Calendar")

    static let definition = WidgetDefinition(
        id: "calendar",
        name: LText("Календарь", "Calendar"),
        summary: LText("Месяц на одном экране: сетка дней, выделение сегодняшнего числа",
                       "A whole month at a glance: day grid with today highlighted"),
        symbol: "calendar",
        defaultSize: CGSize(width: 158, height: 158),
        settings: settings,
        presets: presets,
        content: { context in AnyView(CalendarContentView(context: context)) },
        overrides: [
            "common.fontSize": .number(13),
            "common.fontWeight": .text("semibold"),
            "common.tracking": .number(0),
            "common.lineSpacing": .number(4),
            "common.cornerRadius": .number(30),
            "common.cardStyle": .text("gradient"),
            "common.background": .color(RGBA(hex: "#1E1E24")),
            "common.background2": .color(RGBA(hex: "#111112")),
            "common.gradientAngle": .number(270),
            "common.borderWidth": .number(1),
            "common.borderColor": .color(RGBA(hex: "#797A7B")),
            "common.textColor": .color(RGBA(hex: "#B6B6B8")),
            "calendar.accentColor": .color(RGBA(hex: "#EDEDEF")),
            "calendar.accentTextColor": .color(RGBA(hex: "#141417"))
        ]
    )

    // MARK: - Settings

    private static let settings: [SettingDescriptor] = [
        .toggle("calendar.showTitle", LText("Название месяца", "Month title"), group: group, default: true),

        .toggle("calendar.showYear", LText("Год в заголовке", "Year in the title"), group: group, default: false,
                visibleIf: { $0.bool("calendar.showTitle") }),

        .toggle("calendar.showWeekdays", LText("Дни недели", "Weekday header"), group: group, default: true),

        .toggle("calendar.weekStartsMonday", LText("Неделя с понедельника", "Week starts on Monday"),
                group: group, default: true),

        .toggle("calendar.showAdjacentDays", LText("Дни соседних месяцев", "Adjacent month days"),
                group: group,
                caption: LText("Показывать приглушённые числа до и после месяца",
                              "Show faded day numbers around the month"),
                default: false),

        .toggle("calendar.highlightToday", LText("Выделять сегодня", "Highlight today"), group: group, default: true),

        .picker("calendar.todayStyle", LText("Стиль выделения", "Highlight style"), group: group,
                options: [
                    SettingOption("filled", LText("Заливка", "Filled")),
                    SettingOption("outline", LText("Обводка", "Outline"))
                ],
                default: "filled",
                visibleIf: { $0.bool("calendar.highlightToday") }),

        .color("calendar.accentColor", LText("Цвет акцента", "Accent colour"), group: group,
               default: RGBA(1, 1, 1, 0.95),
               visibleIf: { $0.bool("calendar.highlightToday") }),

        .color("calendar.accentTextColor", LText("Цвет числа в выделении", "Highlighted number colour"),
               group: group, default: RGBA(0.04, 0.04, 0.05, 1),
               visibleIf: { $0.bool("calendar.highlightToday") }),

        .toggle("calendar.tintWeekends", LText("Подсвечивать выходные", "Tint weekends"), group: group,
                default: true)
    ]

    // MARK: - Presets

    private static let presets: [WidgetPreset] = [
        WidgetPreset(id: "dark",
                     name: LText("Тёмная", "Dark"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#0B0B0D", alpha: 0.92)),
                        "common.borderWidth": .number(3),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.9)),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.92)),
                        "common.cornerRadius": .number(30)
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "paper",
                     name: LText("Бумага", "Paper"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(0.98, 0.97, 0.95, 1)),
                        "common.borderWidth": .number(1),
                        "common.borderColor": .color(RGBA(0, 0, 0, 0.12)),
                        "common.textColor": .color(RGBA(hex: "#1A1A1C")),
                        "calendar.accentColor": .color(RGBA(hex: "#E5484D")),
                        "calendar.accentTextColor": .color(RGBA(1, 1, 1, 1)),
                        "common.cornerRadius": .number(24)
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "wide",
                     name: LText("Широкая", "Wide"),
                     values: [
                        "common.cardStyle": .text("glass"),
                        "common.background": .color(RGBA(1, 1, 1, 0.10)),
                        "common.borderWidth": .number(1),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.32)),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.95)),
                        "common.fontSize": .number(17),
                        "common.cornerRadius": .number(34)
                     ],
                     size: CGSize(width: 338, height: 158)),

        WidgetPreset(id: "minimal",
                     name: LText("Только числа", "Numbers only"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.borderWidth": .number(0),
                        "common.padding": .number(0),
                        "common.fontSize": .number(15),
                        "common.fontWeight": .text("medium"),
                        "common.cornerRadius": .number(26),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.92)),
                        "calendar.showTitle": .bool(false),
                        "calendar.showWeekdays": .bool(false),
                        "calendar.highlightToday": .bool(true),
                        "calendar.accentColor": .color(RGBA(hex: "#0A84FF")),
                        "calendar.accentTextColor": .color(RGBA(1, 1, 1, 1))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "accent",
                     name: LText("Акцент", "Accent"),
                     values: [
                        "common.cardStyle": .text("gradient"),
                        "common.background": .color(RGBA(hex: "#1B1D21")),
                        "common.background2": .color(RGBA(hex: "#101010")),
                        "common.gradientAngle": .number(270),
                        "common.borderWidth": .number(8),
                        "common.borderColor": .color(RGBA(hex: "#CECECF")),
                        "common.cornerRadius": .number(26),
                        "common.textColor": .color(RGBA(hex: "#E8E8EA")),
                        "calendar.accentColor": .color(RGBA(hex: "#0A84FF")),
                        "calendar.accentTextColor": .color(RGBA(1, 1, 1, 1)),
                        "calendar.tintWeekends": .bool(true)
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "outline",
                     name: LText("Контур", "Outline"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(1, 1, 1, 0.5)),
                        "common.cornerRadius": .number(30),
                        "common.padding": .number(10),
                        "common.fontWeight": .text("regular"),
                        "common.fontSize": .number(14),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.9)),
                        "calendar.showTitle": .bool(true),
                        "calendar.highlightToday": .bool(true),
                        "calendar.todayStyle": .text("outline"),
                        "calendar.accentColor": .color(RGBA(1, 1, 1, 0.95))
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "warm",
                     name: LText("Тёплая", "Warm"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#FBF7F0")),
                        "common.borderWidth": .number(0),
                        "common.cornerRadius": .number(26),
                        "common.textColor": .color(RGBA(hex: "#2B2723")),
                        "common.secondaryOpacity": .number(0.6),
                        "calendar.accentColor": .color(RGBA(hex: "#E4572E")),
                        "calendar.accentTextColor": .color(RGBA(1, 1, 1, 1))
                     ],
                     size: CGSize(width: 158, height: 158))
    ]

    // MARK: - Month model

    struct Day: Identifiable {
        let id: Int
        let number: Int
        let isCurrentMonth: Bool
        let isToday: Bool
        let isWeekend: Bool
    }

    struct Month {
        var title: String
        var weekdaySymbols: [String]
        var days: [Day]
    }

    static func month(for date: Date, settings: SettingsBag, language: AppLanguage) -> Month {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = language.locale
        calendar.firstWeekday = settings.bool("calendar.weekStartsMonday") ? 2 : 1

        let today = Date()
        let titleFormatter = DateFormatter()
        titleFormatter.calendar = calendar
        titleFormatter.locale = language.locale
        titleFormatter.dateFormat = settings.bool("calendar.showYear") ? "LLLL yyyy" : "LLLL"

        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        let ordered = (0..<7).map { symbols[(firstWeekdayIndex + $0) % 7] }
        let weekdaySymbols = ordered.map { String($0.prefix(1)).uppercased() }

        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let dayRange = calendar.range(of: .day, in: .month, for: date) else {
            return Month(title: "", weekdaySymbols: weekdaySymbols, days: [])
        }

        let firstDay = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var days: [Day] = []
        for offset in 0..<dayRange.count {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: firstDay) else { continue }
            let weekday = calendar.component(.weekday, from: dayDate)
            days.append(Day(id: offset,
                            number: calendar.component(.day, from: dayDate),
                            isCurrentMonth: true,
                            isToday: calendar.isDate(dayDate, inSameDayAs: today),
                            isWeekend: weekday == 1 || weekday == 7))
        }

        // Leading days of the previous month.
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDay),
           let previousRange = calendar.range(of: .day, in: .month, for: previousMonth) {
            var leading: [Day] = []
            for index in 0..<leadingBlanks {
                let number = previousRange.count - leadingBlanks + index + 1
                leading.append(Day(id: -leadingBlanks + index,
                                   number: number,
                                   isCurrentMonth: false,
                                   isToday: false,
                                   isWeekend: false))
            }
            days = leading + days
        }

        // Trailing days of the next month, so the grid is always complete.
        let totalCells = Int(ceil(Double(days.count) / 7.0)) * 7
        var trailing: [Day] = []
        var number = 1
        while days.count + trailing.count < totalCells {
            let index = trailing.count
            let weekday = ((weekdayOfFirst - 1 + days.count + index) % 7) + 1
            trailing.append(Day(id: 1000 + index,
                                number: number,
                                isCurrentMonth: false,
                                isToday: false,
                                isWeekend: weekday == 1 || weekday == 7))
            number += 1
        }
        days += trailing

        return Month(title: titleFormatter.string(from: date).uppercased(),
                     weekdaySymbols: weekdaySymbols,
                     days: days)
    }
}

// MARK: - View

private struct CalendarContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let month = CalendarWidget.month(for: context.date,
                                         settings: settings,
                                         language: Localization.shared.language)
        let fontSize = settings.double("common.fontSize")
        let textColor = settings.color("common.textColor")
        let secondary = settings.double("common.secondaryOpacity")
        let rows = stride(from: 0, to: month.days.count, by: 7).map { Array(month.days[$0..<min($0 + 7, month.days.count)]) }

        return VStack(spacing: fontSize * 0.35) {
            if settings.bool("calendar.showTitle") {
                Text(month.title)
                    .font(.system(size: fontSize * 0.74,
                                  weight: WidgetStyle.weight(settings.string("common.fontWeight")),
                                  design: WidgetStyle.design(settings.string("common.fontDesign"))))
                    .tracking(settings.double("common.tracking"))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if settings.bool("calendar.showWeekdays") {
                HStack(spacing: 0) {
                    ForEach(Array(month.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: fontSize * 0.6, weight: .semibold))
                            .foregroundStyle(textColor.opacity(secondary * 0.85))
                            .frame(maxWidth: .infinity)
                            .opacity(settings.bool("calendar.tintWeekends")
                                     && (index == 5 || index == 6) ? 0.6 : 1)
                    }
                }
            }

            VStack(spacing: fontSize * 0.18) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(row) { day in
                            dayView(day, settings: settings, fontSize: fontSize, textColor: textColor)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func dayView(_ day: CalendarWidget.Day,
                         settings: SettingsBag,
                         fontSize: Double,
                         textColor: Color) -> some View {
        let secondary = settings.double("common.secondaryOpacity")
        let highlight = settings.bool("calendar.highlightToday") && day.isToday
        let accent = settings.color("calendar.accentColor")
        let accentText = settings.color("calendar.accentTextColor")
        let weekdayTint = settings.bool("calendar.tintWeekends") && day.isWeekend

        Text("\(day.number)")
            .font(.system(size: fontSize * 0.82,
                          weight: highlight ? .bold : WidgetStyle.weight(settings.string("common.fontWeight"))))
            .monospacedDigit()
            .foregroundStyle(highlight ? accentText
                                       : textColor.opacity(weekdayTint ? secondary * 0.78 : 1))
            .frame(width: fontSize * 1.5, height: fontSize * 1.5)
            .background {
                if highlight {
                    if settings.string("calendar.todayStyle") == "outline" {
                        Circle().strokeBorder(accent, lineWidth: max(fontSize * 0.12, 1))
                    } else {
                        Circle().fill(accent)
                    }
                }
            }
            .opacity(dayOpacity(day, settings: settings))
    }

    /// Days outside the current month are either hidden or faded.
    private func dayOpacity(_ day: CalendarWidget.Day, settings: SettingsBag) -> Double {
        if day.isCurrentMonth { return 1 }
        return settings.bool("calendar.showAdjacentDays") ? 0.32 : 0
    }
}
