import AppKit
import SwiftUI

/// Borderless panel that hosts one widget.
///
/// It is a non-activating panel: clicking a widget does not steal focus from the
/// application you are working in, which is exactly how the system widgets behave.
final class WidgetWindow: NSPanel {

    let instanceID: UUID

    init(instanceID: UUID, frame: NSRect) {
        self.instanceID = instanceID
        super.init(contentRect: frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        animationBehavior = .none
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
