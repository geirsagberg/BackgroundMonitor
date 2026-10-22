import BackgroundMonitorCore
import SwiftUI

struct TmuxSessionsView: View {
    @ObservedObject var viewModel: TmuxViewModel
    let searchQuery: String

    private var sessions: [TmuxSession] {
        viewModel.sessions.filter { $0.matchesSearchQuery(searchQuery) }
    }

    var body: some View {
        Group {
            if !viewModel.hasScanned {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.scanError {
                VStack(spacing: 14) {
                    Image(systemName: "terminal").font(.system(size: 32)).foregroundStyle(.secondary)
                    Text("Could not list tmux sessions").font(.headline)
                    Text(error).foregroundStyle(.secondary).multilineTextAlignment(.center).textSelection(.enabled)
                    Button("Refresh") { Task { await viewModel.refresh() } }
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sessions.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: searchQuery.isEmpty ? "terminal" : "magnifyingglass")
                        .font(.system(size: 32)).foregroundStyle(.secondary)
                    Text(searchQuery.isEmpty ? "No tmux sessions" : "No matching sessions").font(.headline)
                    if searchQuery.isEmpty {
                        Text("Start a session with tmux new -s name.").foregroundStyle(.secondary)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sessions) { session in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(session.name).font(.system(size: 14, weight: .semibold))
                                    HStack(spacing: 6) {
                                        Badge(text: "\(session.windowCount) \(session.windowCount == 1 ? "window" : "windows")")
                                        Badge(text: session.attachedClients == 0 ? "Detached" : "Attached")
                                    }
                                    Text(session.socketPath)
                                        .font(.caption).foregroundStyle(.secondary)
                                        .lineLimit(1).truncationMode(.middle).help(session.socketPath)
                                }
                                Spacer(minLength: 4)
                                Button { viewModel.open(session) } label: {
                                    Label("Open", systemImage: "terminal")
                                }
                                .help("Attach to \(session.name) in your default terminal")
                                .accessibilityLabel("Open tmux session \(session.name)")
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1))
                        }
                    }
                    .padding(14)
                }
            }
        }
        .alert(item: $viewModel.alertMessage) { message in
            Alert(title: Text(message.title), message: Text(message.message), dismissButton: .default(Text("OK")))
        }
    }
}
