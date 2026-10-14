import Darwin
import Foundation

/// Glob patterns matched against a job's full command line.
/// `*` and `?` match any characters, including `/` and spaces.
public struct IgnoreRules: Equatable, Sendable {
    public var patterns: Set<String>

    public init(patterns: Set<String> = []) {
        self.patterns = patterns
    }

    public func matches(_ command: String) -> Bool {
        patterns.contains { Self.pattern($0, matches: command) }
    }

    public static func pattern(_ pattern: String, matches command: String) -> Bool {
        fnmatch(pattern, command, 0) == 0
    }

    /// A pattern that matches only this exact command line.
    public static func exactPattern(for command: String) -> String {
        var pattern = ""
        for character in command {
            if "\\*?[".contains(character) {
                pattern.append("\\")
            }
            pattern.append(character)
        }
        return pattern
    }
}
