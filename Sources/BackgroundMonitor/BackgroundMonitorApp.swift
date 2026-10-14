import AppKit
import SwiftUI

@main
struct BackgroundMonitorApp: App {
    @StateObject private var viewModel = JobsViewModel()
    @StateObject private var mainWindowLifecycle = MainWindowLifecycle()

    var body: some Scene {
        Window("BackgroundMonitor", id: "main") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 360)
                .background(MainWindowLifecycleObserver(lifecycle: mainWindowLifecycle))
        }
        .defaultSize(width: 820, height: 520)
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
            MenuBarContent(viewModel: viewModel, mainWindowLifecycle: mainWindowLifecycle)
        }
    }
}

extension Notification.Name {
    static let focusJobFilter = Notification.Name("BackgroundMonitor.focusJobFilter")
}
