import SwiftUI

/// Preview of a widget rendered with the real renderer, scaled to fit a box.
///
/// What you see here is pixel-identical to the window on the desktop.
struct WidgetPreview: View {
    let definition: WidgetDefinition
    let settings: SettingsBag
    var size: CGSize
    var maxSize: CGSize
    var showsControls: Bool = false

    var body: some View {
        let scale = min(maxSize.width / max(size.width, 1),
                        maxSize.height / max(size.height, 1),
                        1)
        TimelineView(.periodic(from: Date(), by: 1)) { timeline in
            WidgetSurface(definition: definition, settings: settings, date: timeline.date, size: size)
                .frame(width: size.width, height: size.height)
                .overlay(alignment: .topTrailing) {
                    if showsControls {
                        HStack(spacing: 6) {
                            WidgetCircleButton(systemImage: "slider.horizontal.3", help: "") {}
                            WidgetCircleButton(systemImage: "xmark", help: "") {}
                        }
                        .padding(8)
                    }
                }
        }
        .scaleEffect(scale)
        .frame(width: size.width * scale, height: size.height * scale)
        .allowsHitTesting(false)
    }
}

/// Wallpaper-like backdrop used behind previews so transparent widgets stay visible.
struct WallpaperBackdrop: View {
    var body: some View {
        LinearGradient(colors: [
            Color(red: 0.10, green: 0.12, blue: 0.20),
            Color(red: 0.19, green: 0.10, blue: 0.22),
            Color(red: 0.04, green: 0.05, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)
    }
}
