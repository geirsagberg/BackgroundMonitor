import Foundation

public enum JobScanner {
    public static func scan(ignoreRules: IgnoreRules) -> [JobPresentation] {
        let processes = ProcessTable.snapshot()
        let jobs = BackgroundJobFinder.jobs(in: processes, userID: getuid())

        return jobs.map { job in
            let arguments = ProcessTable.arguments(of: job.process.pid)
            let command = arguments.isEmpty ? job.process.name : arguments.joined(separator: " ")
            let memory = ([job.process.pid] + job.descendantPIDs)
                .reduce(UInt64(0)) { $0 + ProcessTable.residentMemory(of: $1) }

            return JobPresentation(
                job: job,
                name: displayName(arguments: arguments, fallback: job.process.name),
                command: command,
                directory: ProcessTable.workingDirectory(of: job.process.pid),
                memoryBytes: memory,
                isIgnored: ignoreRules.matches(command)
            )
        }
    }

    /// The kernel truncates process names to 16 characters, so prefer argv[0].
    static func displayName(arguments: [String], fallback: String) -> String {
        guard let first = arguments.first, !first.isEmpty else {
            return fallback
        }

        let name = (first as NSString).lastPathComponent
        return name.hasPrefix("-") ? String(name.dropFirst()) : name
    }
}
