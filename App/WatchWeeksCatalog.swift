import SwiftUI
import UIKit
import WatchWeeksCore

struct BrandsView: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    var event: Event? = nil
    var body: some View {
        ScrollView {
            BrandDirectory(guide: guide, event: event).padding(16)
        }.watchPage()
    }
}

struct BrandDirectory: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    var event: Event? = nil
    @State private var query = ""
    @State private var filter: BrandFilter = .all
    @State private var byInterest = true
    @State private var shortlistOnly = false
    @State private var releasesOnly = false
    @State private var stockOnly = false

    private var eligible: [Brand] {
        guard let event else { return guide.brands }
        return guide.brands.filter { $0.eventIDs.contains(event.id) }
    }

    private var releaseBrands: Set<String> {
        Set(guide.releases.filter { event == nil || $0.eventID == event?.id }.compactMap(\.brandID))
    }

    var body: some View {
        let releases = releaseBrands
        let brands = eligible
        let shortlist = brands.count { model.selection(guide, $0).isShortlisted }
        let filtered = Browsing.brands(brands, query: query, filter: filter) { model.selection(guide, $0) }.filter {
            (!shortlistOnly || model.selection(guide, $0).isShortlisted)
                && (!releasesOnly || releases.contains($0.id))
                && (!stockOnly || SingaporeStock.brandIDs.contains($0.id))
        }
        let ordered = filtered.enumerated().sorted {
            let left = model.selection(guide, $0.element)
            let right = model.selection(guide, $1.element)
            if left.isShortlisted != right.isShortlisted { return left.isShortlisted }
            if byInterest, left.interest.priority != right.interest.priority {
                return left.interest.priority > right.interest.priority
            }
            return $0.offset < $1.offset
        }.map(\.element)

        LazyVStack(alignment: .leading, spacing: 12) {
            Text("Brands (\(brands.count))").font(.wwTitle).accessibilityAddTraits(.isHeader)
            WatchSegments(selection: $byInterest, choices: [true, false]) { $0 ? "Interest" : "A–Z" }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Menu {
                        Picker("Filters", selection: $filter) {
                            ForEach(BrandFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(filter == .all ? "Filters" : filter.rawValue, systemImage: "slider.horizontal.3")
                            .font(.wwSubheadline).padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 12)
                    }
                    filterChip("Shortlist \(shortlist)", icon: "pin", selected: $shortlistOnly)
                    filterChip("New releases \(releases.count)", icon: "sparkles", selected: $releasesOnly)
                    if SingaporeStock.applies(to: guide, event: event) {
                        filterChip("On-site stock", icon: "bag", selected: $stockOnly)
                    }
                }
            }
            TextField("Search brands", text: $query)
                .padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 12)
            ForEach(ordered) { brand in
                BrandRow(guide: guide, brand: brand, event: event)
            }
            if ordered.isEmpty { ContentUnavailableView("No matching brands", systemImage: "magnifyingglass") }
        }
    }

    private func filterChip(_ title: String, icon: String, selected: Binding<Bool>) -> some View {
        Button { selected.wrappedValue.toggle() } label: {
            Label(title, systemImage: icon).font(.wwSubheadline)
                .foregroundStyle(selected.wrappedValue ? WatchWeeksStyle.link : WatchWeeksStyle.ink)
                .padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 12)
        }.buttonStyle(.plain)
            .accessibilityAddTraits(selected.wrappedValue ? .isSelected : [])
    }
}

