import XCTest

final class WatchWeeksUITests: XCTestCase {
    @MainActor func testGuestNavigation() {
        let app = XCUIApplication()
        openAsGuest(app)
        XCTAssertTrue(app.buttons["tab-Events"].waitForExistence(timeout: 10))
        let account = app.buttons["Account"]
        XCTAssertTrue(account.waitForExistence(timeout: 2))
        account.tap()
        XCTAssertTrue(app.buttons["Open WatchWeeks account"].waitForExistence(timeout: 2))
        let about = app.buttons["About & analytics"]
        if !about.isHittable { app.swipeUp() }
        about.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches["Share anonymous usage analytics"].exists)
        app.navigationBars["About"].buttons.firstMatch.tap()
        app.buttons["Done"].tap()
        app.buttons["tab-My list"].tap()
        XCTAssertTrue(app.staticTexts["My list"].exists)
    }

    @MainActor func testLiveMobileDesign() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_WW_CAPTURE=1 to exercise the live Singapore guide.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        openAsGuest(app)
        XCTAssertTrue(app.buttons["Singapore"].waitForExistence(timeout: 40))
        capture(app, "01-home")

        app.buttons["Find"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Singapore")
        let guide = app.buttons["Open the Singapore guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()
        XCTAssertTrue(app.staticTexts["Singapore Guide"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-Events"].exists)
        capture(app, "02-singapore")
        app.buttons["Thu"].tap()
        XCTAssertTrue(app.staticTexts["1 event"].exists)
        app.buttons["All"].tap()
        let saturday = app.buttons["Sat, Nov 14"]
        reveal(saturday, in: app)
        saturday.tap()
        let afternoon = app.buttons["Afternoon"]
        reveal(afternoon, in: app)
        afternoon.tap()
        let talkToggle = app.switches["Build around a talk"]
        reveal(talkToggle, in: app)
        if (talkToggle.value as? String) != "1" {
            talkToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(talkToggle.value as? String, "1")
        let talkMenu = app.buttons["planner-talk-menu"]
        reveal(talkMenu, in: app)
        talkMenu.tap()
        app.buttons["4:00 PM · GD100 Screening & Conversation"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "fits all 3 fairs")).firstMatch.exists)
        let copy = app.buttons["Copy plan"]
        reveal(copy, in: app)
        copy.tap()
        XCTAssertTrue(app.buttons["Plan copied"].exists)
        capture(app, "02b-planner")
        app.terminate()
        openAsGuest(app)
        app.buttons["Find"].tap()
        let eventSearch = app.searchFields.firstMatch
        XCTAssertTrue(eventSearch.waitForExistence(timeout: 5))
        eventSearch.tap()
        eventSearch.typeText("Golden Hour Singapore")
        let goldenHour = app.buttons["Golden Hour Singapore"]
        XCTAssertTrue(goldenHour.waitForExistence(timeout: 5))
        goldenHour.tap()
        XCTAssertTrue(app.staticTexts["Golden Hour Singapore"].waitForExistence(timeout: 5))
        capture(app, "03-golden-hour")

        let rate = app.buttons["Must-see, ALTO"]
        reveal(rate, in: app)
        if !rate.isSelected { rate.tap() }
        let shortlist = app.buttons["shortlist-alto"]
        if !shortlist.isHittable { app.swipeDown(velocity: .slow) }
        XCTAssertTrue(shortlist.isHittable)
        if shortlist.label == "Shortlist" { shortlist.tap() }
        let seen = app.buttons["Seen ALTO"]
        if seen.value as? String != "Seen" {
            if !seen.isHittable { app.swipeDown(velocity: .slow) }
            seen.tap()
        }
        XCTAssertTrue(app.buttons["ALTO"].waitForExistence(timeout: 3))
        capture(app, "04-rating")
        app.terminate()

        openAsGuest(app)
        app.buttons["tab-My list"].tap()
        let saved = app.buttons["ALTO"]
        reveal(saved, in: app)
        saved.tap()
        XCTAssertEqual(app.buttons["Seen ALTO"].value as? String, "Seen")
        capture(app, "05-my-list")
        app.buttons["tab-New releases"].tap()
        let chooser = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Choose a guide")).firstMatch
        XCTAssertTrue(chooser.waitForExistence(timeout: 5))
        chooser.tap()
        app.buttons["Singapore"].tap()
        XCTAssertTrue(app.staticTexts["New releases"].waitForExistence(timeout: 5))
        capture(app, "06-new-releases")
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<9 where !element.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.78))
                .press(forDuration: 0.08, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.43)))
        }
        XCTAssertTrue(element.isHittable, "Expected \(element) to be visible")
    }

    @MainActor private func openAsGuest(_ app: XCUIApplication) {
        app.launch()
        let decline = app.buttons["Continue without analytics"]
        if decline.waitForExistence(timeout: 3) { decline.tap() }
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
