import XCTest
@testable import WatchWeeksCore
final class ForthcomingGuideTests: XCTestCase {
    func testAnnouncedTitlesDoNotInventDates() {
        XCTAssertEqual(ForthcomingGuide.awaitingPublication(in:[]).map(\.title),["Geneva (W&W)","British Watchmakers’ Day","Las Vegas"])
    }
    func testPublishedCitiesDisappearFromForthcomingPromo() {
        let guides=[Guide(id:"geneva-2027",city:"Geneva",timeZone:"Europe/Zurich"),Guide(id:"las-vegas-2027",city:"Las Vegas",timeZone:"America/Los_Angeles")]
        XCTAssertEqual(ForthcomingGuide.awaitingPublication(in:guides).map(\.id),["bwd"])
    }
    func testLondonBWDAndUnrelatedGenevaEventAreHandledSeparately() {
        let london=Guide(id:"british-watchmakers-day-2027",city:"London",timeZone:"Europe/London")
        let hk=Guide(id:"hk",city:"Hong Kong",timeZone:"Asia/Hong_Kong",events:[Event(id:"preview",name:"Geneva auction preview")])
        XCTAssertEqual(ForthcomingGuide.awaitingPublication(in:[london,hk]).map(\.id),["geneva","las-vegas"])
    }
    func testPushRoutesRequireSupportedVersionAndSafeIdentity() {
        XCTAssertEqual(GuidePublicationPush.guideID(type:"guide_published",version:1,id:"geneva-2027"),"geneva-2027")
        for id in ["","../account","a/b","https://bad.example","id?token=x",String(repeating:"x",count:129)] {
            XCTAssertNil(GuidePublicationPush.guideID(type:"guide_published",version:1,id:id))
        }
        XCTAssertNil(GuidePublicationPush.guideID(type:"other",version:1,id:"guide"))
        XCTAssertNil(GuidePublicationPush.guideID(type:"guide_published",version:2,id:"guide"))
    }
}
