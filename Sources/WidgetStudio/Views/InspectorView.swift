import SwiftUI

/// The customization inspector for one widget kind: live preview, ready-made
/// presets and every option the widget declares.
struct InspectorView: View {
    @ObservedObject var profile: WidgetProfile

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

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
    }

    // MARK: - Preview

    private var previewHeader: some View {
        ZStack {
            WallpaperBackdrop()
            VStack(spacing: 10) {
                WidgetPreview(definition: profile.definition,
                              settings: profile.bag,
                              size: profile.definition.defaultSize,
                              maxSize: CGSize(width: 380, height: 190))
                Text(L("Так виджет будет выглядеть на рабочем столе",
                       "This is how the widget will look on the desktop"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
        }
        .frame(height: 250)
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
