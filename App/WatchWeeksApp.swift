import SwiftUI
import UIKit
import UserNotifications
import Security
import StoreKit
import WatchWeeksCore

@MainActor final class AppModel: ObservableObject {
    @Published var guides: [Guide] = []
    @Published var activeGuideID: String?
    @Published var pendingPushGuideID: String?
    @Published var visitGuides: [Guide] = []
    @Published var selections: [SelectionKey: Selection] = [:]
    @Published var loading = false
    @Published var message: String?
    @Published var savedAt: Date?
    @Published var stale = false
    @Published var upcomingFeed: UpcomingGuideFeed?
    @Published private(set) var hasLiveUpcomingFeed=false
    private(set) var publishedGuideIDs: Set<String> = []
    @Published var persistenceError: String?
    @Published private(set) var pendingSort: [SelectionKey: Selection] = [:]
    private let store: LocalStore
    private let repository: GuideRepository
    private var loaded = false
    private var selectionsReadable = true
    private var saving: Task<Void, Never>?
    private var refreshTask: Task<Void,Never>?
    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WatchWeeks", isDirectory: true)
        let store = LocalStore(directory: root)
        self.store=store; self.repository=GuideRepository(service: PublicGuideService(), store: store)
        #if DEBUG && targetEnvironment(simulator)
        // Explicit UI-test harness only; no synthetic guide ever enters Release.
        if let city=ProcessInfo.processInfo.environment["WW_NATIVE_QA_CITY"] {
            let singapore=city == "singapore", id=singapore ? "singapore-2026" : "miami-2026"
            guides=[Guide(id:id,city:singapore ? "Singapore" : "Miami",startDate:"2026-11-12",endDate:"2026-11-15",
                timeZone:singapore ? "Asia/Singapore" : "America/New_York",
                events:[Event(id:singapore ? "iamwatch" : "coconut-grove",name:singapore ? "IAMWATCH 2026" : "Coconut Grove Jewelry & Watch Show")],
                dealers:singapore ? nil : [Dealer(name:"Vintage Watches Miami",eventId:"coconut-grove"),Dealer(name:"Aaron Faber Gallery",eventId:"coconut-grove")])]
            activeGuideID=id;loaded=true
        }
        #endif
    }
    func start() async {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["WW_NATIVE_QA_CITY"] != nil { return }
        #endif
        if loaded {
            await refresh()
            return
        }
        loaded = true
        do { selections = try await store.selections() }
        catch { selectionsReadable = false; persistenceError = "Saved selections could not be read. They have not been replaced. Restart after checking device storage."; return }
        visitGuides = (try? await store.rememberedGuides()) ?? []
        if let snapshot = try? await store.snapshot() { guides=snapshot.guides; savedAt=snapshot.fetchedAt; stale=true }
        upcomingFeed=try? await store.upcoming()
        await refresh()
    }
    func refresh() async {
        if let refreshTask { await refreshTask.value;return }
        let work=Task { await self.performRefresh() }
        refreshTask=work
        await work.value
        refreshTask=nil
    }
    private func performRefresh() async {
        loading=true;defer { loading=false }
        async let alertRefresh: Void = refreshUpcoming()
        do { let result = try await repository.load(); guides=result.guides; publishedGuideIDs=result.publishedIDs; savedAt=result.fetchedAt; stale=result.stale; message=result.warning; visitGuides = (try? await store.rememberedGuides()) ?? result.guides }
        catch { if !GuideRefreshFailure.isCancellation(error) { message=GuideRefreshFailure.message(for:error) } }
        await alertRefresh
    }
    func refreshUpcoming() async {
        if let feed=await GuidePublicationAlerts.shared.refreshAvailability() {
            upcomingFeed=feed;hasLiveUpcomingFeed=true;try? await store.saveUpcoming(feed)
        }
    }
    func selection(_ guide: Guide, _ brand: Brand) -> Selection { selections[SelectionKey(guideID: guide.id, brandID: brand.id)] ?? Selection() }

    func selectionForSorting(_ guide: Guide, _ brand: Brand) -> Selection {
        var current = selection(guide, brand)
        if let baseline = pendingSort[SelectionKey(guideID: guide.id, brandID: brand.id)] {
            current.shortlisted = current.isShortlisted
            current.interest = baseline.interest
            current.seen = baseline.seen
        }
        return current
    }

    func resort() {
        if !pendingSort.isEmpty { pendingSort.removeAll() }
    }

    func set(_ selection: Selection, guide: Guide, brand: Brand, feedbackOnSeen: Bool = false) {
        guard persistenceError == nil else { return }
        let previous = self.selection(guide, brand)
        var selection = selection
        if selection.shortlisted == nil, previous.interest != selection.interest {
            selection.shortlisted = previous.isShortlisted
        }
        guard previous != selection else { return }
        let key = SelectionKey(guideID: guide.id, brandID: brand.id)
        if previous.interest != selection.interest || previous.seen != selection.seen {
            let baseline = pendingSort[key] ?? previous
            pendingSort[key] = baseline.interest == selection.interest && baseline.seen == selection.seen
                ? nil : baseline
        }
        selections[key] = selection
        let snapshot = selections; let previousSave = saving; let store = store
        saving = Task { [weak self] in
            await previousSave?.value
            do {
                try await store.saveSelections(snapshot)
                if feedbackOnSeen, !previous.seen, self?.selections[key]?.seen == true {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                if previous.interest != selection.interest {
                    UsageAnalytics.shared.record(.rating, guideID: guide.id)
                }
                if previous.seen != selection.seen {
                    UsageAnalytics.shared.record(.seen, guideID: guide.id)
                }
            } catch { self?.persistenceError = "Your latest changes could not be saved. Keep the app open, free device storage, then tap Retry saving." }
        }
    }
    func retrySaving() async {
        guard selectionsReadable else { return }
        await saving?.value
        do { try await store.saveSelections(selections); persistenceError=nil }
        catch { persistenceError="Selections still could not be saved. Please check device storage." }
    }
}
@main struct WatchWeeksApp: App {
    @UIApplicationDelegateAdaptor(WatchWeeksPushDelegate.self) private var pushDelegate
    init() { BrandTypography.configureNavigation() }
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .onChange(of: phase, initial: true) { _, phase in
                    UsageAnalytics.shared.setPromptForeground(phase == .active)
                    if phase == .background { UsageAnalytics.shared.background();GuidePublicationAlerts.shared.background() }
                }
                .task(id: phase == .background) {
                    guard phase != .background else { return }
                    UsageAnalytics.shared.active()
                    let currentModel=model
                    async let initialGuides: Void = currentModel.start()
                    await GuidePublicationAlerts.shared.foreground()
                    await initialGuides
                    guard !Task.isCancelled else { return }
                    var retryStep=0
                    while !Task.isCancelled {
                        let delay: Double = model.stale ? [30.0,120.0,600.0][min(retryStep,2)] : 300
                        do { try await Task.sleep(for: .seconds(delay)) }
                        catch { return }
                        await model.refresh()
                        retryStep=model.stale ? retryStep+1 : 0
                    }
                }
        }
    }
}
struct RootView: View {
    @ObservedObject private var guideAlerts = GuidePublicationAlerts.shared
    @ObservedObject private var analytics = UsageAnalytics.shared
    @EnvironmentObject var model: AppModel
    @State private var tab: WatchWeeksTab = .events

