import AppKit
import SwiftUI

/// Shows the Dock icon while the main window is open and hides it when the
/// window closes, so the app keeps running from the menu bar.
@MainActor
final class MainWindowLifecycle: ObservableObject {
    func mainWindowDidOpen() {
        setActivationPolicy(.regular)
    }

    func mainWindowDidClose() {
        setActivationPolicy(.accessory)
    }

    func activateApp() {
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setActivationPolicy(_ policy: NSApplication.ActivationPolicy) {
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }
    }
}

struct MainWindowLifecycleObserver: NSViewRepresentable {
    let lifecycle: MainWindowLifecycle

    func makeCoordinator() -> Coordinator {
        Coordinator(lifecycle: lifecycle)
    }

    func makeNSView(context: Context) -> ObservingView {
        let view = ObservingView()
        view.onWindowChanged = { context.coordinator.observe(window: $0) }
        return view
    }

    func updateNSView(_ nsView: ObservingView, context: Context) {}

    final class ObservingView: NSView {
        var onWindowChanged: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChanged?(window)
        }
    }

    @MainActor
    final class Coordinator {
        private let lifecycle: MainWindowLifecycle
        private weak var observedWindow: NSWindow?
        private var closeObserver: NSObjectProtocol?

        init(lifecycle: MainWindowLifecycle) {
            self.lifecycle = lifecycle
        }

        deinit {
            if let closeObserver {
                NotificationCenter.default.removeObserver(closeObserver)
            }
        }

        func observe(window: NSWindow?) {
            guard let window, observedWindow !== window else {
                return
            }

            if let closeObserver {
                NotificationCenter.default.removeObserver(closeObserver)
            }

            observedWindow = window
            lifecycle.mainWindowDidOpen()
            closeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak lifecycle] _ in
                Task { @MainActor in
                    lifecycle?.mainWindowDidClose()
                }
            }
        }
    }
}
