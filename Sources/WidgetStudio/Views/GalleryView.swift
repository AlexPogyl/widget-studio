import SwiftUI

/// The gallery: every widget the app can draw, with a live preview and an
/// "add to desktop" button.
struct GalleryView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    private let columns = [GridItem(.adaptive(minimum: 250, maximum: 340), spacing: 18)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Галерея виджетов", "Widget gallery"))
                        .font(.title2.weight(.semibold))
                    Text(L("Выберите виджет — он появится на рабочем столе, а все его настройки станут доступны в этом окне.",
                           "Pick a widget — it appears on the desktop and every option becomes available in this window."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(WidgetCatalog.all) { definition in
                        GalleryCard(definition: definition)
                    }
                }

                Text(L("Новые виджеты добавляются в один файл: создайте WidgetDefinition и допишите его в WidgetCatalog.all.",
                       "New widgets live in a single file: create a WidgetDefinition and append it to WidgetCatalog.all."))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct GalleryCard: View {
    let definition: WidgetDefinition

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                WallpaperBackdrop()
                WidgetPreview(definition: definition,
                              settings: definition.bag([:]),
                              size: definition.defaultSize,
                              maxSize: CGSize(width: 150, height: 130))
            }
            .frame(height: 170)
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
                    Text("\(Int(definition.defaultSize.width)) × \(Int(definition.defaultSize.height))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        state.addWidget(kind: definition.id)
                    } label: {
                        Label(L("Добавить", "Add"), systemImage: "plus")
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
