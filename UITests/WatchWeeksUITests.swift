import XCTest

final class WatchWeeksUITests: XCTestCase {
    @MainActor func testAnnouncementsThreePlacementsNavigationAndScreenshots() throws {
        let app=XCUIApplication()
        app.launchEnvironment["WW_ANNOUNCED_QA_GUIDE"]=String(data:try XCTUnwrap(Data(base64Encoded:announcedFixtureBase64)),encoding:.utf8)
        app.launchEnvironment["WW_ANNOUNCED_QA_NOW"]="2026-11-12T12:00:00Z"
        app.launch()
        let firstID="1218a21a-53c7-41fb-a8d9-0204c5474c09"
        let home=homeButton("announced-home-\(firstID)",in:app)
        capture(app,"announced-01-home-real-feed-snapshot")
        home.tap()
        XCTAssertTrue(app.tabBars.buttons["New releases"].isSelected)
        let release=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","release-trilobe|")).firstMatch
        XCTAssertTrue(release.waitForExistence(timeout:8))
        let atBrand=XCTNSPredicateExpectation(predicate:NSPredicate(format:"hittable == true"),object:release)
        XCTAssertEqual(XCTWaiter.wait(for:[atBrand],timeout:8),.completed)
        XCTAssertTrue(app.staticTexts["JUST ADDED"].firstMatch.exists || release.label.contains("JUST ADDED"))
        _=homeButton("announced-new_releases-\(firstID)",in:app)
        capture(app,"announced-03-new-releases-real-feed-snapshot")
        app.tabBars.buttons["Events"].tap()
        homeButton("home-guide-singapore-2026",in:app).tap()
        _=homeButton("announced-guide-\(firstID)",in:app)
        capture(app,"announced-02-guide-event-real-feed-snapshot")
        let chip=homeButton("event-chip-iamwatch-trilobe",in:app)
        chip.tap()
        XCTAssertTrue(app.buttons["Brands & attendance"].waitForExistence(timeout:5))
        XCTAssertFalse(app.staticTexts["IAMWATCH program"].exists)
    }
    // Two real public announcements from the Nov 12 feed; simulator test only.
    private let announcedFixtureBase64="eyJ2IjoxLCJndWlkZSI6eyJpZCI6InNpbmdhcG9yZS0yMDI2Iiwic2x1ZyI6InNpbmdhcG9yZSIsImNpdHkiOiJTaW5nYXBvcmUiLCJkYXRlcyI6Ik5vdiAxMuKAkzE1LCAyMDI2IiwidGltZXpvbmUiOiJBc2lhL1NpbmdhcG9yZSIsInN0YXJ0X2RhdGUiOiIyMDI2LTExLTEyIiwiZW5kX2RhdGUiOiIyMDI2LTExLTE1IiwidXJsIjoiaHR0cHM6Ly93YXRjaHdlZWtzLmNvbS9zaW5nYXBvcmUifSwiZXZlbnRzIjpbeyJpZCI6ImlhbXdhdGNoIiwibmFtZSI6IklBTVdBVENIIDIwMjYiLCJ2ZW51ZSI6IlRoZSBTaW5nYXBvcmUgRURJVElPTiIsInVybCI6Imh0dHBzOi8vd3d3LmlhbXdhdGNoLmNvbS9ldmVudC8yMDI2L0hvbWUiLCJub3RlIjoiVGh1IE5vdiAxMiBpcyBpbnZpdGF0aW9uIG9ubHkuIERyZXNzIGNvZGU6IFwiRG91YmxlLVdyaXN0ZWQsIFJlc29ydCBDYXN1YWwuXCIgUHJpbnQgeW91ciBldmVudCBwYXNzIGJlZm9yZSB5b3UgYXJyaXZlIOKAlCBhIHBob3RvIGlzIHRha2VuIGF0IHJlZ2lzdHJhdGlvbiBmb3IgeW91ciBwYXNzLiBQcm9ncmFtIHNlc3Npb25zIGFyZSBzZWF0ZWQgZmlyc3QgY29tZSwgZmlyc3Qgc2VydmVkLiBBcnJpdmUgYWJvdXQgMTUgbWludXRlcyBiZWZvcmUgYSBzZXNzaW9uIHlvdSB3YW50IHRvIGF0dGVuZDsgcmVnaXN0ZXJpbmcgZm9yIGEgc2Vzc2lvbiBkb2VzIG5vdCByZXNlcnZlIGEgc2VhdC4gU2Vzc2lvbnMgaW4gdGhlIFBlbnRob3VzZSBhcmUgZXNjb3J0ZWQuIE1lZXQgYXQgdGhlIElBTVdBVENIIGRlc2sgaW4gdGhlIExldmVsIDEgbG9iYnkgYW5kIHRoZSB0ZWFtIHdpbGwgdGFrZSB5b3UgdXAuXG5cbkdlb3JnZSBEYW5pZWxzIDEwMDogVGhlIEdlbmVzaXMgb2YgQXJ0aXNhbmFsIFdhdGNobWFraW5nLCBwcmVzZW50ZWQgYnkgUGhpbGxpcHMgaW4gQXNzb2NpYXRpb24gd2l0aCBCYWNzICYgUnVzc28gYW5kIFRoZSBIb3VyIEdsYXNzLCBpcyBvbiB2aWV3IGluIHRoZSBCb2FyZHJvb20gdGhyb3VnaG91dCB0aGUgZmFpcjogMjIgb2YgRGFuaWVscycgd2F0Y2hlcywgd2l0aCBTcGFjZSBUcmF2ZWxsZXIgSSBhbmQgU3BhY2UgVHJhdmVsbGVyIElJIGV4aGliaXRlZCB0b2dldGhlciBmb3IgdGhlIGZpcnN0IHRpbWUuIFB1YmxpYyBkYXlzIEZyaSBOb3YgMTMgLSBTdW4gTm92IDE1LCAxMSBBTS04IFBNLiBTYXR1cmRheSBhZnRlcm5vb24gaXMgZGVkaWNhdGVkIHRvIERhbmllbHMsIGluY2x1ZGluZyB0aGUgYXZhbnQtcHJlbWllcmUgb2YgdGhlIFBoaWxsaXBzIGRvY3VtZW50YXJ5IG9uIGhpcyBsaWZlIGFuZCB3b3JrLiIsImRheXMiOlt7ImRhdGUiOiIyMDI2LTExLTEyIiwib3BlbiI6IjE0OjAwIiwiY2xvc2UiOiIyMTowMCIsImFjY2VzcyI6Imludml0YXRpb24ifSx7ImRhdGUiOiIyMDI2LTExLTEzIiwib3BlbiI6IjExOjAwIiwiY2xvc2UiOiIyMDowMCIsImFjY2VzcyI6InJzdnAifSx7ImRhdGUiOiIyMDI2LTExLTE0Iiwib3BlbiI6IjExOjAwIiwiY2xvc2UiOiIyMDowMCIsImFjY2VzcyI6InJzdnAifSx7ImRhdGUiOiIyMDI2LTExLTE1Iiwib3BlbiI6IjExOjAwIiwiY2xvc2UiOiIyMDowMCIsImFjY2VzcyI6InJzdnAifV0sInN0YXJ0X2RhdGUiOiIyMDI2LTExLTEyIiwiZW5kX2RhdGUiOiIyMDI2LTExLTE1In1dLCJicmFuZHMiOlt7Im5hbWUiOiJQZXRlcm1hbm4gQsOpZGF0IiwiYnJhbmRLZXkiOiJwZXRlcm1hbm5iZGF0IiwiZXZlbnRJZCI6ImlhbXdhdGNoIiwid2Vic2l0ZSI6bnVsbCwiaGFzUmVsZWFzZSI6dHJ1ZX0seyJuYW1lIjoiVHJpbG9iZSIsImJyYW5kS2V5IjoidHJpbG9iZSIsImV2ZW50SWQiOiJpYW13YXRjaCIsIndlYnNpdGUiOm51bGwsImhhc1JlbGVhc2UiOnRydWV9XSwicmVsZWFzZXMiOlt7ImJyYW5kIjoiVHJpbG9iZSIsImJyYW5kS2V5IjoidHJpbG9iZSIsImV2ZW50SWQiOiJpYW13YXRjaCIsImtpbmQiOiJkZWJ1dCIsInRleHQiOiJVbmUgRm9sbGUgSm91cm7DqWUgMm5kIEdlbmVyYXRpb24gKEJsdWU7IEJsYWNrOyBHcmV5KSDigJQgVGhlIHNlY29uZCBnZW5lcmF0aW9uIG9mIFVuZSBGb2xsZSBKb3VybsOpZTogYSBuZXcgYmFycmVsLXNoYXBlZCA0MC4zbW0gY2FzZSBpbiBHcmFkZSA1IHRpdGFuaXVtIG9yIHJvc2UgZ29sZCwga2VlcGluZyB0aGUgdGhyZWUgZmxvYXRpbmcgcmluZ3MgdGhhdCB0dXJuIGNvdW50ZXJjbG9ja3dpc2UgYXJvdW5kIGEgZml4ZWQgcG9pbnRlciwgbm93IGRyaXZlbiBieSBUcmlsb2JlJ3MgbWFudWZhY3R1cmUgWC1OaWhpbG8gY2FsaWJyZSAoNCBIeiwgNDItaG91ciByZXNlcnZlKSBpbiBwbGFjZSBvZiB0aGUgWC1DZW50cmljLiBJbiBibHVlLCBibGFjayBhbmQgZ3JleS5cblByaWNlOiDigqwyMyw1MDAiLCJ1cmwiOiJodHRwczovL3RyaWxvYmUuY29tIiwic291cmNlIjpudWxsLCJhd2FyZHMiOltdLCJpbWFnZXMiOlt7InVybCI6Imh0dHBzOi8vd2F0Y2h3ZWVrcy5jb20vYXBpL3B1YmxpYy9yZWxlYXNlcy9pbWFnZXM/a2V5PTkxY2ZmZjFjMDJiYTMxNTBlNzliNDE2NDkzMzY0ZDczOGQ0Y2IwMGNiYTZmNTE1ZDllN2FlZDM3MTBiMjgwZjAiLCJjcmVkaXQiOiJUcmlsb2JlIiwibGluayI6Imh0dHBzOi8vdHJpbG9iZS5jb20ifV19LHsiYnJhbmQiOiJQZXRlcm1hbm4gQsOpZGF0IiwiYnJhbmRLZXkiOiJwZXRlcm1hbm5iZGF0IiwiZXZlbnRJZCI6ImlhbXdhdGNoIiwia2luZCI6ImRlYnV0IiwidGV4dCI6IlJlZmVyZW5jZSAyOTE0IOKAlCBQZXRlcm1hbm4gQsOpZGF0J3MgUmVmZXJlbmNlIDI5MTQgaXMgYSBtb25vcHVzaGVyIGNocm9ub2dyYXBoIHdpdGggYW4gaW5zdGFudGFuZW91cyBtaW51dGUgY291bnRlciwgaW4gYSAzNi41MG1tIHBsYXRpbnVtIGNhc2UgOS45MG1tIHRoaWNrLiBJdHMgc2VtaS1vcGVuIGRpYWwsIG1hZGUgYnkgQ29tYmzDqW1pbmUgZnJvbSBzdGFpbmxlc3Mgc3RlZWwgYW5kIHNhcHBoaXJlIHdpdGggc29saWQgZ29sZCBhcHBsaXF1ZXMsIHNpdHMgb3ZlciB0aGUgaW4taG91c2UgQ2FsaWJlciAyMzQgd2l0aCBhIDU2LWhvdXIgcmVzZXJ2ZS4gTGltaXRlZCB0byAyMCBwaWVjZXMgaW4gcGxhdGludW0uXG5QcmljZTogQ0hGIDE4MCwwMDAgZXggVkFUIiwidXJsIjoiaHR0cHM6Ly9wZXRlcm1hbm4tYmVkYXQuY29tL3JlZmVyZW5jZXMvcmVmZXJlbmNlLTI5MTQvIiwic291cmNlIjpudWxsLCJhd2FyZHMiOltdLCJpbWFnZXMiOlt7InVybCI6Imh0dHBzOi8vd2F0Y2h3ZWVrcy5jb20vYXBpL3B1YmxpYy9yZWxlYXNlcy9pbWFnZXM/a2V5PTljZWVmZmRhOGRlY2I3ZTY4ZDVhNjRjZTI5YTYyYTkxZjE4Nzk2MWQxZWJjYzVkZWEwM2EyMzViMWRjMTQ2MTIiLCJjcmVkaXQiOiJQZXRlcm1hbm4gQsOpZGF0IiwibGluayI6Imh0dHBzOi8vcGV0ZXJtYW5uLWJlZGF0LmNvbS9yZWZlcmVuY2VzL3JlZmVyZW5jZS0yOTE0LyJ9XX1dLCJkZWFsZXJzIjpbXSwiYW5ub3VuY2VkIjpbeyJpZCI6IjEyMThhMjFhLTUzYzctNDFmYi1hOGQ5LTAyMDRjNTQ3NGMwOSIsImJyYW5kIjoiVHJpbG9iZSIsImJyYW5kS2V5IjoidHJpbG9iZSIsIm1vZGVsIjoiVW5lIEZvbGxlIEpvdXJuw6llIDJuZCBHZW5lcmF0aW9uIiwidmFyaWFudCI6IkJsdWU7IEJsYWNrOyBHcmV5IiwiZXZlbnRJZCI6ImlhbXdhdGNoIiwiZXZlbnROYW1lIjoiSUFNV0FUQ0giLCJkYXRlIjoiMjAyNi0xMS0xMiIsImltYWdlVXJsIjoiaHR0cHM6Ly93YXRjaHdlZWtzLmNvbS9hcGkvcHVibGljL3JlbGVhc2VzL2ltYWdlcz9rZXk9OTFjZmZmMWMwMmJhMzE1MGU3OWI0MTY0OTMzNjRkNzM4ZDRjYjAwY2JhNmY1MTVkOWU3YWVkMzcxMGIyODBmMCIsImNyZWRpdCI6IlRyaWxvYmUifSx7ImlkIjoiNjc3NDc2MjktMGFmNC00YmE3LTljZjAtOTVjMThlZDE3MDJlIiwiYnJhbmQiOiJQZXRlcm1hbm4gQsOpZGF0IiwiYnJhbmRLZXkiOiJwZXRlcm1hbm5iZGF0IiwibW9kZWwiOiJSZWZlcmVuY2UgMjkxNCIsInZhcmlhbnQiOm51bGwsImV2ZW50SWQiOiJpYW13YXRjaCIsImV2ZW50TmFtZSI6IklBTVdBVENIIiwiZGF0ZSI6IjIwMjYtMTEtMTIiLCJpbWFnZVVybCI6Imh0dHBzOi8vd2F0Y2h3ZWVrcy5jb20vYXBpL3B1YmxpYy9yZWxlYXNlcy9pbWFnZXM/a2V5PTljZWVmZmRhOGRlY2I3ZTY4ZDVhNjRjZTI5YTYyYTkxZjE4Nzk2MWQxZWJjYzVkZWEwM2EyMzViMWRjMTQ2MTIiLCJjcmVkaXQiOiJQZXRlcm1hbm4gQsOpZGF0In1dfQ=="