struct BrandRow: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var expanded = false
    let guide: Guide
    let brand: Brand
    var showDetails = true
    var event: Event? = nil
    var selection: Selection { model.selection(guide, brand) }
    private let interests: [Interest] = [.mustSee, .interested, .little, .unfamiliar, .skip]

    var body: some View {
        Group {
            if selection.isShortlisted && selection.seen && showDetails && !expanded {
                Button { expanded = true } label: {
                    Text(brand.name).font(.wwHeadline)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 16).watchCard()
                }.buttonStyle(.plain).accessibilityHint("Expand the seen brand")
            } else {
                expandedCard
            }
        }.onChange(of: selection.seen) { _, seen in if seen { expanded = false } }
    }

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if selection.isShortlisted && selection.seen && showDetails {
                    Button { expanded = false } label: {
                        Label(brand.name, systemImage: "chevron.up").font(.wwTitle3).frame(minHeight: 44)
                    }.buttonStyle(.plain).accessibilityHint("Collapse the seen brand")
                } else {
                    Text(brand.name).font(.wwTitle3).accessibilityAddTraits(.isHeader)
                }
                if let summary = brand.summary { Text(summary).font(.wwSubheadline) }
                if event == nil {
                    ForEach(guide.events.filter { brand.eventIDs.contains($0.id) }) { appearance in
                        NavigationLink { EventInfo(guide: guide, event: appearance) } label: {
                            Label(appearance.name, systemImage: "calendar").font(.wwFootnote)
                        }
                    }
                }
                if let release = guide.releases.first(where: { $0.brandID == brand.id && (event == nil || $0.eventID == event?.id) }) {
                    ReleaseBadges(release: release)
                    NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                        Label(release.title, systemImage: "sparkles").font(.wwFootnote).foregroundStyle(WatchWeeksStyle.release)
                    }
                }
                HStack {
                    Button {
                        var updated = selection
                        updated.shortlisted = !selection.isShortlisted
                        model.set(updated, guide: guide, brand: brand)
                    } label: {
                        Label(selection.isShortlisted ? "Shortlisted" : "Shortlist", systemImage: selection.isShortlisted ? "pin.fill" : "pin")
                            .font(.wwSubheadline).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("shortlist-\(brand.id)")
                        .accessibilityAddTraits(selection.isShortlisted ? .isSelected : [])
                    if showDetails {
                        NavigationLink { BrandInfo(guide: guide, brand: brand) } label: {
                            Image(systemName: "ellipsis").frame(minWidth: 44, minHeight: 44)
                        }.buttonStyle(.plain).accessibilityLabel("Details for \(brand.name)")
                    }
                    Spacer(minLength: 0)
                    Button {
                        var updated = selection
                        updated.seen.toggle()
                        model.set(updated, guide: guide, brand: brand)
                    } label: {
                        Image(systemName: selection.seen ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 30)).frame(minWidth: 48, minHeight: 48)
                    }.buttonStyle(.plain).accessibilityLabel("Seen \(brand.name)")
                        .accessibilityValue(selection.seen ? "Seen" : "Not seen")
                        .accessibilityAddTraits(selection.seen ? .isSelected : [])
                }
                if let url = PublicLinks.safeExternal(brand.webURL) {
                    Link("Brand website", destination: url).font(.wwFootnote)
                }
            }.padding(16)
            Divider()
            if typeSize.isAccessibilitySize {
                ForEach(interests, id: \.self, content: rating)
            } else {
                HStack(spacing: 0) {
                    ForEach(interests, id: \.self) { interest in
                        if interest != interests.first { Divider() }
                        rating(interest)
                    }
                }.fixedSize(horizontal: false, vertical: true)
            }
        }.watchCard()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(model.persistenceError != nil)
    }

    private func rating(_ interest: Interest) -> some View {
        let selected = selection.interest == interest
        return Button {
            var updated = selection
            updated.interest = selected ? .none : interest
            model.set(updated, guide: guide, brand: brand)
        } label: {
            Text(interest.label)
                .font(typeSize.isAccessibilitySize ? .wwBody : .wwCaption2)
                .multilineTextAlignment(.center).padding(.horizontal, 3)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selected ? WatchWeeksStyle.control : Color.clear)
                .foregroundStyle(selected ? WatchWeeksStyle.link : WatchWeeksStyle.ink)
        }.buttonStyle(.plain).accessibilityLabel("\(interest.label), \(brand.name)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct CityPicker: View {
    let guides: [Guide]
    @Binding var choice: String?
    var showAll = false

    var body: some View {
        Picker("Guide", selection: $choice) {
            if showAll { Text("All guides").tag(nil as String?) }
            else if choice == nil { Text("Choose a guide").tag(nil as String?) }
            ForEach(guides) { guide in Text(guide.city).tag(Optional(guide.id)) }
        }
        .pickerStyle(.menu).padding(.horizontal, 12).frame(minHeight: 44).watchCard(radius: 12)
    }
}

