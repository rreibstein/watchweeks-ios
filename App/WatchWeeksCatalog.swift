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
        let filtered = Browsing.brands(brands, query: query, filter: filter) { model.selectionForSorting(guide, $0) }.filter {
            (!shortlistOnly || model.selection(guide, $0).isShortlisted)
                && (!releasesOnly || releases.contains($0.id))
                && (!stockOnly || SingaporeStock.brandIDs.contains($0.id))
        }
        let ordered = filtered.enumerated().sorted {
            let left = model.selectionForSorting(guide, $0.element)
            let right = model.selectionForSorting(guide, $1.element)
            if left.isShortlisted != right.isShortlisted { return left.isShortlisted }
            if byInterest, left.seen != right.seen { return !left.seen }
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
                    WatchDropdown(choices: BrandFilter.allCases, selection: filter,
                                  title: { $0.rawValue }, select: { filter = $0 }) {
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
        }.onChange(of: byInterest) { _, _ in model.resort() }
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
    @State private var expanded = false
    let guide: Guide
    let brand: Brand
    var collapsesWhenSeen = true
    var event: Event? = nil
    var selection: Selection { model.selection(guide, brand) }

    var body: some View {
        Group {
            if selection.isShortlisted && selection.seen && collapsesWhenSeen && !expanded {
                Button { expanded = true } label: {
                    HStack(spacing: 8) {
                        mustBadge
                        Text(brand.displayName).font(.wwHeadline).foregroundStyle(displayInk)
                        Spacer(minLength: 0)
                        Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .watchCard(accent: ratingStripe, stripeWidth: 8, fill: cardFill)
                }.buttonStyle(.plain).accessibilityLabel(brand.displayName)
                    .accessibilityValue("Seen").accessibilityHint("Expand the brand")
            } else {
                expandedCard
            }
        }.onChange(of: selection.seen) { _, seen in if seen { expanded = false } }
    }

    private var ratingStripe: Color? {
        selection.interest == .none ? nil : WatchWeeksStyle.rating(selection.interest)
    }

    private var cardFill: Color {
        selection.seen ? WatchWeeksStyle.seenCard : WatchWeeksStyle.card
    }

    private var displayInk: Color {
        selection.seen ? WatchWeeksStyle.ink.opacity(0.70) : WatchWeeksStyle.ink
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
                if selection.isShortlisted && selection.seen && collapsesWhenSeen {
                    Button { expanded = false } label: {
                        HStack(spacing: 8) {
                            mustBadge
                            Label(brand.displayName, systemImage: "chevron.up").font(.wwTitle3).foregroundStyle(displayInk)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain).accessibilityLabel(brand.displayName)
                        .accessibilityHint("Collapse the seen brand")
                } else {
                    HStack(spacing: 8) {
                        mustBadge
                        Text(brand.displayName).font(.wwTitle3).foregroundStyle(displayInk).accessibilityAddTraits(.isHeader)
                    }
                }
                if let summary = brand.summary { Text(summary).font(.wwSubheadline).foregroundStyle(displayInk) }
                if event == nil {
                    ForEach(guide.publicEvents.filter { brand.eventIDs.contains($0.id) }) { appearance in
                        NavigationLink { EventInfo(guide: guide, event: appearance) } label: {
                            Label(appearance.name, systemImage: "calendar").font(.wwFootnote)
                        }
                    }
                }
                if SingaporeStock.applies(to: guide, event: event), SingaporeStock.brandIDs.contains(brand.id) {
                    Label("On-site stock available", systemImage: "bag").font(.wwCaption).foregroundStyle(displayInk)
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
                    Spacer(minLength: 0)
                    Button {
                        var updated = selection
                        updated.seen.toggle()
                        model.set(updated, guide: guide, brand: brand, feedbackOnSeen: true)
                    } label: {
                        Image(systemName: selection.seen ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 30)).frame(minWidth: 48, minHeight: 48)
                    }.buttonStyle(.plain).accessibilityLabel("Seen \(brand.displayName)")
                        .accessibilityValue(selection.seen ? "Seen" : "Not seen")
                        .accessibilityAddTraits(selection.seen ? .isSelected : [])
                }
                if selection.seen || selection.reaction != nil || selection.buyingIntent != nil {
                    feedbackPicker("Reaction", selection: feedback(\.reaction), values: VisitReaction.allCases)
                    feedbackPicker("Buying intent", selection: feedback(\.buyingIntent), values: BuyingIntent.allCases)
                }
                if let url = PublicLinks.safeExternal(brand.webURL) {
                    Link("Brand website", destination: url).font(.wwFootnote)
                }
            }.padding(16)
            BrandRatingBar(guide: guide, brand: brand)
        }.watchCard(accent: ratingStripe, stripeWidth: 8, fill: cardFill)
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

    private func feedbackPicker<Value: RawRepresentable & Hashable>(_ title: String, selection: Binding<Value?>,
                                                                  values: [Value]) -> some View where Value.RawValue == String {
        let value = selection.wrappedValue
        return HStack {
            Text(title).font(.wwSubheadline)
            Spacer()
            WatchDropdown(choices: [nil] + values.map(Optional.some), selection: .some(value),
                          title: { $0?.rawValue ?? "None" }, select: { selection.wrappedValue = $0 }) {
                WatchDropdownLabel(title: value?.rawValue ?? "None")
                    .foregroundStyle(WatchWeeksStyle.link)
            }.accessibilityLabel("\(title), \(value?.rawValue ?? "None")")
        }
    }
}