    var body: some View {
        TabView(selection: $tab) {
            withStatus(DiscoveryView()).watchTab(.events)
            withStatus(VisitView()).watchTab(.list)
            withStatus(CatalogView(releases: false)).watchTab(.brands)
            withStatus(CatalogView(releases: true)).watchTab(.releases)
        }
        .tint(WatchWeeksStyle.link)
        .onChange(of: guideAlerts.pendingGuideID, initial: true) { _, id in
            guard let id else { return }
            tab = .events; model.pendingPushGuideID=id; guideAlerts.clearPendingRoute()
        }
        .onChange(of: tab) { _, value in model.resort(); if value == .list { UsageAnalytics.shared.record(.myList) } }
        .onChange(of: model.activeGuideID) { _, _ in model.resort() }
    }

    private func withStatus<Content: View>(_ content: Content) -> some View {
        content.font(.wwBody).safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if let error = model.persistenceError {
                    VStack {
                        Text(error).font(.wwFootnote)
                        Button("Retry saving") { Task { await model.retrySaving() } }
                    }.padding().background(.regularMaterial)
                } else if !model.pendingSort.isEmpty {
                    sortToast
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else if analytics.showConsentPrompt {
                    AnalyticsEngagementPrompt()
                }
            }
        }
    }

    private var sortToast: some View {
        let count = model.pendingSort.count
        let message = Text(count == 1 ? "1 change" : "\(count) changes")
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                message.monospacedDigit().frame(minWidth: 70)
                sortActions
            }.fixedSize(horizontal: true, vertical: false)
            VStack(spacing: 0) {
                message.multilineTextAlignment(.center)
                sortActions
            }.padding(.top, 8)
        }
        .font(.wwFootnote.weight(.semibold))
        .foregroundStyle(WatchWeeksStyle.ink)
        .padding(.horizontal, 12)
        .watchCard(radius: 16)
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sort-toast")
    }

    private var sortActions: some View {
        HStack(spacing: 12) {
            Button { model.resort() } label: {
                Text("Re-sort").multilineTextAlignment(.center).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }
            Button {
                model.resort()
                tab = .list
            } label: {
                Text("View My list").multilineTextAlignment(.center).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }
        }.buttonStyle(.plain).foregroundStyle(WatchWeeksStyle.link)
    }
}

