import Foundation

public enum GuidePushActivation {
    public static func available(clientReady: Bool, signedEnvironment: APNSEnvironment?, backendPresent: Bool,
                                 deliveryAvailable: Bool, verificationTestFlight: Bool) -> Bool {
        clientReady && signedEnvironment != nil && backendPresent && (deliveryAvailable || verificationTestFlight)
    }
}

/// Contract supplied by the isolated Lovable implementation, Nov 11, 2026.
public struct UpcomingGuideFeed: Codable, Sendable {
    public let v: Int
    public let upcoming: [UpcomingGuide]
    public let capabilities: Capabilities
    public struct Capabilities: Codable, Sendable {
        public let push: Push
        public struct Push: Codable, Sendable { public let available: Bool; public let reason: String? }
    }
    public func validate() throws {
        guard v == 1, upcoming.count <= 200, Set(upcoming.map(\.key)).count == upcoming.count,
              upcoming.allSatisfy({ !$0.key.isEmpty && $0.key.utf8.count <= 128 && !$0.title.isEmpty &&
                  ($0.guide_id == nil || PublicLinks.apiGuide($0.guide_id!) != nil) &&
                  ($0.url == nil || PublicLinks.safeExternal($0.url) != nil) }) else { throw FeedError.invalidResponse }
    }
    public var planned: [UpcomingGuide] { upcoming.filter { $0.state == .planned } }
}
public struct UpcomingGuide: Codable, Identifiable, Sendable {
    public let key: String
    public let title: String
    public let city: String
    public let state: State
    public let start_date: String?
    public let end_date: String?
    public let url: URL?
    public let guide_id: String?
    public var id: String { key }
    public enum State: String, Codable, Sendable { case planned, published }
}

/// Reject missing notification IDs and retain only bounded public identifiers.
public struct GuidePublicationNotification: Equatable, Sendable {
    public let guideID: String
    public let notificationID: String
    public init?(type: String?, version: Int?, guideID: String?, notificationID: String?) {
        guard let guideID=GuidePublicationPush.guideID(type:type,version:version,id:guideID),
              let notificationID, !notificationID.isEmpty, notificationID.utf8.count <= 256,
              notificationID.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || "-_:".unicodeScalars.contains($0) }) else { return nil }
        self.guideID=guideID; self.notificationID=notificationID
    }
}

public struct GuidePublicationInbox: Sendable {
    public private(set) var openedIDs: [String]
    public init(openedIDs: [String] = []) { self.openedIDs=Array(openedIDs.suffix(200)) }
    public mutating func accept(_ notification: GuidePublicationNotification) -> Bool {
        guard !openedIDs.contains(notification.notificationID) else { return false }
        openedIDs.append(notification.notificationID);openedIDs=Array(openedIDs.suffix(200));return true
    }
}
