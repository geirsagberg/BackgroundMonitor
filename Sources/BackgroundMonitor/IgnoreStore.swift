import Foundation

/// Persists ignore patterns in `~/Library/Application Support/BackgroundMonitor/Ignored.json`.
final class IgnoreStore {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let directoryURL = baseURL.appendingPathComponent("BackgroundMonitor", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.fileURL = directoryURL.appendingPathComponent("Ignored.json")
    }

    func load() -> Set<String> {
        guard let data = try? Data(contentsOf: fileURL),
              let patterns = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(patterns)
    }

    func save(_ patterns: Set<String>) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        // The ignore list should never stop the monitor from working.
        try? encoder.encode(patterns.sorted()).write(to: fileURL, options: .atomic)
    }
}
