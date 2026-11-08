import SwiftUI
import UIKit
import PostHog
import WatchWeeksCore

private let analyticsEnabledKey = "analytics.enabled"

@MainActor final class NativeAnalytics: ObservableObject {
    static let shared = NativeAnalytics()
    @Published private(set) var enabled: Bool
    @Published private(set) var choiceMade = UserDefaults.standard.bool(forKey: "analytics.choiceMade")
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    private let sdk = PostHogSDK.shared
    private var configured = false
    private lazy var gate = AnalyticsGate(enabled: enabled) { [weak self] payload in
        guard let self, self.configured else { return }
        var properties: [String: Any] = payload.properties
        if let seen = payload.properties["seen"] {
            properties["seen"] = seen == "true"
        }
        if payload.name == .appOpened {
            properties["first_observed_open"] = !UserDefaults.standard.bool(forKey: "analytics.recordedOpen")
            UserDefaults.standard.set(true, forKey: "analytics.recordedOpen")
        }
        self.sdk.capture(payload.name.rawValue, properties: properties)
    }
    private init() {
        enabled = UserDefaults.standard.bool(forKey: analyticsEnabledKey)
        if enabled { configure() }
    }
    private func configure() {
        guard !configured else { return }
        #if DEBUG && targetEnvironment(simulator)
        // Simulator QA can only send analytics to the Mac's local test receiver.
        guard ProcessInfo.processInfo.environment["WW_ANALYTICS_QA"] == "1" else { return }
        let c = PostHogConfig(projectToken: "phc_watchweeks_simulator", host: "http://localhost:8766")
        #else
        guard let url = Bundle.main.url(forResource: "AnalyticsConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url), let p = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let token = p["projectToken"], token.hasPrefix("phc_"), let host = p["host"], host == "https://us.i.posthog.com" else { return }
        let c = PostHogConfig(projectToken: token, host: host)
        #endif
        let session = URLSessionConfiguration.default
        session.protocolClasses = [AnalyticsConsentProtocol.self]
        c.urlSessionConfiguration = session
        c.optOut = !enabled
        c.captureApplicationLifecycleEvents = false; c.captureScreenViews = false
        c.captureElementInteractions = false; c.captureSwiftUIElementInteractions = false
        c.enableSwizzling = false; c.sessionReplay = false; c.surveys = false
        c.errorTrackingConfig.autoCapture = false
        c.preloadFeatureFlags = false; c.sendFeatureFlagEvent = false
        c.personProfiles = .never; c.disableGeoIp = true; c.setDefaultPersonProperties = false
        c.flushAt = 20; c.maxQueueSize = 500; c.flushIntervalSeconds = 30
        sdk.setup(c); configured = true
    }
    func setEnabled(_ value: Bool) {
        enabled=value; choiceMade=true; UserDefaults.standard.set(true,forKey:"analytics.choiceMade"); UserDefaults.standard.set(value,forKey:analyticsEnabledKey)
        gate.setEnabled(value)
        if value { configure() }
        guard configured else { return }
        if value { sdk.optIn() } else { sdk.optOut() }
    }
    func active() { gate.becameActive(version: version, build: build) }
    func background() { gate.becameInactive() }
    func track(_ name: AnalyticsName, guide: Guide? = nil, eventID: String? = nil, brandID: String? = nil, releaseID: String? = nil, rating: String? = nil, seen: Bool? = nil) {
        gate.track(AnalyticsPayload(name,version:version,build:build,guideID:guide?.id,city:guide?.city,eventID:eventID,brandID:brandID,releaseID:releaseID,rating:rating,seen:seen))
    }
}
// PostHog 3.93.6 can flush previously queued events after optOut().
// Only the SDK session uses this protocol. Consented requests use URLSession's normal transport.
private final class AnalyticsConsentProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        !UserDefaults.standard.bool(forKey: analyticsEnabledKey)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}

struct AnalyticsSettings: View {
    @ObservedObject private var analytics = NativeAnalytics.shared
    var body: some View {
        Section("Usage analytics") {
            Toggle("Share anonymous usage analytics", isOn: Binding(get: { analytics.enabled }, set: { analytics.setEnabled($0) }))
            Text("Optional PostHog analytics help improve WatchWeeks. We send a random app identifier, app/device information and actions such as guide views and ratings. No account, private notes, purchase prices, advertising ID or session replay. Native and website identities are not joined. Turn this off to stop future collection. Previously delivered data may remain under the privacy policy.").font(.wwFootnote).foregroundStyle(.secondary)
        }
    }
}
struct WebsiteLink: View {
    let title: String
    let url: URL
    var guide: Guide? = nil
    @Environment(\.openURL) private var openURL
    var body: some View {
        Button(title) { openURL(url) { accepted in
            if accepted, url.host == "watchweeks.com" { NativeAnalytics.shared.track(.websiteOpened,guide:guide) }
        } }
    }
}
struct ShareGuideButton: View {
    let guide: Guide
    let url: URL
    @State private var showing = false
    var body: some View { Button { showing=true } label: { Label("Share guide",systemImage:"square.and.arrow.up") }.sheet(isPresented:$showing) { ShareController(url:url) { NativeAnalytics.shared.track(.guideShared,guide:guide) } } }
}
struct ShareController: UIViewControllerRepresentable {
    let url: URL
    let completed: @MainActor () -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc=UIActivityViewController(activityItems:[url],applicationActivities:nil)
        let action=completed
        vc.completionWithItemsHandler = { _,success,_,_ in if success { Task { @MainActor in action() } } }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AnalyticsConsent: View {
    @ObservedObject private var analytics = NativeAnalytics.shared
    var body: some View {
        VStack(alignment:.leading,spacing:24) {
            Text("Help improve WatchWeeks").font(.wwTitle)
            Text("May we use optional PostHog analytics to understand which guides and features are useful? This sends a random app identifier and usage actions, not your name, private notes or purchase prices. There is no session replay or advertising tracking. Your website and app identities are not joined.")
            Text("Either choice gives you the full app. You can change it in About at any time.").font(.wwSubheadline).foregroundStyle(.secondary)
            Button("Allow usage analytics") { analytics.setEnabled(true); analytics.track(.appOpened) }.buttonStyle(.bordered)
            Button("Continue without analytics") { analytics.setEnabled(false) }.buttonStyle(.bordered)
            Link("Privacy policy",destination:PublicLinks.privacy)
        }.padding(28).interactiveDismissDisabled()
    }
}
