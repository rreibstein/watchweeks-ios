import Foundation
import XCTest
@testable import WatchWeeksCore

final class LaunchCacheSafetyTests: XCTestCase {
    // Synthetic corruption fixtures only. No customer cache or selections are used.
    private func guide() -> Guide {
        Guide(id:"test-city",city:"Test City",timeZone:"UTC",
              brands:[Brand(id:"brand",name:"Test Brand")],
              releases:[Release(id:"release",title:"Test Watch",brandID:"brand")])
    }
    private func directory() throws -> URL {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)
        return url
    }
    private func badGuide() -> Guide {
        var value=guide()
        value.releases.append(Release(id:"release",title:"Different Watch",brandID:"brand"))
        return value
    }
    func testDuplicateCachedReleaseIDsAreRejectedWithoutChangingSavedSelections() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let store=LocalStore(directory:root)
        let key=SelectionKey(guideID:"test-city",brandID:"brand")
        let selection=[key:Selection(interest:.mustSee,seen:true)]
        try await store.saveSelections(selection)
        let original=try JSONEncoder().encode(GuideSnapshot(fetchedAt:Date(),guides:[badGuide()]))
        let file=root.appendingPathComponent("guides-v1.json");try original.write(to:file)
        do { _=try await store.snapshot();XCTFail("A malformed cache must not reach the launch UI") }
        catch { XCTAssertEqual(error as? FeedError,.invalidResponse) }
        let restored=try await store.selections();XCTAssertEqual(restored,selection)
        XCTAssertEqual(try Data(contentsOf:file),original)
    }
    func testInvalidRememberedLibraryIsRejectedWithoutRewritingIt() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let original=try JSONEncoder().encode([guide(),guide()])
        let file=root.appendingPathComponent("guide-library-v1.json");try original.write(to:file)
        let store=LocalStore(directory:root)
        do { _=try await store.rememberedGuides();XCTFail("Duplicate city IDs must not enter My list") }
        catch { XCTAssertEqual(error as? FeedError,.invalidResponse) }
        XCTAssertEqual(try Data(contentsOf:file),original)
    }
    private struct Service: GuideService {
        let values:[Guide]?
        func guides() async throws -> [Guide] {
            guard let values else { throw URLError(.notConnectedToInternet) };return values
        }
    }
    func testOfflineFallbackCannotReturnMalformedCachedGuide() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        try JSONEncoder().encode(GuideSnapshot(fetchedAt:Date(),guides:[badGuide()]))
            .write(to:root.appendingPathComponent("guides-v1.json"))
        let repository=GuideRepository(service:Service(values:nil),store:LocalStore(directory:root))
        do { _=try await repository.load();XCTFail("Network failure must not bypass cache validation") }
        catch { XCTAssertEqual((error as? URLError)?.code,.notConnectedToInternet) }
    }
    func testHealthyRefreshRepairsSnapshotAndPreservesChecklistLibraryAndSelections() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let store=LocalStore(directory:root),expected=guide()
        try await store.saveGuides([expected])
        let key=SelectionKey(guideID:expected.id,brandID:"brand")
        let picks=[key:Selection(interest:.interested,seen:true)]
        try await store.saveSelections(picks)
        try JSONEncoder().encode(GuideSnapshot(fetchedAt:Date(),guides:[badGuide()]))
            .write(to:root.appendingPathComponent("guides-v1.json"))
        let load=try await GuideRepository(service:Service(values:[expected]),store:store).load()
        XCTAssertFalse(load.stale);XCTAssertEqual(load.guides,[expected])
        let snapshot=try await store.snapshot(),library=try await store.rememberedGuides(),restored=try await store.selections()
        XCTAssertEqual(snapshot?.guides,[expected]);XCTAssertEqual(library,[expected]);XCTAssertEqual(restored,picks)
    }
    func testValidLegacySnapshotWithoutLibraryRemainsUsableOffline() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let expected=guide(),date=Date(timeIntervalSince1970:1_700_000_000)
        try JSONEncoder().encode(GuideSnapshot(fetchedAt:date,guides:[expected]))
            .write(to:root.appendingPathComponent("guides-v1.json"))
        let store=LocalStore(directory:root)
        let load=try await GuideRepository(service:Service(values:nil),store:store).load()
        XCTAssertTrue(load.stale);XCTAssertEqual(load.guides,[expected]);XCTAssertEqual(load.fetchedAt,date)
        let library=try await store.rememberedGuides();XCTAssertEqual(library,[expected])
    }
    func testHealthyRefreshRepairsInvalidLegacyCacheAndKeepsValidOlderGuide() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let older=Guide(id:"older-city",city:"Older City",timeZone:"UTC")
        try JSONEncoder().encode(GuideSnapshot(fetchedAt:Date(),guides:[badGuide(),older]))
            .write(to:root.appendingPathComponent("guides-v1.json"))
        let store=LocalStore(directory:root)
        let load=try await GuideRepository(service:Service(values:[guide()]),store:store).load()
        XCTAssertNil(load.warning)
        let snapshot=try await store.snapshot(),library=try await store.rememberedGuides()
        XCTAssertEqual(snapshot?.guides,[guide()]);XCTAssertEqual(Set(library.map(\.id)),["test-city","older-city"])
    }
    func testHealthyRefreshRepairsDuplicateLibraryWithoutLosingOlderEdition() async throws {
        let root=try directory();defer { try? FileManager.default.removeItem(at:root) }
        let older=Guide(id:"older-city",city:"Older City",timeZone:"UTC")
        try JSONEncoder().encode([older,older,badGuide()])
            .write(to:root.appendingPathComponent("guide-library-v1.json"))
        let store=LocalStore(directory:root),key=SelectionKey(guideID:older.id,brandID:"remembered-brand")
        let selections=[key:Selection(interest:.mustSee,seen:true)]
        try await store.saveSelections(selections)
        let load=try await GuideRepository(service:Service(values:[guide()]),store:store).load()
        XCTAssertNil(load.warning)
        let library=try await store.rememberedGuides(),restored=try await store.selections()
        XCTAssertEqual(Set(library.map(\.id)),["test-city","older-city"]);XCTAssertEqual(restored,selections)
    }
}
