import AppKit
import SwiftUI

@main
struct BackgroundMonitorApp: App {
    @StateObject private var viewModel = JobsViewModel()
    @StateObject private var tmuxViewModel = TmuxViewModel()
    @StateObject private var mainWindowLifecycle = MainWindowLifecycle()

    var body: some Scene {
        Window("BackgroundMonitor", id: "main") {
            ContentView(viewModel: viewModel, tmuxViewModel: tmuxViewModel)
                .frame(minWidth: 600, minHeight: 360)
                .background(MainWindowLifecycleObserver(lifecycle: mainWindowLifecycle))
        }
        .defaultSize(width: 820, height: 520)
        // The content expands freely; only its minimum size should constrain the window.
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .textEditing) {
                Button("Find…") {
                    NotificationCenter.default.post(name: .focusJobFilter, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }

        MenuBarExtra("BackgroundMonitor", systemImage: "terminal") {
            MenuBarContent(viewModel: viewModel, tmuxViewModel: tmuxViewModel, mainWindowLifecycle: mainWindowLifecycle)
        }
    }
}

extension Notification.Name {
    static let focusJobFilter = Notification.Name("BackgroundMonitor.focusJobFilter")
}
