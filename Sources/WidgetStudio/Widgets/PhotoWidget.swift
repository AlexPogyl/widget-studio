import SwiftUI

/// The photo widget: shows one of your pictures, and can rotate through several
/// of them while the day goes by.
enum PhotoWidget {

    static let group = LText("Фото", "Photo")

    static let definition = WidgetDefinition(
        id: "photo",
        name: LText("Фото", "Photo"),
        summary: LText("Ваше фото на рабочем столе — одно или несколько по очереди",
                       "Your own picture on the desktop — one or several in rotation"),
        symbol: "photo",
        defaultSize: CGSize(width: 158, height: 158),
        settings: settings,
        presets: presets,
        content: { context in AnyView(PhotoContentView(context: context)) },
        overrides: [
            // The picture itself is the card: no extra chrome around it.
            "common.cardStyle": .text("none"),
            "common.padding": .number(0),
            "common.borderWidth": .number(0),
            "common.cornerRadius": .number(26),
            "common.shadow": .bool(false)
        ]
    )

    // MARK: - Settings

    private static let settings: [SettingDescriptor] = [
        .images("photo.files", LText("Фотографии", "Photos"), group: group,
                caption: LText("Можно выбрать несколько — они будут меняться по очереди",
                               "Pick several — they will change in turn")),

        .picker("photo.interval", LText("Менять каждые", "Change every"), group: group,
                options: [
                    SettingOption("60", LText("минуту", "minute")),
                    SettingOption("300", LText("5 минут", "5 minutes")),
                    SettingOption("900", LText("15 минут", "15 minutes")),
                    SettingOption("1800", LText("30 минут", "30 minutes")),
                    SettingOption("3600", LText("час", "hour")),
                    SettingOption("21600", LText("6 часов", "6 hours")),
                    SettingOption("86400", LText("сутки", "day"))
                ],
                default: "3600",
                visibleIf: { $0.list("photo.files").count > 1 }),

        .picker("photo.fit", LText("Как вписывать", "Scaling"), group: group,
                options: [
                    SettingOption("fill", LText("Заполнить целиком", "Fill the widget")),
                    SettingOption("fit", LText("Вписать целиком", "Fit the whole picture"))
                ],
                default: "fill"),

        .slider("photo.zoom", LText("Приближение", "Zoom"), group: group,
                range: 1...3, step: 0.05, default: 1),

        .toggle("photo.grayscale", LText("Чёрно-белое", "Black and white"), group: group, default: false),

        .slider("photo.dim", LText("Затемнение", "Darkening"), group: group,
                range: 0...0.8, step: 0.05, default: 0),

        .toggle("photo.showTime", LText("Показывать время", "Show the time"), group: group,
                caption: LText("Часы в углу фотографии", "A clock in the corner of the picture"),
                default: false)
    ]

    // MARK: - Presets

    private static let presets: [WidgetPreset] = [
        WidgetPreset(id: "plain",
                     name: LText("Как есть", "Plain"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.padding": .number(0),
                        "common.borderWidth": .number(0),
                        "common.cornerRadius": .number(26),
                        "photo.fit": .text("fill"),
                        "photo.zoom": .number(1),
                        "photo.grayscale": .bool(false),
                        "photo.dim": .number(0)
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "framed",
                     name: LText("В рамке", "Framed"),
                     values: [
                        "common.cardStyle": .text("solid"),
                        "common.background": .color(RGBA(hex: "#111114", alpha: 1)),
                        "common.padding": .number(8),
                        "common.cornerRadius": .number(30),
                        "common.borderWidth": .number(2),
                        "common.borderColor": .color(RGBA(hex: "#CECECF")),
                        "photo.fit": .text("fit"),
                        "photo.zoom": .number(1),
                        "photo.dim": .number(0)
                     ],
                     size: CGSize(width: 158, height: 158)),

        WidgetPreset(id: "mono",
                     name: LText("Чёрно-белое", "Monochrome"),
                     values: [
                        "common.cardStyle": .text("none"),
                        "common.padding": .number(0),
                        "common.borderWidth": .number(0),
                        "common.cornerRadius": .number(26),
                        "photo.grayscale": .bool(true),
                        "photo.dim": .number(0.15),
                        "photo.fit": .text("fill")
                     ],
                     size: CGSize(width: 158, height: 158))
    ]

    // MARK: - Rotation

    /// Which of the chosen photos is shown at `date`.
    static func index(for date: Date, count: Int, interval: Double) -> Int {
        guard count > 1, interval > 0 else { return 0 }
        let step = Int(date.timeIntervalSinceReferenceDate / interval)
        return ((step % count) + count) % count
    }

    static func interval(_ settings: SettingsBag) -> Double {
        let raw = settings.string("photo.interval")
        return Double(raw) ?? 3600
    }
}

// MARK: - View

private struct PhotoContentView: View {
    let context: WidgetContext

    var body: some View {
        let settings = context.settings
        let files = settings.list("photo.files")
        let index = PhotoWidget.index(for: context.date,
                                      count: files.count,
                                      interval: PhotoWidget.interval(settings))

        ZStack {
            if files.isEmpty {
                emptyState
            } else if let cgImage = PhotoStore.thumbnailImage(named: files[index], maxPixel: 900) {
                picture(cgImage, settings: settings)
            } else {
                missingState
            }

            if settings.bool("photo.showTime") && !files.isEmpty {
                timeOverlay(settings: settings)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: settings.double("common.cornerRadius"), style: .continuous))
    }

    @ViewBuilder
    private func picture(_ cgImage: CGImage, settings: SettingsBag) -> some View {
        let base = Self.photoImage(cgImage)
        let fill = settings.string("photo.fit") != "fit"
        let zoom = settings.double("photo.zoom")

        GeometryReader { proxy in
            base
                .aspectRatio(contentMode: fill ? .fill : .fit)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(zoom)
                .clipped()
        }
        .grayscale(settings.bool("photo.grayscale") ? 1 : 0)
        .overlay {
            if settings.double("photo.dim") > 0 {
                Color.black.opacity(settings.double("photo.dim"))
            }
        }
    }

    /// A picture is media content: keep it in colour even when the system
    /// renders the widget in the accented (tinted) rendering mode.
    private static func photoImage(_ cgImage: CGImage) -> AnyView {
        let image = Image(decorative: cgImage, scale: 1).resizable()
        if #available(macOS 15.0, *) {
            return AnyView(image.widgetAccentedRenderingMode(.fullColor))
        }
        return AnyView(image)
    }

    @ViewBuilder
    private var emptyState: some View {
        ZStack {
            Color.black.opacity(0.35)
            VStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 26, weight: .light))
                Text(L("Добавьте фото", "Add a photo"))
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.75))
        }
    }

    @ViewBuilder
    private var missingState: some View {
        ZStack {
            Color.black.opacity(0.35)
            Text(L("Фото не найдено", "Photo not found"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    @ViewBuilder
    private func timeOverlay(settings: SettingsBag) -> some View {
        let timeZone = ClockWidget.resolvedTimeZone(settings.string("clock.timeZone"))
        let parts = ClockWidget.parts(date: context.date,
                                      timeZone: timeZone,
                                      use24h: settings.bool("clock.use24h"),
                                      leadingZero: settings.bool("clock.leadingZero"))
        VStack {
            HStack {
                Spacer()
                Text("\(parts.hour):\(parts.minute)")
                    .font(.system(size: max(context.size.height * 0.16, 12), weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
            }
            Spacer()
        }
        .padding(10)
    }
}
