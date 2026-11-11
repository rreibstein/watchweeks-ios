import Foundation

/// Stores only the user's alert choice and APNs retry timing, never a device token.
/// A timeout does not revoke permission or invalidate a late APNs response.
@MainActor public final class PushRegistrationIntent {
    private let defaults: UserDefaults
    private let key = "watchweeks.push.requested"
    private let retryKey = "watchweeks.push.tokenRetry"
    private let attemptsKey = "watchweeks.push.tokenAttempts"
    public init(defaults: UserDefaults = .standard) { self.defaults=defaults }
    public var requested: Bool { defaults.bool(forKey:key) }
    public var retryAt: Date? { defaults.object(forKey:retryKey) as? Date }
    public func authorized() { defaults.set(true,forKey:key) }
    public func beginAttempt() { defaults.removeObject(forKey:retryKey) }
    public func receivedToken() {
        defaults.removeObject(forKey:retryKey);defaults.removeObject(forKey:attemptsKey)
    }
    public func retryAfterFailure(now: Date = .now) {
        guard requested else { return }
        let attempt=defaults.integer(forKey:attemptsKey)
        defaults.set(now.addingTimeInterval([30.0,120.0,600.0,1800.0][min(attempt,3)]),forKey:retryKey)
        defaults.set(min(attempt+1,3),forKey:attemptsKey)
    }
    public func cancel() {
        defaults.set(false,forKey:key);receivedToken()
    }
}
