import Combine
import XCTest
@testable import BackgroundMonitor

final class RefreshTests: XCTestCase {
    @MainActor
    func testRepeatedJobRefreshDoesNotPublishScanCompletionAgain() async {
        let model = JobsViewModel()
        await model.refresh()
        var updates = 0
        let subscription = model.$hasScanned.dropFirst().sink { _ in updates += 1 }

        await model.refresh()

        XCTAssertEqual(updates, 0, "An idle refresh must not invalidate views for unchanged scan state.")
        withExtendedLifetime(subscription) {}
    }

    @MainActor
    func testRepeatedTmuxRefreshDoesNotPublishScanCompletionAgain() async {
        let model = TmuxViewModel()
        await model.refresh()
        var updates = 0
        let subscription = model.$hasScanned.dropFirst().sink { _ in updates += 1 }

        await model.refresh()

        XCTAssertEqual(updates, 0, "An idle refresh must not invalidate views for unchanged scan state.")
        withExtendedLifetime(subscription) {}
    }
}
