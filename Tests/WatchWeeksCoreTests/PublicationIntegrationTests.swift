import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class PublicationIntegrationTests: XCTestCase {
    func testLiveUpcomingContractCapturedNovember11() throws {
        let url=try XCTUnwrap(Bundle.module.url(forResource:"upcoming-2026-11-11",withExtension:"json",subdirectory:"Fixtures"))
        let feed=try JSONDecoder().decode(UpcomingGuideFeed.self,from:Data(contentsOf:url))
        try feed.validate()
        XCTAssertEqual(Set(feed.planned.map(\.key)),Set(["geneva-ww","las-vegas","british-watchmakers-day"]))
        XCTAssertTrue(feed.planned.allSatisfy { $0.start_date == nil && $0.end_date == nil })
    }
    func testNewsletterDestinationFallsBackUntilTheActualPageIsLive() async throws {
        let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[MockProtocol.self]
        let service=PublicGuideService(session:URLSession(configuration:config))
        MockProtocol.status=404;MockProtocol.mime="text/html"
        let missing=await service.newsletterDestination();XCTAssertEqual(missing,PublicLinks.home)
        MockProtocol.status=200
        let live=await service.newsletterDestination();XCTAssertEqual(live,PublicLinks.newsletter)
        MockProtocol.mime="application/json"
    }
    func testNotificationOpeningUsesCanonicalMembershipAndOtherwiseFallsBackToGuideList() {
        XCTAssertEqual(GuidePublicationRouting.destination(guideID:"test",canonicalIDs:["test"],loadedIDs:["test"]),"test")
        XCTAssertNil(GuidePublicationRouting.destination(guideID:"test",canonicalIDs:[],loadedIDs:["test"]))
        XCTAssertNil(GuidePublicationRouting.destination(guideID:"test",canonicalIDs:["test"],loadedIDs:[]))
        XCTAssertNil(GuidePublicationRouting.destination(guideID:"unknown",canonicalIDs:["test"],loadedIDs:["test"]))
    }
    func testPushGateRequiresLiveBackendAndVerifiedClientForBothAudiences() {
        XCTAssertFalse(GuidePushActivation.available(clientReady:false,signedEnvironment:.production,backendPresent:true,deliveryAvailable:true,verificationTestFlight:true))
        XCTAssertFalse(GuidePushActivation.available(clientReady:true,signedEnvironment:nil,backendPresent:true,deliveryAvailable:true,verificationTestFlight:true))
        XCTAssertFalse(GuidePushActivation.available(clientReady:true,signedEnvironment:.production,backendPresent:false,deliveryAvailable:true,verificationTestFlight:true))
        XCTAssertFalse(GuidePushActivation.available(clientReady:true,signedEnvironment:.production,backendPresent:true,deliveryAvailable:false,verificationTestFlight:false))
        XCTAssertTrue(GuidePushActivation.available(clientReady:true,signedEnvironment:.production,backendPresent:true,deliveryAvailable:false,verificationTestFlight:true))
        XCTAssertTrue(GuidePushActivation.available(clientReady:true,signedEnvironment:.production,backendPresent:true,deliveryAvailable:true,verificationTestFlight:false))
    }
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
    nonisolated(unsafe) static var headers: [String:String]=[:]
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        // Darwin URLSession can expose POST/PATCH bodies only as a stream to
        // URLProtocol; Linux commonly retains httpBody. Inspect either form.
        var captured=request
        if captured.httpBody == nil, let stream=request.httpBodyStream {
            stream.open();defer { stream.close() }
            var data=Data(),buffer=[UInt8](repeating:0,count:2048)
            while true {
                let count=stream.read(&buffer,maxLength:buffer.count)
                if count <= 0 { break }
                data.append(contentsOf:buffer.prefix(count))
            }
            captured.httpBody=data
        }
        Self.requests.append(captured)
        client?.urlProtocol(self,didReceive:HTTPURLResponse(url:request.url!,statusCode:Self.status,httpVersion:"HTTP/1.1",headerFields:["Content-Type":"application/json"].merging(Self.headers) { _,new in new })!,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:Self.body);client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class PushClientTests: XCTestCase {
    private let id=UUID(uuidString:"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private let token=Data(repeating:0xAB,count:32) // synthetic, test-only
    private var credential: String { try! PushCredential.format(randomBytes:Data(repeating:7,count:32)) }
    override func tearDown() { PushProtocol.requests=[];PushProtocol.headers=[:];super.tearDown() }
    private func client(status: Int, environment: String = "production") -> PushInstallationClient {
        PushProtocol.status=status
        PushProtocol.body=Data("{\"installation_id\":\"\(id)\",\"state\":\"active\",\"environment\":\"\(environment)\",\"guides\":null}".utf8)
        let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[PushProtocol.self]
        return PushInstallationClient(session:URLSession(configuration:config))
    }
    func testRegistrationContractAndProductionEnvironmentForTestFlight() async throws {
        let pending=try PushRegistrationRequest(token:token,environment:.production,appVersion:"1.0.2",osVersion:"26.1")
        let result=try await client(status:201).register(request:pending,credential:credential)
        XCTAssertEqual(result.environment,.production)
        let request=try XCTUnwrap(PushProtocol.requests.last)
        XCTAssertEqual(request.httpMethod,"POST")
        XCTAssertEqual(request.url?.absoluteString,"https://watchweeks.com/api/public/push/installations")
        XCTAssertEqual(request.value(forHTTPHeaderField:"Authorization"),"Bearer " + credential)
        let body=try XCTUnwrap(JSONSerialization.jsonObject(with:XCTUnwrap(request.httpBody)) as? [String:Any])
        XCTAssertEqual(body["apns_token"] as? String,String(repeating:"ab",count:32))
        XCTAssertEqual(body["environment"] as? String,"production")
        XCTAssertTrue(body["guides"] is NSNull)
        XCTAssertEqual(Set(body.keys),Set(["platform","apns_token","environment","app_version","os_version","guides"]))
        XCTAssertEqual(try JSONDecoder().decode(PushRegistrationRequest.self,from:JSONEncoder().encode(pending)),pending)
    }
    func testRecovered200IsAcceptedWithTheSameCredential() async throws {
        let pending=try PushRegistrationRequest(token:token,environment:.production,appVersion:"1",osVersion:"26")
        _ = try await client(status:201).register(request:pending,credential:credential)
        let recovered=try await client(status:200).register(request:pending,credential:credential)
        XCTAssertEqual(recovered.installation_id,id)
        XCTAssertEqual(PushProtocol.requests.last?.value(forHTTPHeaderField:"Authorization"),"Bearer " + credential)
        XCTAssertEqual(PushProtocol.requests.first?.httpBody,PushProtocol.requests.last?.httpBody)
    }
    func testRefusesWrongEnvironment() async throws {
        let pending=try PushRegistrationRequest(token:token,environment:.production,appVersion:"1",osVersion:"26")
        do { _ = try await client(status:201,environment:"sandbox").register(request:pending,credential:credential);XCTFail() }
        catch { XCTAssertEqual(error as? PushServiceError,.invalidResponse) }
    }
    func testConflictAndRateLimitAreExplicitFailures() async throws {
        let pending=try PushRegistrationRequest(token:token,environment:.production,appVersion:"1",osVersion:"26")
        for code in [409,429,503] {
            do { _ = try await client(status:code).register(request:pending,credential:credential);XCTFail() }
            catch {
                if code == 409 { XCTAssertEqual(error as? PushServiceError,.http(code)) }
                else { XCTAssertEqual(error as? PushServiceError,.retryable(code,nil)) }
            }
        }
    }
    func testRetryAfterIsRespected() async throws {
        let pending=try PushRegistrationRequest(token:token,environment:.production,appVersion:"1",osVersion:"26")
        PushProtocol.headers=["Retry-After":"120"]
        do { _ = try await client(status:429).register(request:pending,credential:credential);XCTFail() }
        catch PushServiceError.retryable(let code,let date) {
            XCTAssertEqual(code,429);XCTAssertGreaterThan(try XCTUnwrap(date).timeIntervalSinceNow,110)
        }
    }
    func testTokenRotationAndDeleteUseOnlyInstallationCredential() async throws {
        _ = try await client(status:200).rotate(id:id,credential:credential,token:token,environment:.production,appVersion:"1",osVersion:"26")
        XCTAssertEqual(PushProtocol.requests.last?.httpMethod,"PATCH")
        XCTAssertEqual(PushProtocol.requests.last?.value(forHTTPHeaderField:"Authorization"),"Bearer " + credential)
        XCTAssertEqual(PushProtocol.requests.last?.url?.lastPathComponent,id.uuidString.lowercased())
        let body=try XCTUnwrap(JSONSerialization.jsonObject(with:XCTUnwrap(PushProtocol.requests.last?.httpBody)) as? [String:Any])
        XCTAssertEqual(Set(body.keys),Set(["apns_token","environment","app_version","os_version"]))
        try await client(status:204).delete(id:id,credential:credential)
        try await client(status:404).delete(id:id,credential:credential)
    }
    func testInvalidTokensAndHeaderInjectionNeverReachTransport() async {
        do { _ = try PushRegistrationRequest(token:Data([1]),environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        do { _ = try await client(status:200).read(id:id,credential:"wwpi_test\r\nInjected: yes");XCTFail() } catch {}
        XCTAssertTrue(PushProtocol.requests.isEmpty)
    }
}

@MainActor private final class MemoryPushStore: PushCredentialStore {
    var value: PushCredential?
    var denyWrites=false
    func load() throws -> PushCredential? { value }
    func save(_ credential: PushCredential) throws {
        if denyWrites { throw URLError(.cannotWriteToFile) };value=credential
    }
    func remove() throws { value=nil }
}
@MainActor private final class PushTestClock {
    var value=Date(timeIntervalSince1970:1000)
}
private actor FakePushService: PushInstallationService {
    let id=UUID()
    var deletes=0
    var rotations=0
    var code: Int?
    var pause=false
    var loseFirstResponse=false
    var started=false
    var requests: [PushRegistrationRequest]=[]
    var credentials: [String]=[]
    var continuation: CheckedContinuation<Void,Never>?
    let beforeRegister: (@Sendable (PushRegistrationRequest,String) async -> Void)?
    init(beforeRegister: (@Sendable (PushRegistrationRequest,String) async -> Void)? = nil) { self.beforeRegister=beforeRegister }
    func setCode(_ code: Int?) { self.code=code }
    func setLoseFirstResponse() { loseFirstResponse=true }
    func setPause() { pause=true }
    func resume() { continuation?.resume();continuation=nil }
    func register(request: PushRegistrationRequest, credential: String) async throws -> PushRegistration {
        requests.append(request);credentials.append(credential)
        await beforeRegister?(request,credential)
        started=true
        if pause { await withCheckedContinuation { continuation=$0 } }
        if loseFirstResponse && requests.count == 1 { throw URLError(.networkConnectionLost) }
        if let code { throw PushServiceError.http(code) }
        return PushRegistration(installation_id:id,state:"active",environment:request.environment,guides:nil)
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
    private let token=Data(repeating:1,count:32)
    func testCredentialFormatAndDurabilityBeforeFirstRequest() async throws {
        let store=MemoryPushStore()
        let service=FakePushService(beforeRegister: { request,credential in
            await MainActor.run {
                XCTAssertEqual(store.value?.secret,credential)
                XCTAssertEqual(store.value?.pendingRequest,request)
                XCTAssertNil(store.value?.id)
            }
        })
        let subscription=PushSubscription(service:service,store:store)
        try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26")
        let secret=try XCTUnwrap(store.value?.secret)
        XCTAssertEqual(secret.utf8.count,48);XCTAssertTrue(secret.hasPrefix("wwpi_"))
        XCTAssertFalse(secret.contains("="));XCTAssertFalse(secret.contains("+"));XCTAssertFalse(secret.contains("/"))
        XCTAssertNil(store.value?.pendingRequest);XCTAssertNotNil(store.value?.id)
    }
    func testNoRequestIsSentIfKeychainWriteFails() async {
        let store=MemoryPushStore(),service=FakePushService();store.denyWrites=true
        let subscription=PushSubscription(service:service,store:store)
        do { try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        let requests=await service.requests;XCTAssertTrue(requests.isEmpty)
        XCTAssertNotEqual(subscription.state,.on)
    }
    func testLostResponseSurvivesRestartAndReusesExactCredentialAndRequest() async throws {
        let store=MemoryPushStore(),service=FakePushService(),clock=PushTestClock()
        await service.setLoseFirstResponse()
        let subscription=PushSubscription(service:service,store:store,now:{ clock.value })
        do { try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        let pending=try XCTUnwrap(store.value)
        XCTAssertNotNil(pending.pendingRequest);XCTAssertNil(pending.id)
        let reopened=PushSubscription(service:service,store:store,makeCredential:{ throw PushServiceError.invalidRequest },now:{ clock.value })
        do { try await reopened.reconcile();XCTFail("Backoff must prevent immediate retry") } catch {}
        let before=await service.requests;XCTAssertEqual(before.count,1)
        clock.value.addTimeInterval(31)
        try await reopened.reconcile()
        let requests=await service.requests,credentials=await service.credentials
        XCTAssertEqual(requests.count,2);XCTAssertEqual(requests[0],requests[1])
        XCTAssertEqual(credentials[0],credentials[1]);XCTAssertEqual(credentials[0],pending.secret)
        XCTAssertEqual(reopened.state,.on);XCTAssertEqual(store.value?.secret,pending.secret)
        XCTAssertNil(store.value?.pendingRequest)
    }
    func testAcknowledgedEnrollmentRotationAndUnsubscribe() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26")
        let credential=store.value?.secret
        XCTAssertEqual(subscription.state,.on)
        try await subscription.register(token:Data(repeating:2,count:32),environment:.production,appVersion:"1",osVersion:"26")
        let rotations=await service.rotations;XCTAssertEqual(rotations,1)
        XCTAssertEqual(store.value?.secret,credential)
        try await subscription.disable()
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
    }
    func testDeniedPermissionDoesNotCreateAnInstallationAndRevokesAnExistingOne() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        try await subscription.permissionChanged(granted:false)
        let requests=await service.requests;XCTAssertTrue(requests.isEmpty)
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
        try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26")
        try await subscription.permissionChanged(granted:false)
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
        let deletes=await service.deletes;XCTAssertEqual(deletes,1)
    }
    func testRateLimitAnd503UseIncreasingPersistentBackoff() async throws {
        let store=MemoryPushStore(),service=FakePushService(),clock=PushTestClock()
        let subscription=PushSubscription(service:service,store:store,now:{ clock.value })
        await service.setCode(429)
        do { try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        XCTAssertEqual(store.value?.retryAt,clock.value.addingTimeInterval(30))
        clock.value.addTimeInterval(31);await service.setCode(503)
        do { try await subscription.reconcile();XCTFail() } catch {}
        XCTAssertEqual(store.value?.retryAt,clock.value.addingTimeInterval(120))
        let requests=await service.requests;XCTAssertEqual(requests.count,2)
        clock.value.addTimeInterval(121);await service.setCode(400)
        do { try await subscription.reconcile();XCTFail() } catch {}
        XCTAssertNil(store.value?.retryAt,"Definitive failure must not leave a past deadline causing a retry loop")
    }
    func testDeployment404PreservesPendingCredentialAndRevocationClearsKnownInstallation() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        await service.setCode(404)
        do { try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26");XCTFail() } catch {}
        let credential=store.value?.secret
        do { try await subscription.reconcile();XCTFail() } catch {}
        XCTAssertEqual(store.value?.secret,credential);XCTAssertNotNil(store.value?.pendingRequest)
        await service.setCode(nil);try await subscription.reconcile()
        await service.setCode(410);try await subscription.reconcile()
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
    }
    func testOfflineUnsubscribePersistsAndRetriesAfterRestart() async throws {
        let store=MemoryPushStore(),service=FakePushService(),clock=PushTestClock()
        let subscription=PushSubscription(service:service,store:store,now:{ clock.value })
        try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26")
        await service.setCode(503)
        do { try await subscription.disable();XCTFail() } catch {}
        XCTAssertEqual(subscription.state,.deletionPending);XCTAssertEqual(store.value?.wantsAlerts,false)
        clock.value.addTimeInterval(31);await service.setCode(nil)
        let reopened=PushSubscription(service:service,store:store,now:{ clock.value })
        try await reopened.reconcile()
        XCTAssertEqual(reopened.state,.off);XCTAssertNil(store.value)
    }
    func testOptOutWhileRegistrationIsInFlightDeletesAcknowledgedEnrollment() async throws {
        let store=MemoryPushStore(),service=FakePushService()
        let subscription=PushSubscription(service:service,store:store)
        await service.setPause()
        let task=Task { try await subscription.register(token:token,environment:.production,appVersion:"1",osVersion:"26") }
        for _ in 0..<100 {
            if await service.started { break }
            try await Task.sleep(for:.milliseconds(10))
        }
        let started=await service.started;XCTAssertTrue(started)
        try await subscription.disable();XCTAssertNotEqual(subscription.state,.on)
        await service.resume();try await task.value
        XCTAssertEqual(subscription.state,.off);XCTAssertNil(store.value)
        let deletes=await service.deletes;XCTAssertEqual(deletes,1)
    }
}
