import Foundation
import XCTest
@testable import WatchWeeksCore
final class PublicContractTests: XCTestCase {
    func fixture(_ name:String) throws -> Data { try Data(contentsOf:Bundle.module.url(forResource:name,withExtension:"json",subdirectory:"Fixtures")!) }
    func testObservedGuideIndex() throws {
        let p=try JSONDecoder().decode(PublicIndex.self,from:fixture("index"));XCTAssertEqual(p.v,1);XCTAssertTrue(p.guides.contains{$0.id=="singapore-2026"})
    }
    func testObservedSingaporeAndAustin() throws {
        for name in ["singapore","austin"] {
            let d=try JSONDecoder().decode(PublicDetail.self,from:fixture(name));let g=try d.model()
            XCTAssertFalse(g.events.isEmpty);XCTAssertFalse(g.brands.isEmpty);XCTAssertFalse(g.releases.isEmpty)
            XCTAssertEqual(Set(g.brands.map(\.id)).count,g.brands.count)
            XCTAssertTrue(g.events.allSatisfy{!$0.days.isEmpty})
        }
        let g=try JSONDecoder().decode(PublicDetail.self,from:fixture("singapore")).model()
        XCTAssertEqual(g.brands.first{$0.id=="atelierwen"}?.eventIDs.count,2)
        XCTAssertEqual(g.events.first{$0.id=="iamwatch"}?.days.first?.access,"invitation")
    }
    func testUnsupportedVersionRejected() throws {
        var p=try JSONSerialization.jsonObject(with:fixture("singapore")) as! [String:Any];p["v"]=999
        let detail=try JSONDecoder().decode(PublicDetail.self,from:JSONSerialization.data(withJSONObject:p))
        XCTAssertThrowsError(try detail.model())
    }
    func testMissingAndMalformedWireFields() throws {
        var p=try JSONSerialization.jsonObject(with:fixture("singapore")) as! [String:Any]
        p["brands"]=[["brandKey":123]]
        XCTAssertThrowsError(try JSONDecoder().decode(PublicDetail.self,from:JSONSerialization.data(withJSONObject:p)))
    }
}

extension PublicContractTests {
    func testAustinEditionSeparatesAccessAndModels() throws {
        let guide = try JSONDecoder().decode(PublicDetail.self, from: fixture("austin")).model()
        let fair = try XCTUnwrap(guide.publicEvents.first { $0.id == "minutes-hours" })
        XCTAssertFalse(guide.publicEvents.contains { $0.id == "minutes-preview" })
        XCTAssertEqual(guide.accessSessions(for: fair).map(\.id), ["minutes-preview"])
        let baltic = guide.newReleases(for: "baltic").filter { $0.eventID == "intersect" }
        let rift = try XCTUnwrap(baltic.first { $0.title == "Hermétique The Rift" })
        XCTAssertEqual(rift.displayedPrice, "€620")
        XCTAssertEqual(rift.displayBadges, ["Sold out"])
        XCTAssertTrue(rift.imageURL?.lastPathComponent.contains("hermetique") == true)
        XCTAssertEqual(baltic.first { $0.title == "Aquascaphe GMT MK-II" }?.displayBadges, [])
        XCTAssertEqual(guide.newReleases(for: "yema").filter(\.isNotExhibited).count, 2)
        XCTAssertEqual(guide.newReleases(for: "christopherward").filter {
            $0.displayBadges.contains("GPHG 2026 nominee")
        }.map(\.title), ["C1 Loco Classic"])
        XCTAssertEqual(Brand.canonicalName("CW", id: nil), "Christopher Ward")
        XCTAssertEqual(Brand.canonicalName("TWCO", id: "toolwatchco"), "TWCO. (Tool Watch Co.)")
    }

    func testLegacySelectionCanStoreIndependentFeedback() throws {
        var selection = try JSONDecoder().decode(Selection.self, from: Data(#"{"interest":2,"seen":true}"#.utf8))
        XCTAssertNil(selection.reaction)
        selection.reaction = .loved
        selection.buyingIntent = .considerBuying
        let restored = try JSONDecoder().decode(Selection.self, from: JSONEncoder().encode(selection))
        XCTAssertEqual(restored.reaction, .loved)
        XCTAssertEqual(restored.buyingIntent, .considerBuying)
        XCTAssertEqual(restored.interest, .mustSee)
        XCTAssertTrue(restored.seen)
    }
}
