import Foundation

/// One choice of a picker setting.
struct SettingOption: Identifiable, Hashable {
    let id: String
    let title: LText

    init(_ id: String, _ title: LText) {
        self.id = id
        self.title = title
    }
}

/// How a setting is presented in the inspector.
enum SettingControl {
    case toggle
    case slider(min: Double, max: Double, step: Double, unit: String?)
    case stepper(min: Double, max: Double, step: Double, unit: String?)
    case color
    case picker([SettingOption])
    case text(multiline: Bool)
    /// Picks an application bundle (used by the "open on click" action).
    case application
}

/// Declarative description of a single customization option.
///
/// Widgets never build UI themselves: they declare a list of descriptors and the
/// framework renders the inspector, the defaults and the persistence for them.
struct SettingDescriptor: Identifiable {
    let id: String
    let title: LText
    let caption: LText?
    let group: LText
    let control: SettingControl
    let defaultValue: SettingValue
    let isVisible: ((SettingsBag) -> Bool)?

    init(id: String,
         title: LText,
         caption: LText? = nil,
         group: LText,
         control: SettingControl,
         defaultValue: SettingValue,
         isVisible: ((SettingsBag) -> Bool)? = nil) {
        self.id = id
        self.title = title
        self.caption = caption
        self.group = group
        self.control = control
        self.defaultValue = defaultValue
        self.isVisible = isVisible
    }

    /// Copy of the descriptor with another default (used by widget overrides).
    func withDefault(_ value: SettingValue) -> SettingDescriptor {
        SettingDescriptor(id: id,
                          title: title,
                          caption: caption,
                          group: group,
                          control: control,
                          defaultValue: value,
                          isVisible: isVisible)
    }
}

// MARK: - Convenience builders

extension SettingDescriptor {
    static func toggle(_ id: String,
                       _ title: LText,
                       group: LText,
                       caption: LText? = nil,
                       default defaultValue: Bool = false,
                       visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .toggle, defaultValue: .bool(defaultValue), isVisible: visibleIf)
    }

    static func slider(_ id: String,
                       _ title: LText,
                       group: LText,
                       range: ClosedRange<Double>,
                       step: Double = 1,
                       default defaultValue: Double,
                       unit: String? = nil,
                       caption: LText? = nil,
                       visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .slider(min: range.lowerBound, max: range.upperBound,
                                           step: step, unit: unit),
                          defaultValue: .number(defaultValue), isVisible: visibleIf)
    }

    static func stepper(_ id: String,
                        _ title: LText,
                        group: LText,
                        range: ClosedRange<Double>,
                        step: Double = 1,
                        default defaultValue: Double,
                        unit: String? = nil,
                        caption: LText? = nil,
                        visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .stepper(min: range.lowerBound, max: range.upperBound,
                                            step: step, unit: unit),
                          defaultValue: .number(defaultValue), isVisible: visibleIf)
    }

    static func color(_ id: String,
                      _ title: LText,
                      group: LText,
                      default defaultValue: RGBA,
                      caption: LText? = nil,
                      visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .color, defaultValue: .color(defaultValue), isVisible: visibleIf)
    }

    static func picker(_ id: String,
                       _ title: LText,
                       group: LText,
                       options: [SettingOption],
                       default defaultValue: String,
                       caption: LText? = nil,
                       visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .picker(options), defaultValue: .text(defaultValue), isVisible: visibleIf)
    }

    static func application(_ id: String,
                            _ title: LText,
                            group: LText,
                            caption: LText? = nil,
                            visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .application, defaultValue: .text(""), isVisible: visibleIf)
    }

    static func text(_ id: String,
                     _ title: LText,
                     group: LText,
                     default defaultValue: String = "",
                     multiline: Bool = false,
                     caption: LText? = nil,
                     visibleIf: ((SettingsBag) -> Bool)? = nil) -> SettingDescriptor {
        SettingDescriptor(id: id, title: title, caption: caption, group: group,
                          control: .text(multiline: multiline),
                          defaultValue: .text(defaultValue), isVisible: visibleIf)
    }
}
