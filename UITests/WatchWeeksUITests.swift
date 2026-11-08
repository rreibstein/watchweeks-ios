import XCTest
final class WatchWeeksUITests: XCTestCase {
    @MainActor func testGuestNavigation() {
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Discover"].waitForExistence(timeout: 10))
        app.tabBars.buttons["My Visit"].tap()
        XCTAssertTrue(app.navigationBars["My Visit"].exists)
        app.tabBars.buttons["About"].tap()
        XCTAssertTrue(app.staticTexts["Your visit, your device"].exists)
    }
    @MainActor func testCaptureDiscovery() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else { throw XCTSkip("Capture only after real feed integration and release identity verification") }
        let app = XCUIApplication(); app.launch()
        // Capture actual UI only. Owner must inspect content before App Store use.
        sleep(8)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "01-discovery"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