private struct BrandRatingBar: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    let guide: Guide
    let brand: Brand
    private let interests: [Interest] = [.mustSee, .interested, .little, .unfamiliar, .skip]

    var body: some View {
        let selection = model.selection(guide, brand)
        VStack(spacing: 0) {
            Divider()
            if typeSize.isAccessibilitySize {
                ForEach(interests, id: \.self) { interest in
                    if interest != interests.first { Divider() }
                    rating(interest, selection: selection)
                }
            } else {
                HStack(spacing: 0) {
                    ForEach(interests, id: \.self) { interest in
                        if interest != interests.first { Divider() }
                        rating(interest, selection: selection)
                    }
                }.fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(.plain)
        .disabled(model.persistenceError != nil)
    }

    private func rating(_ interest: Interest, selection: Selection) -> some View {
        let selected = selection.interest == interest
        return Button {
            var updated = selection
            updated.interest = selected ? .none : interest
            model.set(updated, guide: guide, brand: brand)
        } label: {
            Text(interest.label)
                .font(typeSize.isAccessibilitySize ? .wwBody.weight(.semibold) : .wwCaption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 3)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, minHeight: 44, maxHeight: .infinity)
                .foregroundStyle(selected ? .white : WatchWeeksStyle.ink)
                .background {
                    if selected { Rectangle().fill(WatchWeeksStyle.rating(interest)) }
                }
                .contentShape(Rectangle())
        }
        .accessibilityLabel("\(interest.label), \(brand.displayName)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(selected ? "Clears this rating" : "Rates this brand")
    }
}

private struct CityPicker: View {
    let guides: [Guide]
    @Binding var choice: String?
    var showAll = false

    var body: some View {
        let options = (showAll ? [nil as String?] : []) + guides.map { Optional($0.id) }
        WatchDropdown(choices: options, selection: .some(choice), title: name, select: { choice = $0 }) {
            WatchDropdownLabel(title: name(choice)).foregroundStyle(WatchWeeksStyle.link)
        }.accessibilityLabel("Guide, \(name(choice))")
            .padding(.horizontal, 12).watchCard(radius: 12)
    }

    private func name(_ id: String?) -> String {
        guides.first { $0.id == id }?.city ?? (showAll ? "All guides" : "Choose a guide")
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
            ScrollView {
                WatchHeader()
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
            }.watchPage().toolbar(.hidden, for: .navigationBar)
                .onAppear {
                    guideID = model.visitGuides.contains(where: { $0.id == model.activeGuideID }) ? model.activeGuideID : nil
                }
        }.onChange(of: byInterest) { _, _ in model.resort() }
    }

    private func saved(in guide: Guide) -> [Brand] {
        guide.brands.filter { brand in
            let selection = model.selectionForSorting(guide, brand)
            if shortlistedOnly { return selection.isShortlisted }
            return selection.isShortlisted || selection.interest != .none || selection.seen || selection.reaction != nil || selection.buyingIntent != nil
        }.sorted { left, right in
            let first = model.selectionForSorting(guide, left), second = model.selectionForSorting(guide, right)
            if first.isShortlisted != second.isShortlisted { return first.isShortlisted }
            if byInterest, first.seen != second.seen { return !first.seen }
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
            let visible = all.filter { !remaining || !model.selectionForSorting(guide, $0).seen }
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
        }.watchPage().navigationBarTitleDisplayMode(.inline).watchFindToolbar()
    }
}

