import SwiftUI

/// Group titles shared by all widgets.
enum SettingGroup {
    static let card = LText("Карточка", "Card")
    static let typography = LText("Шрифт", "Typography")
    static let geometry = LText("Размер и положение", "Size & position")
    static let behavior = LText("Поведение", "Behaviour")
}

/// Visual helpers shared by the widgets.
enum WidgetStyle {
    static func design(_ raw: String) -> Font.Design {
        switch raw {
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        case "serif": return .serif
        default: return .default
        }
    }

    static func weight(_ raw: String) -> Font.Weight {
        switch raw {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .bold
        }
    }

    static func unitPoints(angle: Double) -> (UnitPoint, UnitPoint) {
        let radians = angle * .pi / 180
        let dx = cos(radians) / 2
        let dy = sin(radians) / 2
        return (UnitPoint(x: 0.5 - dx, y: 0.5 + dy),
                UnitPoint(x: 0.5 + dx, y: 0.5 - dy))
    }

    /// Shear transform used to fake an oblique face.
    /// `height` is the approximate height of the text so the glyphs stay centred.
    static func shear(degrees: Double, height: CGFloat) -> CGAffineTransform {
        guard abs(degrees) > 0.01 else { return .identity }
        let slope = CGFloat(tan(degrees * .pi / 180))
        return CGAffineTransform(a: 1, b: 0, c: -slope, d: 1, tx: slope * height / 2, ty: 0)
    }
}

/// Font option lists used by the shared typography settings.
enum FontChoices {
    static let designs: [SettingOption] = [
        SettingOption("default", LText("Системный", "System")),
        SettingOption("rounded", LText("Округлый", "Rounded")),
        SettingOption("monospaced", LText("Моноширинный", "Monospaced")),
        SettingOption("serif", LText("С засечками", "Serif"))
    ]

    static let weights: [SettingOption] = [
        SettingOption("light", LText("Тонкий", "Light")),
        SettingOption("regular", LText("Обычный", "Regular")),
        SettingOption("medium", LText("Средний", "Medium")),
        SettingOption("semibold", LText("Полужирный", "Semibold")),
        SettingOption("bold", LText("Жирный", "Bold")),
        SettingOption("heavy", LText("Тяжёлый", "Heavy")),
        SettingOption("black", LText("Чёрный", "Black"))
    ]
}
