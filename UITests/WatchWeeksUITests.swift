import XCTest

final class WatchWeeksUITests: XCTestCase {
    @MainActor func testGuestNavigation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Allow usage analytics"].exists)
        XCTAssertFalse(app.buttons["Continue without analytics"].exists)
        XCTAssertFalse(app.buttons["Account"].exists)
        XCTAssertTrue(app.buttons["Find"].exists)
        app.tabBars.buttons["My list"].tap()
        let about = app.buttons["About & privacy"]
        if !about.isHittable { app.swipeUp() }
        about.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 2))
        let privacy = app.buttons["Privacy policy"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 3))
        privacy.tap()
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
            .wait(for: .runningForeground, timeout: 10))
        app.activate()
        app.navigationBars["About"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["My list"].exists)
    }

    @MainActor func testLiveMobileDesign() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_WW_CAPTURE=1 to exercise the live Singapore guide.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Singapore"].waitForExistence(timeout: 40))
        capture(app, "01-home")
        let preview = app.buttons["Renaud Tixier, Monday Skeleton"]
        reveal(preview, in: app)
        preview.tap()
        XCTAssertTrue(app.staticTexts["Monday Skeleton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Explore at Golden Hour Singapore"].exists)
        XCTAssertFalse(app.links["Full details"].exists)
        XCTAssertFalse(app.buttons["Full details"].exists)
        let photo = app.buttons["View photo"].firstMatch
        XCTAssertTrue(photo.exists)
        photo.tap()
        let closePhoto = app.buttons["Close photo"]
        XCTAssertTrue(closePhoto.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Photo: Renaud Tixier"].exists)
        closePhoto.tap()
        capture(app, "01b-release")
        let interested = app.buttons["Interested, Renaud Tixier"]
        let resort = app.buttons["Re-sort"]
        reveal(interested, in: app)
        XCTAssertGreaterThanOrEqual(interested.frame.height, 44)
        for label in ["Must see", "Interested", "If time", "Unfamiliar", "Skip"] {
            XCTAssertTrue(app.buttons["\(label), Renaud Tixier"].exists)
        }
        interested.tap()
        XCTAssertTrue(interested.isSelected)
        XCTAssertTrue(resort.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["View My list"].exists)
        assertToastPlacement(in: app)
        resort.tap()
        XCTAssertFalse(resort.exists)
        interested.tap()
        XCTAssertFalse(interested.isSelected)
        XCTAssertTrue(resort.waitForExistence(timeout: 2))
        resort.tap()
        let back = app.navigationBars.firstMatch.buttons.firstMatch
        XCTAssertFalse(back.label.isEmpty)
        back.tap()

        let cardHeader = app.buttons["home-guide-singapore-2026"]
        let guideTitle = app.staticTexts["Singapore Guide"]
        reveal(cardHeader, in: app)
        cardHeader.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.35)).tap()
        XCTAssertTrue(guideTitle.waitForExistence(timeout: 5))
        app.navigationBars.firstMatch.buttons.firstMatch.tap()

        let summary = app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@", " brands · ", " events · "
        )).firstMatch
        reveal(summary, in: app)
        summary.tap()
        XCTAssertTrue(guideTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Events"].exists)
        capture(app, "02-singapore")
        app.buttons["Thu"].tap()
        XCTAssertTrue(app.staticTexts["0 events"].exists)
        app.buttons["By day"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Invitation only")).firstMatch.exists)
        app.buttons["All"].tap()
        app.buttons["By # of brands"].tap()
        let planner = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Plan your fair day")).firstMatch
        reveal(planner, in: app)
        planner.tap()
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
        let copy = app.buttons["copy-plan"]
        reveal(copy, in: app)
        if copy.frame.midY > app.frame.height * 0.82 { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(copy.isHittable)
        copy.tap()
        let copied = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "copy-plan", "Plan copied")).firstMatch
        XCTAssertTrue(copied.waitForExistence(timeout: 5))
        capture(app, "02b-planner")
        XCTAssertFalse(app.buttons["Find"].isHittable)
        XCTAssertFalse(app.buttons["Full guide and planning tools"].exists)
        XCTAssertTrue(app.buttons["Share guide"].exists)
        app.terminate()
        app.launch()
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
        let carouselPhoto = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "event-release-card-renaudtixier"
        )).firstMatch
        reveal(carouselPhoto, in: app)
        XCTAssertGreaterThan(carouselPhoto.frame.height, 190)
        capture(app, "03b-event-releases")
        app.tabBars.buttons["New releases"].tap()
        let singaporeReleases = app.staticTexts.containing(
            NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Singapore ·", "new releases")
        ).firstMatch
        XCTAssertTrue(singaporeReleases.waitForExistence(timeout: 5))
        app.tabBars.buttons["Events"].tap()
        XCTAssertTrue(app.staticTexts["Golden Hour Singapore"].waitForExistence(timeout: 5))

        let collapsedBrand = app.buttons["ALTO"]
        if collapsedBrand.exists {
            reveal(collapsedBrand, in: app)
            collapsedBrand.tap()
            let previouslySeen = app.buttons["Seen ALTO"]
            reveal(previouslySeen, in: app)
            previouslySeen.tap()
            XCTAssertTrue(resort.waitForExistence(timeout: 2))
            resort.tap()
        }
        let rate = app.buttons["Must see, ALTO"]
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
            XCTAssertTrue(resort.waitForExistence(timeout: 2))
            assertToastPlacement(in: app)
            capture(app, "04b-resort")
            resort.tap()
        }
        XCTAssertTrue(app.buttons["ALTO"].waitForExistence(timeout: 3))
        capture(app, "04-rating")
        app.terminate()

        app.launch()
        app.tabBars.buttons["My list"].tap()
        let saved = app.buttons["ALTO"]
        reveal(saved, in: app)
        saved.tap()
        XCTAssertEqual(app.buttons["Seen ALTO"].value as? String, "Seen")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Share My Picks")).firstMatch.exists)
        capture(app, "05-my-list")
        app.tabBars.buttons["New releases"].tap()
        let chooser = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Choose a guide")).firstMatch
        XCTAssertTrue(chooser.waitForExistence(timeout: 5))
        chooser.tap()
        app.buttons["Singapore"].tap()
        XCTAssertTrue(app.staticTexts["New releases"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Interest"].exists)
        XCTAssertTrue(app.searchFields["Search releases"].exists || app.textFields["Search releases"].exists)
        app.buttons["Event, All events"].tap()
        let goldenHourFilter = app.buttons["Golden Hour Singapore"]
        XCTAssertTrue(goldenHourFilter.waitForExistence(timeout: 3))
        goldenHourFilter.tap()
        XCTAssertTrue(app.buttons["Event, Golden Hour Singapore"].waitForExistence(timeout: 3))
        app.buttons["Event, Golden Hour Singapore"].tap()
        app.buttons["All events"].tap()
        capture(app, "06-new-releases")
        let releaseRating = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Interested, ")).firstMatch
        reveal(releaseRating, in: app)
        let wasSelected = releaseRating.isSelected
        releaseRating.tap()
        XCTAssertEqual(releaseRating.isSelected, !wasSelected)
        assertToastPlacement(in: app)
        resort.tap()

        app.tabBars.buttons["Brands A–Z"].tap()
        app.buttons["A–Z"].tap()
        for (index, brand) in ["22Studio", "AndoAndoAndo", "Angles", "Anoma", "Artime"].enumerated() {
            let rating = app.buttons["If time, \(brand)"]
            reveal(rating, in: app)
            XCTAssertGreaterThanOrEqual(rating.frame.width, 44)
            XCTAssertGreaterThanOrEqual(rating.frame.height, 44)
            rating.tap()
            let count = index + 1
            XCTAssertTrue(app.staticTexts[count == 1 ? "1 change" : "\(count) changes"].exists)
            assertToastPlacement(in: app)
            if count == 4 { capture(app, "07-four-change-toast") }
        }
        resort.tap()
    }

    @MainActor func testRatingsAtLargestDynamicType() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_WW_CAPTURE=1 to exercise ratings with the live guide.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let find = app.buttons["Find"]
        XCTAssertTrue(find.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(find.frame.height, 44)
        find.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Renaud Tixier")
        let result = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Renaud Tixier")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 20))
        result.tap()
        let mustSee = app.buttons["Must see, Renaud Tixier"]
        let interested = app.buttons["Interested, Renaud Tixier"]
        reveal(mustSee, in: app)
        XCTAssertGreaterThanOrEqual(mustSee.frame.height, 44)
        XCTAssertEqual(mustSee.frame.midX, interested.frame.midX, accuracy: 2)
        XCTAssertLessThanOrEqual(mustSee.frame.maxY, interested.frame.minY)
        mustSee.tap()
        assertToastPlacement(in: app)
        capture(app, "08-largest-type-ratings")
        app.buttons["Re-sort"].tap()
    }

    @MainActor private func assertToastPlacement(in app: XCUIApplication) {
        let toast = app.descendants(matching: .any)["sort-toast"].firstMatch
        XCTAssertTrue(toast.exists)
        XCTAssertEqual(toast.frame.midX, app.frame.midX, accuracy: 2)
        XCTAssertLessThanOrEqual(toast.frame.maxY, app.tabBars.firstMatch.frame.minY)
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<9 where !element.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.78))
                .press(forDuration: 0.08, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.43)))
        }
        XCTAssertTrue(element.isHittable, "Expected \(element) to be visible")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
