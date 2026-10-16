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

                Toggle(L("Показывать значок в строке меню", "Show menu bar icon"), isOn: $state.app.showStatusItem)
                    .toggleStyle(.switch)

                Toggle(L("Открывать окно при запуске", "Open the window on launch"),
                       isOn: $state.app.windowOnLaunch)
                    .toggleStyle(.switch)
            }

            Section(L("Виджеты на рабочем столе", "Widgets on the desktop")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("Добавляются системной галереей:", "Added by the system gallery:"))
                        .font(.callout)
                    Text(L("правый клик по рабочему столу → «Изменить виджеты…» → Widget Studio",
                           "right-click the desktop → “Edit Widgets…” → Widget Studio"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button {
                        state.reloadSystemWidgets()
                    } label: {
                        Label(L("Обновить виджеты", "Reload widgets"), systemImage: "arrow.clockwise")
                    }
                    Spacer()
                    Button(L("Как добавить виджет…", "How to add a widget…")) {
                        AppEnvironment.shared.settingsWindow?.showHowToAddWidget()
                    }
                }
            }

            Section(L("Конфигурация", "Configuration")) {
                HStack {
                    Button(L("Показать файл настроек", "Reveal config file")) { Store.revealInFinder() }
                    Spacer()
                    Button(L("Экспорт…", "Export…")) { state.exportConfiguration() }
                    Button(L("Импорт…", "Import…")) { state.importConfiguration() }
                }

                HStack {
                    Text(L("Настроено видов виджетов", "Configured widget kinds"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(state.profiles.count)")
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
                        Text(L("Кастомизируемые системные виджеты для рабочего стола macOS. Виджет часов повторяет виджет с iPhone.",
                               "Customizable system widgets for the macOS desktop. The clock widget mirrors the iPhone one."))
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
