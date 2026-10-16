import SwiftUI

/// The settings window: a sidebar with the gallery, the placed widgets and the
/// application preferences, plus the matching detail pane.
struct SettingsRootView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 340)
        } detail: {
            detail
        }
        .frame(minWidth: 840, minHeight: 560)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $state.selection) {
            Section(L("Виджеты", "Widgets")) {
                Label(L("Галерея", "Gallery"), systemImage: "square.grid.2x2")
                    .tag(SidebarSelection.gallery)
            }

            if !state.widgets.isEmpty {
                Section(L("На рабочем столе", "On the desktop")) {
                    ForEach(state.widgets) { instance in
                        widgetRow(instance)
                            .tag(SidebarSelection.widget(instance.id))
                            .contextMenu {
                                Button(L("Дублировать", "Duplicate")) { state.duplicate(instance) }
                                Button(instance.hidden ? L("Показать", "Show") : L("Скрыть", "Hide")) {
                                    instance.hidden.toggle()
                                }
                                Divider()
                                Button(L("Удалить", "Delete"), role: .destructive) { state.remove(instance) }
                            }
                    }
                }
            }

            Section(L("Приложение", "Application")) {
                Label(L("Настройки", "Preferences"), systemImage: "gearshape")
                    .tag(SidebarSelection.application)
            }
        }
        .listStyle(.sidebar)
    }

    private func widgetRow(_ instance: WidgetInstance) -> some View {
        HStack(spacing: 8) {
            Image(systemName: instance.definition.symbol)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(instance.definition.name.value)
                Text("\(Int(instance.size.width)) × \(Int(instance.size.height)) · \(instance.level.title.value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if instance.hidden {
                Image(systemName: "eye.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch state.selection {
        case .widget(let id):
            if let instance = state.instance(with: id) {
                InspectorView(instance: instance)
                    .id(instance.id)
            } else {
                GalleryView()
            }
        case .application:
            AppSettingsView()
        default:
            GalleryView()
        }
    }
}