private struct ReleaseDirectory: View {
    let guide: Guide
    let proxy: ScrollViewProxy
    @State private var query = ""
    @State private var eventID: String?

    init(guide: Guide, eventID: String? = nil, proxy: ScrollViewProxy) {
        self.guide = guide
        self.proxy = proxy
        _eventID = State(initialValue: eventID)
    }

    var body: some View {
        let releases = guide.releaseCatalog(eventID: eventID).filter {
            query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
                || ($0.displayBrandName?.localizedCaseInsensitiveContains(query) ?? false)
        }.sorted { left, right in
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
                WatchDropdown(choices: [nil] + guide.publicEvents.map { Optional($0.id) },
                              selection: .some(eventID), title: eventName, select: { eventID = $0 }) {
                    WatchDropdownLabel(title: eventName(eventID)).foregroundStyle(WatchWeeksStyle.link)
                }.accessibilityLabel("Event, \(eventName(eventID))")
            }.padding(.horizontal, 12).frame(minHeight: 44).watchCard()
            if !releases.isEmpty {
                let titles = Dictionary(uniqueKeysWithValues: releases.map {
                    ($0.id, "\($0.displayBrandName ?? "Watch") — \($0.title)")
                })
                WatchDropdown(choices: releases.map(\.id), title: { titles[$0] ?? "" }, select: { id in
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                }) {
                    Label("Jump to brand or model", systemImage: "arrow.down.to.line").frame(minHeight: 44)
                }
            }
            ForEach(releases) { release in
                VStack(spacing: 0) {
                    NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                        ReleaseCard(release: release, guide: guide, standalone: false)
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("release-\(release.id)")
                    if let brand = guide.brands.first(where: { $0.id == release.brandID }) {
                        BrandRatingBar(guide: guide, brand: brand)
                    }
                }.watchCard().clipShape(RoundedRectangle(cornerRadius: 16))
                    .id(release.id)
            }
            if releases.isEmpty { ContentUnavailableView("No matching releases", systemImage: "sparkles") }
        }
    }

    private func eventName(_ id: String?) -> String {
        guide.publicEvents.first { $0.id == id }?.name ?? "All events"
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
        ForEach(Array(images.dropFirst(skipFirst ? 1 : 0).enumerated()), id: \.offset) { _, image in
            ReleasePhoto(image: image, height: 200)
        }
    }
}

struct ReleaseCard: View {
    let release: Release
    let guide: Guide
    var compact = false
    var standalone = true
    var showsEvent = false
    @State private var photoNearViewport = false

