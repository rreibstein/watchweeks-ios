import XCTest
@testable import WatchWeeksCore

final class UsageAnalyticsPromptTests: XCTestCase {
    @MainActor func testPromptNeedsBothMeaningfulUseAndThirtyActiveSeconds() {
        let name="analytics.prompt.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        var now: TimeInterval=0
        let policy=UsageAnalyticsPromptPolicy(defaults:defaults,uptime:{now})
        policy.setActive(true)
        policy.record(.opened);policy.record(.opened)
        now=35
        XCTAssertFalse(policy.shouldPresent) // Launch/foreground aren't engagement.
        policy.record(.guide);XCTAssertFalse(policy.shouldPresent)
        policy.record(.myList);XCTAssertTrue(policy.shouldPresent)
        XCTAssertNil(defaults.object(forKey:"usageAnalytics.consent"))
        XCTAssertNil(defaults.string(forKey:"usageAnalytics.installID"))
        XCTAssertNil(defaults.data(forKey:"usageAnalytics.pending.v1"))
    }

    @MainActor func testBackgroundAndInactiveTimeDoNotCountAndRestartKeepsProgress() {
        let name="analytics.prompt.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        var now: TimeInterval=0
        let policy=UsageAnalyticsPromptPolicy(defaults:defaults,uptime:{now})
        policy.setActive(true);policy.record(.guide);policy.record(.rating)
        now=10;policy.setActive(false);now=1000
        XCTAssertEqual(policy.remainingActiveSeconds,20)
        XCTAssertFalse(policy.shouldPresent)
        let restored=UsageAnalyticsPromptPolicy(defaults:defaults,uptime:{now})
        restored.setActive(true);now=1019
        XCTAssertFalse(restored.shouldPresent)
        now=1020;XCTAssertTrue(restored.shouldPresent)
    }

    @MainActor func testDismissalAndExistingChoicesSuppressPromptAcrossLaunches() {
        let name="analytics.prompt.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let policy=UsageAnalyticsPromptPolicy(defaults:defaults)
        policy.dismiss()
        XCTAssertTrue(UsageAnalyticsPromptPolicy(defaults:defaults).hasChoice)
        defaults.removePersistentDomain(forName:name)
        defaults.set(false,forKey:"usageAnalytics.consent")
        XCTAssertTrue(UsageAnalyticsPromptPolicy(defaults:defaults).hasChoice)
        defaults.set(true,forKey:"usageAnalytics.consent")
        XCTAssertTrue(UsageAnalyticsPromptPolicy(defaults:defaults).hasChoice)
    }

    @MainActor func testExplicitRefusalWhileAlreadyOffIsRememberedAndNeverSends() async {
        let name="analytics.prompt.\(UUID())", defaults=UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let client=UsageAnalyticsClient(token:"test",endpoint:URL(string:"https://example.invalid")!,version:"1",build:"1",defaults:defaults) { _ in
            XCTFail("Refusing analytics must never transmit");return 200
        }
        client.setEnabled(false);client.record(.guide)
        await Task.yield()
        XCTAssertFalse(client.enabled);XCTAssertEqual(client.pendingCount,0)
        XCTAssertTrue(UsageAnalyticsPromptPolicy(defaults:defaults).hasChoice)
    }
}
