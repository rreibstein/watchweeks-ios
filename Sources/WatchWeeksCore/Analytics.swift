import Foundation
public enum AnalyticsName: String, CaseIterable, Sendable {
    case appOpened = "app_opened", guideViewed = "guide_viewed", eventViewed = "event_viewed", brandViewed = "brand_viewed", ratingSet = "brand_rating_set", seenToggled = "brand_seen_toggled", myVisitViewed = "my_visit_viewed", releaseViewed = "release_viewed", guideShared = "guide_shared", websiteOpened = "website_link_opened"
}
public struct AnalyticsPayload: Equatable, Sendable {
    public let name: AnalyticsName
    public let properties: [String: String]
    public init(_ name: AnalyticsName, version: String, build: String, guideID: String? = nil, city: String? = nil, eventID: String? = nil, brandID: String? = nil, releaseID: String? = nil, rating: String? = nil, seen: Bool? = nil) {
        self.name=name
        var p=["platform":"ios_native", "app_version":version, "app_build":build, "instrumentation_version":"1"]
        // No free-form notes, titles, URLs, searches, prices or account identifiers.
        for (key,value) in [("guide_id",guideID),("city",city),("event_id",eventID),("brand_id",brandID),("release_id",releaseID),("rating_category",rating)] { if let value { p[key]=value } }
        if let seen { p["seen"] = seen ? "true" : "false" }
        self.properties=p
    }
}
@MainActor public final class AnalyticsGate {
    public private(set) var enabled: Bool
    private let send: (AnalyticsPayload) -> Void
    private var active = false
    public init(enabled: Bool = false, send: @escaping (AnalyticsPayload) -> Void) { self.enabled=enabled; self.send=send }
    public func setEnabled(_ enabled: Bool) { self.enabled=enabled }
    public func track(_ payload: AnalyticsPayload) { if enabled { send(payload) } }
    public func becameActive(version: String, build: String) {
        guard !active else { return }; active=true
        track(AnalyticsPayload(.appOpened,version:version,build:build))
    }
    public func becameInactive() { active=false }
}
