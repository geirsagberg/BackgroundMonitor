import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var viewModel: JobsViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Window") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        if viewModel.visibleJobs.isEmpty {
            Text("No background processes")
        } else {
            ForEach(viewModel.visibleJobs) { job in
                Menu("\(job.name) — \(job.directoryText ?? String(job.pid))") {
                    Button("Kill") { viewModel.kill(job) }
                    Button("Force Kill") { viewModel.kill(job, force: true) }
                    Divider()
                    Button(job.isIgnored ? "Unignore" : "Ignore") {
                        viewModel.setIgnored(job, !job.isIgnored)
                    }
                }
            }
        }

        Divider()

        Button("Quit BackgroundMonitor") {
            NSApp.terminate(nil)
        }
    }
}
