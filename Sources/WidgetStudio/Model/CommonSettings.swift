import SwiftUI

/// Appearance options that every widget gets for free.
///
/// Widgets only describe their own content; the card, its border, its shadow and
/// the typography are handled by the framework and are therefore customizable for
/// all widgets in exactly the same way.
enum CommonSettings {

    static let definitions: [SettingDescriptor] = card + typography

    // MARK: - Card

    static let card: [SettingDescriptor] = [
        .picker("common.cardStyle", LText("Фон карточки", "Card background"), group: SettingGroup.card,
                options: [
                    SettingOption("solid", LText("Сплошной", "Solid")),
                    SettingOption("gradient", LText("Градиент", "Gradient")),
                    SettingOption("glass", LText("Стекло", "Glass")),
                    SettingOption("none", LText("Без фона", "No background"))
                ],
                default: "gradient"),

        .color("common.background", LText("Цвет фона", "Background colour"), group: SettingGroup.card,
               default: RGBA(hex: "#1B1D21", alpha: 1)),

        .color("common.background2", LText("Второй цвет градиента", "Gradient end colour"), group: SettingGroup.card,
               default: RGBA(hex: "#101010", alpha: 1),
               visibleIf: { $0.string("common.cardStyle") == "gradient" }),

        .slider("common.gradientAngle", LText("Угол градиента", "Gradient angle"), group: SettingGroup.card,
                range: 0...360, step: 1, default: 270, unit: "°",
                visibleIf: { $0.string("common.cardStyle") == "gradient" }),

        .slider("common.cornerRadius", LText("Скругление", "Corner radius"), group: SettingGroup.card,
                range: 0...120, step: 1, default: 26, unit: "pt"),

        .slider("common.borderWidth", LText("Толщина обводки", "Border width"), group: SettingGroup.card,
                range: 0...16, step: 0.5, default: 8, unit: "pt"),

        .color("common.borderColor", LText("Цвет обводки", "Border colour"), group: SettingGroup.card,
               default: RGBA(hex: "#CECECF"),
               visibleIf: { $0.double("common.borderWidth") > 0 }),

        .slider("common.padding", LText("Внутренние отступы", "Inner padding"), group: SettingGroup.card,
                range: 0...48, step: 1, default: 10, unit: "pt"),

        .slider("common.opacity", LText("Прозрачность", "Opacity"), group: SettingGroup.card,
                range: 0.1...1, step: 0.01, default: 1),

        .toggle("common.shadow", LText("Тень окна", "Window shadow"), group: SettingGroup.card,
                caption: LText("Системная тень вокруг всей карточки", "System shadow around the whole card"))
    ]

    // MARK: - Typography

    static let typography: [SettingDescriptor] = [
        .picker("common.fontDesign", LText("Гарнитура", "Typeface"), group: SettingGroup.typography,
                options: FontChoices.designs, default: "default"),

        .picker("common.fontWeight", LText("Насыщенность", "Weight"), group: SettingGroup.typography,
                options: FontChoices.weights, default: "black"),

        .slider("common.fontSize", LText("Размер шрифта", "Font size"), group: SettingGroup.typography,
                range: 8...220, step: 1, default: 79, unit: "pt"),

        .toggle("common.italic", LText("Курсив", "Italic"), group: SettingGroup.typography, default: true),

        .slider("common.slant", LText("Дополнительный наклон", "Extra slant"), group: SettingGroup.typography,
                range: 0...24, step: 0.5, default: 0, unit: "°"),

        .slider("common.tracking", LText("Межбуквенный интервал", "Letter spacing"), group: SettingGroup.typography,
                range: -10...20, step: 0.5, default: 1),

        .slider("common.lineSpacing", LText("Межстрочный интервал", "Line spacing"), group: SettingGroup.typography,
                range: -40...40, step: 1, default: 3, unit: "pt",
                caption: LText("Для часов это реальный зазор между строками цифр",
                               "For the clock this is the real gap between the digit rows")),

        .color("common.textColor", LText("Цвет текста", "Text colour"), group: SettingGroup.typography,
               default: RGBA(hex: "#CCCCCE")),

        .slider("common.secondaryOpacity", LText("Яркость доп. текста", "Secondary text brightness"),
                group: SettingGroup.typography,
                range: 0.1...1, step: 0.01, default: 0.66)
    ]
}
