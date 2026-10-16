import AppKit
import SwiftUI

/// Application preferences.
struct AppSettingsView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    private let repositoryURL = URL(string: "https://github.com/AlexPogyl/widget-studio")!

    var body: some View {
        Form {
            Section(L("Интерфейс", "Interface")) {
                Picker(L("Язык", "Language"), selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.menu)

                Toggle(L("Показывать значок в Dock", "Show icon in Dock"), isOn: $state.app.showDockIcon)
                    .toggleStyle(.switch)

                Toggle(L("Кнопки при наведении на виджет", "Show buttons on widget hover"),
                       isOn: $state.app.showHoverControls)
                    .toggleStyle(.switch)
            }

            Section(L("Виджеты", "Widgets")) {
                Toggle(L("Показывать виджеты на рабочем столе", "Show widgets on the desktop"),
                       isOn: $state.widgetsHidden)
                    .toggleStyle(.switch)

                Toggle(L("Прилипание к сетке", "Snap to grid"), isOn: $state.app.snapToGrid)
                    .toggleStyle(.switch)

                if state.app.snapToGrid {
                    HStack {
                        Text(L("Шаг сетки", "Grid step"))
                        Spacer()
                        Text("\(Int(state.app.gridSize)) pt")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Stepper("", value: $state.app.gridSize, in: 2...64, step: 2)
                            .labelsHidden()
                    }
                }

                Picker(L("Уровень новых виджетов", "Level of new widgets"), selection: $state.app.defaultLevel) {
                    ForEach(WidgetLevel.allCases) { level in
                        Text(level.title.value).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(L("Конфигурация", "Configuration")) {
                HStack {
                    Button(L("Показать файл настроек", "Reveal config file")) { Store.revealInFinder() }
                    Spacer()
                    Button(L("Экспорт…", "Export…")) { state.exportConfiguration() }
                    Button(L("Импорт…", "Import…")) { state.importConfiguration() }
                }

                HStack {
                    Text(L("Виджетов на рабочем столе", "Widgets on the desktop"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(state.widgets.count)")
                        .font(.system(.body, design: .monospaced))
                }

                Button(L("Сбросить всё к исходному состоянию", "Reset everything to defaults"), role: .destructive) {
                    state.resetEverything()
                }
            }

            Section(L("О программе", "About")) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Widget Studio \(version)")
                            .font(.headline)
                        Text(L("Кастомизируемые виджеты для рабочего стола macOS. Виджет часов повторяет виджет с iPhone.",
                               "Customizable desktop widgets for macOS. The clock widget mirrors the iPhone one."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(repositoryURL)
                    } label: {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { state.app.language }, set: { state.app.language = $0 })
    }
}