    var body: some View {
        if standalone { content.watchCard() }
        else { content }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let url = release.displayImages.first?.resolvedURL {
                if compact {
                    photo(url, load: photoNearViewport)
                        .onGeometryChange(for: Bool.self) { proxy in
                            guard let bounds = proxy.bounds(of: .scrollView(axis: .horizontal)) else { return false }
                            let frame = proxy.frame(in: .scrollView(axis: .horizontal))
                            return frame.maxX > -160 && frame.minX < bounds.width + 160
                        } action: { photoNearViewport = $0 }
                } else {
                    photo(url, load: true)
                }
            }
            if let brand = release.displayBrandName {
                Text(brand).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
            }
            ReleaseBadges(release: release)
            Text(release.title).font(.wwTitle3)
            if let price = release.displayedPrice { Text(price).font(.wwSubheadline.weight(.semibold)) }
            if !compact || showsEvent, let event = guide.events.first(where: { $0.id == release.eventID }) {
                Text(event.name).font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
            }
            if let credit = release.displayImages.first?.credit {
                Text("Photo: \(credit)").font(.wwCaption2).foregroundStyle(WatchWeeksStyle.secondary)
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }

    private func photo(_ url: URL, load: Bool) -> some View {
        WatchWeeksStyle.control.aspectRatio(4.0 / 3.0, contentMode: .fit)
            .overlay { if load { ReleaseImage(url: url) } }
            .clipShape(RoundedRectangle(cornerRadius: 8))
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

private struct ReleasePhoto: View {
    let image: ReleaseImageData
    var height: CGFloat? = nil
    @State private var showing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { showing = true } label: {
                Group {
                    if let height { Color.clear.frame(height: height) }
                    else { Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit) }
                }
                .overlay { ReleaseImage(url: image.resolvedURL) }
                .clipped()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View photo")
            if let credit = image.credit {
                Text("Photo: \(credit)").font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
            }
        }
        .fullScreenCover(isPresented: $showing) {
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button { showing = false } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }.buttonStyle(.plain).accessibilityLabel("Close photo")
                }
                ReleaseImage(url: image.resolvedURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let credit = image.credit {
                    Text("Photo: \(credit)").font(.wwFootnote)
                }
            }
            .padding()
            .foregroundStyle(.white)
            .background { Color.black.ignoresSafeArea() }
        }
    }
}

struct ReleaseDetail: View {
    @State private var recordedView = false
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let release: Release
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = release.displayImages.first { ReleasePhoto(image: image) }
                ReleaseBadges(release: release)
                Text(release.title).font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
                if let brand = release.displayBrandName { Text(brand).font(.wwTitle2) }
                if let price = release.displayedPrice { Text(price).font(.wwHeadline) }
                VStack(alignment: .leading, spacing: 8) {
                    if let brand = guide.brands.first(where: { $0.id == release.brandID }) {
                        Text("Rate \(brand.displayName)").font(.wwHeadline)
                        BrandRatingBar(guide: guide, brand: brand)
                            .watchCard().clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    if !release.isNotExhibited && !release.isTeaser { releaseActions }
                }
                if let details = release.details { Text(details).textSelection(.enabled) }
                ReleaseGallery(images: release.displayImages, skipFirst: !release.displayImages.isEmpty)
            }.padding()
        }.watchPage().navigationBarTitleDisplayMode(.inline).watchFindToolbar()
            .task {
                model.activeGuideID = guide.id
                if !recordedView { recordedView=true; UsageAnalytics.shared.record(.release, guideID: guide.id, releaseID: release.id) }
            }
    }

    private var releaseActions: some View {
        let eventIDs = Set(guide.newReleases(for: release.brandID).filter {
            $0.title.caseInsensitiveCompare(release.title) == .orderedSame && !$0.isNotExhibited
        }.compactMap(\.eventID))
        return VStack(spacing: 8) {
            ForEach(guide.publicEvents.filter { eventIDs.contains($0.id) }) { event in
                NavigationLink { EventInfo(guide: guide, event: event) } label: {
                    Label("Explore at \(event.name)", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered).tint(WatchWeeksStyle.release)
            }
        }.font(.wwSubheadline.weight(.semibold))
    }
}
struct AboutView: View {
    @ObservedObject private var analytics = UsageAnalytics.shared
    @State private var explainAnalytics = false
    @State private var chooseAnalytics = false

