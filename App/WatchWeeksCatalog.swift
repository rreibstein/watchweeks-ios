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
        Set(guide.newReleases.filter { event == nil || $0.eventID == event?.id }.compactMap(\.brandID))
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
                        filterChip("On-site stock available", icon: "bag", selected: $stockOnly)
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
                    HStack(spacing: 8) {
                        mustBadge
                        Text(brand.displayName).font(.wwHeadline)
                    }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 16)
                        .watchCard(accent: ratingStripe, stripeWidth: 8)
                }.buttonStyle(.plain).accessibilityLabel(brand.displayName)
                    .accessibilityHint("Expand the seen brand")
            } else {
                expandedCard
            }
        }.onChange(of: selection.seen) { _, seen in if seen { expanded = false } }
    }

    private var ratingStripe: Color? {
        selection.interest == .none ? nil : WatchWeeksStyle.rating(selection.interest)
    }

    @ViewBuilder private var mustBadge: some View {
        if selection.interest == .mustSee {
            Text("MUST").font(.wwCaption2.bold()).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(WatchWeeksStyle.rating(.mustSee), in: Capsule())
                .accessibilityLabel("Must see")
        }
    }

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if selection.isShortlisted && selection.seen && showDetails {
                    Button { expanded = false } label: {
                        HStack(spacing: 8) {
                            mustBadge
                            Label(brand.displayName, systemImage: "chevron.up").font(.wwTitle3)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain).accessibilityLabel(brand.displayName)
                        .accessibilityHint("Collapse the seen brand")
                } else {
                    HStack(spacing: 8) {
                        mustBadge
                        Text(brand.displayName).font(.wwTitle3).accessibilityAddTraits(.isHeader)
                    }
                }
                if let summary = brand.summary { Text(summary).font(.wwSubheadline) }
                if event == nil {
                    ForEach(guide.publicEvents.filter { brand.eventIDs.contains($0.id) }) { appearance in
                        NavigationLink { EventInfo(guide: guide, event: appearance) } label: {
                            Label(appearance.name, systemImage: "calendar").font(.wwFootnote)
                        }
                    }
                }
                if SingaporeStock.applies(to: guide, event: event), SingaporeStock.brandIDs.contains(brand.id) {
                    Label("On-site stock available", systemImage: "bag").font(.wwCaption)
                }
                let releases = guide.releaseCatalog(brandID: brand.id, eventID: event?.id)
                if !releases.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(releases) { release in
                                NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                                    ReleaseCard(release: release, guide: guide)
                                }.buttonStyle(.plain)
                                ReleaseGallery(images: release.displayImages, skipFirst: !release.displayImages.isEmpty)
                                if !release.displaySharedImages.isEmpty {
                                    Text("Other photos from this release group").font(.wwCaption)
                                    ReleaseGallery(images: release.displaySharedImages)
                                }
                            }
                        }
                    } label: {
                        Label("\(releases.count) new \(releases.count == 1 ? "release" : "releases")", systemImage: "sparkles")
                            .font(.wwFootnote).padding(8).watchCard(radius: 16)
                    }
                    let badges = Array(Set(releases.flatMap(\.displayBadges))).sorted()
                    ForEach(badges, id: \.self) { ReleaseBadge(label: $0) }
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
                        }.buttonStyle(.plain).accessibilityLabel("Details for \(brand.displayName)")
                    }
                    Spacer(minLength: 0)
                    Button {
                        var updated = selection
                        updated.seen.toggle()
                        model.set(updated, guide: guide, brand: brand)
                    } label: {
                        Image(systemName: selection.seen ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 30)).frame(minWidth: 48, minHeight: 48)
                    }.buttonStyle(.plain).accessibilityLabel("Seen \(brand.displayName)")
                        .accessibilityValue(selection.seen ? "Seen" : "Not seen")
                        .accessibilityAddTraits(selection.seen ? .isSelected : [])
                }
                if selection.seen || selection.reaction != nil || selection.buyingIntent != nil {
                    Picker("Reaction", selection: feedback(\.reaction)) {
                        Text("None").tag(nil as VisitReaction?)
                        ForEach(VisitReaction.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                    }
                    Picker("Buying intent", selection: feedback(\.buyingIntent)) {
                        Text("None").tag(nil as BuyingIntent?)
                        ForEach(BuyingIntent.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                    }
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
        }.watchCard(accent: ratingStripe, stripeWidth: 8)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(model.persistenceError != nil)
    }

    private func feedback<Value>(_ field: WritableKeyPath<Selection, Value>) -> Binding<Value> {
        Binding(get: { selection[keyPath: field] }, set: { value in
            var updated = selection
            updated[keyPath: field] = value
            model.set(updated, guide: guide, brand: brand)
        })
    }

    private func rating(_ interest: Interest) -> some View {
        let selected = selection.interest == interest
        return Button {
            var updated = selection
            updated.interest = selected ? .none : interest
            model.set(updated, guide: guide, brand: brand)
        } label: {
            Text(interest.label)
                .font(typeSize.isAccessibilitySize ? .wwBody.weight(.semibold) : .wwCaption2.weight(.semibold))
                .multilineTextAlignment(.center).padding(.horizontal, 2).padding(.vertical, 4)
                .frame(maxWidth: .infinity, minHeight: 44, maxHeight: .infinity)
                .background(selected ? WatchWeeksStyle.rating(interest) : Color.clear)
                .foregroundStyle(selected ? .white : WatchWeeksStyle.ink)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel("\(interest.label), \(brand.displayName)")
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
                        if let draft = picks(in: guides) {
                            ShareLink(item: draft) { Label("Share My Picks", systemImage: "square.and.arrow.up") }
                        }
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
            return selection.isShortlisted || selection.interest != .none || selection.seen || selection.reaction != nil || selection.buyingIntent != nil
        }.sorted { left, right in
            let first = model.selection(guide, left), second = model.selection(guide, right)
            if first.isShortlisted != second.isShortlisted { return first.isShortlisted }
            if byInterest, first.interest.priority != second.interest.priority { return first.interest.priority > second.interest.priority }
            return left.displayName.localizedStandardCompare(right.displayName) == .orderedAscending
        }
    }

    private func picks(in guides: [Guide]) -> String? {
        let sections = guides.compactMap { guide -> String? in
            let lines = guide.brands.compactMap { brand -> String? in
                let selection = model.selection(guide, brand)
                var labels: [String] = []
                if selection.interest == .mustSee { labels.append(Interest.mustSee.label) }
                if selection.isShortlisted { labels.append("Shortlist") }
                if selection.reaction == .loved { labels.append("Loved") }
                guard !labels.isEmpty else { return nil }
                return "• \(brand.displayName) — \(labels.joined(separator: ", "))"
            }.sorted()
            return lines.isEmpty ? nil : ([guide.city] + lines).joined(separator: "\n")
        }
        return sections.isEmpty ? nil : (["My WatchWeeks picks"] + sections).joined(separator: "\n\n")
    }

    @ViewBuilder private func citySection(_ guide: Guide) -> some View {
        let all = saved(in: guide)
        if !all.isEmpty {
            Text(guide.city).font(.wwTitle2).accessibilityAddTraits(.isHeader)
            let total = guide.brands.count
            let seen = guide.brands.count { model.selection(guide, $0).seen }
            ProgressView("\(seen) of \(total) seen", value: Double(seen), total: Double(total))
                .padding(12).watchCard()
            let visible = all.filter { !remaining || !model.selection(guide, $0).seen }
            if visible.isEmpty { Text("You’ve seen every brand on this list.").font(.wwSubheadline) }
            let pinned = visible.filter { model.selection(guide, $0).isShortlisted }
            if !pinned.isEmpty {
                Text("Shortlist").font(.wwHeadline)
                ForEach(pinned) { brand in BrandRow(guide: guide, brand: brand) }
            }
            let unpinned = visible.filter { !model.selection(guide, $0).isShortlisted }
            ForEach(guide.events) { event in
                let brands = unpinned.filter { $0.eventIDs.contains(event.id) }
                if !brands.isEmpty {
                    Text(event.name).font(.wwHeadline).foregroundStyle(WatchWeeksStyle.secondary)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(brands) { brand in BrandRow(guide: guide, brand: brand, event: event) }
                }
            }
            let eventIDs = Set(guide.events.map(\.id))
            ForEach(unpinned.filter { eventIDs.isDisjoint(with: $0.eventIDs) }) { brand in
                BrandRow(guide: guide, brand: brand)
            }
        }
    }
}

