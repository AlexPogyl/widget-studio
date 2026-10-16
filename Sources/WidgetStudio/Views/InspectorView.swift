import SwiftUI

/// The three system widget sizes, used by the inspector preview.
enum WidgetPreviewSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: LText {
        switch self {
        case .small: return LText("Маленький", "Small")
        case .medium: return LText("Средний", "Medium")
        case .large: return LText("Большой", "Large")
        }
    }

    var size: CGSize {
        switch self {
        case .small: return CGSize(width: 164, height: 164)
        case .medium: return CGSize(width: 344, height: 164)
        case .large: return CGSize(width: 344, height: 344)
        }
    }
}

/// The customization inspector for one widget kind: live preview, ready-made
/// presets and every option the widget declares.
struct InspectorView: View {
    @ObservedObject var profile: WidgetProfile

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    /// Widgets look different in every size, so the preview can show them all.
    @State private var previewSize: WidgetPreviewSize = .small

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            Divider()
            Form {
                presetsSection
                ForEach(profile.definition.groups, id: \.self) { group in
                    let descriptors = profile.definition.settings(in: group)
                        .filter { $0.isVisible?(profile.bag) ?? true }
                    if !descriptors.isEmpty {
                        Section(group.value) {
                            ForEach(descriptors) { descriptor in
                                SettingRow(descriptor: descriptor, profile: profile)
                            }
                        }
                    }
                }
                resetSection
            }
            .formStyle(.grouped)
        }
        .task(id: profile.kind) {
            if profile.kind == WeatherWidget.definition.id {
                state.refreshWeatherIfNeeded()
            }
        }
        .onChange(of: profile.bag.string("weather.city")) { _ in
            if profile.kind == WeatherWidget.definition.id {
                state.refreshWeatherIfNeeded(force: true)
            }
        }
    }

    // MARK: - Preview

    private var previewHeader: some View {
        ZStack {
            WallpaperBackdrop()
            VStack(spacing: 10) {
                WidgetPreview(definition: profile.definition,
                              settings: profile.bag,
                              size: previewSize.size,
                              maxSize: CGSize(width: 420, height: 175))
                Picker("", selection: $previewSize) {
                    ForEach(WidgetPreviewSize.allCases) { size in
                        Text(size.title.value).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 320)
                Text(L("Размер виджета выбирается на рабочем столе: потяните за уголок в режиме редактирования",
                       "The size is chosen on the desktop: drag the corner while editing widgets"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(14)
        }
        .frame(height: 275)
    }

    // MARK: - Presets

    @ViewBuilder
    private var presetsSection: some View {
        if !profile.definition.presets.isEmpty {
            Section(L("Готовые стили", "Presets")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profile.definition.presets) { preset in
                            let active = profile.matches(preset)
                            Button {
                                profile.apply(preset)
                            } label: {
                                Text(preset.name.value)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background {
                                        Capsule().fill(active ? Color.accentColor : Color.secondary.opacity(0.15))
                                    }
                                    .foregroundStyle(active ? Color.white : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            HStack {
                Button(L("Сбросить оформление", "Reset appearance"), role: .destructive) {
                    profile.applyDefaultSettings()
                }
                Spacer()
                Button {
                    state.reloadSystemWidgets()
                } label: {
                    Label(L("Обновить виджеты", "Reload widgets"), systemImage: "arrow.clockwise")
                }
            }
            Text(L("Изменения применяются к системным виджетам автоматически. Если виджет на рабочем столе не изменился, нажмите «Обновить виджеты».",
                   "Changes are applied to the system widgets automatically. If a widget on the desktop does not update, press “Reload widgets”."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
