import XCTest
@testable import WatchWeeksCore

final class EventPlanningTests: XCTestCase {
    func testLocalScheduleKeepsSingaporeDateAndRejectsRawInvalidValues() throws {
        let day = EventDay(date: "2026-11-12", open: "14:00", close: "21:00", access: "invitation")
        let range = try XCTUnwrap(LocalSchedule.interval(day, zone: "Asia/Singapore"))
        let utc = ISO8601DateFormatter()
        XCTAssertEqual(range.lowerBound, utc.date(from: "2026-11-12T06:00:00Z"))
        XCTAssertEqual(range.upperBound, utc.date(from: "2026-11-12T13:00:00Z"))
        let label = LocalSchedule.label(day, zone: "Asia/Singapore")
        XCTAssertTrue(label.contains("2:00 PM – 9:00 PM · Invitation only"))
        XCTAssertFalse(label.contains("2026-11-12"))
        XCTAssertNil(LocalSchedule.minute("24:55"))
        XCTAssertNil(LocalSchedule.minute("14:60"))
        XCTAssertNil(LocalSchedule.accessLabel("internal_flag"))
    }

    func testLiveStatusUsesLocalDayAndClosingBoundary() throws {
        let event = Event(id: "fair", name: "Fair", days: [
            EventDay(date: "2026-11-13", open: "11:00", close: "20:00", access: nil),
            EventDay(date: "2026-11-14", open: "11:00", close: "20:00", access: nil)
        ])
        let guide = Guide(id: "singapore", city: "Singapore", timeZone: "Asia/Singapore", events: [event])
        let utc = ISO8601DateFormatter()
        for (instant, expected) in [("02:59", LiveEvent.Status.today), ("03:00", .now), ("12:00", .tomorrow)] {
            let now = try XCTUnwrap(utc.date(from: "2026-11-13T\(instant):00Z"))
            XCTAssertEqual(LiveEvent.next(in: [guide], now: now)?.status, expected)
        }
    }

    func testSingaporePlannerShowsSaturdayTalkTradeOffWithoutOverlappingTravel() throws {
        let fixture = try XCTUnwrap(Bundle.module.url(forResource: "singapore", withExtension: "json", subdirectory: "Fixtures"))
        let detail = try JSONDecoder().decode(PublicDetail.self, from: Data(contentsOf: fixture))
        let events = try detail.model().events
        let spring = try XCTUnwrap(events.first { $0.id == "spring-sprang-sprung" })
        XCTAssertEqual(LocalSchedule.days(for: spring, guideID: "singapore-2026").first?.close, "18:00")
        let date = "2026-11-14"
        let afternoon = 780..<1020
        let noTalk = SingaporeItinerary.plan(events: events, date: date, window: afternoon)
        XCTAssertEqual(noTalk.count, 3)
        let talk = SingaporeItinerary.Talk(title: "GD100 Screening & Conversation", date: date, hours: 960..<1020)
        let plan = SingaporeItinerary.plan(events: events, date: date, window: afternoon, talk: talk)
        XCTAssertEqual(plan.filter { !$0.isTalk }.count, 2)
        XCTAssertEqual(plan.last?.hours, talk.hours)
        for (first, second) in zip(plan, plan.dropFirst()) {
            XCTAssertGreaterThanOrEqual(second.hours.lowerBound, first.hours.upperBound + second.transit)
        }
        let friday = SingaporeItinerary.plan(events: events, date: "2026-11-13", window: 660..<1200)
        XCTAssertFalse(friday.contains { $0.eventID == "spring-sprang-sprung" })
    }

    func testLegacySelectionsAndExplicitShortlistOverride() throws {
        let old = Data(#"{"interest":2,"seen":true}"#.utf8)
        let selection = try JSONDecoder().decode(Selection.self, from: old)
        XCTAssertTrue(selection.isShortlisted)
        XCTAssertFalse(Selection(interest: .mustSee, seen: true, shortlisted: false).isShortlisted)
    }

    func testReleaseMetadataOnlyDisplaysSupportedValues() {
        let release = Release(id: "release", title: "Watch", details: "Price: CHF 3,150. Availability: Sold out.", awards: ["GPHG 2026 Winner"])
        XCTAssertEqual(release.displayedPrice, "CHF 3,150")
        XCTAssertEqual(release.displayBadges, ["Sold out", "GPHG 2026 Winner"])
        XCTAssertNil(Release(id: "none", title: "Watch", details: "Price unavailable").displayedPrice)
    }
}