struct VisitView: View {
    @EnvironmentObject var model: AppModel
    @State private var remaining = false
    @State private var shortlistedOnly = false
    @State private var byInterest = true
    @State private var guideID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WatchHeader()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text("My list").font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
                        if !model.visitGuides.isEmpty {
                            CityPicker(guides: model.visitGuides, choice: $guideID, showAll: true)
                        }
                        WatchSegments(selection: $byInterest, choices: [true, false]) { $0 ? "Interest" : "A–Z" }
                        VStack(spacing: 6) {
                            Toggle("Shortlist only", isOn: $shortlistedOnly)
                            Toggle("Show remaining only", isOn: $remaining)
                        }.padding(12).watchCard()
                        Text("Your list is saved on this device.").font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
                        let guides = model.visitGuides.filter { guideID == nil || $0.id == guideID }
                        if !guides.contains(where: { !saved(in: $0).isEmpty }) {
                            ContentUnavailableView("Your list is empty", systemImage: "checklist",
                                                   description: Text("Rate, shortlist or check off a brand to find it here."))
                        }
                        ForEach(guides) { guide in citySection(guide) }
                    }.padding(16)
                }
            }.watchPage().toolbar(.hidden, for: .navigationBar)
                .onAppear {
                    guideID = model.visitGuides.contains(where: { $0.id == model.activeGuideID }) ? model.activeGuideID : nil
                }
        }
    }

    private func saved(in guide: Guide) -> [Brand] {
        guide.brands.filter { brand in
            let selection = model.selection(guide, brand)
            if shortlistedOnly { return selection.isShortlisted }
            return selection.isShortlisted || selection.interest != .none || selection.seen
        }.sorted { left, right in
            let first = model.selection(guide, left), second = model.selection(guide, right)
            if first.isShortlisted != second.isShortlisted { return first.isShortlisted }
            if byInterest, first.interest.priority != second.interest.priority { return first.interest.priority > second.interest.priority }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
    }

    @ViewBuilder private func citySection(_ guide: Guide) -> some View {
        let all = saved(in: guide)
        if !all.isEmpty {
            Text(guide.city).font(.wwTitle2).accessibilityAddTraits(.isHeader)
            let seen = all.count { model.selection(guide, $0).seen }
            ProgressView("\(seen) of \(all.count) seen", value: Double(seen), total: Double(all.count))
                .padding(12).watchCard()
            let visible = all.filter { !remaining || !model.selection(guide, $0).seen }
            if visible.isEmpty { Text("You’ve seen every brand on this list.").font(.wwSubheadline) }
            ForEach(guide.events) { event in
                let brands = visible.filter { $0.eventIDs.contains(event.id) }
                if !brands.isEmpty {
                    Text(event.name).font(.wwHeadline).foregroundStyle(WatchWeeksStyle.secondary)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(brands) { brand in BrandRow(guide: guide, brand: brand, event: event) }
                }
            }
            let eventIDs = Set(guide.events.map(\.id))
            ForEach(visible.filter { eventIDs.isDisjoint(with: $0.eventIDs) }) { brand in
                BrandRow(guide: guide, brand: brand)
            }
        }
    }
}

struct ReleasesView: View {
    let guide: Guide
    var eventID: String?
    var body: some View {
        ScrollView {
            ReleaseDirectory(guide: guide, eventID: eventID).padding(16)
        }.watchPage()
    }
}

