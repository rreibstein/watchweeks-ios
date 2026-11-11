import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class GuideRefreshFailureTests: XCTestCase {
    func testCanceledWorkNeverBecomesAUserFacingError() {
        for error: any Error in [CancellationError(),URLError(.cancelled),NSError(domain:NSURLErrorDomain,code:-999),NSError(domain:"Swift.CancellationError",code:1)] {
            XCTAssertTrue(GuideRefreshFailure.isCancellation(error))
            XCTAssertNil(GuideRefreshFailure.message(for:error))
        }
        XCTAssertFalse(GuideRefreshFailure.isCancellation(NSError(domain:"OtherService",code:-999)))
    }
    func testRealFailuresUseReadableCopyWithoutInternalErrorTypes() {
        for error: any Error in [URLError(.notConnectedToInternet),FeedError.http(503),FeedError.invalidResponse] {
            let message=GuideRefreshFailure.message(for:error)
            XCTAssertNotNil(message)
            XCTAssertFalse(message?.contains("Swift.") ?? true)
            XCTAssertFalse(message?.contains("NSURLError") ?? true)
        }
    }
    private struct InterruptedService: GuideService {
        let urlCancellation: Bool
        func guides() async throws -> [Guide] {
            if urlCancellation { throw URLError(.cancelled) }
            throw CancellationError()
        }
    }
    func testInterruptedRefreshLeavesLastGoodContentAndSelectionsIntact() async throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        let store=LocalStore(directory:directory)
        let guide=Guide(id:"saved-test",city:"Test",timeZone:"UTC")
        let savedAt=Date(timeIntervalSince1970:123)
        try await store.saveGuides([guide],now:savedAt)
        let key=SelectionKey(guideID:guide.id,brandID:"saved-brand")
        try await store.saveSelections([key:Selection(interest:.mustSee,seen:true)])
        for urlCancellation in [false,true] {
            do {
                _ = try await GuideRepository(service:InterruptedService(urlCancellation:urlCancellation),store:store).load()
                XCTFail("An interruption must propagate as cancellation, not an error banner or new snapshot")
            } catch { XCTAssertTrue(GuideRefreshFailure.isCancellation(error)) }
            let snapshot=try await store.snapshot(),selections=try await store.selections()
            XCTAssertEqual(snapshot?.guides,[guide]);XCTAssertEqual(snapshot?.fetchedAt,savedAt)
            XCTAssertEqual(selections[key]?.seen,true);XCTAssertEqual(selections[key]?.interest,.mustSee)
        }
    }
    func testVerifiedSandboxDownloadEnablesInternalSetupWithoutLegacyReceipt() {
        XCTAssertTrue(GuidePushActivation.internalVerificationBuild(allowed:true,verifiedSandboxTransaction:true,legacySandboxReceipt:false))
        XCTAssertTrue(GuidePushActivation.internalVerificationBuild(allowed:true,verifiedSandboxTransaction:nil,legacySandboxReceipt:true))
        XCTAssertFalse(GuidePushActivation.internalVerificationBuild(allowed:false,verifiedSandboxTransaction:true,legacySandboxReceipt:true))
    }
    func testVerifiedProductionDownloadCannotUseTestFlightBypass() {
        XCTAssertFalse(GuidePushActivation.internalVerificationBuild(allowed:true,verifiedSandboxTransaction:false,legacySandboxReceipt:true))
        XCTAssertFalse(GuidePushActivation.internalVerificationBuild(allowed:true,verifiedSandboxTransaction:nil,legacySandboxReceipt:false))
        let internalAccess=GuidePushActivation.internalVerificationBuild(allowed:true,verifiedSandboxTransaction:false,legacySandboxReceipt:false)
        XCTAssertFalse(GuidePushActivation.available(clientReady:true,signedEnvironment:.production,backendPresent:true,deliveryAvailable:false,verificationTestFlight:internalAccess))
    }
}
