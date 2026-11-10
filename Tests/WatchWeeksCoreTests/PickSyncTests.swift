import XCTest
import WatchWeeksCore

final class PickSyncTests: XCTestCase {
    func testIndependentChangesMergeAndPrivateFeedbackStaysLocal() {
        let base = SyncPick(Selection())
        var local = Selection(interest: .mustSee, shortlisted: false)
        local.reaction = .loved
        local.buyingIntent = .secondLook
        let remote = SyncPick(Selection(seen: true))
        let expected = SyncPick(interest: .mustSee, shortlisted: false, seen: true)
        XCTAssertEqual(PickMerge.merge(base: base, local: SyncPick(local), remote: remote), .merged(expected))
        XCTAssertEqual(expected.applying(to: local).reaction, .loved)
        XCTAssertEqual(expected.applying(to: local).buyingIntent, .secondLook)
    }

    func testFirstImportDoesNotSilentlyReplaceExistingGuestPicks() {
        let local = SyncPick(Selection(interest: .mustSee))
        let remote = SyncPick(Selection(interest: .skip, seen: true))
        XCTAssertEqual(PickMerge.merge(base: nil, local: local, remote: remote),
                       .conflict([.interest, .shortlisted, .seen]))
    }

    func testExplicitClearingAndConcurrentRatingConflict() {
        let base = SyncPick(Selection(interest: .mustSee))
        let cleared = SyncPick(Selection())
        let changed = SyncPick(Selection(interest: .little))
        XCTAssertEqual(PickMerge.merge(base: base, local: cleared, remote: base), .merged(cleared))
        XCTAssertEqual(PickMerge.merge(base: base, local: cleared, remote: changed), .conflict([.interest]))
    }
}
