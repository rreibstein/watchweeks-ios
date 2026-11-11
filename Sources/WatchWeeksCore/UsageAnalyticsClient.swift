import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum UsageAction: String, Codable, Sendable {
    case optedIn = "usage_analytics_enabled", opened = "app_opened"
    case guide = "guide_viewed", event = "event_viewed", release = "release_viewed"
    case rating = "brand_rating_set", seen = "brand_seen_toggled"
    case myList = "my_visit_viewed", shared = "guide_shared", website = "website_link_opened"
}

/// Explicit PostHog capture API, with consent-gated bounded durable delivery.
/// No automatic collection, replay, device fingerprinting or website identity.
@MainActor public final class UsageAnalyticsClient {
    public typealias Transport = @MainActor (URLRequest) async throws -> Int
    public private(set) var enabled: Bool
    public var pendingCount: Int { queue.count }
    private struct Properties: Codable {
        let platform = "ios_native"
        let geoDisabled = true
        let personProfiles = false
        let appVersion: String
        let appBuild: String
        let guideID: String?
        let eventID: String?
        let releaseID: String?
        enum CodingKeys: String, CodingKey {
            case platform, geoDisabled = "$geoip_disable", personProfiles = "$process_person_profile"
            case appVersion = "app_version", appBuild = "app_build", guideID = "guide_id", eventID = "event_id", releaseID = "release_id"
        }
    }
    private struct Envelope: Codable {
        let api_key: String
        let event: UsageAction
        let distinct_id: String
        let properties: Properties
        let timestamp: String
        let uuid: UUID
    }
    private let defaults: UserDefaults
    private let token: String
    private let endpoint: URL
    private let version: String
    private let build: String
    private let transport: Transport
    private var identity: String?
    private var queue: [Envelope] = []
    private var delivery: Task<Void, Never>?
    private var foreground = false
    private let consentKey = "usageAnalytics.consent"
    private let identityKey = "usageAnalytics.installID"
    private let queueKey = "usageAnalytics.pending.v1"

    public init(token: String, endpoint: URL, version: String, build: String, defaults: UserDefaults = .standard, transport: Transport? = nil) {
        self.token=token; self.endpoint=endpoint; self.version=version; self.build=build; self.defaults=defaults
        if let transport { self.transport=transport }
        else {
            let configuration=URLSessionConfiguration.ephemeral
            #if !os(Linux)
            configuration.waitsForConnectivity=true
            #endif
            configuration.timeoutIntervalForResource=90
            let session=URLSession(configuration:configuration)
            self.transport = { request in
                let (_,response)=try await session.data(for:request)
                return (response as? HTTPURLResponse)?.statusCode ?? 503
            }
        }
        enabled=defaults.bool(forKey:consentKey)
        if enabled {
            identity=defaults.string(forKey:identityKey) ?? UUID().uuidString
            defaults.set(identity,forKey:identityKey)
            if let data=defaults.data(forKey:queueKey), let saved=try? JSONDecoder().decode([Envelope].self,from:data) {
                queue=Array(saved.filter { $0.distinct_id == identity && $0.api_key == token }.suffix(100))
            }
            retry()
        } else {
            defaults.removeObject(forKey:queueKey)
            defaults.removeObject(forKey:identityKey)
        }
    }
    public func setEnabled(_ value: Bool) {
        // Persist an explicit refusal even when analytics was already off.
        defaults.set(value,forKey:consentKey)
        guard enabled != value else { return }
        enabled=value
        if value {
            identity=UUID().uuidString; defaults.set(identity,forKey:identityKey)
            record(.optedIn)
        } else {
            identity=nil; queue=[]; delivery?.cancel(); delivery=nil
            defaults.removeObject(forKey:identityKey); defaults.removeObject(forKey:queueKey)
        }
    }
    public func becameActive() {
        if !foreground { foreground=true; record(.opened) }
        retry()
    }
    public func becameBackground() { foreground=false }
    public func record(_ action: UsageAction, guideID: String? = nil, eventID: String? = nil, releaseID: String? = nil) {
        guard enabled, let identity else { return }
        let p=Properties(appVersion:version,appBuild:build,guideID:guideID,eventID:eventID,releaseID:releaseID)
        let envelope=Envelope(api_key:token,event:action,distinct_id:identity,properties:p,timestamp:ISO8601DateFormatter().string(from:.now),uuid:UUID())
        if queue.count == 100 { queue.removeFirst() }
        queue.append(envelope); persist(); retry()
    }
    public func retry() {
        guard enabled, let identity, !queue.isEmpty, delivery == nil else { return }
        delivery=Task { [weak self] in await self?.flush(identity:identity) }
    }
    /// Stop a delivery attempt without losing previously consented queued events.
    public func suspendDelivery() { delivery?.cancel(); delivery=nil }
    private func persist() { defaults.set(try? JSONEncoder().encode(queue),forKey:queueKey) }
    private func flush(identity: String) async {
        var delay=2
        while enabled, self.identity == identity, let envelope=queue.first, !Task.isCancelled {
            var request=URLRequest(url:endpoint); request.httpMethod="POST"
            request.setValue("application/json",forHTTPHeaderField:"Content-Type")
            request.httpBody=try? JSONEncoder().encode(envelope)
            let status=(try? await transport(request)) ?? 503
            guard enabled, self.identity == identity, !Task.isCancelled else { return }
            if status < 500 && status != 429 {
                if queue.first?.uuid == envelope.uuid { queue.removeFirst() }
                persist(); delay=2
            } else {
                do { try await Task.sleep(for:.seconds(delay)) } catch { return }
                delay=min(delay*2,60)
            }
        }
        if self.identity == identity, !Task.isCancelled { delivery=nil }
    }
}
