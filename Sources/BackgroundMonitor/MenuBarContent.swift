import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var viewModel: JobsViewModel
    @ObservedObject var tmuxViewModel: TmuxViewModel
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

        Menu("tmux Sessions") {
            if let error = tmuxViewModel.scanError {
                Text(error)
            } else if tmuxViewModel.sessions.isEmpty {
                Text(tmuxViewModel.hasScanned ? "No tmux sessions" : "Looking for sessions…")
            } else {
                ForEach(tmuxViewModel.sessions) { session in
                    Button("Open \(session.name)") { tmuxViewModel.open(session) }
                        .help(session.socketPath)
                }
            }
        }

        Divider()

        Button("Quit BackgroundMonitor") {
            NSApp.terminate(nil)
        }
    }
}
