import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Renders a single customization option from its descriptor.
///
/// Every row is generated from the schema, so a widget author never writes UI
/// code — they only describe which options exist.
struct SettingRow: View {
    let descriptor: SettingDescriptor
    @ObservedObject var profile: WidgetProfile

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
                    Text(formatted(profile.bag.double(descriptor.id), step: step, unit: unit))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: numberBinding, in: minimum...maximum, step: step)
            }

        case .stepper(let minimum, let maximum, let step, let unit):
            HStack {
                label
                Spacer()
                Text(formatted(profile.bag.double(descriptor.id), step: step, unit: unit))
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

        case .date:
            VStack(alignment: .leading, spacing: 6) {
                label
                DatePicker("", selection: dateBinding, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

        case .images:
            VStack(alignment: .leading, spacing: 8) {
                label

                if !imageNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(imageNames, id: \.self) { name in
                                ZStack(alignment: .topTrailing) {
                                    if let thumbnail = PhotoStore.thumbnail(named: name) {
                                        Image(nsImage: thumbnail)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 68, height: 68)
                                            .clipShape(RoundedRectangle(cornerRadius: 9))
                                    } else {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(width: 68, height: 68)
                                    }
                                    Button {
                                        removeImage(name)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 5, y: -5)
                                    .help(L("Убрать фото", "Remove photo"))
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.horizontal, 1)
                    }
                }

                HStack {
                    Button(L("Добавить фото…", "Add photos…")) { addImages() }
                    if !imageNames.isEmpty {
                        Text(L("\(imageNames.count) шт.", "\(imageNames.count) selected"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(L("Очистить", "Clear")) {
                            for name in imageNames { PhotoStore.remove(name) }
                            profile.set(descriptor.id, .list([]))
                        }
                    }
                }
            }

        case .application:
            VStack(alignment: .leading, spacing: 6) {
                label
                HStack(spacing: 8) {
                    if let image = WidgetLauncher.icon(for: applicationPath) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(WidgetLauncher.displayName(for: applicationPath))
                    } else {
                        Text(L("Не выбрано", "Not selected"))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(L("Выбрать…", "Choose…")) { chooseApplication() }
                    if !applicationPath.isEmpty {
                        Button(L("Убрать", "Clear")) { profile.set(descriptor.id, .text("")) }
                    }
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

    // MARK: - Date

    private var dateBinding: Binding<Date> {
        Binding(get: {
            let raw = profile.bag.string(descriptor.id)
            return ISO8601DateFormatter().date(from: raw) ?? Date()
        }, set: { newValue in
            profile.set(descriptor.id, .text(ISO8601DateFormatter().string(from: newValue)))
        })
    }

    // MARK: - Photo picker

    private var imageNames: [String] { profile.bag.list(descriptor.id) }

    private func addImages() {
        let panel = NSOpenPanel()
        panel.title = L("Выберите фотографии", "Choose photos")
        panel.prompt = L("Добавить", "Add")
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        var names = imageNames
        for url in panel.urls {
            if let name = PhotoStore.importImage(from: url) { names.append(name) }
        }
        profile.set(descriptor.id, .list(names))
    }

    private func removeImage(_ name: String) {
        var names = imageNames
        names.removeAll { $0 == name }
        profile.set(descriptor.id, .list(names))
        PhotoStore.remove(name)
    }

    // MARK: - Application picker

    private var applicationPath: String { profile.bag.string(descriptor.id) }

    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.title = L("Выберите приложение", "Choose an application")
        panel.prompt = L("Выбрать", "Choose")
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        profile.set(descriptor.id, .text(url.path))
    }

    // MARK: - Bindings

    private var boolBinding: Binding<Bool> {
        Binding(get: { profile.bag.bool(descriptor.id) },
                set: { profile.set(descriptor.id, .bool($0)) })
    }

    private var numberBinding: Binding<Double> {
        Binding(get: { profile.bag.double(descriptor.id) },
                set: { profile.set(descriptor.id, .number($0)) })
    }

    private var stringBinding: Binding<String> {
        Binding(get: { profile.bag.string(descriptor.id) },
                set: { profile.set(descriptor.id, .text($0)) })
    }

    private var colorBinding: Binding<Color> {
        Binding(get: { profile.bag.color(descriptor.id) },
                set: { profile.set(descriptor.id, .color(RGBA(color: $0))) })
    }

    private func formatted(_ value: Double, step: Double, unit: String?) -> String {
        let text = step < 1 ? String(format: "%.2f", value) : String(format: "%.0f", value)
        return unit.map { "\(text) \($0)" } ?? text
    }
}
