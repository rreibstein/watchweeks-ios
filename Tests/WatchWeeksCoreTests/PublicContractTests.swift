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
