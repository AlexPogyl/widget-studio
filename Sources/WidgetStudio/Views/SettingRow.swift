import SwiftUI

/// Renders a single customization option from its descriptor.
///
/// Every row is generated from the schema, so a widget author never writes UI
/// code — they only describe which options exist.
struct SettingRow: View {
    let descriptor: SettingDescriptor
    @ObservedObject var instance: WidgetInstance

    @EnvironmentObject private var localization: Localization

    var body: some View {
        switch descriptor.control {
        case .toggle:
            Toggle(isOn: boolBinding) { label }
                .toggleStyle(.switch)

        case .slider(let minimum, let maximum, let step, let unit):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    label
                    Spacer()
                    Text(formatted(instance.bag.double(descriptor.id), step: step, unit: unit))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: numberBinding, in: minimum...maximum, step: step)
            }

        case .stepper(let minimum, let maximum, let step, let unit):
            HStack {
                label
                Spacer()
                Text(formatted(instance.bag.double(descriptor.id), step: step, unit: unit))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Stepper("", value: numberBinding, in: minimum...maximum, step: step)
                    .labelsHidden()
            }

        case .color:
            ColorPicker(selection: colorBinding, supportsOpacity: true) { label }

        case .picker(let options):
            Picker(selection: stringBinding) {
                ForEach(options) { option in
                    Text(option.title.value).tag(option.id)
                }
            } label: {
                label
            }
            .pickerStyle(.menu)

        case .text(let multiline):
            VStack(alignment: .leading, spacing: 6) {
                label
                if multiline {
                    TextEditor(text: stringBinding)
                        .font(.system(size: 13))
                        .frame(minHeight: 70)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        }
                } else {
                    TextField("", text: stringBinding)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(descriptor.title.value)
            if let caption = descriptor.caption {
                Text(caption.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bindings

    private var boolBinding: Binding<Bool> {
        Binding(get: { instance.bag.bool(descriptor.id) },
                set: { instance.set(descriptor.id, .bool($0)) })
    }

    private var numberBinding: Binding<Double> {
        Binding(get: { instance.bag.double(descriptor.id) },
                set: { instance.set(descriptor.id, .number($0)) })
    }

    private var stringBinding: Binding<String> {
        Binding(get: { instance.bag.string(descriptor.id) },
                set: { instance.set(descriptor.id, .text($0)) })
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { instance.bag.color(descriptor.id) },
                set: { instance.set(descriptor.id, .color(RGBA(color: $0))) })
    }

    private func formatted(_ value: Double, step: Double, unit: String?) -> String {
        let text = step < 1 ? String(format: "%.2f", value) : String(format: "%.0f", value)
        return unit.map { "\(text) \($0)" } ?? text
    }
}