private extension View {
    func watchTab(_ item: WatchWeeksTab) -> some View {
        tabItem { Label(item.rawValue, systemImage: item.symbol) }
            .tag(item)
    }
}

private enum WatchWeeksTab: String {
    case events = "Events", list = "My list", brands = "Brands A–Z", releases = "New releases"

    var symbol: String {
        switch self {
        case .events: "calendar"
        case .list: "checklist"
        case .brands: "character.book.closed"
        case .releases: "sparkles"
        }
    }
}

// All text styles use bundled WatchWeeks typography and preserve Dynamic Type.
extension Font {
    static let wwBody = Font.custom("SpaceGrotesk-Regular", size: 17, relativeTo: .body)
    static let wwHeadline = Font.custom("SpaceGrotesk-SemiBold", size: 17, relativeTo: .headline)
    static let wwSubheadline = Font.custom("SpaceGrotesk-Regular", size: 15, relativeTo: .subheadline)
    static let wwCallout = Font.custom("SpaceGrotesk-Regular", size: 16, relativeTo: .callout)
    static let wwFootnote = Font.custom("SpaceGrotesk-Regular", size: 13, relativeTo: .footnote)
    static let wwCaption = Font.custom("SpaceGrotesk-Medium", size: 12, relativeTo: .caption)
    static let wwCaption2 = Font.custom("SpaceGrotesk-Regular", size: 11, relativeTo: .caption2)
    static let wwTitle = Font.custom("SpaceGrotesk-Bold", size: 28, relativeTo: .title)
    static let wwTitle2 = Font.custom("SpaceGrotesk-Bold", size: 22, relativeTo: .title2)
    static let wwTitle3 = Font.custom("SpaceGrotesk-SemiBold", size: 20, relativeTo: .title3)
    static let wwLargeTitle = Font.custom("SpaceGrotesk-Bold", size: 34, relativeTo: .largeTitle)
}
@MainActor enum BrandTypography {
    static func configureNavigation() {
        #if DEBUG
        for name in ["Regular", "Medium", "SemiBold", "Bold"] {
            assert(UIFont(name: "SpaceGrotesk-" + name, size: 17) != nil, "Bundled Space Grotesk failed to register")
        }
        #endif
        let bar = UINavigationBar.appearance()
        if let font = UIFont(name: "SpaceGrotesk-Bold", size: 34) {
            bar.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)]
        }
        if let font = UIFont(name: "SpaceGrotesk-SemiBold", size: 17) {
            bar.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)]
        }
        if let font = UIFont(name: "SpaceGrotesk-Regular", size: 17) {
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: font)]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
                .setTitleTextAttributes(attributes, for: .normal)
        }

    }
}

