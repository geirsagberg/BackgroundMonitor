import XCTest
@testable import BackgroundMonitorCore

final class BackgroundJobFinderTests: XCTestCase {
    private let user: UInt32 = 501

    private func process(
        _ pid: Int32,
        parent: Int32,
        name: String,
        group: Int32? = nil,
        terminalGroup: Int32 = 0,
        terminal: String? = nil,
        user: UInt32 = 501
    ) -> ProcessRecord {
        ProcessRecord(
            pid: pid,
            parentPID: parent,
            processGroupID: group ?? pid,
            terminalProcessGroupID: terminalGroup,
            userID: user,
            terminal: terminal,
            name: name
        )
    }

    private func jobPIDs(_ processes: [ProcessRecord]) -> [Int32] {
        BackgroundJobFinder.jobs(in: processes, userID: user).map(\.process.pid).sorted()
    }

    func testBackgroundJobOfInteractiveShellIsListedWithItsChildren() {
        let processes = [
            process(10, parent: 1, name: "Terminal", user: 0),
            process(20, parent: 10, name: "-zsh", terminalGroup: 20, terminal: "ttys001"),
            process(30, parent: 20, name: "npm", terminalGroup: 20, terminal: "ttys001"),
            process(31, parent: 30, name: "node", group: 30, terminalGroup: 20, terminal: "ttys001"),
        ]

        let jobs = BackgroundJobFinder.jobs(in: processes, userID: user)

        XCTAssertEqual(jobs.map(\.process.pid), [30])
        XCTAssertEqual(jobs.first?.descendantPIDs, [31])
    }

    func testForegroundJobOfTerminalIsNotListed() {
        let processes = [
            process(20, parent: 1, name: "zsh", terminalGroup: 30, terminal: "ttys001"),
            process(30, parent: 20, name: "vim", terminalGroup: 30, terminal: "ttys001"),
        ]

        XCTAssertEqual(jobPIDs(processes), [])
    }

    func testDetachedProcessUnderNonShellAppIsNotListed() {
        let processes = [
            process(10, parent: 1, name: "Slack"),
            process(11, parent: 10, name: "Slack Helper"),
        ]

        XCTAssertEqual(jobPIDs(processes), [])
    }

    func testCommandStartedByAgentShellIsListed() {
        let processes = [
            process(10, parent: 1, name: "claude"),
            process(20, parent: 10, name: "zsh"),
            process(30, parent: 20, name: "bun", group: 20),
            process(31, parent: 30, name: "sh", group: 20),
            process(32, parent: 31, name: "vite", group: 20),
        ]

        let jobs = BackgroundJobFinder.jobs(in: processes, userID: user)

        XCTAssertEqual(jobs.map(\.process.pid), [30])
        XCTAssertEqual(jobs.first?.descendantPIDs.sorted(), [31, 32])
    }

    func testOrphanStillAttachedToTerminalIsListed() {
        let processes = [
            process(30, parent: 1, name: "bun", terminalGroup: 99, terminal: "ttys002"),
            process(40, parent: 1, name: "launch-agent"),
        ]

        XCTAssertEqual(jobPIDs(processes), [30])
    }

    func testOtherUsersProcessesAreNotListed() {
        let processes = [
            process(20, parent: 1, name: "zsh", user: 0),
            process(30, parent: 20, name: "sleep", user: 0),
        ]

        XCTAssertEqual(jobPIDs(processes), [])
    }

    func testParsesProcessArguments() {
        var buffer: [UInt8] = withUnsafeBytes(of: Int32(2)) { Array($0) }
        buffer += Array("/bin/sleep".utf8) + [0, 0, 0]
        buffer += Array("sleep".utf8) + [0] + Array("100".utf8) + [0]
        buffer += Array("PATH=/bin".utf8) + [0]

        XCTAssertEqual(ProcessTable.parseProcessArguments(buffer), ["sleep", "100"])
    }

    func testDisplayNameUsesFirstArgument() {
        XCTAssertEqual(
            JobScanner.displayName(arguments: ["/Users/me/.cache/gitstatusd-darwin-arm64", "-G"], fallback: "gitstatusd-darwi"),
            "gitstatusd-darwin-arm64"
        )
        XCTAssertEqual(JobScanner.displayName(arguments: [], fallback: "node"), "node")
    }

    func testDurationText() {
        XCTAssertEqual(JobPresentation.durationText(42), "42s")
        XCTAssertEqual(JobPresentation.durationText(125), "2m")
        XCTAssertEqual(JobPresentation.durationText(3 * 3_600 + 120), "3h 2m")
        XCTAssertEqual(JobPresentation.durationText(2 * 86_400 + 3_600), "2d 1h")
    }

    func testAbbreviatesHomeDirectory() {
        XCTAssertEqual(JobPresentation.abbreviatingHome("/Users/me/code", home: "/Users/me"), "~/code")
        XCTAssertEqual(JobPresentation.abbreviatingHome("/Users/meg", home: "/Users/me"), "/Users/meg")
    }
}
