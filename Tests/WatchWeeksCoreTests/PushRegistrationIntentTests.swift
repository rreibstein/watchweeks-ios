import XCTest
@testable import WatchWeeksCore

final class PushRegistrationIntentTests: XCTestCase {
    @MainActor func testAuthorizationSurvivesRelaunchWithoutStoringATokenOrCredential() async {
        let name="push.intent.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let intent=PushRegistrationIntent(defaults:defaults)
        XCTAssertFalse(intent.requested);intent.authorized()
        XCTAssertTrue(PushRegistrationIntent(defaults:defaults).requested)
        XCTAssertEqual(Set((defaults.persistentDomain(forName:name) ?? [:]).keys),["watchweeks.push.requested"])
    }
    @MainActor func testTimeoutPreservesIntentAndAcceptsALateTokenWithoutAnotherPermissionFlow() async {
        let name="push.intent.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let intent=PushRegistrationIntent(defaults:defaults), now=Date(timeIntervalSince1970:1000)
        intent.authorized();intent.retryAfterFailure(now:now)
        XCTAssertTrue(intent.requested);XCTAssertEqual(intent.retryAt,now.addingTimeInterval(30))
        intent.receivedToken()
        XCTAssertTrue(intent.requested);XCTAssertNil(intent.retryAt)
    }
    @MainActor func testBackoffIsDurableAndInFlightAttemptDoesNotLeavePastRetryDeadline() async {
        let name="push.intent.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let now=Date(timeIntervalSince1970:1000), intent=PushRegistrationIntent(defaults:defaults)
        intent.authorized();intent.retryAfterFailure(now:now)
        let restored=PushRegistrationIntent(defaults:defaults)
        XCTAssertEqual(restored.retryAt,now.addingTimeInterval(30))
        restored.beginAttempt();XCTAssertNil(restored.retryAt)
        restored.retryAfterFailure(now:now);XCTAssertEqual(restored.retryAt,now.addingTimeInterval(120))
        restored.retryAfterFailure(now:now);XCTAssertEqual(restored.retryAt,now.addingTimeInterval(600))
        for _ in 0..<5 { restored.retryAfterFailure(now:now) }
        XCTAssertEqual(restored.retryAt,now.addingTimeInterval(1800))
    }
    @MainActor func testDeniedPermissionOrUnsubscribeClearsIntentAndRetries() async {
        let name="push.intent.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let intent=PushRegistrationIntent(defaults:defaults)
        intent.authorized();intent.retryAfterFailure();intent.cancel();intent.retryAfterFailure()
        let restored=PushRegistrationIntent(defaults:defaults)
        XCTAssertFalse(restored.requested);XCTAssertNil(restored.retryAt)
    }
}
