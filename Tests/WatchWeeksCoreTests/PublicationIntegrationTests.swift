import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class PublicationIntegrationTests: XCTestCase {
    // Sanitized contract examples, not production records or event dates.
    private let upcoming=Data(#"{"v":1,"upcoming":[{"key":"test-guide","title":"Test Guide","city":"Test City","state":"planned","start_date":null,"end_date":null,"url":null,"guide_id":null}],"capabilities":{"push":{"available":false,"reason":"backend_not_ready"}}}"#.utf8)
    func testUpcomingContractAndOfflineStorage() async throws {
        let feed=try JSONDecoder().decode(UpcomingGuideFeed.self,from:upcoming)
        try feed.validate()
        XCTAssertEqual(feed.planned.map(\.key),["test-guide"])
        XCTAssertNil(feed.planned.first?.start_date)
        XCTAssertFalse(feed.capabilities.push.available)
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        let store=LocalStore(directory:directory);try await store.saveUpcoming(feed)
        let saved=try await LocalStore(directory:directory).upcoming()
        XCTAssertEqual(saved?.planned.first?.title,"Test Guide")
    }
    func testUnknownUpcomingVersionAndMalformedRecordsAreRejected() throws {
        let unsupported=try JSONDecoder().decode(UpcomingGuideFeed.self,from:Data(String(decoding:upcoming,as:UTF8.self).replacingOccurrences(of:"\"v\":1",with:"\"v\":2").utf8))
        XCTAssertThrowsError(try unsupported.validate())
        var object=try XCTUnwrap(JSONSerialization.jsonObject(with:upcoming) as? [String:Any])
        let rows=try XCTUnwrap(object["upcoming"] as? [[String:Any]])
        object["upcoming"]=rows+rows
        let duplicate=try JSONDecoder().decode(UpcomingGuideFeed.self,from:JSONSerialization.data(withJSONObject:object))
        XCTAssertThrowsError(try duplicate.validate())
        XCTAssertThrowsError(try JSONDecoder().decode(UpcomingGuideFeed.self,from:Data("{}".utf8)))
    }
    func testPushRequiresAllFieldsAndNeverUsesPayloadURLs() {
        XCTAssertNotNil(GuidePublicationNotification(type:"guide_published",version:1,guideID:"test-2027",notificationID:"test-2027:guide_published:v1"))
        XCTAssertNil(GuidePublicationNotification(type:"guide_published",version:1,guideID:"test-2027",notificationID:nil))
        XCTAssertNil(GuidePublicationNotification(type:"guide_published",version:99,guideID:"test-2027",notificationID:"test"))
        XCTAssertNil(GuidePublicationNotification(type:"guide_published",version:1,guideID:"https://malicious.invalid",notificationID:"test"))
        XCTAssertNil(GuidePublicationNotification(type:"guide_published",version:1,guideID:"test",notificationID:String(repeating:"a",count:257)))
    }
    func testDuplicateOpensAreSuppressedAcrossRestartsWithBoundedStorage() throws {
        let notification=try XCTUnwrap(GuidePublicationNotification(type:"guide_published",version:1,guideID:"test",notificationID:"test:guide_published:v1"))
        var inbox=GuidePublicationInbox(openedIDs:(0..<200).map { "test-\($0)" })
        XCTAssertTrue(inbox.accept(notification));XCTAssertEqual(inbox.openedIDs.count,200)
        var restarted=GuidePublicationInbox(openedIDs:inbox.openedIDs)
        XCTAssertFalse(restarted.accept(notification))
    }
    func testIndividualFailureRetainsLastGoodGuideAndOtherGuideRefreshes() async throws {
        let singapore=try Data(contentsOf:XCTUnwrap(Bundle.module.url(forResource:"singapore",withExtension:"json",subdirectory:"Fixtures")))
        let austin=try Data(contentsOf:XCTUnwrap(Bundle.module.url(forResource:"austin",withExtension:"json",subdirectory:"Fixtures")))
        let detail=try JSONDecoder().decode(PublicDetail.self,from:singapore)
        let old=try detail.model()
        let other=try JSONDecoder().decode(PublicDetail.self,from:austin)
        let index=try JSONSerialization.data(withJSONObject:["v":1,"guides":[
            try JSONSerialization.jsonObject(with:singapore) as! [String:Any],
            try JSONSerialization.jsonObject(with:austin) as! [String:Any]
        ].map { $0["guide"]! }])
        MockProtocol.status=200;MockProtocol.mime="application/json"
        MockProtocol.bodies=["/api/public/guides":index,"/api/public/guides/austin-2026":austin]
        let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[MockProtocol.self]
        let service=PublicGuideService(session:URLSession(configuration:config))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            MockProtocol.statusByPath=[:];MockProtocol.bodies=[:]
            try? FileManager.default.removeItem(at:directory)
        }
        let store=LocalStore(directory:directory)
        let savedAt=Date(timeIntervalSince1970:123)
        try await store.saveGuides([old],now:savedAt)
        let selection=SelectionKey(guideID:old.id,brandID:old.brands[0].id)
        try await store.saveSelections([selection:Selection(interest:.mustSee,seen:true)])
        for code in [404,503] {
            MockProtocol.statusByPath=["/api/public/guides/singapore-2026":code]
            let result=try await GuideRepository(service:service,store:store).load()
            XCTAssertTrue(result.stale);XCTAssertEqual(result.fetchedAt,savedAt)
            XCTAssertEqual(result.guides.first,old)
            XCTAssertEqual(result.guides.last?.id,other.guide.id)
            XCTAssertEqual(result.publishedIDs,Set([old.id,other.guide.id]))
        }
        MockProtocol.bodies["/api/public/guides/singapore-2026"]=singapore
        MockProtocol.statusByPath=[:]
        let recovered=try await GuideRepository(service:service,store:store).load()
        XCTAssertFalse(recovered.stale)
        let selections=try await store.selections()
        XCTAssertEqual(selections[selection]?.interest,.mustSee)
        XCTAssertEqual(selections[selection]?.seen,true)
    }
}

