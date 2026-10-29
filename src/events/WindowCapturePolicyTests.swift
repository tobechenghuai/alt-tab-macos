import XCTest

final class WindowCapturePolicyTests: XCTestCase {
    func testDisabledBackgroundCaptureStillAllowsVisibleSwitcher() {
        XCTAssertTrue(WindowCapturePolicy.allowsCapture(inBackground: false, switcherActive: true))
        XCTAssertFalse(WindowCapturePolicy.allowsCapture(inBackground: false, switcherActive: false))
    }

    func testDisablingBackgroundCaptureInvalidatesQueuedIdleCapture() {
        XCTAssertTrue(WindowCapturePolicy.allowsCapture(inBackground: true, switcherActive: false))
        XCTAssertFalse(WindowCapturePolicy.allowsCapture(inBackground: false, switcherActive: false))
    }

    func testEnabledBackgroundCaptureAllowsBothSessionStates() {
        for active in [true, false] {
            XCTAssertTrue(WindowCapturePolicy.allowsCapture(inBackground: true, switcherActive: active))
        }
    }
}