struct WebsiteLink: View {
    let title: String
    let url: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(title) { openURL(url) { accepted in if accepted, url.host == "watchweeks.com" { UsageAnalytics.shared.record(.website) } } }
    }
}

@MainActor final class UsageAnalytics: ObservableObject {
    static let shared = UsageAnalytics()
    @Published private(set) var enabled = false
    @Published private(set) var showConsentPrompt = false
    private let client: UsageAnalyticsClient?
    private let prompt: UsageAnalyticsPromptPolicy
    private var promptIsActive = false
    private var promptTimer: Task<Void, Never>?
    #if DEBUG && targetEnvironment(simulator)
    let qaRecorder: AnalyticsQARecorder?
    #endif
    var isAvailable: Bool { client != nil }
    private init() {
        let defaults: UserDefaults
        let token: String?
        let endpoint: URL
        #if DEBUG && targetEnvironment(simulator)
        defaults=ProcessInfo.processInfo.environment["WW_ANALYTICS_QA_SUITE"].flatMap(UserDefaults.init(suiteName:)) ?? .standard
        token=ProcessInfo.processInfo.environment["WW_ANALYTICS_QA"] == "1" ? "phc_watchweeks_qa" : nil
        endpoint=URL(string:"http://localhost:8766/i/v0/e/")!
        #elseif DEBUG || targetEnvironment(simulator)
        defaults = .standard; token=nil; endpoint=URL(string:"http://localhost:8766/i/v0/e/")!
        #else
        defaults = .standard
        token=(Bundle.main.object(forInfoDictionaryKey:"WatchWeeksPostHogToken") as? String).flatMap { $0.hasPrefix("phc_") ? $0 : nil }
        endpoint=URL(string:"https://us.i.posthog.com/i/v0/e/")!
        #endif
        prompt=UsageAnalyticsPromptPolicy(defaults:defaults)
        let transport: UsageAnalyticsClient.Transport?
        #if DEBUG && targetEnvironment(simulator)
        if token != nil {
            let recorder=AnalyticsQARecorder(defaults:defaults)
            qaRecorder=recorder
            transport = { request in try recorder.receive(request) }
        } else { qaRecorder=nil; transport=nil }
        #else
        transport=nil
        #endif
        if let token {
            client=UsageAnalyticsClient(token:token,endpoint:endpoint,
                version:Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "unknown",
                build:Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as? String ?? "unknown",defaults:defaults,transport:transport)
            enabled=client?.enabled ?? false
        } else { client=nil }
    }
    func setEnabled(_ value: Bool) {
        client?.setEnabled(value); enabled=client?.enabled ?? false
        prompt.dismiss(); updatePrompt()
    }
    func declinePrompt() { setEnabled(false) }
    func setPromptForeground(_ active: Bool) {
        promptIsActive=active; prompt.setActive(active); updatePrompt()
    }
    private func updatePrompt() {
        promptTimer?.cancel(); promptTimer=nil
        showConsentPrompt=isAvailable && promptIsActive && prompt.shouldPresent
        guard isAvailable, promptIsActive, !prompt.hasChoice, prompt.hasEngaged,
              !showConsentPrompt else { return }
        let delay=prompt.remainingActiveSeconds
        promptTimer=Task { [weak self] in
            do { try await Task.sleep(for:.seconds(delay)) } catch { return }
            guard let self, !Task.isCancelled else { return }
            self.updatePrompt()
        }
    }
    func active() { client?.becameActive() }
    func background() { client?.becameBackground() }
    func record(_ action: UsageAction, guideID: String? = nil, eventID: String? = nil, releaseID: String? = nil) {
        // Before consent the prompt sees only the action category, never IDs or
        // event history. The delivery client's independent consent guard stays on.
        prompt.record(action); updatePrompt()
        client?.record(action,guideID:guideID,eventID:eventID,releaseID:releaseID)
    }
}