struct ReleasesView: View {
    let guide: Guide
    var eventID: String?
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ReleaseDirectory(guide: guide, eventID: eventID, proxy: proxy).padding(16)
            }
        }.watchPage()
    }
}

private struct ReleaseDirectory: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let proxy: ScrollViewProxy
    @State private var query = ""
    @State private var eventID: String?
    @State private var byInterest = false

    init(guide: Guide, eventID: String? = nil, proxy: ScrollViewProxy) {
        self.guide = guide
        self.proxy = proxy
        _eventID = State(initialValue: eventID)
    }

    private func priority(_ release: Release) -> Int {
        guard let brand = guide.brands.first(where: { $0.id == release.brandID }) else { return 0 }
        return model.selection(guide, brand).interest.priority
    }

    var body: some View {
        let releases = guide.releaseCatalog(eventID: eventID).filter {
            query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
                || ($0.displayBrandName?.localizedCaseInsensitiveContains(query) ?? false)
        }.sorted { left, right in
            if byInterest, priority(left) != priority(right) { return priority(left) > priority(right) }
            let leftName = left.displayBrandName ?? left.title
            let rightName = right.displayBrandName ?? right.title
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
                    ForEach(guide.publicEvents) { event in Text(event.name).tag(Optional(event.id)) }
                }.pickerStyle(.menu)
            }.padding(.horizontal, 12).frame(minHeight: 44).watchCard()
            WatchSegments(selection: $byInterest, choices: [false, true]) { $0 ? "Interest" : "A–Z" }
            if !releases.isEmpty {
                Menu {
                    ForEach(releases) { release in
                        Button("\(release.displayBrandName ?? "Watch") — \(release.title)") {
                            withAnimation { proxy.scrollTo(release.id, anchor: .top) }
                        }
                    }
                } label: {
                    Label("Jump to brand or model", systemImage: "arrow.down.to.line").frame(minHeight: 44)
                }
            }
            ForEach(releases) { release in
                NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                    ReleaseCard(release: release, guide: guide)
                }.buttonStyle(.plain).id(release.id)
            }
            if releases.isEmpty { ContentUnavailableView("No matching releases", systemImage: "sparkles") }
        }
    }
}

