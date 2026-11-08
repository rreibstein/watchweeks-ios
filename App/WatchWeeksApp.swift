import SwiftUI
import WatchWeeksCore

@MainActor final class AppModel: ObservableObject {
    @Published var guides: [Guide] = []
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
        if let snapshot = try? await store.snapshot() { guides=snapshot.guides; savedAt=snapshot.fetchedAt; stale=true }
        await refresh()
    }
    func refresh() async {
        guard !loading else { return }; loading=true; defer { loading=false }
        do { let result = try await repository.load(); guides=result.guides; savedAt=result.fetchedAt; stale=result.stale; message=result.warning }
        catch { message=error.localizedDescription }
    }
    func selection(_ guide: Guide, _ brand: Brand) -> Selection { selections[SelectionKey(guideID: guide.id, brandID: brand.id)] ?? Selection() }
    func set(_ selection: Selection, guide: Guide, brand: Brand) {
        guard persistenceError == nil else { return }
        selections[SelectionKey(guideID: guide.id, brandID: brand.id)] = selection
        let snapshot = selections; let previous = saving; let store = store
        saving = Task { [weak self] in
            await previous?.value
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
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).task { await model.start() }
                .onChange(of: phase) { _, phase in if phase == .active { Task { await model.refresh() } } }
        }
    }
}
struct RootView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        TabView {
            DiscoveryView().tabItem { Label("Discover", systemImage: "globe.europe.africa") }
            VisitView().tabItem { Label("My Visit", systemImage: "checklist") }
            AboutView().tabItem { Label("About", systemImage: "info.circle") }
        }
        .safeAreaInset(edge: .bottom) {
            if let error = model.persistenceError {
                VStack { Text(error).font(.footnote); Button("Retry saving") { Task { await model.retrySaving() } } }.padding().background(.regularMaterial)
            }
        }
    }
}
struct DiscoveryView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""
    var ordered: [Guide] {
        model.guides.filter { query.isEmpty || $0.city.localizedCaseInsensitiveContains(query) }
            .sorted { a,b in
                func rank(_ g: Guide) -> Int { switch EventDates.status(g) { case .current: 0; case .upcoming: 1; case .unknown: 2; case .past: 3 } }
                if rank(a) != rank(b) { return rank(a) < rank(b) }
                return (a.startDate ?? "9999") < (b.startDate ?? "9999")
            }
    }
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Your independent guide to watch events around the world.").font(.subheadline).foregroundStyle(.secondary) }
                if model.loading && model.guides.isEmpty { ProgressView("Loading guides…") }
                if let message = model.message { Section { Text(message).font(.callout); Button("Try again") { Task { await model.refresh() } } } }
                if model.stale, let date = model.savedAt { Label("Offline copy · updated \(date.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock.arrow.circlepath").font(.caption) }
                ForEach(ordered) { guide in
                    NavigationLink { CityView(guide: guide) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(EventDates.status(guide).rawValue).font(.caption).foregroundStyle(.secondary)
                            Text(guide.city).font(.title2.bold())
                            Text(dateRange(guide)).font(.subheadline)
                            if let summary = guide.summary { Text(summary).lineLimit(3).foregroundStyle(.secondary) }
                        }.padding(.vertical, 8)
                    }
                }
                if ordered.isEmpty && !model.loading { ContentUnavailableView(query.isEmpty ? "No guides loaded" : "No matching cities", systemImage: "globe", description: Text(query.isEmpty ? "Pull to refresh. Previously loaded guides will be available here offline." : "Try another search.")) }
            }
            .navigationTitle("WatchWeeks").searchable(text: $query, prompt: "Search cities")
            .refreshable { await model.refresh() }
        }
    }
}
func dateRange(_ g: Guide) -> String { [g.startDate, g.endDate].compactMap { $0 }.map { EventDates.label($0, zone: g.timeZone) }.joined(separator: " – ") }
struct CityView: View {
    let guide: Guide
    @State private var section = "Events"
    var body: some View {
        VStack(spacing: 0) {
            Picker("Explore", selection: $section) { ForEach(["Events", "Brands", "Releases"], id: \.self) { Text($0) } }.pickerStyle(.segmented).padding()
            switch section {
            case "Brands": BrandsView(guide: guide)
            case "Releases": ReleasesView(guide: guide)
            default:
                List {
                    Section { Text(dateRange(guide)); Text("All schedules use \(guide.timeZone) local time.").font(.caption).foregroundStyle(.secondary) }
                    ForEach(guide.events) { event in
                        Section(event.name) {
                            if let venue = event.venue { Label(venue, systemImage: "mappin.and.ellipse") }
                            if let address = event.address { Text(address).textSelection(.enabled) }
                            Text(EventDates.label(event.startsAt, zone: guide.timeZone))
                            if let end = event.endsAt { Text("Until \(EventDates.label(end, zone: guide.timeZone))") }
                            if let url = PublicLinks.safeExternal(event.webURL) { Link("Event information", destination: url); ShareLink(item: url) }
                        }
                    }
                    if guide.events.isEmpty { ContentUnavailableView("No event details available", systemImage: "calendar") }
                }
            }
        }.navigationTitle(guide.city).navigationBarTitleDisplayMode(.inline)
            .toolbar { if let url = PublicLinks.safeExternal(guide.webURL) { ShareLink(item: url) } }
    }
}
struct BrandsView: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    @State private var query = ""
    @State private var filter: BrandFilter = .all
    var brands: [Brand] { Browsing.brands(guide.brands, query: query, filter: filter) { model.selection(guide, $0) } }
    var body: some View {
        List {
            Picker("Show brands", selection: $filter) { ForEach(BrandFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
            ForEach(brands) { brand in BrandRow(guide: guide, brand: brand) }
            if brands.isEmpty { ContentUnavailableView("No matching brands", systemImage: "magnifyingglass", description: Text("Try another search or filter.")) }
        }.searchable(text: $query, prompt: "Search brands")
    }
}
struct BrandRow: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let brand: Brand
    var selection: Selection { model.selection(guide, brand) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(brand.name).font(.headline)
            if let summary = brand.summary { Text(summary).font(.subheadline).foregroundStyle(.secondary) }
            let venues = guide.events.filter { brand.eventIDs.contains($0.id) }.map { [$0.name, $0.venue].compactMap { $0 }.joined(separator: " · ") }
            ForEach(venues, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
            Picker("Interest in \(brand.name)", selection: Binding(get: { selection.interest }, set: { model.set(Selection(interest: $0, seen: selection.seen), guide: guide, brand: brand) })) {
                ForEach(Interest.allCases, id: \.self) { Text($0.label).tag($0) }
            }.pickerStyle(.menu)
            Toggle("Seen \(brand.name)", isOn: Binding(get: { selection.seen }, set: { model.set(Selection(interest: selection.interest, seen: $0), guide: guide, brand: brand) }))
            if let url = PublicLinks.safeExternal(brand.webURL) { Link("Brand information", destination: url).font(.subheadline) }
        }.padding(.vertical, 6).disabled(model.persistenceError != nil)
    }
}
struct VisitView: View {
    @EnvironmentObject var model: AppModel
    @State private var remaining = false
    var count: Int { model.selections.values.filter { $0.interest != .none }.count }
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Your selections stay on this device. They do not sync with your WatchWeeks website account.").font(.footnote).foregroundStyle(.secondary); Toggle("Show remaining only", isOn: $remaining) }
                ForEach(model.guides) { guide in
                    let selected = guide.brands.filter { let s = model.selection(guide, $0); return s.interest != .none && (!remaining || !s.seen) }
                    if !selected.isEmpty {
                        Section(guide.city) {
                            let all = guide.brands.filter { model.selection(guide, $0).interest != .none }
                            let seen = all.filter { model.selection(guide, $0).seen }.count
                            ProgressView("\(seen) of \(all.count) seen", value: Double(seen), total: Double(max(all.count, 1)))
                            ForEach(selected.sorted { model.selection(guide, $0).interest.rawValue > model.selection(guide, $1).interest.rawValue }) { brand in BrandRow(guide: guide, brand: brand) }
                        }
                    }
                }
                if count == 0 { ContentUnavailableView("Plan your visit", systemImage: "checklist", description: Text("Choose Interested or Must see on a brand in any city guide. Your checklist works offline after that guide is loaded.")) }
                if model.guides.isEmpty && count > 0 { Text("Your saved selections are preserved. Load their guides to view the checklist.") }
            }.navigationTitle("My Visit")
        }
    }
}
struct ReleasesView: View {
    let guide: Guide
    @State private var query = ""
    var body: some View {
        List {
            ForEach(guide.releases.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || ($0.brandName?.localizedCaseInsensitiveContains(query) == true) }) { release in
                NavigationLink { ReleaseDetail(release: release) } label: {
                    HStack { ReleaseImage(url: release.imageURL).frame(width: 72, height: 72).clipped(); VStack(alignment: .leading) { Text(release.title).font(.headline); if let brand = release.brandName { Text(brand).foregroundStyle(.secondary) } } }
                }
            }
            if guide.releases.isEmpty { ContentUnavailableView("No releases available", systemImage: "clock") }
        }.searchable(text: $query, prompt: "Search releases")
    }
}
struct ReleaseImage: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: PublicLinks.safeExternal(url)) { phase in
            if let image = phase.image { image.resizable().scaledToFit() }
            else { ZStack { Color.secondary.opacity(0.08); Image(systemName: "clock").font(.largeTitle).foregroundStyle(.secondary) } }
        }.accessibilityHidden(true)
    }
}
struct ReleaseDetail: View {
    let release: Release
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            ReleaseImage(url: release.imageURL).frame(height: 280)
            Text(release.title).font(.largeTitle.bold())
            if let brand = release.brandName { Text(brand).font(.title2) }
            if let details = release.details { Text(details).textSelection(.enabled) }
            if let url = PublicLinks.safeExternal(release.webURL) { Link("Full details", destination: url); ShareLink(item: url) }
        }.padding() }.navigationTitle("New release").navigationBarTitleDisplayMode(.inline)
    }
}
struct AboutView: View {
    var body: some View {
        NavigationStack { List {
            Section("WatchWeeks") { Text("WatchWeeks is an independent guide to watch fairs and events. It is not affiliated with or endorsed by the listed event organizers or brands.") }
            Section("Your visit, your device") { Text("No account is required. Interest ratings and seen selections are saved on this device and do not synchronize with the website. Removing the app removes its local data."); Text("Previously loaded guides work offline. Images and content you have not loaded may require a connection.") }
            Section("Explore more") { Link("Full WatchWeeks website", destination: PublicLinks.home); Text("Use the website for accounts, synchronization and advanced planning.").font(.footnote); Link("Privacy policy", destination: PublicLinks.privacy) }
            Section { Text("Version 1.0.0 (1)").foregroundStyle(.secondary) }
        }.navigationTitle("About") }
    }
}
