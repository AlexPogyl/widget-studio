import AppKit
import SwiftUI

/// Root view of a widget window: rendering, hover controls, dragging, snapping
/// and the context menu.
struct WidgetHostView: View {
    @ObservedObject var instance: WidgetInstance

    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var localization: Localization

    @State private var hovering = false
    /// Offset between the mouse pointer and the widget centre when a drag starts.
    @State private var dragAnchor: CGPoint?

    var body: some View {
        let definition = instance.definition
        let settings = instance.bag

        TimelineView(.periodic(from: Date(), by: 1)) { timeline in
            WidgetSurface(definition: definition, settings: settings, date: timeline.date, size: instance.size)
        }
        .frame(width: instance.size.width, height: instance.size.height)
        .overlay(alignment: .topTrailing) { hoverControls }
        .overlay { selectionOutline }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .gesture(dragGesture)
        .contextMenu { contextMenu }
    }

    // MARK: - Hover controls

    @ViewBuilder
    private var hoverControls: some View {
        if hovering && state.app.showHoverControls && !instance.locked {
            HStack(spacing: 6) {
                WidgetCircleButton(systemImage: "slider.horizontal.3",
                                   help: L("Настроить виджет", "Customize widget")) {
                    openInspector()
                }
                WidgetCircleButton(systemImage: "xmark",
                                   help: L("Скрыть виджет", "Hide widget")) {
                    instance.hidden = true
                }
            }
            .padding(8)
            .transition(.opacity)
        } else if hovering && instance.locked {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(8)
        }
    }

    @ViewBuilder
    private var selectionOutline: some View {
        if hovering && state.app.showHoverControls {
            RoundedRectangle(cornerRadius: max(instance.bag.double("common.cornerRadius"), 6), style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.85),
                              style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .padding(1)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Dragging

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { _ in
                guard !instance.locked else { return }
                let mouse = NSEvent.mouseLocation
                if dragAnchor == nil {
                    dragAnchor = CGPoint(x: instance.center.x - mouse.x,
                                         y: instance.center.y - mouse.y)
                }
                guard let anchor = dragAnchor else { return }
                instance.center = CGPoint(x: mouse.x + anchor.x, y: mouse.y + anchor.y)
            }
            .onEnded { _ in
                guard dragAnchor != nil else { return }
                dragAnchor = nil
                snapToGridAndEdges()
            }
    }

    private func snapToGridAndEdges() {
        guard state.app.snapToGrid else { return }
        let grid = max(state.app.gridSize, 1)
        var center = instance.center
        center.x = (center.x / grid).rounded() * grid
        center.y = (center.y / grid).rounded() * grid

        if let visible = state.screen(containing: center)?.visibleFrame {
            let halfWidth = instance.size.width / 2
            let halfHeight = instance.size.height / 2
            let margin: CGFloat = 14
            if abs(center.x - (visible.minX + halfWidth)) < margin { center.x = visible.minX + halfWidth }
            if abs(center.x - (visible.maxX - halfWidth)) < margin { center.x = visible.maxX - halfWidth }
            if abs(center.y - (visible.minY + halfHeight)) < margin { center.y = visible.minY + halfHeight }
            if abs(center.y - (visible.maxY - halfHeight)) < margin { center.y = visible.maxY - halfHeight }
        }
        instance.center = center
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenu: some View {
        Button(L("Настроить…", "Customize…")) { openInspector() }
        Button(L("Дублировать", "Duplicate")) { state.duplicate(instance) }
        Button(L("По центру экрана", "Center on screen")) { state.centerOnScreen(instance) }

        Divider()

        ForEach(WidgetLevel.allCases) { level in
            Button {
                instance.level = level
            } label: {
                Label(level.title.value,
                      systemImage: instance.level == level ? "checkmark" : level.symbol)
            }
        }

        Divider()

        Button(instance.locked ? L("Разблокировать", "Unlock") : L("Заблокировать", "Lock")) {
            instance.locked.toggle()
        }
        Button(L("Скрыть", "Hide")) { instance.hidden = true }
        Button(L("Сбросить оформление", "Reset appearance")) { instance.applyDefaultSettings() }

        Divider()

        Button(L("Удалить виджет", "Delete widget"), role: .destructive) {
            state.remove(instance)
        }
    }

    private func openInspector() {
        AppEnvironment.shared.settingsWindow?.show(selecting: instance.id)
    }
}
