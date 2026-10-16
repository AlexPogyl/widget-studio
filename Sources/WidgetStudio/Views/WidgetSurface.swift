import SwiftUI

/// Draws one widget: the content provided by the widget plus the shared card
/// chrome (background, border, radius, padding, opacity).
///
/// It is used both by the live window and by the previews in the settings window,
/// so what you see in the inspector is exactly what you get on the desktop.
struct WidgetSurface: View {
    let definition: WidgetDefinition
    let settings: SettingsBag
    var date: Date = Date()
    /// Size of the card; used by the widgets for their own scaling decisions.
    var size: CGSize = CGSize(width: 158, height: 158)

    var body: some View {
        definition.content(WidgetContext(settings: settings, date: date, size: size))
            .padding(settings.double("common.padding"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { background }
            .clipShape(shape)
            .overlay { border }
            .opacity(settings.double("common.opacity"))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: settings.double("common.cornerRadius"), style: .continuous)
    }

    @ViewBuilder
    private var background: some View {
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

    @ViewBuilder
    private var border: some View {
        if settings.double("common.borderWidth") > 0 && settings.string("common.cardStyle") != "none" {
            shape.strokeBorder(settings.color("common.borderColor"),
                               lineWidth: settings.double("common.borderWidth"))
        }
    }
}

/// Small round button used by the hover controls and previews.
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