private struct ReleaseDirectory: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    @State private var query = ""
    @State private var eventID: String?
    @State private var byInterest = false

    init(guide: Guide, eventID: String? = nil) {
        self.guide = guide
        _eventID = State(initialValue: eventID)
    }

    private func priority(_ release: Release) -> Int {
        guard let brand = guide.brands.first(where: { $0.id == release.brandID }) else { return 0 }
        return model.selection(guide, brand).interest.priority
    }

    var body: some View {
        let releases = guide.releases.filter {
            (eventID == nil || $0.eventID == eventID)
                && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
                    || ($0.brandName?.localizedCaseInsensitiveContains(query) ?? false))
        }.sorted { left, right in
            if byInterest, priority(left) != priority(right) { return priority(left) > priority(right) }
            let leftName = left.brandName ?? left.title
            let rightName = right.brandName ?? right.title
            if leftName != rightName { return leftName.localizedStandardCompare(rightName) == .orderedAscending }
            return left.title.localizedStandardCompare(right.title) == .orderedAscending
        }
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("New releases").font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
            Text("\(guide.city) · \(releases.count) new releases")
                .font(.wwHeadline).foregroundStyle(WatchWeeksStyle.release)
            Text("Recent and upcoming watches from exhibitors. Check with the brand for show availability.")
                .font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
            HStack {
                TextField("Search releases", text: $query)
                Picker("Event", selection: $eventID) {
                    Text("All events").tag(nil as String?)
                    ForEach(guide.events) { event in Text(event.name).tag(Optional(event.id)) }
                }.pickerStyle(.menu)
            }.padding(.horizontal, 12).frame(minHeight: 44).watchCard()
            WatchSegments(selection: $byInterest, choices: [false, true]) { $0 ? "Interest" : "A–Z" }
            ForEach(releases) { release in
                NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                    ReleaseCard(release: release, guide: guide)
                }.buttonStyle(.plain)
            }
            if releases.isEmpty { ContentUnavailableView("No matching releases", systemImage: "sparkles") }
        }
    }
}

private struct ReleaseBadges: View {
    let release: Release
    var body: some View {
        ForEach(release.displayBadges, id: \.self) { badge in
            Text(badge).font(.wwCaption.weight(.semibold))
                .foregroundStyle(badge == "Sold out" ? WatchWeeksStyle.secondary : WatchWeeksStyle.link)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(WatchWeeksStyle.control, in: Capsule())
        }
    }
}

struct ReleaseCard: View {
    let release: Release
    let guide: Guide
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if release.imageURL != nil {
                Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay { ReleaseImage(url: release.imageURL) }
                    .clipped()
            }
            if let brand = release.brandName {
                Text(brand).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
            }
            ReleaseBadges(release: release)
            Text(release.title).font(.wwTitle3)
            if let price = release.displayedPrice { Text(price).font(.wwSubheadline.weight(.semibold)) }
            if !compact, let event = guide.events.first(where: { $0.id == release.eventID }) {
                Text(event.name).font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
            }
            if let credit = release.images.first?.credit, release.imageURL != nil {
                Text("Photo: \(credit)").font(.wwCaption2).foregroundStyle(WatchWeeksStyle.secondary)
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).watchCard()
    }
}