private final class PushProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status=201
    nonisolated(unsafe) static var body=Data()
    nonisolated(unsafe) static var requests: [URLRequest]=[]
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        client?.urlProtocol(self,didReceive:HTTPURLResponse(url:request.url!,statusCode:Self.status,httpVersion:"HTTP/1.1",headerFields:["Content-Type":"application/json"])!,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:Self.body);client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class PushClientTests: XCTestCase {
    private let id=UUID(uuidString:"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private let token=Data(repeating:0xAB,count:32) // synthetic, test-only
    override func tearDown() { PushProtocol.requests=[];super.tearDown() }
    private func client(status: Int, environment: String = "production") -> PushInstallationClient {
        PushProtocol.status=status
        PushProtocol.body=Data("{\"installation_id\":\"\(id)\",\"credential\":\"wwpi_SYNTHETIC_ONLY\",\"state\":\"active\",\"environment\":\"\(environment)\",\"guides\":null}".utf8)
        let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[PushProtocol.self]
        return PushInstallationClient(session:URLSession(configuration:config))
    }
    func testRegistrationContractAndProductionEnvironmentForTestFlight() async throws {
        let result=try await client(status:201).register(token:token,environment:.production,appVersion:"1.0.2",osVersion:"26.1")
        XCTAssertEqual(result.environment,.production)
        let request=try XCTUnwrap(PushProtocol.requests.last)
        XCTAssertEqual(request.httpMethod,"POST")
        XCTAssertEqual(request.url?.absoluteString,"https://watchweeks.com/api/public/push/installations")
        XCTAssertNil(request.value(forHTTPHeaderField:"Authorization"))
        let body=try XCTUnwrap(JSONSerialization.jsonObject(with:XCTUnwrap(request.httpBody)) as? [String:Any])
        XCTAssertEqual(body["apns_token"] as? String,String(repeating:"ab",count:32))
        XCTAssertEqual(body["environment"] as? String,"production")
        XCTAssertTrue(body["guides"] is NSNull)
        XCTAssertEqual(Set(body.keys),Set(["platform","apns_token","environment","app_version","os_version","guides"]))
    }
    func testRefusesWrongEnvironmentOrNon201Acknowledgment() async {
        for (status,environment) in [(200,"production"),(201,"sandbox")] {
            do {
                _ = try await client(status:status,environment:environment).register(token:token,environment:.production,appVersion:"1",osVersion:"26")
                XCTFail("Must not consider a mismatched enrollment active")
            } catch { XCTAssertEqual(error as? PushServiceError,.invalidResponse) }
        }
    }
    func testConflictAndRateLimitAreExplicitFailures() async {
        for code in [409,429,503] {
            do { _ = try await client(status:code).register(token:token,environment:.production,appVersion:"1",osVersion:"26");XCTFail() }
            catch { XCTAssertEqual(error as? PushServiceError,.http(code)) }
        }
    }
    func testTokenRotationAndDeleteUseOnlyInstallationCredential() async throws {
        _ = try await client(status:200).rotate(id:id,credential:"wwpi_SYNTHETIC_ONLY",token:token,environment:.production,appVersion:"1",osVersion:"26")
        XCTAssertEqual(PushProtocol.requests.last?.httpMethod,"PATCH")
        XCTAssertEqual(PushProtocol.requests.last?.value(forHTTPHeaderField:"Authorization"),"Bearer wwpi_SYNTHETIC_ONLY")
        XCTAssertEqual(PushProtocol.requests.last?.url?.lastPathComponent,id.uuidString.lowercased())
        try await client(status:204).delete(id:id,credential:"wwpi_SYNTHETIC_ONLY")
        try await client(status:404).delete(id:id,credential:"wwpi_SYNTHETIC_ONLY")
    }
    func testInvalidTokensAndHeaderInjectionNeverReachTransport() async {
        let service=client(status:201)
        do { _ = try await service.register(token:Data([1]),environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        do { _ = try await service.read(id:id,credential:"wwpi_test\r\nInjected: yes");XCTFail() } catch {}
        XCTAssertTrue(PushProtocol.requests.isEmpty)
    }
}

@MainActor private final class MemoryPushStore: PushCredentialStore {
    var value: PushCredential?
    func load() throws -> PushCredential? { value }
    func save(_ credential: PushCredential) throws { value=credential }
    func remove() throws { value=nil }
}
private actor FakePushService: PushInstallationService {
    let id=UUID()
    var deletes=0
    var rotations=0
    var code: Int?
    var pause=false
    var started=false
    var continuation: CheckedContinuation<Void,Never>?
    func setCode(_ code: Int?) { self.code=code }
    func setPause() { pause=true }
    func resume() { continuation?.resume();continuation=nil }
    func register(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushRegistration {
        started=true
        if pause { await withCheckedContinuation { continuation=$0 } }
        if let code { throw PushServiceError.http(code) }
        return PushRegistration(installation_id:id,credential:"wwpi_SYNTHETIC_ONLY",state:"active",environment:environment,guides:nil)
    }
    func rotate(id: UUID, credential: String, token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushInstallationState {
        rotations+=1
        if let code { throw PushServiceError.http(code) }
        return PushInstallationState(installation_id:id,state:"active",environment:environment,guides:nil)
    }
    func read(id: UUID, credential: String) async throws -> PushInstallationState {
        if let code { throw PushServiceError.http(code) }
        return PushInstallationState(installation_id:id,state:"active",environment:.production,guides:nil)
    }
    func delete(id: UUID, credential: String) async throws { if let code { throw PushServiceError.http(code) };deletes+=1 }
}
@MainActor final class PushSubscriptionTests: XCTestCase {
    func testAcknowledgedEnrollmentRotationAndUnsubscribe() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        try await subscription.register(token:Data(repeating:1,count:32),environment:.production,appVersion:"1",osVersion:"26")
        XCTAssertEqual(subscription.state,.on);XCTAssertNotNil(store.value)
        try await subscription.register(token:Data(repeating:2,count:32),environment:.production,appVersion:"1",osVersion:"26")
        let rotations=await service.rotations;XCTAssertEqual(rotations,1)
        try await subscription.disable()
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
    }
    func testNetworkFailureNeverShowsOnAndRevocationClearsCredentials() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        await service.setCode(503)
        do { try await subscription.register(token:Data(),environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
        await service.setCode(nil)
        try await subscription.register(token:Data(),environment:.production,appVersion:"1",osVersion:"26")
        await service.setCode(410)
        try await subscription.reconcile()
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
    }
    func testOfflineUnsubscribePersistsAndRetriesAfterRestart() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        try await subscription.register(token:Data(),environment:.production,appVersion:"1",osVersion:"26")
        await service.setCode(503)
        do { try await subscription.disable();XCTFail() } catch {}
        XCTAssertEqual(subscription.state,.deletionPending);XCTAssertEqual(store.value?.wantsAlerts,false)
        await service.setCode(nil)
        let reopened=PushSubscription(service:service,store:store)
        try await reopened.reconcile()
        XCTAssertEqual(reopened.state,.off);XCTAssertNil(store.value)
    }
    func testOptOutWhileRegistrationIsInFlightDeletesAcknowledgedEnrollment() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        await service.setPause()
        let task=Task { try await subscription.register(token:Data(),environment:.production,appVersion:"1",osVersion:"26") }
        for _ in 0..<100 {
            if await service.started { break }
            try await Task.sleep(for:.milliseconds(10))
        }
        let started=await service.started;XCTAssertTrue(started)
        try await subscription.disable()
        XCTAssertNotEqual(subscription.state,.on)
        await service.resume();try await task.value
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
        let deletes=await service.deletes;XCTAssertEqual(deletes,1)
    }
}