#if DEBUG && targetEnvironment(simulator)
/// Test-only receiver: consumes the actual serialized request without any network.
/// The production Release binary contains neither this receiver nor its UI.
@MainActor final class AnalyticsQARecorder: ObservableObject {
    @Published private(set) var events: [[String:String]]
    private let defaults: UserDefaults
    init(defaults: UserDefaults) {
        self.defaults=defaults
        events=(defaults.array(forKey:"analyticsQA.received") as? [[String:String]]) ?? []
    }
    var json: String {
        guard let data=try? JSONSerialization.data(withJSONObject:events), let text=String(data:data,encoding:.utf8) else { return "[]" }
        return text
    }
    func receive(_ request: URLRequest) throws -> Int {
        guard request.url?.host == "localhost", request.httpMethod == "POST",
              let data=request.httpBody,
              let payload=try JSONSerialization.jsonObject(with:data) as? [String:Any],
              payload["api_key"] as? String == "phc_watchweeks_qa",
              let name=payload["event"] as? String, let id=payload["distinct_id"] as? String,
              let properties=payload["properties"] as? [String:Any],
              properties["platform"] as? String == "ios_native",
              properties["$geoip_disable"] as? Bool == true,
              properties["$process_person_profile"] as? Bool == false else {
            throw NSError(domain:"AnalyticsQA.InvalidPayload",code:1)
        }
        events.append(["event":name,"id":id]);events=Array(events.suffix(100))
        defaults.set(events,forKey:"analyticsQA.received")
        return 200
    }
}
struct AnalyticsQADiagnostics: View {
    @ObservedObject var recorder: AnalyticsQARecorder
    var body: some View {
        Text("Analytics QA: \(recorder.events.count)")
            .accessibilityIdentifier("analytics-qa-events")
            .accessibilityValue(recorder.json)
    }
}
#endif

