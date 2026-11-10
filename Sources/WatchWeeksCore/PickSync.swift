import Foundation

/// The account payload covers checklist picks. Feedback and buying intent stay on-device.
public struct SyncPick: Codable, Equatable, Sendable {
    public let interest: Interest
    public let shortlisted: Bool
    public let seen: Bool

    public init(_ selection: Selection) {
        self.init(interest: selection.interest, shortlisted: selection.isShortlisted, seen: selection.seen)
    }

    public init(interest: Interest, shortlisted: Bool, seen: Bool) {
        self.interest = interest
        self.shortlisted = shortlisted
        self.seen = seen
    }

    public func applying(to local: Selection) -> Selection {
        var selection = local
        selection.interest = interest
        selection.shortlisted = shortlisted
        selection.seen = seen
        return selection
    }
}

public enum PickMerge {
    public enum Field: String, Hashable, Sendable {
        case interest, shortlisted, seen
    }

    public enum Result: Equatable, Sendable {
        case merged(SyncPick)
        case conflict(Set<Field>)
    }

    /// A missing baseline means the device has never synced this pick.
    /// When both copies exist, ask the owner to resolve differences.
    public static func merge(base: SyncPick?, local: SyncPick, remote: SyncPick) -> Result {
        var conflicts: Set<Field> = []

        func resolve<Value: Equatable>(_ field: Field, _ base: Value?, _ local: Value, _ remote: Value) -> Value {
            if local == remote || remote == base { return local }
            if local == base { return remote }
            conflicts.insert(field)
            return local
        }

        let interest = resolve(.interest, base?.interest, local.interest, remote.interest)
        let shortlisted = resolve(.shortlisted, base?.shortlisted, local.shortlisted, remote.shortlisted)
        let seen = resolve(.seen, base?.seen, local.seen, remote.seen)
        if !conflicts.isEmpty { return .conflict(conflicts) }
        return .merged(SyncPick(interest: interest, shortlisted: shortlisted, seen: seen))
    }
}
