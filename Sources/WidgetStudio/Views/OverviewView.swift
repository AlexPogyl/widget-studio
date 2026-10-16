import AppKit
import SwiftUI

/// The first screen of the app: what the widgets look like and how to put them
/// on the desktop with the system widget gallery.
struct OverviewView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    private let columns = [GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 18)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                howToCard
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(WidgetCatalog.all) { definition in
                        WidgetCard(definition: definition)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("Widget Studio", "Widget Studio"))
                .font(.largeTitle.weight(.semibold))
            Text(L("Виджеты для рабочего стола macOS. Настройте внешний вид — системные виджеты подхватят его автоматически.",
                   "Widgets for the macOS desktop. Customize the look — the system widgets pick it up automatically."))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("Как добавить виджет на рабочий стол", "How to add a widget to the desktop"),
                  systemImage: "hand.tap")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                step(1, L("Правый клик (или два пальца) по свободному месту рабочего стола",
                          "Right-click (or tap with two fingers) an empty spot on the desktop"))
                step(2, L("Выберите «Изменить виджеты…»", "Choose “Edit Widgets…”"))
                step(3, L("В списке слева выберите Widget Studio и перетащите виджет на рабочий стол",
                          "Pick Widget Studio in the list on the left and drag a widget onto the desktop"))
            }

            HStack(spacing: 10) {
                Button {
                    state.reloadSystemWidgets()
                } label: {
                    Label(L("Обновить виджеты", "Reload widgets"), systemImage: "arrow.clockwise")
                }
                Text(L("Перетаскивание, размер и удаление виджетов делает сама macOS. Если виджет на рабочем столе выглядит пустым — уберите его и добавьте заново.",
                       "Dragging, resizing and removing widgets is handled by macOS. If a widget on the desktop looks empty, remove it and add it again."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.accentColor.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(number).")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
        }
    }
}

/// One widget kind in the overview grid.
private struct WidgetCard: View {
    let definition: WidgetDefinition

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                WallpaperBackdrop()
                WidgetPreview(definition: definition,
                              settings: state.existingProfile(for: definition.id)?.bag ?? definition.bag([:]),
                              size: definition.defaultSize,
                              maxSize: CGSize(width: 160, height: 140))
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: definition.symbol)
                        .foregroundStyle(.secondary)
                    Text(definition.name.value)
                        .font(.headline)
                }
                Text(definition.summary.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(L("системный виджет", "system widget"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        state.selection = .widget(definition.id)
                    } label: {
                        Label(L("Настроить", "Customize"), systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                }
        }
    }
}