// A signed, integrated client and a live backend are required. App Store users
// additionally require proven remote availability; TestFlight can verify delivery.
@MainActor final class GuidePublicationAlerts: ObservableObject {
    static let shared = GuidePublicationAlerts()
    @Published private(set) var isConfigured=false
    @Published private(set) var isBusy=false
    @Published private(set) var isEnabled=false
    @Published private(set) var deletionPending=false
    @Published private(set) var isVerificationMode=false
    @Published private(set) var installationID: String?
    @Published private(set) var permissionDenied=false
    @Published private(set) var hasEnrollment=false
    @Published private(set) var isChecking=false
    var statusLabel: String {
        if deletionPending { return "Turning off" }
        if isBusy { return "Connecting" }
        if isEnabled { return "On" }
        return hasEnrollment ? "Pending" : "Off"
    }
    @Published private(set) var message: String?
    @Published private(set) var pendingGuideID: String?
    private let subscription=PushSubscription(service:PushInstallationClient(),store:PushKeychainStore(),makeCredential: {
        var bytes=[UInt8](repeating:0,count:32)
        guard SecRandomCopyBytes(kSecRandomDefault,bytes.count,&bytes) == errSecSuccess else { throw PushServiceError.invalidRequest }
        return try PushCredential.format(randomBytes:Data(bytes))
    })
    private var registration: Task<Void,Never>?
    private var acceptToken=false
    private var timeout: Task<Void,Never>?
    private var retry: Task<Void,Never>?
    private var active=false
    private var registeredThisProcess=false
    private var lastReconciled: Date?
    private var serviceTask: Task<UpcomingGuideFeed?,Never>?
    private var distributionTask: Task<Void,Never>?
    private var lastDistributionAttempt: Date?
    private var verifiedSandboxTransaction: Bool?
    private var backendPresent=false
    private var deliveryAvailable=false
    private var availabilityError: String?
    private var waitingToken: Data?
    private let intent: PushRegistrationIntent = {
        #if DEBUG && targetEnvironment(simulator)
        if let suite=ProcessInfo.processInfo.environment["WW_PUSH_PERMISSION_QA_SUITE"], let defaults=UserDefaults(suiteName:suite) {
            return PushRegistrationIntent(defaults:defaults)
        }
        #endif
        return PushRegistrationIntent()
    }()
    private let defaults=UserDefaults.standard
    private let seenKey="watchweeks.opened-publication-notifications.v1"
    private var environment: APNSEnvironment? {
        #if targetEnvironment(simulator)
        return nil // Simulator UI QA never enrolls a real token or asks permission.
        #else
        // Set only by the signed-build setup; validate against the final signed
        // aps-environment entitlement using scripts/verify-push-archive.py.
        guard Bundle.main.object(forInfoDictionaryKey:"WatchWeeksPushIntegrationVerified") as? Bool == true,
              let value=Bundle.main.object(forInfoDictionaryKey:"WatchWeeksAPNsEnvironment") as? String else { return nil }
        return APNSEnvironment(rawValue:value)
        #endif
    }
    private init() {}
    private var isTestFlight: Bool {
        GuidePushActivation.internalVerificationBuild(
            allowed:Bundle.main.object(forInfoDictionaryKey:"WatchWeeksPushVerificationBuild") as? Bool == true,
            verifiedSandboxTransaction:verifiedSandboxTransaction,
            legacySandboxReceipt:Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
    }
    private var permissionEligible: Bool {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["WW_PUSH_PERMISSION_QA"] == "1" { return true }
        #endif
        return environment != nil && (deliveryAvailable || isTestFlight)
    }
    var homeActionTitle: String {
        if deletionPending { return "Turning off…" }
        if isEnabled { return "Notifications on" }
        if permissionDenied { return "Open notification settings" }
        if hasEnrollment || isBusy { return "Finishing setup…" }
        return "Notify me"
    }
    private func updateConfiguration() {
        let wasConfigured=isConfigured
        let beta=GuidePushActivation.internalVerificationBuild(
            allowed:Bundle.main.object(forInfoDictionaryKey:"WatchWeeksPushVerificationBuild") as? Bool == true,
            verifiedSandboxTransaction:verifiedSandboxTransaction,
            legacySandboxReceipt:Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
        isConfigured=GuidePushActivation.available(
            clientReady:Bundle.main.object(forInfoDictionaryKey:"WatchWeeksPushIntegrationVerified") as? Bool == true,
            signedEnvironment:environment,backendPresent:backendPresent,deliveryAvailable:deliveryAvailable,verificationTestFlight:beta)
        isVerificationMode=isConfigured && !deliveryAvailable && beta
        isChecking=serviceTask != nil || distributionTask != nil
        if isConfigured, let token=waitingToken {
            waitingToken=nil;receivedDeviceToken(token)
        }
        if !wasConfigured && isConfigured && active {
            Task { guard self.active else { return };await self.foreground() }
        }
    }
    private static func verifiedTestFlightTransaction() async -> Bool? {
        // AppTransaction.shared reads Apple's verified download metadata. Do not
        // call refresh(), request purchases, identify the account, or send its JWS.
        do {
            let result=try await AppTransaction.shared
            guard case .verified(let transaction)=result else { return nil }
            return transaction.environment == .sandbox
        } catch { return nil }
    }
    private func checkDistribution() {
        #if !targetEnvironment(simulator)
        guard verifiedSandboxTransaction == nil, distributionTask == nil,
              lastDistributionAttempt == nil || Date().timeIntervalSince(lastDistributionAttempt!) >= 30 else { return }
        lastDistributionAttempt=Date()
        distributionTask=Task {
            verifiedSandboxTransaction=await Self.verifiedTestFlightTransaction()
            distributionTask=nil;updateConfiguration()
        }
        #endif
    }
    func refreshAvailability() async -> UpcomingGuideFeed? {
        checkDistribution()
        if let serviceTask { return await serviceTask.value }
        let work=Task { () -> UpcomingGuideFeed? in
            defer { serviceTask=nil;updateConfiguration() }
            do {
                let feed=try await PublicGuideService().upcoming()
                backendPresent=true;deliveryAvailable=feed.capabilities.push.available;availabilityError=nil
                return feed
            } catch {
                if !GuideRefreshFailure.isCancellation(error) { availabilityError="Couldn’t reach the guide alert service. Check your connection and retry." }
                return nil
            }
        }
        serviceTask=work;updateConfiguration()
        return await work.value
    }
    var availabilityMessage: String {
        if isChecking { return "Checking notification setup…" }
        if let availabilityError { return availabilityError }
        if isConfigured { return "Guide alerts are ready to enable on this device." }
        return "Publication alerts are awaiting delivery verification. If you’re using TestFlight, retry setup while connected to the internet."
    }
    private func syncState() {
        isEnabled=subscription.state == .on
        deletionPending=subscription.state == .deletionPending
        installationID=(try? subscription.installationID())?.uuidString.lowercased()
        hasEnrollment=intent.requested || (try? subscription.hasSavedSubscription()) == true
    }
    func foreground() async {
        active=true
        defer { syncState();scheduleRetry() }
        do {
            // No credential exists in current releases. Do not register or ask
            // permission automatically for a guest who has never enrolled.
            let saved=try subscription.hasSavedSubscription()
            let settings=await UNUserNotificationCenter.current().notificationSettings()
            permissionDenied=settings.authorizationStatus == .denied
            let allowed: [UNAuthorizationStatus] = [.authorized,.provisional,.ephemeral]
            if !allowed.contains(settings.authorizationStatus) {
                intent.cancel();waitingToken=nil
                acceptToken=false;timeout?.cancel();registeredThisProcess=false
                try await subscription.permissionChanged(granted:false)
            }
            else {
                if intent.requested, !isConfigured, intent.retryAt == nil || intent.retryAt! <= Date() {
                    _ = await refreshAvailability()
                    if !isConfigured { intent.retryAfterFailure();return }
                }
                let hasRetry=try subscription.retryDate() != nil
                if lastReconciled == nil || Date().timeIntervalSince(lastReconciled!) >= 900 || hasRetry {
                    try await subscription.reconcile(allowEnrollment:isConfigured);lastReconciled=Date()
                }
                if saved {
                    guard try subscription.hasSavedSubscription() else { intent.cancel();waitingToken=nil;return }
                    intent.authorized()
                }
                if let token=waitingToken, isConfigured { waitingToken=nil;receivedDeviceToken(token) }
                if (saved || intent.requested), permissionEligible, environment != nil,
                   waitingToken == nil, !registeredThisProcess,
                   intent.retryAt == nil || intent.retryAt! <= Date() {
                    registerWithApple()
                }
            }
            syncState()
        } catch { syncState();message="Alert preferences could not refresh. Please retry." }
    }
    func background() { active=false;retry?.cancel();retry=nil }
    private func scheduleRetry() {
        retry?.cancel();retry=nil
        let dates=[intent.retryAt,(isConfigured || deletionPending) ? (try? subscription.retryDate()) : nil].compactMap { $0 }
        guard active, let date=dates.min() else { return }
        retry=Task { [weak self] in
            do { try await Task.sleep(for:.seconds(max(1,date.timeIntervalSinceNow))) } catch { return }
            await self?.foreground()
        }
    }
    func requestSubscription() async {
        guard !isBusy else { return };isBusy=true
        // No backend fetch before the OS dialog for a known eligible download.
        // TestFlight eligibility is local signed Apple metadata, not APNs routing.
        if !permissionEligible {
            checkDistribution();await distributionTask?.value
            if !permissionEligible, environment != nil { _ = await refreshAvailability() }
        }
        guard permissionEligible else { isBusy=false;message=availabilityMessage;return }
        do {
            let allowed=try await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound])
            guard allowed else {
                permissionDenied=true
                intent.cancel();waitingToken=nil
                acceptToken=false;timeout?.cancel();registeredThisProcess=false
                try await subscription.permissionChanged(granted:false);syncState();isBusy=false
                message="Notifications are off. You can change this in device Settings.";return
            }
            permissionDenied=false
            intent.authorized();syncState();message="Finishing notification setup…"
            if environment != nil { registerWithApple() }
            else { isBusy=false } // Simulator permission QA never obtains an APNs token.
            Task { _ = await self.refreshAvailability() }
        } catch { isBusy=false;message="Notification permission could not be requested." }
    }
    private func registerWithApple() {
        intent.beginAttempt()
        acceptToken=true;registeredThisProcess=true
        UIApplication.shared.registerForRemoteNotifications()
        timeout?.cancel()
        timeout=Task { [weak self] in
            do { try await Task.sleep(for:.seconds(30)) } catch { return }
            self?.registrationFailed()
        }
    }
    func receivedDeviceToken(_ data: Data) {
        guard acceptToken || intent.requested || (try? subscription.hasSavedSubscription()) == true,
              let environment else { return }
        acceptToken=false
        timeout?.cancel()
        intent.receivedToken()
        guard isConfigured else {
            waitingToken=data;isBusy=false;intent.retryAfterFailure();syncState();scheduleRetry();return
        }
        guard registration == nil else { return }
        isBusy=true
        registration=Task {
            defer { registration=nil;isBusy=false;syncState();scheduleRetry() }
            do {
                let version=Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? ""
                try await subscription.register(token:data,environment:environment,appVersion:version,osVersion:UIDevice.current.systemVersion)
                message=subscription.state == .on ? "Guide alerts are enabled." : "Guide alerts are off."
            } catch { message="Finishing notification setup when connected…" }
        }
    }
    func unsubscribe() async {
        intent.cancel();waitingToken=nil;registeredThisProcess=false
        acceptToken=false
        defer { scheduleRetry() }
        timeout?.cancel()
        do {
            try await subscription.disable()
            await registration?.value
            isBusy=false
            syncState()
            message=deletionPending ? "Unsubscribe is pending. Reopen the app online to finish." : "Guide alerts are off."
        } catch { isBusy=false;syncState();message="Unsubscribe is pending. Retry online to finish; alerts may still arrive until confirmed." }
    }
    func registrationFailed() {
        timeout?.cancel();registeredThisProcess=false;isBusy=false
        guard intent.requested || (try? subscription.hasSavedSubscription()) == true else { return }
        // Keep accepting a late token, and retry without another consent flow.
        intent.retryAfterFailure();syncState();scheduleRetry()
        message="Finishing notification setup when connected…"
    }
    func openPublishedGuide(_ notification: GuidePublicationNotification) {
        var inbox=GuidePublicationInbox(openedIDs:defaults.stringArray(forKey:seenKey) ?? [])
        guard inbox.accept(notification) else { return }
        defaults.set(inbox.openedIDs,forKey:seenKey)
        pendingGuideID=notification.guideID
    }
    func clearPendingRoute() { pendingGuideID=nil }
}