    var body: some View {
        List {
            Section("WatchWeeks") {
                Text("WatchWeeks is an independent guide to watch fairs and events. It is not affiliated with or endorsed by the listed event organizers or brands.")
                WebsiteLink(title: "Privacy policy", url: PublicLinks.privacy)
                if let email = URL(string: "mailto:reed.reibstein@gmail.com") {
                    Link("Email support", destination: email)
                    if let correction = URL(string: "mailto:reed.reibstein@gmail.com?subject=WatchWeeks%20correction") {
                        Link("Report a correction", destination: correction)
                    }
                }
            }
            Section("Your visit, your device") {
                Text("Your shortlist, ratings and seen selections are saved on this device. They do not automatically synchronize with website accounts.")
                Text("Previously loaded guides work offline. Links and content you have not loaded may require a connection.")
            }
            #if DEBUG && targetEnvironment(simulator)
            if let recorder=analytics.qaRecorder { AnalyticsQADiagnostics(recorder:recorder) }
            #endif
            if analytics.isAvailable {
                Section("Usage analytics") {
                    LabeledContent("Sharing", value: analytics.enabled ? "On" : "Off")
                    if analytics.enabled {
                        Button("Turn off usage analytics") { analytics.setEnabled(false) }
                            .frame(minHeight: 44)
                    } else {
                        Button("Learn about usage analytics") { explainAnalytics = true }
                            .frame(minHeight: 44)
                    }
                    Text("Optional. Your choice does not affect any WatchWeeks features.")
                        .font(.wwFootnote).foregroundStyle(.secondary)
                }
            }
            Section("Guide notifications") {
                Text("Notification permission and usage analytics are separate choices. Push alerts are not enabled in this build while the delivery service is being prepared. No push token is registered or sent.")
            }
            Section("Explore more") {
                WebsiteLink(title: "WatchWeeks website", url: PublicLinks.home)
            }
            Section {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))").foregroundStyle(.secondary)
                }
            }
        }.scrollContentBackground(.hidden).watchPage().navigationTitle("About")
            .sheet(isPresented: $explainAnalytics) {
                NavigationStack {
                    List {
                        Section {
                            Text("Sharing usage helps us see which guides and features are useful and what to improve.")
                            Text("PostHog receives a random app identifier, app version/build, public guide/event/release IDs and actions such as viewing a guide, changing a rating, using My list or sharing. We do not send your selected rating, Seen value, notes, email, search queries or purchase prices. We do not join native and website identities or use this for ads or session replay.")
                            Text("Consented events may be stored on this device and retried when connectivity returns. Turning sharing off clears pending analytics and cancels delivery; requests already in flight cannot be recalled. Previously delivered data may remain under the privacy policy.")
                            Text("Sharing is off unless you turn it on. You can change your choice here at any time.")
                        }
                        Button("Choose a preference") { chooseAnalytics = true }
                            .frame(minHeight: 44)
                    }
                    .navigationTitle("Optional usage analytics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { explainAnalytics = false }
                        }
                    }
                    .alert("Share usage analytics?", isPresented: $chooseAnalytics) {
                        Button("Keep off", role: .cancel) { explainAnalytics = false }
                        Button("Share usage") {
                            analytics.setEnabled(true)
                            explainAnalytics = false
                        }
                    } message: {
                        Text("You can turn sharing off anytime in About & privacy.")
                    }
                }
            }
    }
}

struct BrandInfo: View {
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let brand: Brand
    var body: some View {
        ScrollView {
            BrandRow(guide: guide, brand: brand, collapsesWhenSeen: false).padding(16)
        }.watchPage().navigationBarTitleDisplayMode(.inline).watchFindToolbar()
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
            ScrollViewReader { proxy in
                ScrollView {
                    WatchHeader()
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
