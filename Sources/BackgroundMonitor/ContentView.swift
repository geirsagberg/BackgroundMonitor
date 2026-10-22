import AppKit
import BackgroundMonitorCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JobsViewModel
    @ObservedObject var tmuxViewModel: TmuxViewModel
    @State private var showsTmux = false
    @State private var searchQuery = ""
    @State private var isRefreshing = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text("BackgroundMonitor")
                        .font(.system(size: 22, weight: .semibold))
                        .fixedSize()

                    Text("\(displayedCount)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("View", selection: $showsTmux) {
                        Text("Processes").tag(false)
                        Text("tmux").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()

                    Button {
                        let refreshesTmux = showsTmux
                        isRefreshing = true
                        Task {
                            defer { isRefreshing = false }
                            if refreshesTmux {
                                await tmuxViewModel.refresh()
                            } else {
                                await viewModel.refresh()
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(isRefreshing)
                    .help("Refresh (⌘R)")
                    .accessibilityLabel("Refresh")
                }

                HStack(spacing: 12) {
                    FilterField(text: $searchQuery, isFocused: $isSearchFieldFocused, showsTmux: showsTmux)
                        .frame(minWidth: 120, maxWidth: .infinity)

                    if !showsTmux {
                        Picker("Sort", selection: $viewModel.sortOrder) {
                            ForEach(JobSortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        .help("Sort processes")

                        Toggle("Show ignored", isOn: $viewModel.showsIgnored)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .fixedSize()
                            .help("Show processes you have ignored")

                        Button {
                            viewModel.showsIgnoreRules = true
                        } label: {
                            Image(systemName: "eye.slash")
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.bordered)
                        .help("Ignore rules")
                        .accessibilityLabel("Ignore rules")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if showsTmux {
                TmuxSessionsView(viewModel: tmuxViewModel, searchQuery: searchQuery)
            } else if displayedJobs.isEmpty {
                EmptyStateView(
                    hasScanned: viewModel.hasScanned,
                    searchQuery: $searchQuery,
                    ignoredCount: viewModel.showsIgnored ? 0 : viewModel.ignoredCount,
                    showIgnored: { viewModel.showsIgnored = true }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(displayedJobs) { job in
                            JobRow(job: job, viewModel: viewModel)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .focusJobFilter)) { _ in
            isSearchFieldFocused = true
        }
        .sheet(isPresented: $viewModel.showsIgnoreRules) {
            IgnoreRulesView(viewModel: viewModel)
        }
        .alert(item: $viewModel.alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var displayedCount: Int {
        showsTmux ? tmuxViewModel.sessions.filter { $0.matchesSearchQuery(searchQuery) }.count : displayedJobs.count
    }

    private var displayedJobs: [JobPresentation] {
        viewModel.visibleJobs.filter { $0.matchesSearchQuery(searchQuery) }
    }
}

private struct FilterField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let showsTmux: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(showsTmux ? "Filter sessions" : "Filter processes", text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .accessibilityHint(showsTmux ? "Filters by session name or socket." : "Filters by name, command, folder, PID, or terminal.")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear filter")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }
}

private struct EmptyStateView: View {
    let hasScanned: Bool
    @Binding var searchQuery: String
    let ignoredCount: Int
    let showIgnored: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            if !hasScanned {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: searchQuery.isEmpty ? "terminal" : "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                Text(searchQuery.isEmpty ? "No background processes" : "No matching processes")
                    .font(.headline)

                if !searchQuery.isEmpty {
                    Button("Clear Filter") { searchQuery = "" }
                        .buttonStyle(.bordered)
                } else if ignoredCount > 0 {
                    Button("Show \(ignoredCount) Ignored") { showIgnored() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(32)
    }
}

private struct JobRow: View {
    let job: JobPresentation
    @ObservedObject var viewModel: JobsViewModel

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(job.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    if let directory = job.directoryText {
                        Text(directory)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }

                Text(job.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(job.command)
                    .textSelection(.enabled)

                HStack(spacing: 6) {
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        Badge(text: job.uptimeText(now: context.date), systemImage: "clock", accessibilityLabel: "Uptime")
                    }
                    Badge(text: job.memoryText, systemImage: "memorychip", accessibilityLabel: "Memory")
                    Badge(text: "PID \(job.pid)")
                    Badge(text: job.terminalText, accessibilityLabel: "Terminal")
                    if let processCount = job.processCountText {
                        Badge(text: processCount)
                    }
                    if job.isIgnored {
                        Badge(text: "Ignored")
                    }
                }
            }

            Spacer(minLength: 4)

            Button(role: .destructive) {
                viewModel.kill(job)
            } label: {
                // Only the icon is red; red text on a bordered button is hard to read in dark mode.
                Label {
                    Text("Kill")
                } icon: {
                    Image(systemName: "stop.circle")
                        .foregroundStyle(.red)
                }
            }
            .help("Send SIGTERM to \(job.name) and its children")
            .accessibilityLabel("Kill \(job.name)")

            Menu {
                Button(role: .destructive) {
                    viewModel.kill(job, force: true)
                } label: {
                    Label("Force Kill", systemImage: "xmark.octagon")
                }
                .help("Send SIGKILL to \(job.name) and its children")

                Divider()

                if !job.isIgnored {
                    Button {
                        viewModel.ignore(job)
                    } label: {
                        Label("Ignore", systemImage: "eye.slash")
                    }
                } else if viewModel.canUnignore(job) {
                    Button {
                        viewModel.unignore(job)
                    } label: {
                        Label("Unignore", systemImage: "eye")
                    }
                } else {
                    Button {
                        viewModel.showsIgnoreRules = true
                    } label: {
                        Label("Edit Ignore Rules…", systemImage: "eye.slash")
                    }
                }

                Button {
                    viewModel.copyCommand(job)
                } label: {
                    Label("Copy Command", systemImage: "doc.on.doc")
                }

                Button {
                    viewModel.revealDirectory(job)
                } label: {
                    Label("Show Folder in Finder", systemImage: "folder")
                }
                .disabled(job.directory == nil)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 26, height: 26)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("More actions")
            .accessibilityLabel("More actions for \(job.name)")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
        .opacity(job.isIgnored ? 0.6 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Background process \(job.name)")
    }
}

struct Badge: View {
    let text: String
    var systemImage: String?
    var accessibilityLabel: String?

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            Text(text)
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
        )
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel ?? text)
        .accessibilityValue(accessibilityLabel == nil ? "" : text)
    }
}