    @MainActor func testRapidReleaseHasNoAnalyticsOrNotificationEnrollment() {
        let app=XCUIApplication();app.launchEnvironment["WW_NATIVE_QA_CITY"]="singapore";app.launch()
        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout:10))
        XCTAssertFalse(app.buttons["guide-updates"].exists)
        XCTAssertFalse(app.buttons["analytics-prompt-allow"].exists)
        homeButton("home-about-privacy",in:app).tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout:5))
        XCTAssertFalse(app.buttons["Guide alert preferences"].exists)
        XCTAssertFalse(app.buttons["Learn about usage analytics"].exists)
    }
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure=false
    }
    @MainActor private func homeButton(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        // LazyVStack can report an offscreen activation point as an XCTest error
        // when isHittable is queried after returning from a navigation destination.
        // Re-query each snapshot and scroll until the full row is inside the viewport.
        for _ in 0..<24 {
            let button=app.buttons[identifier].firstMatch
            if button.exists {
                let frame=button.frame, window=app.windows.firstMatch.frame
                let bar=app.tabBars.firstMatch
                let bottom=bar.exists ? min(window.maxY-44,bar.frame.minY-8) : window.maxY-80
                if frame.minY.isFinite, frame.maxY.isFinite, frame.height > 0,
                   frame.width > 0, frame.minY >= window.minY+44, frame.maxY <= bottom { return button }
                if frame.height > 0, frame.width > 0, frame.minY.isFinite, frame.minY < window.minY+44 {
                    app.swipeDown(velocity:.slow);continue
                }
            }
            app.swipeUp(velocity:.slow)
        }
        let hierarchy=XCTAttachment(string:app.debugDescription)
        hierarchy.name="Home accessibility hierarchy";hierarchy.lifetime = .keepAlways;add(hierarchy)
        let screenshot=XCTAttachment(screenshot:app.screenshot())
        screenshot.name="Home after scrolling";screenshot.lifetime = .keepAlways;add(screenshot)
        let controls=app.buttons.allElementsBoundByIndex.suffix(12).map { "[\($0.identifier)] \($0.label)" }.joined(separator:"; ")
        XCTFail("Home button was not visible after scrolling: " + identifier + ". Home controls: " + String(controls.prefix(1800)))
        return app.buttons[identifier].firstMatch
    }
    @MainActor func testGuestNavigation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Allow usage analytics"].exists)
        XCTAssertFalse(app.buttons["Continue without analytics"].exists)
        XCTAssertFalse(app.buttons["Account"].exists)
        XCTAssertTrue(app.buttons["Find"].exists)
        homeButton("home-about-privacy",in:app).tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 2))
        app.navigationBars["About"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Events"].isSelected)
        homeButton("home-about-privacy",in:app).tap()
        let privacy = app.buttons["Privacy policy"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 3))
        privacy.tap()
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
            .wait(for: .runningForeground, timeout: 10))
    }

    @MainActor func testIAMWATCHScheduleIsPrimaryWithDayFilteringAndSpeakers() {
        let app=XCUIApplication()
        app.launchEnvironment["WW_NATIVE_QA_CITY"]="singapore"
        app.launchEnvironment["WW_SCHEDULE_QA_HTML"]="""
        <section aria-label="Program"><h2>Program (2)</h2>
        <h3>Fri Nov 13</h3><article><p class="font-mono">9 AM–10 AM · GTG</p><h4>The OGs</h4><p class="flex">Penthouse</p></article>
        <h3>Sat Nov 14</h3><article><p class="font-mono">10 AM–11 AM · Lecture</p><h4>Régleurs: Watchmaking's Invisible Masters of Precision</h4><p class="flex">Wonder Room</p><div class="text-sm"><span class="font-bold uppercase">Presenter </span>Carlos Torres</div></article></section>
        """
        app.launch()
        homeButton("home-guide-singapore-2026",in:app).tap()
        XCTAssertFalse(app.buttons["By day"].exists)
        let event=app.buttons["event-iamwatch"]
        XCTAssertTrue(event.waitForExistence(timeout:5));event.tap()
        XCTAssertTrue(app.staticTexts["IAMWATCH program"].waitForExistence(timeout:5))
        XCTAssertTrue(app.buttons["Schedule"].exists)
        XCTAssertTrue(app.buttons["Brands & attendance"].exists)
        XCTAssertTrue(app.staticTexts["The OGs"].waitForExistence(timeout:5))
        let saturday=app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","Sat")).firstMatch
        XCTAssertTrue(saturday.exists);saturday.tap()
        XCTAssertFalse(app.staticTexts["The OGs"].exists)
        let session=app.staticTexts["Régleurs: Watchmaking's Invisible Masters of Precision"]
        XCTAssertTrue(session.waitForExistence(timeout:5))
        let details=app.buttons["Session details"].firstMatch
        if !details.isHittable { app.swipeUp() };details.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Carlos Torres")).firstMatch.waitForExistence(timeout:5))
    }

    @MainActor func testCoconutGroveDealersAreVerticalAlphabeticalAndSearchable() {
        let app=XCUIApplication();app.launchEnvironment["WW_NATIVE_QA_CITY"]="miami";app.launch()
        homeButton("home-guide-miami-2026",in:app).tap()
        let event=app.buttons["event-coconut-grove"]
        XCTAssertTrue(event.waitForExistence(timeout:5));event.tap()
        let search=app.textFields["Search dealers"]
        XCTAssertTrue(search.waitForExistence(timeout:5))
        let first=app.staticTexts["dealer-coconut-grove|Aaron Faber Gallery"]
        let last=app.staticTexts["dealer-coconut-grove|Vintage Watches Miami"]
        XCTAssertTrue(first.exists);XCTAssertTrue(last.exists)
        XCTAssertLessThan(first.frame.minY,last.frame.minY)
        search.tap();search.typeText("vintage")
        XCTAssertTrue(last.waitForExistence(timeout:5));XCTAssertFalse(first.exists)
    }

    @MainActor func testForegroundingKeepsBrowsingAvailableWithoutCancellationBanner() {
        let app=XCUIApplication();app.launch()
        XCTAssertTrue(app.tabBars.buttons["Events"].waitForExistence(timeout:10))
        for _ in 0..<2 {
            XCUIDevice.shared.press(.home);app.activate()
            XCTAssertTrue(app.buttons["Find"].waitForExistence(timeout:10))
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","CancellationError")).firstMatch.exists)
            XCTAssertTrue(app.tabBars.buttons["Brands A–Z"].isEnabled)
        }
    }

    @MainActor func testLiveMobileDesign() throws {
        guard ProcessInfo.processInfo.environment["WW_CAPTURE"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_WW_CAPTURE=1 to exercise the live Singapore guide.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home-guide-singapore-2026"].waitForExistence(timeout: 40))
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

        let summary = app.staticTexts["home-guide-summary-singapore-2026"]
        reveal(summary, in: app)
        summary.tap()
        XCTAssertTrue(guideTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Events"].exists)
        capture(app, "02-singapore")
        app.buttons["Thu"].tap()
        XCTAssertTrue(app.staticTexts["0 events"].exists)
        XCTAssertFalse(app.buttons["By day"].exists)
        app.buttons["All"].tap()
        let cityRelease = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "city-release-card-")).firstMatch
        reveal(cityRelease, in: app)
        XCTAssertGreaterThan(cityRelease.frame.height, 100)
        capture(app, "02b-city-releases")
        cityRelease.tap()
        XCTAssertTrue(app.buttons["View photo"].firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        let releases = app.buttons["city-releases"]
        reveal(releases, in: app)
        releases.tap()
        XCTAssertTrue(app.buttons["Event, All events"].waitForExistence(timeout: 5))
        app.navigationBars.firstMatch.buttons.firstMatch.tap()

        let shareGuide = app.buttons["Share guide"]
        reveal(shareGuide, in: app)
        XCTAssertTrue(app.navigationBars.firstMatch.buttons["Find"].isHittable)
        XCTAssertFalse(app.staticTexts["WatchWeeks"].exists)
        XCTAssertFalse(app.staticTexts["Plan your fair day"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Plan your fair day")).firstMatch.exists)
        XCTAssertFalse(app.buttons["Full guide and planning tools"].exists)
        XCTAssertTrue(releases.exists)
        app.navigationBars.firstMatch.buttons["Find"].tap()
        let eventSearch = app.searchFields.firstMatch
        XCTAssertTrue(eventSearch.waitForExistence(timeout: 5))
        eventSearch.tap()
        eventSearch.typeText("Golden Hour Singapore")
        let goldenHour = app.buttons["Golden Hour Singapore"]
        XCTAssertTrue(goldenHour.waitForExistence(timeout: 5))
        goldenHour.tap()
        XCTAssertTrue(app.staticTexts["Golden Hour Singapore"].waitForExistence(timeout: 5))
        capture(app, "03-golden-hour")
        let directions = app.buttons["Directions"]
        reveal(directions, in: app)
        directions.tap()
        XCTAssertTrue(app.buttons["Apple Maps"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Google Maps"].exists)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        XCTAssertFalse(app.buttons["Apple Maps"].exists)

        let carouselPhoto = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "event-release-card-renaudtixier"
        )).firstMatch
        reveal(carouselPhoto, in: app)
        XCTAssertGreaterThan(carouselPhoto.frame.height, 190)
        capture(app, "03b-event-releases")
        let calendar = app.buttons["Add to Calendar"]
        if calendar.exists {
            XCTAssertFalse(app.buttons["Choose a day"].exists)
            for _ in 0..<4 where !calendar.isHittable { app.swipeDown(velocity: .slow) }
            XCTAssertTrue(calendar.isHittable)
            calendar.tap()
            let cancel = app.navigationBars.buttons["Cancel"].firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 5))
            cancel.tap()
            let discard = app.buttons["Discard Changes"].firstMatch
            if discard.waitForExistence(timeout: 3) { discard.tap() }
            XCTAssertTrue(cancel.waitForNonExistence(timeout: 5))
            let tabsRestored = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in app.tabBars.buttons["New releases"].isHittable },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [tabsRestored], timeout: 5), .completed)
        }
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
        XCTAssertFalse(app.buttons["Details for ALTO"].exists)
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