struct ReleaseImage: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: PublicLinks.safeExternal(url)) { phase in
            if let image = phase.image { image.resizable().scaledToFit() }
            else { Color.secondary.opacity(0.08) }
        }.accessibilityHidden(true)
    }
}
struct ReleaseDetail: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let release: Release
    @State private var tracked = false
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            if release.imageURL != nil {
                Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay { ReleaseImage(url: release.imageURL) }.clipped()
            }
            ReleaseBadges(release: release)
            Text(release.title).font(.wwLargeTitle)
            if let brand = release.brandName { Text(brand).font(.wwTitle2) }
            if let price = release.displayedPrice { Text(price).font(.wwHeadline) }
            if let kind = release.kind { Text(kind.capitalized).font(.wwCaption) }
            if let event = guide.events.first(where: { $0.id == release.eventID }) {
                NavigationLink("See at \(event.name)") { EventInfo(guide: guide, event: event) }
            }
            if let brand = guide.brands.first(where: { $0.id == release.brandID }) {
                let mustSee = model.selection(guide, brand).interest == .mustSee
                Button(mustSee ? "Clear Must-see" : "Mark as Must-see") {
                    var selection = model.selection(guide, brand)
                    selection.interest = mustSee ? .none : .mustSee
                    model.set(selection, guide: guide, brand: brand)
                }.buttonStyle(.bordered).frame(minHeight: 44)
            }
            if let details = release.details { Text(details).textSelection(.enabled) }
            ForEach(Array(release.images.enumerated()), id: \.offset) { index, image in
                if index > 0 { ReleaseImage(url:image.resolvedURL).frame(height:240) }
                if let credit = image.credit {
                    if let url = PublicLinks.safeExternal(image.link.flatMap(URL.init(string:))) {
                        Link("Photo: \(credit)", destination: url).font(.wwCaption)
                    } else {
                        Text("Photo: \(credit)").font(.wwCaption).foregroundStyle(.secondary)
                    }
                }
            }
            if let url = PublicLinks.safeExternal(release.webURL) { Link("Full details", destination: url); ShareLink(item: url) }
        }.padding() }.watchPage().navigationTitle("New release").navigationBarTitleDisplayMode(.inline).accountAccess()
            .task {
                model.activeGuideID = guide.id
                if !tracked { tracked = true; NativeAnalytics.shared.track(.releaseViewed, guide: guide, eventID: release.eventID, brandID: release.brandID, releaseID: release.id) }
            }
    }
}
struct AboutView: View {
    var body: some View {
        List {
            Section("WatchWeeks") { Text("WatchWeeks is an independent guide to watch fairs and events. It is not affiliated with or endorsed by the listed event organizers or brands.") }
            AnalyticsSettings()
            Section("Your visit, your device") { Text("No account is required. Interest ratings and seen selections are saved on this device and do not synchronize with the website. Removing the app removes its local data."); Text("Previously loaded guides work offline. Images and content you have not loaded may require a connection.") }
            Section("Explore more") { WebsiteLink(title:"Full WatchWeeks website",url:PublicLinks.home); Text("Use the website for accounts, synchronization and advanced planning.").font(.wwFootnote); Link("Privacy policy", destination: PublicLinks.privacy) }
            Section { Text("Version 1.0.0 (1)").foregroundStyle(.secondary) }
        }.scrollContentBackground(.hidden).watchPage().navigationTitle("About")
    }
}

struct BrandInfo: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let brand: Brand
    @State private var tracked = false
    var body: some View {
        ScrollView { BrandRow(guide:guide,brand:brand,showDetails:false).padding(16) }.watchPage()
            .navigationTitle(brand.name).accountAccess()
            .task {
                model.activeGuideID = guide.id
                if !tracked { tracked = true; NativeAnalytics.shared.track(.brandViewed, guide: guide, brandID: brand.id) }
            }
    }
}

struct CatalogView: View {
    @EnvironmentObject var model: AppModel
    let releases: Bool
    @State private var guideID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WatchHeader()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !model.guides.isEmpty { CityPicker(guides: model.guides, choice: $guideID) }
                        if let guide = model.guides.first(where: { $0.id == guideID }) {
                            if releases {
                                ReleaseDirectory(guide: guide).id(guide.id)
                            } else {
                                BrandDirectory(guide: guide).id(guide.id)
                            }
                        } else if model.guides.isEmpty {
                            ContentUnavailableView("No guides loaded", systemImage: "globe",
                                                   description: Text("Open Events to load the guides."))
                        } else {
                            Text(releases ? "Choose a guide to explore new releases." : "Choose a guide to browse brands.")
                                .foregroundStyle(WatchWeeksStyle.secondary)
                        }
                    }.padding(16)
                }
            }.watchPage().toolbar(.hidden, for: .navigationBar)
                .onAppear { selectGuide() }
                .onChange(of: model.guides.map(\.id)) { _, _ in selectGuide() }
                .onChange(of: model.activeGuideID) { _, _ in selectGuide() }
                .onChange(of: guideID) { _, value in
                    if let value { model.activeGuideID = value }
                }
        }
    }

    private func selectGuide() {
        guideID = model.guides.contains(where: { $0.id == model.activeGuideID }) ? model.activeGuideID : nil
    }
}
