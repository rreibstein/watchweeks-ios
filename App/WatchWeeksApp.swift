import SwiftUI
import UIKit
import WatchWeeksCore

@MainActor final class AppModel: ObservableObject {
    @Published var guides: [Guide] = []
    @Published var activeGuideID: String?
    @Published var releaseRequest:ReleaseNavigationRequest?
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
        if let json=ProcessInfo.processInfo.environment["WW_ANNOUNCED_QA_GUIDE"],let data=json.data(using:.utf8),
           let guide=try? JSONDecoder().decode(PublicDetail.self,from:data).model() {
            guides=[guide];activeGuideID=guide.id;loaded=true
        }
        #endif
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
        if ProcessInfo.processInfo.environment["WW_NATIVE_QA_CITY"] != nil || ProcessInfo.processInfo.environment["WW_ANNOUNCED_QA_GUIDE"] != nil { return }
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
        if let feed=try? await PublicGuideService().upcoming() {
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
    init() { BrandTypography.configureNavigation() }
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .onChange(of: phase, initial: true) { _, phase in
                    UsageAnalytics.shared.setPromptForeground(phase == .active)
                    if phase == .background { UsageAnalytics.shared.background() }
                }
                .task(id: phase == .background) {
                    guard phase != .background else { return }
                    UsageAnalytics.shared.active()
                    let currentModel=model
                    async let initialGuides: Void = currentModel.start()
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
        .onChange(of:model.releaseRequest?.id) { _, value in if value != nil { tab = .releases } }
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

/// Rapid release: feature calls are inert. No consent/ID/queue is read or written.
@MainActor final class UsageAnalytics {
    static let shared=UsageAnalytics()
    func active() {}
    func background() {}
    func setPromptForeground(_ active:Bool) {}
    func record(_ action:UsageAction,guideID:String? = nil,eventID:String? = nil,releaseID:String? = nil) {}
    func recordAnnouncement(_ item:AnnouncedRelease?,guideID:String,source:AnnouncedSurface,position:Int?,count:Int) {}
}
