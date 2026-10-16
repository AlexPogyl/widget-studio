import SwiftUI

/// The settings window: a sidebar with the overview, every widget kind and the
/// application preferences, plus the matching detail pane.
struct SettingsRootView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 320)
        } detail: {
            detail
        }
        .frame(minWidth: 880, minHeight: 560)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $state.selection) {
            Section(L("Виджеты", "Widgets")) {
                Label(L("Обзор", "Overview"), systemImage: "square.grid.2x2")
                    .tag(SidebarSelection.overview)
                ForEach(WidgetCatalog.all) { definition in
                    Label(definition.name.value, systemImage: definition.symbol)
                        .tag(SidebarSelection.widget(definition.id))
                }
            }

            Section(L("Приложение", "Application")) {
                Label(L("Настройки", "Preferences"), systemImage: "gearshape")
                    .tag(SidebarSelection.application)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch state.selection {
        case .widget(let kind):
            if let profile = state.existingProfile(for: kind) {
                InspectorView(profile: profile)
                    .id(profile.kind)
            } else {
                OverviewView()
            }
        case .application:
            AppSettingsView()
        default:
            OverviewView()
        }
    }
}
