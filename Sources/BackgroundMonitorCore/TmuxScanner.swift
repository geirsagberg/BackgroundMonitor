import Foundation

public struct TmuxSnapshot: Sendable {
    public let executablePath: String
    public let sessions: [TmuxSession]
}

public enum TmuxError: LocalizedError {
    case notInstalled
    case invalidOutput
    case scanFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Install tmux, then refresh."
        case .invalidOutput:
            return "tmux returned an unreadable session list."
        case .scanFailed(let message):
            return message
        }
    }
}

public enum TmuxScanner {
    static let format = "#{session_id}|#{session_windows}|#{session_attached}|#{session_name}"

    public static func scan() throws -> TmuxSnapshot {
        let environment = ProcessInfo.processInfo.environment
        guard let executable = executablePath(environment: environment) else {
            throw TmuxError.notInstalled
        }

        return try scan(executablePath: executable, socketPaths: socketPaths(environment: environment))
    }

    static func scan(executablePath executable: String, socketPaths: [String]) throws -> TmuxSnapshot {
        var sessions: [TmuxSession] = []
        for socket in socketPaths {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.environment = ProcessInfo.processInfo.environment.merging(["LC_ALL": "C"]) { _, value in value }
            process.arguments = ["-N", "-S", socket, "list-sessions", "-F", format]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = output
            try process.run()
            let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3, execute: timeout)
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            timeout.cancel()
            if process.terminationReason == .uncaughtSignal {
                throw TmuxError.scanFailed("tmux did not respond while listing sessions.")
            }
            let text = String(decoding: data, as: UTF8.self)
            guard process.terminationStatus == 0 else {
                // Socket files may outlive their server, or disappear during a refresh.
                if text.contains("Connection refused") || text.contains("No such file or directory")
                    || text.contains("no server running") || text.contains("no sessions") {
                    continue
                }
                throw TmuxError.scanFailed(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            sessions += try parse(text, socketPath: socket)
        }

        return TmuxSnapshot(executablePath: executable, sessions: sessions.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
        })
    }

    static func executablePath(environment: [String: String]) -> String? {
        // Finder-launched apps do not inherit the user's interactive shell PATH.
        let directories = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
            + ["/opt/homebrew/bin", "/usr/local/bin", NSHomeDirectory() + "/.local/bin"]
        return directories.map { $0 + "/tmux" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func socketPaths(environment: [String: String]) -> [String] {
        let fileManager = FileManager.default
        let roots = Set(["/tmp", environment["TMUX_TMPDIR"]].compactMap { $0 })
        var paths = Set<String>()
        for root in roots {
            let directory = URL(fileURLWithPath: root).appendingPathComponent("tmux-\(getuid())")
            let entries = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            for entry in entries {
                let attributes = try? fileManager.attributesOfItem(atPath: entry.path)
                if attributes?[.type] as? FileAttributeType == .typeSocket,
                   (attributes?[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() {
                    paths.insert(entry.resolvingSymlinksInPath().path)
                }
            }
        }
        if let tmux = environment["TMUX"] {
            let parts = tmux.components(separatedBy: ",")
            if parts.count >= 3 {
                let socket = parts.dropLast(2).joined(separator: ",")
                paths.insert(URL(fileURLWithPath: socket).resolvingSymlinksInPath().path)
            }
        }
        return paths.sorted()
    }

    static func parse(_ output: String, socketPath: String) throws -> [TmuxSession] {
        try output.split(separator: "\n").map { line in
            let fields = line.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
            guard fields.count == 4, fields[0].hasPrefix("$"),
                  Int(fields[0].dropFirst()) != nil,
                  let windows = Int(fields[1]), windows >= 0,
                  let attached = Int(fields[2]), attached >= 0 else {
                throw TmuxError.invalidOutput
            }
            return TmuxSession(socketPath: socketPath, sessionID: String(fields[0]),
                               name: String(fields[3]), windowCount: windows, attachedClients: attached)
        }
    }
}
