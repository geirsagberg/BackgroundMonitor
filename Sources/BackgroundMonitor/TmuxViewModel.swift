import AppKit
import BackgroundMonitorCore
import Foundation
import UniformTypeIdentifiers

@MainActor
final class TmuxViewModel: ObservableObject {
    @Published private(set) var sessions: [TmuxSession] = []
    @Published private(set) var hasScanned = false
    @Published private(set) var scanError: String?
    @Published var alertMessage: AlertMessage?

    private var executablePath: String?
    private var refreshTask: Task<Void, Never>?

    init() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    deinit { refreshTask?.cancel() }

    func refresh() async {
        let result = await Task.detached(priority: .utility) {
            Result { try TmuxScanner.scan() }
        }.value
        switch result {
        case .success(let snapshot):
            if sessions != snapshot.sessions { sessions = snapshot.sessions }
            executablePath = snapshot.executablePath
            scanError = nil
        case .failure(let error):
            sessions = []
            executablePath = nil
            scanError = error.localizedDescription
        }
        hasScanned = true
    }

    func open(_ session: TmuxSession) {
        guard let executablePath else { return }
        let fileManager = FileManager.default
        let scriptURL = fileManager.temporaryDirectory.appendingPathComponent("BackgroundMonitor-\(UUID().uuidString).command")
        do {
            // Write with owner-only permissions from the start. The script deletes itself when run.
            guard fileManager.createFile(atPath: scriptURL.path,
                                         contents: Data(session.attachScript(executablePath: executablePath).utf8),
                                         attributes: [.posixPermissions: 0o700]) else {
                throw CocoaError(.fileWriteUnknown)
            }
            // iTerm2 can be the executable handler while .command files still belong to Terminal.
            guard let terminalURL = NSWorkspace.shared.urlForApplication(toOpen: UTType.unixExecutable) else {
                throw CocoaError(.fileReadUnknown, userInfo: [NSLocalizedDescriptionKey: "No default terminal is configured for Unix executables."])
            }
            NSWorkspace.shared.open([scriptURL], withApplicationAt: terminalURL, configuration: .init()) { [weak self] _, error in
                guard let error else { return }
                try? FileManager.default.removeItem(at: scriptURL)
                Task { @MainActor in
                    self?.alertMessage = AlertMessage(title: "Could not open \(session.name)", message: error.localizedDescription)
                }
            }
        } catch {
            try? fileManager.removeItem(at: scriptURL)
            alertMessage = AlertMessage(title: "Could not open \(session.name)", message: error.localizedDescription)
        }
    }
}
