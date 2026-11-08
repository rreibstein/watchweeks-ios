import XCTest
@testable import WatchWeeksCore
final class AnalyticsTests: XCTestCase {
    @MainActor func testConsentAndForegroundDeduplication() async {
        var events:[AnalyticsPayload]=[]
        let gate=AnalyticsGate { events.append($0) }
        gate.becameActive(version:"1",build:"1"); XCTAssertTrue(events.isEmpty)
        gate.setEnabled(true); gate.becameActive(version:"1",build:"1"); XCTAssertTrue(events.isEmpty)
        gate.becameInactive();gate.becameActive(version:"1",build:"1");gate.becameActive(version:"1",build:"1");XCTAssertEqual(events.count,1)
        gate.setEnabled(false);gate.track(AnalyticsPayload(.ratingSet,version:"1",build:"1",rating:"must"));XCTAssertEqual(events.count,1)
    }
    func testEventAllowlistHasOnlyPublicContext() {
        for event in AnalyticsName.allCases {
            let p=AnalyticsPayload(event,version:"1.0.0",build:"1",guideID:"singapore-2026",brandID:"atelierwen",rating:"must")
            XCTAssertEqual(p.properties["platform"],"ios_native")
            XCTAssertEqual(Set(p.properties.keys),Set(["platform","app_version","app_build","instrumentation_version","guide_id","brand_id","rating_category"]))
        }
    }
}
