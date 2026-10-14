import Foundation

public struct BackgroundJob: Equatable, Sendable {
    public let process: ProcessRecord
    /// Every process started by the job, at any depth.
    public let descendantPIDs: [Int32]

    public init(process: ProcessRecord, descendantPIDs: [Int32]) {
        self.process = process
        self.descendantPIDs = descendantPIDs
    }
}

/// Finds processes the user started from a shell that are no longer the
/// foreground job of a terminal.
///
/// A job is a user-owned process that is not a shell, not in a terminal's
/// foreground, and either has a shell ancestor or was orphaned while still
/// attached to a terminal. Processes started by a job are rolled into it.
public enum BackgroundJobFinder {
    public static let shellNames: Set<String> = [
        "sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "csh", "nu", "pwsh"
    ]

    public static func jobs(in processes: [ProcessRecord], userID: UInt32) -> [BackgroundJob] {
        let processesByPID = Dictionary(processes.map { ($0.pid, $0) }, uniquingKeysWith: { first, _ in first })
        var childrenByPID: [Int32: [Int32]] = [:]
        for process in processes where process.pid != process.parentPID {
            childrenByPID[process.parentPID, default: []].append(process.pid)
        }

        func ancestors(of process: ProcessRecord) -> [ProcessRecord] {
            var result: [ProcessRecord] = []
            var visited: Set<Int32> = [process.pid]
            var parentPID = process.parentPID

            while parentPID > 1, visited.insert(parentPID).inserted, let parent = processesByPID[parentPID] {
                result.append(parent)
                parentPID = parent.parentPID
            }

            return result
        }

        func isCandidate(_ process: ProcessRecord) -> Bool {
            guard process.userID == userID,
                  !isShell(process),
                  !process.isTerminalForeground
            else {
                return false
            }

            if process.parentPID == 1 {
                return process.terminal != nil
            }

            return ancestors(of: process).contains(where: isShell)
        }

        func descendants(of pid: Int32) -> [Int32] {
            var result: [Int32] = []
            var visited: Set<Int32> = [pid]
            var queue = childrenByPID[pid] ?? []

            while let next = queue.popLast() {
                guard visited.insert(next).inserted else { continue }
                result.append(next)
                queue.append(contentsOf: childrenByPID[next] ?? [])
            }

            return result
        }

        let candidatePIDs = Set(processes.filter(isCandidate).map(\.pid))

        return processes
            .filter { candidatePIDs.contains($0.pid) }
            .filter { process in
                !ancestors(of: process).contains { candidatePIDs.contains($0.pid) }
            }
            .sorted { $0.startDate > $1.startDate }
            .map { BackgroundJob(process: $0, descendantPIDs: descendants(of: $0.pid)) }
    }

    public static func isShell(_ process: ProcessRecord) -> Bool {
        var name = Substring(process.name)
        if name.hasPrefix("-") {
            name = name.dropFirst()
        }

        return shellNames.contains(String(name))
    }
}
