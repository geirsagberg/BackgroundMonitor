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
}
