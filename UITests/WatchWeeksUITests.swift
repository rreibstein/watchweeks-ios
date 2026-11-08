import XCTest
final class WatchWeeksUITests: XCTestCase {
    @MainActor func testGuestNavigation() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["Continue without analytics"].waitForExistence(timeout: 3) { app.buttons["Continue without analytics"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Account"].waitForExistence(timeout: 2))
        app.buttons["Account"].tap()
        XCTAssertTrue(app.buttons["Open WatchWeeks account"].waitForExistence(timeout: 2))
        app.buttons["Done"].tap()
        app.tabBars.buttons["My list"].tap()
        XCTAssertTrue(app.navigationBars["My list"].exists)
        app.tabBars.buttons["About"].tap()
        XCTAssertTrue(app.staticTexts["Your visit, your device"].exists)
    }
    @MainActor func testCaptureDiscovery() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else { throw XCTSkip("Capture only after real feed integration and release identity verification") }
        let app = XCUIApplication(); app.launch()
        if app.buttons["Continue without analytics"].waitForExistence(timeout: 3) { app.buttons["Continue without analytics"].tap() }
        // Capture actual UI only. Owner must inspect content before App Store use.
        sleep(8)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "01-discovery"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
