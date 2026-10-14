import Foundation

public struct JobPresentation: Identifiable, Equatable, Sendable {
    public let job: BackgroundJob
    public let name: String
    public let command: String
    public let directory: String?
    public let memoryBytes: UInt64
    public let isIgnored: Bool

    public init(
        job: BackgroundJob,
        name: String,
        command: String,
        directory: String?,
        memoryBytes: UInt64,
        isIgnored: Bool
    ) {
        self.job = job
        self.name = name
        self.command = command
        self.directory = directory
        self.memoryBytes = memoryBytes
        self.isIgnored = isIgnored
    }

    public var id: Int32 { job.process.pid }
    public var pid: Int32 { job.process.pid }

    public var processCountText: String? {
        let count = job.descendantPIDs.count
        guard count > 0 else { return nil }
        return count == 1 ? "+1 child" : "+\(count) children"
    }

    public var directoryText: String? {
        directory.map { Self.abbreviatingHome($0) }
    }

    public var terminalText: String {
        job.process.terminal ?? "Detached"
    }

    public var memoryText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }

    public func uptimeText(now: Date = Date()) -> String {
        Self.durationText(now.timeIntervalSince(job.process.startDate))
    }

    public func matchesSearchQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return [name, command, directory ?? "", String(pid), terminalText]
            .contains { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    static func durationText(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let days = seconds / 86_400
        let hours = seconds % 86_400 / 3_600
        let minutes = seconds % 3_600 / 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(seconds)s"
    }

    /// Shortens paths in the home folder to `~/…`.
    public static func abbreviatingHome(_ path: String, home: String = NSHomeDirectory()) -> String {
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}
