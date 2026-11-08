import SwiftUI
import UIKit
import WatchWeeksCore

@MainActor final class AppModel: ObservableObject {
    @Published var guides: [Guide] = []
    @Published var activeGuideID: String?
    @Published var visitGuides: [Guide] = []
    @Published var selections: [SelectionKey: Selection] = [:]
    @Published var loading = false
    @Published var message: String?
    @Published var savedAt: Date?
    @Published var stale = false
    @Published var persistenceError: String?
    private let store: LocalStore
    private let repository: GuideRepository
    private var loaded = false
    private var selectionsReadable = true
    private var saving: Task<Void, Never>?
    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WatchWeeks", isDirectory: true)
        let store = LocalStore(directory: root)
        self.store=store; self.repository=GuideRepository(service: PublicGuideService(), store: store)
    }
    func start() async {
        guard !loaded else { return }; loaded = true
        do { selections = try await store.selections() }
        catch { selectionsReadable = false; persistenceError = "Saved selections could not be read. They have not been replaced. Restart after checking device storage."; return }
        visitGuides = (try? await store.rememberedGuides()) ?? []
        if let snapshot = try? await store.snapshot() { guides=snapshot.guides; savedAt=snapshot.fetchedAt; stale=true }
        await refresh()
    }
    func refresh() async {
        guard !loading else { return }; loading=true; defer { loading=false }
        do { let result = try await repository.load(); guides=result.guides; savedAt=result.fetchedAt; stale=result.stale; message=result.warning; visitGuides = (try? await store.rememberedGuides()) ?? result.guides }
        catch { message=error.localizedDescription }
    }
    func selection(_ guide: Guide, _ brand: Brand) -> Selection { selections[SelectionKey(guideID: guide.id, brandID: brand.id)] ?? Selection() }
    func set(_ selection: Selection, guide: Guide, brand: Brand) {
        guard persistenceError == nil else { return }
        let previous = self.selection(guide, brand)
        var selection = selection
        if selection.shortlisted == nil, previous.interest != selection.interest {
            selection.shortlisted = previous.isShortlisted
        }
        guard previous != selection else { return }
        if previous.interest != selection.interest { NativeAnalytics.shared.track(.ratingSet,guide:guide,brandID:brand.id,rating:selection.interest.category) }
        if previous.seen != selection.seen { NativeAnalytics.shared.track(.seenToggled,guide:guide,brandID:brand.id,seen:selection.seen) }
        selections[SelectionKey(guideID: guide.id, brandID: brand.id)] = selection
        let snapshot = selections; let previousSave = saving; let store = store
        saving = Task { [weak self] in
            await previousSave?.value
            do { try await store.saveSelections(snapshot) }
            catch { self?.persistenceError = "Your latest changes could not be saved. Keep the app open, free device storage, then tap Retry saving." }
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
            RootView().environmentObject(model).task { NativeAnalytics.shared.active(); await model.start() }
                .onChange(of: phase) { _, phase in if phase == .active { NativeAnalytics.shared.active(); Task { await model.refresh() } }; if phase == .background { NativeAnalytics.shared.background() } }
        }
    }
}
struct RootView: View {
    @ObservedObject private var analytics = NativeAnalytics.shared
    @EnvironmentObject var model: AppModel
    @State private var tab: WatchWeeksTab = .events

    var body: some View {
        TabView(selection: $tab) {
            DiscoveryView().tag(WatchWeeksTab.events).toolbar(.hidden, for: .tabBar)
            VisitView().tag(WatchWeeksTab.list).toolbar(.hidden, for: .tabBar)
            CatalogView(releases: false).tag(WatchWeeksTab.brands).toolbar(.hidden, for: .tabBar)
            CatalogView(releases: true).tag(WatchWeeksTab.releases).toolbar(.hidden, for: .tabBar)
        }
        .sheet(isPresented: Binding(get: { !analytics.choiceMade }, set: { _ in })) { AnalyticsConsent() }
        .onChange(of: tab) { _, value in if value == .list { analytics.track(.myVisitViewed) } }
        .tint(WatchWeeksStyle.link)
        .font(.wwBody)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if let error = model.persistenceError {
                    VStack {
                        Text(error).font(.wwFootnote)
                        Button("Retry saving") { Task { await model.retrySaving() } }
                    }.padding()
                }
                HStack(spacing: 0) {
                    ForEach(WatchWeeksTab.allCases, id: \.self) { item in
                        Button { tab = item } label: {
                            VStack(spacing: 4) {
                                Image(systemName: item.symbol).font(.system(size: 21))
                                Text(item.rawValue).font(.wwCaption).multilineTextAlignment(.center)
                            }
                            .foregroundStyle(tab == item ? WatchWeeksStyle.ink : WatchWeeksStyle.secondary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(tab == item ? WatchWeeksStyle.control : Color.clear)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(tab == item ? .isSelected : [])
                        .accessibilityIdentifier("tab-\(item.rawValue)")
                    }
                }
            }
            .background(WatchWeeksStyle.card.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(WatchWeeksStyle.border).frame(height: 1) }
        }
    }
}

private enum WatchWeeksTab: String, CaseIterable {
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

    }
}

// Account access is local UI, never conditional on feed/auth network readiness.
struct AccountButton: View {
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            Image(systemName: "person.crop.circle").frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Account")
        .accessibilityHint("Manage your existing WatchWeeks account on the website")
        .sheet(isPresented: $showing) { AccountView() }
    }
}
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Your WatchWeeks account") {
                    Text("Use your existing WatchWeeks account on the website to sign in, manage your account and access website synchronization.")
                    WebsiteLink(title: "Open WatchWeeks account", url: PublicLinks.account)
                }
                Section("On this iPhone") {
                    Text("You can use the native app without signing in. Your native ratings and seen selections are stored on this device. Signing in on the website does not sign you into this app or synchronize these native selections.")
                    Text("The account website needs an internet connection. Your previously loaded guides and native checklist remain available offline.")
                    NavigationLink("About & analytics") { AboutView() }
                }
            }
            .font(.wwBody)
            .scrollContentBackground(.hidden).watchPage()
            .navigationTitle("Account")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
extension View {
    func guideToolbar() -> some View {
        toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { WatchWordmark(compact: true) }
                ToolbarItemGroup(placement: .topBarTrailing) { WatchFindButton(compact: true); AccountButton() }
            }
    }

    func accountAccess() -> some View {
        toolbar(.visible, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { AccountButton() } }
    }
}
