import Foundation

/// Supported interface languages.
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case ru
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }

    var locale: Locale { Locale(identifier: self == .ru ? "ru_RU" : "en_US") }
}

/// A string that exists in both supported languages.
///
/// The whole UI is built from `LText` values instead of a `.strings` table:
/// it keeps every translation next to the code that uses it and works inside a
/// plain SwiftPM executable without resource bundles.
struct LText: Equatable, Hashable {
    let ru: String
    let en: String

    init(_ ru: String, _ en: String) {
        self.ru = ru
        self.en = en
    }

    /// Same text in both languages (proper nouns, numbers, symbols).
    static func both(_ value: String) -> LText { LText(value, value) }

    /// Localized value for the currently selected language.
    var value: String { Localization.shared.language == .ru ? ru : en }
}

/// Observable holder of the current language. Views observe it so that
/// switching the language re-renders the interface instantly.
final class Localization: ObservableObject {
    static let shared = Localization()

    @Published var language: AppLanguage = .ru

    private init() {}
}

/// Terse helper for one-off strings inside view bodies.
@inline(__always)
func L(_ ru: String, _ en: String) -> String {
    Localization.shared.language == .ru ? ru : en
}
