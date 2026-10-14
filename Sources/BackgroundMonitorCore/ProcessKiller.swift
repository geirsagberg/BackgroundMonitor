import Darwin
import Foundation

public enum ProcessKillError: Error, LocalizedError, Sendable {
    case failed(pid: Int32, message: String)

    public var errorDescription: String? {
        switch self {
        case .failed(let pid, let message):
            return "Could not stop process \(pid): \(message)"
        }
    }
}

public enum ProcessKiller {
    /// Signals the job and every process it started, children first.
    /// Processes that already exited are skipped.
    public static func kill(_ job: BackgroundJob, force: Bool) throws {
        let signal = force ? SIGKILL : SIGTERM

        for pid in job.descendantPIDs.reversed() + [job.process.pid] {
            if Darwin.kill(pid, signal) != 0, errno != ESRCH {
                throw ProcessKillError.failed(pid: pid, message: String(cString: strerror(errno)))
            }
        }
    }
}
