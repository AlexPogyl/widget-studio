import SwiftUI

/// The customization inspector for one placed widget: live preview, ready-made
/// presets and every option the widget declares.
struct InspectorView: View {
    @ObservedObject var instance: WidgetInstance

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            Divider()
            Form {
                presetsSection
                ForEach(instance.definition.groups, id: \.self) { group in
                    let descriptors = instance.definition.settings(in: group)
                        .filter { $0.isVisible?(instance.bag) ?? true }
                    if !descriptors.isEmpty {
                        Section(group.value) {
                            ForEach(descriptors) { descriptor in
                                SettingRow(descriptor: descriptor, instance: instance)
                            }
                        }
                    }
                }
                geometrySection
                behaviourSection
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
                WidgetPreview(definition: instance.definition,
                              settings: instance.bag,
                              size: instance.size,
                              maxSize: CGSize(width: 380, height: 200),
                              showsControls: state.app.showHoverControls)
                Text("\(instance.definition.name.value) · \(Int(instance.size.width)) × \(Int(instance.size.height))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
        }
        .frame(height: 260)
    }

    // MARK: - Presets

    @ViewBuilder
    private var presetsSection: some View {
        if !instance.definition.presets.isEmpty {
            Section(L("Готовые стили", "Presets")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(instance.definition.presets) { preset in
                            let active = instance.matches(preset)
                            Button {
                                instance.apply(preset)
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

    // MARK: - Geometry

    private var geometrySection: some View {
        Section(SettingGroup.geometry.value) {
            Picker(L("Размер", "Size"), selection: sizePresetBinding) {
                Text(L("Маленький 158 × 158", "Small 158 × 158")).tag("small")
                Text(L("Средний 338 × 158", "Medium 338 × 158")).tag("medium")
                Text(L("Большой 338 × 338", "Large 338 × 338")).tag("large")
                Text(L("Свой", "Custom")).tag("custom")
            }
            .pickerStyle(.menu)

            sliderRow(L("Ширина", "Width"), value: widthBinding, range: 60...900)
            sliderRow(L("Высота", "Height"), value: heightBinding, range: 60...900)
            sliderRow(L("Позиция X", "Position X"), value: xBinding, range: -4000...4000)
            sliderRow(L("Позиция Y", "Position Y"), value: yBinding, range: -4000...4000)

            HStack {
                Button(L("По центру экрана", "Center on screen")) {
                    state.centerOnScreen(instance)
                }
                Spacer()
                Button(L("Дублировать", "Duplicate")) { state.duplicate(instance) }
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }

    // MARK: - Behaviour

    private var behaviourSection: some View {
        Section(SettingGroup.behavior.value) {
            Picker(L("Уровень окна", "Window level"), selection: levelBinding) {
                ForEach(WidgetLevel.allCases) { level in
                    Text(level.title.value).tag(level)
                }
            }
            .pickerStyle(.menu)

            Toggle(L("Заблокировать перемещение", "Lock position"), isOn: $instance.locked)
                .toggleStyle(.switch)
            Toggle(L("Не реагировать на клики", "Ignore mouse clicks"), isOn: $instance.clickThrough)
                .toggleStyle(.switch)
            Toggle(L("Скрыть виджет", "Hide widget"), isOn: $instance.hidden)
                .toggleStyle(.switch)
        }
    }

    private var resetSection: some View {
        Section {
            HStack {
                Button(L("Сбросить оформление", "Reset appearance"), role: .destructive) {
                    instance.applyDefaultSettings()
                }
                Spacer()
                Button(L("Удалить виджет", "Delete widget"), role: .destructive) {
                    state.remove(instance)
                }
            }
        }
    }

    // MARK: - Bindings

    private var widthBinding: Binding<Double> {
        Binding(get: { instance.size.width }, set: { instance.size.width = max($0, 60) })
    }

    private var heightBinding: Binding<Double> {
        Binding(get: { instance.size.height }, set: { instance.size.height = max($0, 60) })
    }

    private var xBinding: Binding<Double> {
        Binding(get: { instance.center.x },
                set: { instance.center = CGPoint(x: $0, y: instance.center.y) })
    }

    private var yBinding: Binding<Double> {
        Binding(get: { instance.center.y },
                set: { instance.center = CGPoint(x: instance.center.x, y: $0) })
    }

    private var levelBinding: Binding<WidgetLevel> {
        Binding(get: { instance.level }, set: { instance.level = $0 })
    }

    private var sizePresetBinding: Binding<String> {
        Binding(get: { currentSizePreset }, set: { applySizePreset($0) })
    }

    private var currentSizePreset: String {
        let width = instance.size.width
        let height = instance.size.height
        if abs(width - 158) < 1 && abs(height - 158) < 1 { return "small" }
        if abs(width - 338) < 1 && abs(height - 158) < 1 { return "medium" }
        if abs(width - 338) < 1 && abs(height - 338) < 1 { return "large" }
        return "custom"
    }

    private func applySizePreset(_ id: String) {
        switch id {
        case "small": instance.size = CGSize(width: 158, height: 158)
        case "medium": instance.size = CGSize(width: 338, height: 158)
        case "large": instance.size = CGSize(width: 338, height: 338)
        default: break
        }
    }
}
