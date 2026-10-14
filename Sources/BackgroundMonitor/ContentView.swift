import AppKit
import BackgroundMonitorCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JobsViewModel
    @State private var searchQuery = ""
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("BackgroundMonitor")
                    .font(.system(size: 22, weight: .semibold))
                    .fixedSize()

                Text("\(displayedJobs.count)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)

                FilterField(text: $searchQuery, isFocused: $isSearchFieldFocused)
                    .frame(minWidth: 120, maxWidth: .infinity)

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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if displayedJobs.isEmpty {
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
        .alert(item: $viewModel.alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var displayedJobs: [JobPresentation] {
        viewModel.visibleJobs.filter { $0.matchesSearchQuery(searchQuery) }
    }
}

private struct FilterField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Filter processes", text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)

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
                        Badge(text: job.uptimeText(now: context.date), systemImage: "clock")
                    }
                    Badge(text: job.memoryText, systemImage: "memorychip")
                    Badge(text: "PID \(job.pid)")
                    Badge(text: job.terminalText)
                    if let processCount = job.processCountText {
                        Badge(text: processCount)
                    }
                    if job.isIgnored {
                        Badge(text: "Ignored")
                    }
                }
            }

            Spacer(minLength: 4)

            Button("Kill") {
                viewModel.kill(job)
            }
            .help("Send SIGTERM to the process and its children")

            Menu {
                Button("Force Kill") {
                    viewModel.kill(job, force: true)
                }
                .help("Send SIGKILL to the process and its children")

                Divider()

                Button(job.isIgnored ? "Unignore" : "Ignore") {
                    viewModel.setIgnored(job, !job.isIgnored)
                }

                Button("Copy Command") {
                    viewModel.copyCommand(job)
                }

                Button("Show Folder in Finder") {
                    viewModel.revealDirectory(job)
                }
                .disabled(job.directory == nil)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
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
    }
}

private struct Badge: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
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
    }
}
