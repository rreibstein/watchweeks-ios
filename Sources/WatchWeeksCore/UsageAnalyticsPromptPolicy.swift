import Foundation

/// Local presentation counters only. No event history or identifiers are saved,
/// and this policy never enables analytics or sends anything to a server.
@MainActor public final class UsageAnalyticsPromptPolicy {
    public static let requiredActiveSeconds: TimeInterval = 30
    private let defaults: UserDefaults
    private let uptime: () -> TimeInterval
    private var activeSince: TimeInterval?
    private let durationKey = "usageAnalytics.prompt.activeSeconds"
    private let interactionsKey = "usageAnalytics.prompt.interactions"
    private let dismissedKey = "usageAnalytics.prompt.dismissed"

    public init(defaults: UserDefaults = .standard,
                uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.defaults = defaults; self.uptime = uptime
    }

    public var hasChoice: Bool {
        defaults.object(forKey: "usageAnalytics.consent") != nil || defaults.bool(forKey: dismissedKey)
    }
    public var remainingActiveSeconds: TimeInterval {
        let elapsed = activeSince.map { max(0, uptime() - $0) } ?? 0
        return max(0, Self.requiredActiveSeconds - defaults.double(forKey: durationKey) - elapsed)
    }
    public var hasEngaged: Bool { defaults.integer(forKey: interactionsKey) >= 2 }
    public var shouldPresent: Bool { !hasChoice && hasEngaged && remainingActiveSeconds == 0 }

    public func setActive(_ active: Bool) {
        guard !hasChoice else { activeSince=nil; return }
        if let start = activeSince {
            let duration = defaults.double(forKey: durationKey) + max(0, uptime() - start)
            defaults.set(min(Self.requiredActiveSeconds, duration), forKey: durationKey)
        }
        activeSince = active ? uptime() : nil
    }

    public func record(_ action: UsageAction) {
        guard !hasChoice else { return }
        switch action {
        case .guide, .event, .release, .rating, .seen, .myList:
            defaults.set(min(2, defaults.integer(forKey: interactionsKey) + 1), forKey: interactionsKey)
        default: break // Launch, timers, refreshes and external links aren't engagement.
        }
    }

    public func dismiss() { defaults.set(true, forKey: dismissedKey) }
}