/// Device-bound, excluded from iCloud synchronization and device migration.
@MainActor private final class PushKeychainStore: PushCredentialStore {
    private var query: [String:Any] { [kSecClass as String:kSecClassGenericPassword,
        kSecAttrService as String:"com.watchweeks.app.guide-push.v1",kSecAttrAccount as String:"installation"] }
    func load() throws -> PushCredential? {
        var request=query;request[kSecReturnData as String]=true;request[kSecMatchLimit as String]=kSecMatchLimitOne
        var result: CFTypeRef?
        let status=SecItemCopyMatching(request as CFDictionary,&result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data=result as? Data else { throw PushServiceError.invalidResponse }
        return try JSONDecoder().decode(PushCredential.self,from:data)
    }
    func save(_ credential: PushCredential) throws {
        let data=try JSONEncoder().encode(credential)
        let values: [String:Any]=[kSecValueData as String:data,
            kSecAttrAccessible as String:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status=SecItemUpdate(query as CFDictionary,values as CFDictionary)
        if status == errSecItemNotFound {
            var record=query;record.merge(values) { _,new in new };status=SecItemAdd(record as CFDictionary,nil)
        }
        guard status == errSecSuccess else { throw PushServiceError.invalidResponse }
    }
    func remove() throws {
        let status=SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw PushServiceError.invalidResponse }
    }
}
@MainActor final class WatchWeeksPushDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey:Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate=self
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        GuidePublicationAlerts.shared.receivedDeviceToken(deviceToken)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        GuidePublicationAlerts.shared.registrationFailed()
    }
    private nonisolated static func publication(_ payload: [AnyHashable:Any]) -> GuidePublicationNotification? {
        GuidePublicationNotification(type:payload["type"] as? String,version:payload["payload_v"] as? Int,
            guideID:payload["guide_id"] as? String,notificationID:payload["notification_id"] as? String)
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let notification=Self.publication(response.notification.request.content.userInfo) else { return }
        await GuidePublicationAlerts.shared.openPublishedGuide(notification)
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard Self.publication(notification.request.content.userInfo) != nil else { return [] }
        return [.banner,.sound]
    }
}