private struct ReleaseBadge: View {
    let label: String
    var body: some View {
        let award = label.localizedCaseInsensitiveContains("GPHG")
        Text(label).font(.wwCaption.weight(.semibold))
            .foregroundStyle(award ? Color.black : (label == "Sold out" ? WatchWeeksStyle.secondary : WatchWeeksStyle.link))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(award ? Color(red: 1, green: 0.83, blue: 0.53) : WatchWeeksStyle.control, in: Capsule())
    }
}

private struct ReleaseBadges: View {
    let release: Release
    var body: some View {
        ForEach(release.displayBadges, id: \.self) { ReleaseBadge(label: $0) }
    }
}

private struct ReleaseGallery: View {
    let images: [ReleaseImageData]
    var skipFirst = false

    var body: some View {
        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
            if index > 0 || !skipFirst { ReleaseImage(url: image.resolvedURL).frame(height: 200) }
            if let credit = image.credit {
                if let url = PublicLinks.safeExternal(image.link.flatMap(URL.init(string:))) {
                    Link("Photo: \(credit)", destination: url).font(.wwCaption)
                } else {
                    Text("Photo: \(credit)").font(.wwCaption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ReleaseCard: View {
    let release: Release
    let guide: Guide
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let url = release.displayImages.first?.resolvedURL {
                Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay { ReleaseImage(url: url) }
                    .clipped()
            }
            if let brand = release.displayBrandName {
                Text(brand).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
            }
            ReleaseBadges(release: release)
            Text(release.title).font(.wwTitle3)
            if let price = release.displayedPrice { Text(price).font(.wwSubheadline.weight(.semibold)) }
            if !compact, let event = guide.events.first(where: { $0.id == release.eventID }) {
                Text(event.name).font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
            }
            if let credit = release.displayImages.first?.credit {
                Text("Photo: \(credit)").font(.wwCaption2).foregroundStyle(WatchWeeksStyle.secondary)
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).watchCard()
    }
}

struct ReleaseImage: View {
    let url: URL?
    var contentMode: ContentMode = .fit
    var body: some View {
        AsyncImage(url: PublicLinks.safeExternal(url)) { phase in
            if let image = phase.image { image.resizable().aspectRatio(contentMode: contentMode) }
            else { Color.secondary.opacity(0.08) }
        }.accessibilityHidden(true)
    }
}
struct ReleaseDetail: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let release: Release
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            if let url = release.displayImages.first?.resolvedURL {
                Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay { ReleaseImage(url: url) }.clipped()
            }
            ReleaseBadges(release: release)
            Text(release.title).font(.wwLargeTitle)
            if let brand = release.displayBrandName { Text(brand).font(.wwTitle2) }
            if let price = release.displayedPrice { Text(price).font(.wwHeadline) }
            if !release.isNotExhibited && !release.isTeaser {
                if let brand = guide.brands.first(where: { $0.id == release.brandID }) {
                    let mustSee = model.selection(guide, brand).interest == .mustSee
                    Button {
                        var selection = model.selection(guide, brand)
                        selection.interest = mustSee ? .none : .mustSee
                        model.set(selection, guide: guide, brand: brand)
                    } label: {
                        if mustSee { Label("Must see", systemImage: "checkmark").frame(minHeight: 32) }
                        else { Text("Mark as Must-see").frame(minHeight: 32) }
                    }.buttonStyle(.borderedProminent)
                        .tint(mustSee ? WatchWeeksStyle.live : WatchWeeksStyle.rating(.mustSee))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(mustSee ? .isSelected : [])
                }
                let eventIDs = Set(guide.newReleases(for: release.brandID).filter {
                    $0.title.caseInsensitiveCompare(release.title) == .orderedSame && !$0.isNotExhibited
                }.compactMap(\.eventID))
                ForEach(guide.publicEvents.filter { eventIDs.contains($0.id) }) { event in
                    let others = guide.brands.count { $0.id != release.brandID && $0.eventIDs.contains(event.id) }
                    let context = release.displayBrandName.map { " (\($0) + \(others) other brands)" } ?? ""
                    NavigationLink("Explore \(event.name)\(context)") { EventInfo(guide: guide, event: event) }
                }
            }
            if let details = release.details { Text(details).textSelection(.enabled) }
            ReleaseGallery(images: release.displayImages, skipFirst: !release.displayImages.isEmpty)
            if !release.displaySharedImages.isEmpty {
                Text("Other photos from this release group").font(.wwHeadline)
                ReleaseGallery(images: release.displaySharedImages)
            }
            if let url = PublicLinks.safeExternal(release.webURL) { Link("Full details", destination: url); ShareLink(item: url) }
        }.padding() }.watchPage().navigationTitle("New release").navigationBarTitleDisplayMode(.inline).accountAccess()
            .task {
                model.activeGuideID = guide.id
            }
    }
}
struct AboutView: View {
    var body: some View {
        List {
            Section("WatchWeeks") {
                Text("WatchWeeks is an independent guide to watch fairs and events. It is not affiliated with or endorsed by the listed event organizers or brands.")
                WebsiteLink(title: "Privacy policy", url: PublicLinks.privacy)
            }
            Section("Your visit, your device") {
                Text("Your shortlist, ratings and seen selections are saved on this device. The iPhone app sends no product analytics.")
                Text("Previously loaded guides work offline. Links and content you have not loaded may require a connection.")
            }
            Section("Explore more") {
                WebsiteLink(title: "Full WatchWeeks website", url: PublicLinks.home)
                Text("Use the website for accounts, synchronization and advanced planning.").font(.wwFootnote)
            }
            Section {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))").foregroundStyle(.secondary)
                }
            }
        }.scrollContentBackground(.hidden).watchPage().navigationTitle("About")
    }
}

struct BrandInfo: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let brand: Brand
    var body: some View {
        ScrollView { BrandRow(guide:guide,brand:brand,showDetails:false).padding(16) }.watchPage()
            .navigationTitle(brand.displayName).accountAccess()
            .task {
                model.activeGuideID = guide.id
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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !model.guides.isEmpty { CityPicker(guides: model.guides, choice: $guideID) }
                            if let guide = model.guides.first(where: { $0.id == guideID }) {
                                if releases {
                                    ReleaseDirectory(guide: guide, proxy: proxy).id(guide.id)
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
