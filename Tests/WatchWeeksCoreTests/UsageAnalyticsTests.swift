import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
final class UsageAnalyticsTests: XCTestCase {
    @MainActor func testDeclineAndConsentPayloadAllowlist() async throws {
        let name="analytics.tests.\(UUID())"; let defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        var delivered:[Data]=[]
        let client=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1.0.2",build:"1",defaults:defaults) { request in
            delivered.append(request.httpBody!);return 200
        }
        client.record(.rating,guideID:"singapore"); await Task.yield(); XCTAssertTrue(delivered.isEmpty)
        client.setEnabled(true)
        client.record(.guide,guideID:"singapore")
        for _ in 0..<30 where delivered.count < 2 { await Task.yield() }
        XCTAssertEqual(delivered.count,2)
        let data=try XCTUnwrap(delivered.last)
        let body=try JSONSerialization.jsonObject(with:data) as! [String:Any]
        let props=body["properties"] as! [String:Any]
        XCTAssertEqual(props["platform"] as? String,"ios_native")
        XCTAssertEqual(props["guide_id"] as? String,"singapore")
        XCTAssertEqual(props["$geoip_disable"] as? Bool,true)
        XCTAssertEqual(Set(props.keys),["platform","$geoip_disable","$process_person_profile","app_version","app_build","guide_id"])
        client.setEnabled(false);client.record(.rating);await Task.yield();XCTAssertEqual(delivered.count,2)
    }
    @MainActor func testOfflineQueueSurvivesRestartAndOptOutPurgesIt() async throws {
        let name="analytics.tests.\(UUID())";let defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let offline=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in throw URLError(.notConnectedToInternet) }
        offline.setEnabled(true);offline.record(.event,guideID:"singapore",eventID:"fair")
        await Task.yield();offline.suspendDelivery();XCTAssertEqual(offline.pendingCount,2)
        var delivered=0
        let restored=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in delivered+=1;return 200 }
        for _ in 0..<30 where delivered < 2 { await Task.yield() }
        XCTAssertEqual(delivered,2);XCTAssertEqual(restored.pendingCount,0)
        restored.setEnabled(false)
        let declined=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in XCTFail("Opted out");return 200 }
        XCTAssertFalse(declined.enabled);XCTAssertEqual(declined.pendingCount,0)
    }
    @MainActor func testForegroundDoesNotDoubleCountInactiveTransitionsAndQueueIsBounded() async throws {
        let name="analytics.tests.\(UUID())";let defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let client=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in 503 }
        client.setEnabled(true);client.becameActive();client.becameActive()
        XCTAssertEqual(client.pendingCount,2)
        client.becameBackground();client.becameActive();XCTAssertEqual(client.pendingCount,3)
        for _ in 0..<110 { client.record(.guide) };XCTAssertEqual(client.pendingCount,100)
        client.setEnabled(false);XCTAssertEqual(client.pendingCount,0)
        XCTAssertNil(defaults.data(forKey:"usageAnalytics.pending.v1"))
        XCTAssertNil(defaults.string(forKey:"usageAnalytics.installID"))
    }
}

final class UsageAnalyticsCancellationTests: XCTestCase {
    @MainActor func testOptOutWhileRequestIsInFlightDoesNotSendNextQueuedEvent() async throws {
        let name="analytics.tests.\(UUID())";let defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        var started=0
        var response: CheckedContinuation<Int,Never>?
        let client=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in
            started+=1
            return await withCheckedContinuation { response=$0 }
        }
        client.setEnabled(true);client.record(.rating)
        for _ in 0..<30 where response == nil { await Task.yield() }
        XCTAssertEqual(started,1)
        client.setEnabled(false);response?.resume(returning:200)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(started,1);XCTAssertEqual(client.pendingCount,0)
        XCTAssertNil(defaults.data(forKey:"usageAnalytics.pending.v1"))
    }
}
