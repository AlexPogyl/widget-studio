import SwiftUI

/// The widget's own content, without any card chrome.
///
/// The card (background, border, corners) is drawn separately by
/// `WidgetCardBackground` so that it can live in the widget's
/// `containerBackground` — that is what makes a widget look right in the
/// system's tinted / Liquid Glass rendering modes, where everything drawn as
/// *content* is tinted and the background is replaced by the system material.
struct WidgetSurfaceContent: View {
    let definition: WidgetDefinition
    let settings: SettingsBag
    var date: Date = Date()
    /// Size of the card; used by the widgets for their own scaling decisions.
    var size: CGSize = CGSize(width: 158, height: 158)

    var body: some View {
        definition.content(WidgetContext(settings: settings, date: date, size: size))
            .padding(settings.double("common.padding"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The card itself: background fill, gradient, glass and the border.
struct WidgetCardBackground: View {
    let settings: SettingsBag
    /// App previews clip the card to its rounded corners themselves; inside
    /// `containerBackground` the system clips to the real widget shape.
    var rounded: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: settings.double("common.cornerRadius"), style: .continuous)
        Group {
            fill
            if settings.double("common.borderWidth") > 0 && settings.string("common.cardStyle") != "none" {
                shape.strokeBorder(settings.color("common.borderColor"),
                                   lineWidth: settings.double("common.borderWidth"))
            }
        }
        .clipShape(shape, if: rounded)
    }

    @ViewBuilder
    private var fill: some View {
        let shape = RoundedRectangle(cornerRadius: settings.double("common.cornerRadius"), style: .continuous)
        switch settings.string("common.cardStyle") {
        case "none":
            Color.clear
        case "gradient":
            let points = WidgetStyle.unitPoints(angle: settings.double("common.gradientAngle"))
            shape.fill(LinearGradient(colors: [settings.color("common.background"),
                                               settings.color("common.background2")],
                                      startPoint: points.0,
                                      endPoint: points.1))
        case "glass":
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(settings.color("common.background"))
            }
        default:
            shape.fill(settings.color("common.background"))
        }
    }
}

private extension View {
    @ViewBuilder
    func clipShape<S: Shape>(_ shape: S, if condition: Bool) -> some View {
        if condition {
            clipShape(shape)
        } else {
            self
        }
    }
}

/// Draws one widget the way the app previews it: content plus the card chrome.
struct WidgetSurface: View {
    let definition: WidgetDefinition
    let settings: SettingsBag
    var date: Date = Date()
    var size: CGSize = CGSize(width: 158, height: 158)

    var body: some View {
        WidgetSurfaceContent(definition: definition, settings: settings, date: date, size: size)
            .background { WidgetCardBackground(settings: settings, rounded: true) }
            .opacity(settings.double("common.opacity"))
    }
}

/// Small round button used by the previews.
struct WidgetCircleButton: View {
    let systemImage: String
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .overlay { Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5) }
                }
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
