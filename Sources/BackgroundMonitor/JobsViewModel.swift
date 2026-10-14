import AppKit
import BackgroundMonitorCore
import Foundation

struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum JobSortOrder: String, CaseIterable, Identifiable {
    case name = "Name"
    case pid = "PID"

    var id: Self { self }
}

@MainActor
final class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobPresentation] = []
    @Published private(set) var hasScanned = false
    @Published var showsIgnored = false
    @Published var sortOrder: JobSortOrder {
        didSet { UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder") }
    }
    @Published var alertMessage: AlertMessage?

    private var ignoredCommands: Set<String>
    private let ignoreStore: IgnoreStore
    private var refreshTask: Task<Void, Never>?

    init(ignoreStore: IgnoreStore = IgnoreStore()) {
        self.ignoreStore = ignoreStore
        self.ignoredCommands = ignoreStore.load()
        self.sortOrder = UserDefaults.standard.string(forKey: "sortOrder")
            .flatMap(JobSortOrder.init(rawValue:)) ?? .name

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    var visibleJobs: [JobPresentation] {
        let shownJobs = showsIgnored ? jobs : jobs.filter { !$0.isIgnored }

        switch sortOrder {
        case .name:
            return shownJobs.sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.pid < $1.pid : order == .orderedAscending
            }
        case .pid:
            return shownJobs.sorted { $0.pid < $1.pid }
        }
    }

    var ignoredCount: Int {
        jobs.filter(\.isIgnored).count
    }

    func refresh() async {
        let ignoredCommands = ignoredCommands
        let scannedJobs = await Task.detached(priority: .utility) {
            JobScanner.scan(ignoredCommands: ignoredCommands)
        }.value

        if scannedJobs != jobs {
            jobs = scannedJobs
        }
        hasScanned = true
    }

    func kill(_ presentation: JobPresentation, force: Bool = false) {
        do {
            try ProcessKiller.kill(presentation.job, force: force)
        } catch {
            alertMessage = AlertMessage(
                title: "Could not stop \(presentation.name)",
                message: error.localizedDescription
            )
        }

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await refresh()
        }
    }

    func setIgnored(_ presentation: JobPresentation, _ isIgnored: Bool) {
        if isIgnored {
            ignoredCommands.insert(presentation.command)
        } else {
            ignoredCommands.remove(presentation.command)
        }
        ignoreStore.save(ignoredCommands)
        Task { await refresh() }
    }

    func copyCommand(_ presentation: JobPresentation) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(presentation.command, forType: .string)
    }

    func revealDirectory(_ presentation: JobPresentation) {
        guard let directory = presentation.directory else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory)
    }
}
