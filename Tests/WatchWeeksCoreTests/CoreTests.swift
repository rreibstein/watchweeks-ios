import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
// All examples in this file are SYNTHETIC, never bundled into the application.
final class CoreTests: XCTestCase {
    func guide(id: String = "test-city") -> Guide { Guide(id: id, city: "Test City", startDate: "2026-11-12", endDate: "2026-11-15", timeZone: "Asia/Singapore", brands: [Brand(id: "brand-a", name: "Example A"), Brand(id: "brand-b", name: "Example B")]) }
    func temporaryStore() -> (LocalStore, URL) { let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); return (LocalStore(directory: url), url) }
    func testInternalCacheRoundTrip() throws { let g = guide(); XCTAssertEqual(try JSONDecoder().decode(Guide.self, from: JSONEncoder().encode(g)), g) }
    func testMissingAndMalformedInternalFields() {
        XCTAssertThrowsError(try JSONDecoder().decode(Guide.self, from: Data(#"{"city":"Test"}"#.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(Guide.self, from: Data(#"{"id":123}"#.utf8)))
    }
    func testGuideAvailabilityUsesEventTimezoneAndInclusiveEndDay() {
        let g=guide()
        XCTAssertEqual(EventDates.status(g, now: EventDates.parse("2026-11-11T15:59:00Z", zone: g.timeZone)!), .upcoming)
        XCTAssertEqual(EventDates.status(g, now: EventDates.parse("2026-11-11T16:00:00Z", zone: g.timeZone)!), .current)
        XCTAssertEqual(EventDates.status(g, now: EventDates.parse("2026-11-15T15:59:00Z", zone: g.timeZone)!), .current)
        XCTAssertEqual(EventDates.status(g, now: EventDates.parse("2026-11-15T16:00:00Z", zone: g.timeZone)!), .past)
    }
    func testInvalidDatesAndUnknownSchedule() {
        XCTAssertNil(EventDates.parse("2026-02-30", zone: "Asia/Singapore"))
        XCTAssertNil(EventDates.parse("tomorrow", zone: "Asia/Singapore"))
        XCTAssertEqual(EventDates.status(Guide(id: "x", city: "Test", timeZone: "UTC")), .unknown)
    }
    func testFractionalDatesAndTimezoneDisplay() {
        let a=EventDates.parse("2026-11-12T09:00:00.000+08:00", zone: "Asia/Singapore")
        let b=EventDates.parse("2026-11-12T01:00:00Z", zone: "UTC")
        XCTAssertEqual(a,b)
        XCTAssertNotEqual(EventDates.label("2026-11-12T01:00:00Z", zone: "UTC"), EventDates.label("2026-11-12T01:00:00Z", zone: "Asia/Singapore"))
    }
    func testStableIdentityValidation() {
        XCTAssertThrowsError(try GuideRepository.validate([guide(),guide()]))
        XCTAssertNoThrow(try GuideRepository.validate([guide(),guide(id: "other")]))
        var g=guide(); g.brands.append(g.brands[0]); XCTAssertThrowsError(try GuideRepository.validate([g]))
    }
    func testSearchAndFilters() {
        let brands=guide().brands
        func selection(_ brand: Brand) -> Selection { Selection(interest: brand.id == "brand-a" ? .mustSee : .interested, seen: brand.id == "brand-b") }
        XCTAssertEqual(Browsing.brands(brands, query: " EXAMPLE A ", filter: .all, selection: selection).count,1)
        XCTAssertEqual(Browsing.brands(brands, query: "", filter: .remaining, selection: selection).map(\.id),["brand-a"])
        XCTAssertEqual(Browsing.brands(brands, query: "", filter: .seen, selection: selection).map(\.id),["brand-b"])
    }
    func testPersistenceAndMultiCityIsolation() async throws {
        let (store,url)=temporaryStore(); defer { try? FileManager.default.removeItem(at:url) }
        let a=SelectionKey(guideID:"a",brandID:"same"), b=SelectionKey(guideID:"b",brandID:"same")
        let expected=[a:Selection(interest:.mustSee,seen:true), b:Selection(interest:.interested)]
        try await store.saveSelections(expected)
        let reopened=LocalStore(directory:url); let actual=try await reopened.selections(); XCTAssertEqual(actual,expected)
        try await store.saveSelections([a:Selection()]); let cleared=try await reopened.selections(); XCTAssertEqual(cleared[a]?.interest,Interest.none)
    }
    func testEmptyStore() async throws { let (store,_)=temporaryStore(); let result=try await store.selections(); XCTAssertTrue(result.isEmpty) }
    func testCorruptSelectionsAreNotOverwrittenByRead() async throws {
        let (store,url)=temporaryStore(); defer { try? FileManager.default.removeItem(at:url) }
        try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)
        let file=url.appendingPathComponent("selections-v1.json"); try Data("bad".utf8).write(to:file)
        do { _ = try await store.selections(); XCTFail("Should fail") } catch {}
        XCTAssertEqual(try String(contentsOf:file,encoding:.utf8),"bad")
    }
    struct Stub: GuideService { let result: [Guide]?; func guides() async throws -> [Guide] { guard let result else { throw URLError(.notConnectedToInternet) }; return result } }
    func testOfflineFallbackAndRefresh() async throws {
        let (store,url)=temporaryStore(); defer { try? FileManager.default.removeItem(at:url) }
        let first=try await GuideRepository(service:Stub(result:[guide()]),store:store).load(); XCTAssertFalse(first.stale)
        let offline=try await GuideRepository(service:Stub(result:nil),store:store).load(); XCTAssertTrue(offline.stale); XCTAssertEqual(offline.guides,first.guides); XCTAssertEqual(offline.fetchedAt,first.fetchedAt)
        let refreshed=try await GuideRepository(service:Stub(result:[]),store:store).load(); XCTAssertFalse(refreshed.stale); XCTAssertTrue(refreshed.guides.isEmpty)
    }
    func testUncachedOfflineThrows() async { let (store,_)=temporaryStore(); do { _ = try await GuideRepository(service:Stub(result:nil),store:store).load(); XCTFail("Expected error") } catch {} }
    func testRemovedGuideRemainsInChecklistLibrary() async throws {
        let (store,url)=temporaryStore(); defer { try? FileManager.default.removeItem(at:url) }
        try await store.saveGuides([guide()]);try await store.saveGuides([])
        let library=try await store.rememberedGuides();let index=try await store.snapshot()
        XCTAssertEqual(library.count,1);XCTAssertEqual(index?.guides.count,0)
    }
    func testWebsiteRatingCategories() {
        XCTAssertEqual([Interest.mustSee,.interested,.little,.unfamiliar,.skip].map(\.category),["must","moderate","little","unknown","none"])
        XCTAssertNotEqual(Interest.none,Interest.skip)
    }
    func testPublicURLs() {
        XCTAssertEqual(PublicLinks.apiGuide("abc")?.absoluteString,"https://watchweeks.com/api/public/guides/abc")
        for id in ["", "..", "a/b", "a?b", "%2F", "a#b"] { XCTAssertNil(PublicLinks.apiGuide(id)) }
        XCTAssertNil(PublicLinks.safeExternal(URL(string:"javascript:alert(1)")))
        XCTAssertNil(PublicLinks.safeExternal(URL(string:"https://user:password@watchweeks.com")))
    }
}
