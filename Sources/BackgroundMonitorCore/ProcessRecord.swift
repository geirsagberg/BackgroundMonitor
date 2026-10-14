import Foundation

public struct ProcessRecord: Equatable, Sendable {
    public let pid: Int32
    public let parentPID: Int32
    public let processGroupID: Int32
    public let terminalProcessGroupID: Int32
    public let userID: UInt32
    /// Controlling terminal name, such as `ttys004`, or nil when detached.
    public let terminal: String?
    public let name: String
    public let startDate: Date

    public init(
        pid: Int32,
        parentPID: Int32,
        processGroupID: Int32,
        terminalProcessGroupID: Int32 = 0,
        userID: UInt32,
        terminal: String? = nil,
        name: String,
        startDate: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.pid = pid
        self.parentPID = parentPID
        self.processGroupID = processGroupID
        self.terminalProcessGroupID = terminalProcessGroupID
        self.userID = userID
        self.terminal = terminal
        self.name = name
        self.startDate = startDate
    }

    /// True when the process is the job a terminal is currently showing.
    public var isTerminalForeground: Bool {
        terminal != nil && processGroupID == terminalProcessGroupID
    }
}
