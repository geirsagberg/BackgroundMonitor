import Foundation

public struct TmuxSession: Identifiable, Equatable, Sendable {
    public let socketPath: String
    public let sessionID: String
    public let name: String
    public let windowCount: Int
    public let attachedClients: Int

    public var id: String { "\(socketPath):\(sessionID)" }

    public init(socketPath: String, sessionID: String, name: String, windowCount: Int, attachedClients: Int) {
        self.socketPath = socketPath
        self.sessionID = sessionID
        self.name = name
        self.windowCount = windowCount
        self.attachedClients = attachedClients
    }

    public func matchesSearchQuery(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || name.localizedCaseInsensitiveContains(query)
            || socketPath.localizedCaseInsensitiveContains(query)
    }

    /// Use the server and stable session ID, so renames and duplicate names are harmless.
    public func attachScript(executablePath: String) -> String {
        let arguments = [executablePath, "-S", socketPath, "attach-session", "-t", sessionID]
            .map { "'" + $0.replacingOccurrences(of: "'", with: "'\"'\"'") + "'" }
            .joined(separator: " ")
        return "#!/bin/sh\n/bin/rm -f -- \"$0\"\nunset TMUX\nexec \(arguments)\n"
    }

    /// Ends the session and every window in it. A session that is already gone counts as killed.
    public func kill(executablePath: String) throws {
        guard let result = try TmuxCommand.run(executablePath, ["-N", "-S", socketPath, "kill-session", "-t", sessionID]) else {
            throw TmuxError.commandFailed("tmux did not respond while killing \(name).")
        }
        if result.status == 0 || TmuxCommand.isMissingServer(result.output) || result.output.contains("can't find session") {
            return
        }
        throw TmuxError.commandFailed(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
