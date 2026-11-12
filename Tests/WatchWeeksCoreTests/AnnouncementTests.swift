import XCTest
@testable import WatchWeeksCore

final class AnnouncementTests:XCTestCase {
    private let now=ISO8601DateFormatter().date(from:"2026-11-12T17:30:00Z")!
    private func raw() throws -> [String:Any] {
        let url=try XCTUnwrap(Bundle.module.url(forResource:"announced-singapore-2026-11-12",withExtension:"json",subdirectory:"Fixtures"))
        return try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [String:Any]
    }
    private func decode(_ raw:[String:Any]) throws -> Guide {
        try JSONDecoder().decode(PublicDetail.self,from:JSONSerialization.data(withJSONObject:raw)).model()
    }
    private func dated(_ dates:[String],zone:String="Asia/Singapore") throws -> Guide {
        var value=try raw(),header=value["guide"] as! [String:Any]
        header["timezone"]=zone;value["guide"]=header
        let sample=(value["announced"] as! [[String:Any]])[0]
        value["announced"]=dates.enumerated().map { index,date in
            var item=sample;item["id"]="fixture-\(index)";item["date"]=date;return item
        }
        return try decode(value)
    }
    func testActualPublicContractOrderAndUnknownFields() throws {
        var value=try raw();value["future_extra"]=["ignore":true]
        var items=value["announced"] as! [[String:Any]]
        items[0]["unknown_property"]="ignored";value["announced"]=items
        let guide=try decode(value)
        XCTAssertEqual(guide.announced?.count,12)
        XCTAssertEqual(guide.recentAnnounced(now:now).map(\.id),items.compactMap{$0["id"] as? String})
        XCTAssertEqual(guide.recentAnnounced(now:now).first?.brand,"Trilobe")
        XCTAssertEqual(guide.recentAnnounced(now:now).first?.eventName,"IAMWATCH")
    }
    func testSevenLocalCalendarDatesAndNoFutureDates() throws {
        let g=try dated(["2026-11-06","2026-11-07","2026-11-12","2026-11-13","2026-11-14"])
        XCTAssertEqual(g.recentAnnounced(now:now).map(\.date),["2026-11-07","2026-11-12","2026-11-13"])
        let la=try dated(["2026-11-05","2026-11-06","2026-11-12","2026-11-13"],zone:"America/Los_Angeles")
        XCTAssertEqual(la.recentAnnounced(now:now).map(\.date),["2026-11-06","2026-11-12"])
    }
    func testCalendarWindowAcrossDaylightSavingBoundary() throws {
        let g=try dated(["2026-10-26","2026-10-27","2026-11-02","2026-11-03"],zone:"America/Los_Angeles")
        let date=ISO8601DateFormatter().date(from:"2026-11-03T07:30:00Z")!
        XCTAssertEqual(g.recentAnnounced(now:date).map(\.date),["2026-10-27","2026-11-02"])
    }
    func testMissingEmptyNullAndMalformedAdditionsDoNotHideGuide() throws {
        for field in [nil,[] as [Any],NSNull(),"bad"] as [Any?] {
            var value=try raw();value.removeValue(forKey:"announced")
            if let field { value["announced"]=field }
            let guide=try decode(value)
            XCTAssertTrue(guide.recentAnnounced(now:now).isEmpty)
            XCTAssertFalse(guide.events.isEmpty)
        }
        var value=try raw();var items=value["announced"] as! [[String:Any]]
        items.insert(["id":"broken"],at:0);value["announced"]=items
        XCTAssertEqual(try decode(value).recentAnnounced(now:now).count,12)
    }
    func testUnsafePhotosInvalidDatesAndDuplicateIDsAreRejectedWithoutResorting() throws {
        var value=try raw();var items=value["announced"] as! [[String:Any]]
        items[0]["imageUrl"]="http://example.invalid/photo.jpg";items[1]["date"]="2026-99-99"
        items.append(items[2]);value["announced"]=items
        let result=try decode(value).recentAnnounced(now:now)
        XCTAssertEqual(result.count,10);XCTAssertEqual(result.first?.id,items[2]["id"] as? String)
    }
    func testHomeThresholdAndEventSpecificPhotoDeduplication() throws {
        let single=try dated(["2026-11-12"])
        XCTAssertTrue(single.announcedPhotoExclusions(surface:.home,now:now).isEmpty)
        XCTAssertEqual(single.recentAnnounced(now:now,eventID:"iamwatch").count,1)
        XCTAssertTrue(single.recentAnnounced(now:now,eventID:"golden-hour").isEmpty)
        let two=try dated(["2026-11-12","2026-11-12"])
        XCTAssertEqual(two.announcedPhotoExclusions(surface:.home,now:now),Set(two.recentAnnounced(now:now).map(\.brandKey)))
        XCTAssertTrue(two.announcedPhotoExclusions(surface:.guide,now:now,eventIDs:["not-visible"]).isEmpty)
    }
    func testJustAddedRequiresSameBrandEventRecentModelText() throws {
        let g=try decode(raw()),item=try XCTUnwrap(g.announced?.first)
        XCTAssertTrue(g.releaseCatalog().contains{$0.brandID == item.brandKey && g.isJustAdded($0,now:now)})
        let r=Release(id:"test",title:item.model.uppercased(),details:"Full reveal",brandID:item.brandKey,eventID:item.eventId)
        XCTAssertTrue(g.isJustAdded(r,now:now))
        XCTAssertFalse(g.isJustAdded(Release(id:"other",title:item.model,brandID:item.brandKey,eventID:"other-event"),now:now))
        XCTAssertFalse(g.isJustAdded(Release(id:"other",title:item.model,brandID:"other-brand",eventID:item.eventId),now:now))
        XCTAssertFalse(g.isJustAdded(r,now:now.addingTimeInterval(10*86400)))
        XCTAssertFalse(g.isJustAdded(Release(id:"other",title:"Different watch",brandID:item.brandKey,eventID:item.eventId),now:now))
    }
    func testOldAndNewCacheCompatibilityAndExpiry() throws {
        let g=try decode(raw()),data=try JSONEncoder().encode(g)
        let restored=try JSONDecoder().decode(Guide.self,from:data)
        XCTAssertEqual(restored.announced,g.announced)
        XCTAssertTrue(restored.recentAnnounced(now:now.addingTimeInterval(10*86400)).isEmpty)
        var old=try JSONSerialization.jsonObject(with:data) as! [String:Any]
        old.removeValue(forKey:"announced");old.removeValue(forKey:"announcementsResolved")
        let legacy=try JSONDecoder().decode(Guide.self,from:JSONSerialization.data(withJSONObject:old))
        XCTAssertNil(legacy.announced)
    }
    func testEventBrandChipsPrioritizeReleaseAndKeepVisitOrderWithoutDuplicates() {
        var brands=(0..<12).map { Brand(id:"brand-\($0)",name:"Brand \($0)",eventIDs:["fair"]) }
        brands[10].releaseEventIDs=["fair"]
        let g=Guide(id:"g",city:"City",timeZone:"UTC",brands:brands+[brands[0]])
        let first=g.eventChipBrands(eventID:"fair",seed:"same-visit")
        XCTAssertEqual(first.brands.count,8);XCTAssertEqual(first.remaining,4)
        XCTAssertEqual(first.brands.first?.id,"brand-10")
        XCTAssertEqual(Set(first.brands.map(\.id)).count,8)
        XCTAssertEqual(first.brands.map(\.id),g.eventChipBrands(eventID:"fair",seed:"same-visit").brands.map(\.id))
        XCTAssertTrue(g.eventChipBrands(eventID:"other",seed:"same").brands.isEmpty)
        let single=Guide(id:"g",city:"City",timeZone:"UTC",brands:[brands[0]])
        XCTAssertTrue(single.eventChipBrands(eventID:"fair",seed:"same").brands.isEmpty)
    }
    @MainActor func testTelemetryIsConsentedAndOmitsModelNotesCreditAndPrices() async throws {
        let name="announced.analytics.\(UUID())",defaults=UserDefaults(suiteName:name)!
        defer{defaults.removePersistentDomain(forName:name)}
        var bodies:[[String:Any]]=[]
        let c=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { request in
            bodies.append(try JSONSerialization.jsonObject(with:request.httpBody!) as! [String:Any]);return 200
        }
        let interaction=AnnouncementInteraction(source:.home,brandKey:"trilobe",position:0,count:12,date:"2026-11-12")
        c.record(.announced,guideID:"singapore-2026",eventID:"iamwatch",announcement:interaction)
        await Task.yield();XCTAssertTrue(bodies.isEmpty)
        c.setEnabled(true);c.record(.announced,guideID:"singapore-2026",eventID:"iamwatch",announcement:interaction)
        for _ in 0..<50 where bodies.count<2 { await Task.yield() }
        let p=try XCTUnwrap(bodies.last?["properties"] as? [String:Any])
        XCTAssertEqual(p["source"] as? String,"home");XCTAssertEqual(p["brand_key"] as? String,"trilobe")
        XCTAssertEqual(p["position"] as? Int,0);XCTAssertEqual(p["count"] as? Int,12)
        XCTAssertEqual(p["announced_date"] as? String,"2026-11-12")
        XCTAssertFalse(Set(p.keys).contains(where:{["model","notes","prices","credit","variant"].contains($0)}))
        c.setEnabled(false)
    }
}
