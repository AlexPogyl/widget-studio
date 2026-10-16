import SwiftUI

/// A very small widget that shows a custom text — handy for reminders, a motto
/// or a label on the desktop, and a compact example of adding a new widget.
enum NoteWidget {

    static let group = LText("Текст", "Text")

    static let definition = WidgetDefinition(
        id: "note",
        name: LText("Заметка", "Note"),
        summary: LText("Произвольный текст на рабочем столе", "Any text you want on the desktop"),
        symbol: "text.alignleft",
        defaultSize: CGSize(width: 240, height: 120),
        settings: settings,
        presets: presets,
        content: { context in AnyView(NoteContentView(context: context)) },
        overrides: [
            "common.fontSize": .number(18),
            "common.fontWeight": .text("medium"),
            "common.italic": .bool(false),
            "common.tracking": .number(0),
            "common.lineSpacing": .number(4),
            "common.cornerRadius": .number(24),
            "common.borderWidth": .number(1),
            "common.borderColor": .color(RGBA(1, 1, 1, 0.22)),
            "common.background": .color(RGBA(hex: "#111114", alpha: 0.82))
        ]
    )

    private static let settings: [SettingDescriptor] = [
        .text("note.text", LText("Текст", "Text"), group: group,
              default: L("Ваша заметка", "Your note"),
              multiline: true,
              caption: LText("Поддерживаются переносы строк", "Line breaks are supported")),

        .picker("note.alignment", LText("Выравнивание", "Alignment"), group: group,
                options: [
                    SettingOption("leading", LText("По левому краю", "Leading")),
                    SettingOption("center", LText("По центру", "Center")),
                    SettingOption("trailing", LText("По правому краю", "Trailing"))
                ],
                default: "center"),

        .toggle("note.uppercase", LText("ЗАГЛАВНЫМИ", "UPPERCASE"), group: group, default: false)
    ]

    private static let presets: [WidgetPreset] = [
        WidgetPreset(id: "sticky",
                     name: LText("Стикер", "Sticky"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#F7D774", alpha: 0.96)),
                        "common.textColor": .color(RGBA(hex: "#2A2412")),
                        "common.borderWidth": .number(0),
                        "common.cornerRadius": .number(16)
                     ],
                     size: CGSize(width: 240, height: 140)),

        WidgetPreset(id: "caption",
                     name: LText("Подпись", "Caption"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.borderWidth": .number(0),
                        "common.padding": .number(0),
                        "common.fontSize": .number(22),
                        "common.fontWeight": .text("semibold"),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.9))
                     ],
                     size: CGSize(width: 320, height: 60)),

        WidgetPreset(id: "terminal",
                     name: LText("Терминал", "Terminal"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#050805")),
                        "common.cornerRadius": .number(18),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(hex: "#2BE07A", alpha: 0.6)),
                        "common.fontDesign": .text("monospaced"),
                        "common.fontSize": .number(16),
                        "common.textColor": .color(RGBA(hex: "#2BE07A")),
                        "note.alignment": .text("leading")
                     ],
                     size: CGSize(width: 320, height: 140)),

        WidgetPreset(id: "headline",
                     name: LText("Заголовок", "Headline"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.borderWidth": .number(0),
                        "common.padding": .number(0),
                        "common.fontWeight": .text("bold"),
                        "common.fontSize": .number(34),
                        "common.textColor": .color(RGBA(1, 1, 1, 0.94)),
                        "note.uppercase": .bool(true)
                     ],
                     size: CGSize(width: 420, height: 90)),

        WidgetPreset(id: "quote",
                     name: LText("Цитата", "Quote"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#141416", alpha: 0.86)),
                        "common.cornerRadius": .number(22),
                        "common.borderWidth": .number(0),
                        "common.fontDesign": .text("serif"),
                        "common.italic": .bool(true),
                        "common.fontSize": .number(17),
                        "common.textColor": .color(RGBA(hex: "#E9E6DF")),
                        "note.alignment": .text("center")
                     ],
                     size: CGSize(width: 320, height: 160))
    ]
}

private struct NoteContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let raw = settings.string("note.text")
        let text = settings.bool("note.uppercase") ? raw.uppercased() : raw

        return Text(text.isEmpty ? L("Пустая заметка", "Empty note") : text)
            .font(.system(size: settings.double("common.fontSize"),
                          weight: WidgetStyle.weight(settings.string("common.fontWeight")),
                          design: WidgetStyle.design(settings.string("common.fontDesign"))))
            .italic(settings.bool("common.italic"))
            .tracking(settings.double("common.tracking"))
            .foregroundStyle(settings.color("common.textColor"))
            .multilineTextAlignment(alignment(settings.string("note.alignment")))
            .lineSpacing(settings.double("common.lineSpacing"))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment(settings.string("note.alignment")))
    }

    private func alignment(_ raw: String) -> TextAlignment {
        switch raw {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }

    private func frameAlignment(_ raw: String) -> Alignment {
        switch raw {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
}
