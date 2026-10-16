import AppKit
import Combine
import SwiftUI

/// Creates one `WidgetWindow` per `WidgetInstance` and keeps the windows in sync
/// with the model (size, position, stacking level, visibility).
final class WidgetWindowManager {

    private let state: AppState
    private var windows: [UUID: WidgetWindow] = [:]
    private var instanceObservers: [UUID: AnyCancellable] = [:]
    private var cancellables: Set<AnyCancellable> = []

    init(state: AppState) {
        self.state = state
        observeState()
        sync()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screensChanged),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Observation

    private func observeState() {
        state.$widgets
            .sink { [weak self] widgets in
                guard let self else { return }
                self.sync()
                self.observeInstances(widgets)
            }
            .store(in: &cancellables)

        state.$widgetsHidden
            .sink { [weak self] _ in self?.applyVisibility() }
            .store(in: &cancellables)

        state.$app
            .sink { [weak self] _ in self?.applyAll() }
            .store(in: &cancellables)
    }

    private func observeInstances(_ widgets: [WidgetInstance]) {
        let ids = Set(widgets.map { $0.id })
        for id in instanceObservers.keys where !ids.contains(id) {
            instanceObservers[id] = nil
        }
        for widget in widgets where instanceObservers[widget.id] == nil {
            instanceObservers[widget.id] = widget.objectWillChange
                .sink { [weak self, weak widget] _ in
                    guard let self, let widget else { return }
                    // objectWillChange fires before the value is updated.
                    DispatchQueue.main.async { self.apply(widget) }
                }
        }
    }

    @objc private func screensChanged() {
        clampToScreens()
        applyAll()
    }

    // MARK: - Sync

    private func sync() {
        let ids = Set(state.widgets.map { $0.id })

        for (id, window) in windows where !ids.contains(id) {
            window.orderOut(nil)
            window.contentView = nil
            windows[id] = nil
        }

        for instance in state.widgets where windows[instance.id] == nil {
            let window = WidgetWindow(instanceID: instance.id, frame: instance.frame)
            let root = WidgetHostView(instance: instance)
                .environmentObject(state)
                .environmentObject(Localization.shared)
            let hosting = NSHostingView(rootView: root)
            hosting.layer?.backgroundColor = NSColor.clear.cgColor
            window.contentView = hosting
            windows[instance.id] = window
            apply(instance)
            window.orderFrontRegardless()
        }
    }

    func applyAll() {
        for instance in state.widgets { apply(instance) }
        applyVisibility()
    }

    private func applyVisibility() {
        for instance in state.widgets {
            guard let window = windows[instance.id] else { continue }
            if state.widgetsHidden || instance.hidden {
                window.orderOut(nil)
            } else {
                window.orderFrontRegardless()
            }
        }
    }

    /// Pushes the model into the window. Never writes back to the model.
    private func apply(_ instance: WidgetInstance) {
        guard let window = windows[instance.id] else { return }

        let level = instance.level.windowLevel
        if window.level != level { window.level = level }

        let behavior: NSWindow.CollectionBehavior = instance.level == .normal
            ? [.managed, .participatesInCycle]
            : [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        if window.collectionBehavior != behavior { window.collectionBehavior = behavior }

        window.ignoresMouseEvents = instance.clickThrough
        window.hasShadow = instance.bag.bool("common.shadow")

        let frame = instance.frame
        if !frame.equalTo(window.frame) {
            window.setFrame(frame, display: true, animate: false)
        }

        if state.widgetsHidden || instance.hidden {
            if window.isVisible { window.orderOut(nil) }
        } else if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    /// Brings widgets back on screen after a display configuration change.
    private func clampToScreens() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        for instance in state.widgets {
            let visible = screens.contains { screen in
                screen.visibleFrame.intersects(instance.frame)
            }
            guard !visible else { continue }
            let target = NSScreen.main?.visibleFrame ?? screens[0].visibleFrame
            instance.center = CGPoint(x: target.midX, y: target.midY)
        }
    }
}
