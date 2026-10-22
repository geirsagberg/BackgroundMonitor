import XCTest
@testable import BackgroundMonitorCore

final class TmuxTests: XCTestCase {
    func testDiscoversRealTmuxSessionsOnAnIsolatedServer() throws {
        guard let executable = TmuxScanner.executablePath(environment: ProcessInfo.processInfo.environment) else {
            throw XCTSkip("tmux is not installed")
        }
        // Keep the Unix socket path short enough for sockaddr_un on macOS.
        let socket = "/tmp/bgm-test-\(UUID().uuidString)"
        defer { _ = try? run(executable, ["-S", socket, "kill-server"]) }
        XCTAssertEqual(try run(executable, ["-f", "/dev/null", "-S", socket, "new-session", "-d", "-s", "monitor-test", "/bin/sleep", "60"]), 0)
        XCTAssertEqual(try run(executable, ["-S", socket, "new-window", "-t", "monitor-test:", "/bin/sleep", "60"]), 0)
        let snapshot = try TmuxScanner.scan(executablePath: executable, socketPaths: [socket])
        let session = try XCTUnwrap(snapshot.sessions.first)
        XCTAssertEqual(snapshot.sessions.count, 1)
        XCTAssertEqual(session.name, "monitor-test")
        XCTAssertEqual(session.windowCount, 2)
        XCTAssertEqual(session.attachedClients, 0)
        XCTAssertEqual(try run(executable, ["-S", socket, "rename-session", "-t", session.sessionID, "renamed"]), 0)
        let renamed = try XCTUnwrap(TmuxScanner.scan(executablePath: executable, socketPaths: [socket]).sessions.first)
        XCTAssertEqual(renamed.id, session.id)
        XCTAssertEqual(renamed.name, "renamed")
    }

    func testFindsInheritedSocketPathsContainingCommas() {
        let paths = TmuxScanner.socketPaths(environment: ["TMUX": "/tmp/custom,socket,123,0"])
        XCTAssertTrue(paths.contains(URL(fileURLWithPath: "/tmp/custom,socket").resolvingSymlinksInPath().path))
    }

    func testParsesSessionsAndPreservesNames() throws {
        let sessions = try TmuxScanner.parse("$1|2|0|dev server\n$3|1|2|work|project\n", socketPath: "/tmp/tmux-501/default")
        XCTAssertEqual(sessions.map(\.name), ["dev server", "work|project"])
        XCTAssertEqual(sessions.map(\.windowCount), [2, 1])
        XCTAssertEqual(sessions.map(\.attachedClients), [0, 2])
        XCTAssertEqual(sessions.map(\.sessionID), ["$1", "$3"])
        XCTAssertTrue(try TmuxScanner.parse("", socketPath: "/tmp/default").isEmpty)
    }

    func testRejectsMalformedSessionOutput() {
        for output in ["work: 2 windows", "$1|two|0|work", "$1|2|-1|work", "work|1|0|name"] {
            XCTAssertThrowsError(try TmuxScanner.parse(output, socketPath: "/tmp/default"))
        }
    }

    func testSessionIdentityIncludesServerAndSurvivesRename() throws {
        let first = try XCTUnwrap(TmuxScanner.parse("$1|1|0|work", socketPath: "/tmp/first").first)
        let renamed = try XCTUnwrap(TmuxScanner.parse("$1|1|0|other", socketPath: "/tmp/first").first)
        let otherServer = try XCTUnwrap(TmuxScanner.parse("$1|1|0|work", socketPath: "/tmp/second").first)
        XCTAssertEqual(first.id, renamed.id)
        XCTAssertNotEqual(first.id, otherServer.id)
        XCTAssertTrue(first.matchesSearchQuery(" WORK "))
        XCTAssertTrue(first.matchesSearchQuery("first"))
        XCTAssertFalse(first.matchesSearchQuery("other"))
    }

    func testScannerQueriesEachSocketWithoutStartingAServer() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("tmux")
        try writeExecutable("""
        #!/bin/sh
        [ "$1" = '-N' ] && [ "$2" = '-S' ] && [ "$4" = 'list-sessions' ] && [ "$5" = '-F' ] || exit 2
        case "$3" in
          */stale) echo 'error connecting: Connection refused' >&2; exit 1 ;;
          */first) printf '$1|2|0|zeta\n' ;;
          */second) printf '$1|1|1|alpha\n' ;;
        esac
        """, to: executable)
        let snapshot = try TmuxScanner.scan(executablePath: executable.path,
                                            socketPaths: ["/tmp/first", "/tmp/stale", "/tmp/second"])
        XCTAssertEqual(snapshot.sessions.map(\.name), ["alpha", "zeta"])
        XCTAssertEqual(Set(snapshot.sessions.map(\.id)).count, 2)
        XCTAssertEqual(snapshot.executablePath, executable.path)
    }

    func testScannerSurfacesServerErrors() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("tmux")
        try writeExecutable("#!/bin/sh\necho 'Permission denied' >&2\nexit 1\n", to: executable)
        XCTAssertThrowsError(try TmuxScanner.scan(executablePath: executable.path, socketPaths: ["/tmp/default"])) {
            XCTAssertEqual($0.localizedDescription, "Permission denied")
        }
    }

    func testAttachScriptPreservesArgumentsAndExistingClients() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("tmux ' $special `name`")
        try writeExecutable("#!/bin/sh\n[ -z \"${TMUX+x}\" ] || exit 2\nprintf '%s\\n' \"$@\"\n", to: executable)
        let socket = "/tmp/server's $socket `name`"
        let session = TmuxSession(socketPath: socket, sessionID: "$42", name: "work", windowCount: 1, attachedClients: 1)
        let script = directory.appendingPathComponent("Attach.command")
        try writeExecutable(session.attachScript(executablePath: executable.path), to: script)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [script.path]
        process.environment = ["TMUX": "old socket,123,0"]
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "-S\n\(socket)\nattach-session\n-t\n$42\n")
        XCTAssertFalse(FileManager.default.fileExists(atPath: script.path))
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    private func writeExecutable(_ text: String, to url: URL) throws {
        try Data(text.utf8).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }
}
