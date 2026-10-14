import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var viewModel: JobsViewModel
    let mainWindowLifecycle: MainWindowLifecycle
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Window") {
            mainWindowLifecycle.mainWindowDidOpen()
            openWindow(id: "main")
            mainWindowLifecycle.activateApp()
        }

        Divider()

        if viewModel.visibleJobs.isEmpty {
            Text("No background processes")
        } else {
            ForEach(viewModel.visibleJobs) { job in
                Menu("\(job.name) — \(job.directoryText ?? String(job.pid))") {
                    Button("Kill", role: .destructive) { viewModel.kill(job) }
                    Button("Force Kill", role: .destructive) { viewModel.kill(job, force: true) }
                    Divider()
                    Button("Ignore") { viewModel.ignore(job) }
                }
            }
        }

        Divider()

        Button("Quit BackgroundMonitor") {
            NSApp.terminate(nil)
        }
    }
}
