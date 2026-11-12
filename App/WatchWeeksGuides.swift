import SwiftUI
import UIKit
import EventKitUI
import WatchWeeksCore

struct DiscoveryView: View {
    @EnvironmentObject var model: AppModel
    @State private var pushDestinationID: String?

    var ordered: [Guide] {
        // The home page highlights these guides editorially. Newly published guides
        // retain feed order within their active or past group.
        let featured = ["singapore-2026", "hong-kong-2026", "miami-2026", "nyww-2026", "austin-2026"]
        let known = featured.compactMap { id in model.guides.first { $0.id == id } }
        let others = model.guides.filter { !featured.contains($0.id) }
        let all = known + others
        return all.filter { EventDates.status($0) != .past } + all.filter { EventDates.status($0) == .past }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                    WatchHeader()
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Text("Make the most of every watch fair.")
                            .font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
                        Text("The independent guide to watch events around the world. Discover the brands exhibiting, explore the new releases, and plan your must-sees.")
                            .foregroundStyle(WatchWeeksStyle.secondary)
                        LiveStatusPanel(guides: model.guides)
                        Text("Guides").font(.wwTitle).accessibilityAddTraits(.isHeader)
                        if model.loading && model.guides.isEmpty { ProgressView("Loading guides…") }
                        if let message = model.message {
                            Text(message).font(.wwCallout)
                            Button("Try again") { Task { await model.refresh() } }
                        }
                        if model.stale && !model.loading, let date = model.savedAt {
                            Label("Offline copy · updated \(date.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock.arrow.circlepath").font(.wwCaption)
                        }
                        ForEach(ordered.filter { EventDates.status($0) != .past }) {
                            GuidePreview(guide: $0, past: false).id($0.id)
                        }
                        if ordered.isEmpty && !model.loading {
                            ContentUnavailableView("No guides loaded", systemImage: "globe", description: Text("Pull to refresh. Previously loaded guides are available offline."))
                        }
                    }.padding(16)
                    // Keep the alert controls mounted and ahead of past editions.
                    ForthcomingGuidesPromo(guides:model.guides)
                        .padding(.horizontal,16).padding(.bottom,16)
                    let past = ordered.filter { EventDates.status($0) == .past }
                    if !past.isEmpty {
                        Text("Past guides").font(.wwTitle).accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("past-guides-heading")
                            .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,16)
                        LazyVStack(alignment:.leading,spacing:16) {
                            ForEach(past) { GuidePreview(guide:$0,past:true).id($0.id) }
                        }.padding(16)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink { AboutView() } label: {
                            Label("About & privacy", systemImage: "info.circle")
                                .font(.wwFootnote).frame(maxWidth:.infinity,minHeight:44)
                        }.accessibilityIdentifier("home-about-privacy")
                    }.padding(.horizontal,16).padding(.bottom,16)
                }
                .refreshable { await model.refresh() }
            .watchPage().toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item:$pushDestinationID) { id in
                    if let guide=model.guides.first(where:{ $0.id == id }) { CityView(guide:guide) }
                    else { ContentUnavailableView("Guide unavailable",systemImage:"globe") }
                }
                .task(id:model.pendingPushGuideID) {
                    guard model.pendingPushGuideID != nil else { return }
                    pushDestinationID=nil
                    if !openPendingGuide() {
                        while model.loading {
                            do { try await Task.sleep(for:.milliseconds(100)) } catch { return }
                        }
                        if !openPendingGuide() { await model.refresh() }
                        if !openPendingGuide() { model.pendingPushGuideID=nil }
                    }
                }
                .onChange(of:model.guides) { _, _ in _ = openPendingGuide() }
                .onAppear { model.activeGuideID = nil }
        }
    }
    @discardableResult private func openPendingGuide() -> Bool {
        guard let pending=model.pendingPushGuideID,
              let id=GuidePublicationRouting.destination(guideID:pending,canonicalIDs:model.publishedGuideIDs,loadedIDs:Set(model.guides.map(\.id))) else { return false }
        pushDestinationID=id;model.pendingPushGuideID=nil;return true
    }
}

private struct LiveStatusPanel: View {
    let guides: [Guide]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let highlights = LiveEvent.highlights(in: guides, now: context.date)
            if !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Around the fairs").font(.wwHeadline).accessibilityAddTraits(.isHeader)
                    ForEach(highlights, id: \.guide.id) { item in
                        if let hours = LocalSchedule.hours(item.day) {
                            NavigationLink { EventInfo(guide: item.guide, event: item.event) } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ActivityPill(title: item.status.rawValue, color: item.status.color)
                                    Text(item.event.name).font(.wwTitle3)
                                    Text(item.status == .now
                                         ? "Closes at \(LocalSchedule.timeLabel(hours.upperBound)) · \(item.guide.city) time"
                                         : "Opens at \(LocalSchedule.timeLabel(hours.lowerBound)) · \(item.guide.city) time")
                                        .font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                                }.padding(14).frame(maxWidth: .infinity, alignment: .leading).watchCard()
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private extension LiveEvent.Status {
    var color: Color {
        switch self {
        case .now: WatchWeeksStyle.live
        case .today: WatchWeeksStyle.today
        case .finished, .tomorrow: WatchWeeksStyle.quiet
        }
    }
}

private struct ActivityPill: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title).font(.wwCaption2.bold()).foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color, in: Capsule())
    }
}

private struct GuidePreview: View {
    let guide: Guide
    let past: Bool
    private var homeDates: String {
        if guide.id == "miami-2026", let event = guide.publicEvents.first(where: guide.isDealerShow) {
            return dateRange(event.startsAt, event.endsAt, zone: guide.timeZone)
        }
        return guideDateRange(guide)
    }
    var body: some View {
        let releases = guide.releaseCatalog()
        VStack(alignment: .leading, spacing: 12) {
            if past {
                guideLink
            } else {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let activity = LiveEvent.citySchedule(in: guide, now: context.date)
                    VStack(alignment: .leading, spacing: 8) {
                        if let status = LiveEvent.homeStatus(in: guide, now: context.date) {
                            ActivityPill(title: status.title, color: status.isLive ? WatchWeeksStyle.live : WatchWeeksStyle.today)
                                .accessibilityIdentifier("home-guide-status-\(guide.id)")
                            if let eventName = status.eventName, status.daysUntil != 0 {
                                Text("Next public event: \(eventName)").font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
                            }
                        }
                        guideLink
                        if let activity, !activity.today.isEmpty {
                            todaySchedule(activity.today, now: context.date)
                        }
                    }
                }
            }
            Text("\(guide.brands.count) brands · \(guide.publicEvents.count) events · \(releases.count) new releases")
                .font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                .accessibilityIdentifier("home-guide-summary-\(guide.id)")
            if past {
                Text(guide.summary ?? "A recap of \(guide.city)’s watch events, exhibitors and new releases.")
                    .font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
            }
            if !releases.isEmpty {
                CityReleases(guide: guide, releases: releases, past: past)
            }
            if !past {
                ForEach(guide.publicEvents.sorted { brandCount(guide, $0) > brandCount(guide, $1) }.prefix(3)) { event in
                    if guide.isDealerShow(event) {
                        Text("\(event.name) · \(guide.dealers(at: event).count) dealers").font(.wwFootnote)
                        DealerList(dealers:Array(guide.dealers(at:event).prefix(4)),searchable:false)
                        NavigationLink { EventInfo(guide:guide,event:event) } label: {
                            Text("See all \(guide.dealers(at:event).count) dealers · A–Z").font(.wwFootnote).frame(minHeight:44)
                        }.buttonStyle(.plain).foregroundStyle(WatchWeeksStyle.link)
                    } else if brandCount(guide, event) > 0 {
                        Text("\(event.name) · \(brandCount(guide, event)) brands").font(.wwFootnote)
                    }
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background {
                NavigationLink { CityView(guide: guide) } label: {
                    Color.clear
                        .watchCard(accent: WatchWeeksStyle.city(guide), stripeWidth: 6)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
    }

    private var guideLink: some View {
        NavigationLink { CityView(guide: guide) } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(guide.city).font(.wwTitle)
                    Text(homeDates).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.wwHeadline)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityIdentifier("home-guide-\(guide.id)")
    }

    private func todaySchedule(_ slots: [LiveEvent.Slot], now: Date) -> some View {
        let zone = TimeZone(identifier: guide.timeZone)
        let abbreviation: String? = switch guide.timeZone {
        case "Asia/Singapore": "SGT"
        case "Asia/Hong_Kong": "HKT"
        default: zone?.abbreviation(for: now)
        }
        return VStack(alignment: .leading, spacing: 0) {
            Text(abbreviation.map { "Today · \($0)" } ?? "Today · local time")
                .font(.wwCaption.bold()).foregroundStyle(WatchWeeksStyle.secondary)
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                if let hours = LocalSchedule.hours(slot.day) {
                    NavigationLink { EventInfo(guide: guide, event: slot.event) } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.event.name).font(.wwFootnote.weight(.semibold))
                                Text(LocalSchedule.hoursLabel(hours, compact: true)).font(.wwCaption)
                                    .foregroundStyle(WatchWeeksStyle.secondary)
                            }
                            Spacer(minLength: 0)
                            if slot.interval.contains(now) {
                                ActivityPill(title: "Now", color: WatchWeeksStyle.live)
                            }
                        }.frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }.padding(10).background(WatchWeeksStyle.control, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct CityReleases: View {
    let guide: Guide
    let releases: [Release]
    let past: Bool

    private var highlights: [Release] {
        // Match the web home page's featured brands when their photos pass the
        // provenance filter, then fill any open slots from the city's catalog.
        let featured: [String]
        switch guide.id {
        case "singapore-2026": featured = ["renaudtixier", "czapek", "dennison"]
        case "hong-kong-2026": featured = ["earthencompany", "straum", "gronefeld"]
        case "miami-2026": featured = ["arminstrom", "arnoldson", "beauregard"]
        case "austin-2026": featured = ["circula", "elliotbrown", "formex"]
        case "nyww-2026": featured = ["bremont", "brewwatchco", "bulova"]
        default: featured = []
        }
        let preferred = featured.compactMap { brandID in
            releases.first { $0.brandID == brandID && !$0.displayImages.isEmpty }
        }
        var photos: Set<URL> = []
        var result: [Release] = []
        for release in preferred + releases {
            guard let url = release.displayImages.first?.resolvedURL, photos.insert(url).inserted else { continue }
            result.append(release)
            if result.count == 3 { break }
        }
        return result
    }

    var body: some View {
        let items = highlights
        Divider()
        Text(past ? "New release highlights" : "\(releases.count) new releases")
            .font(.wwCaption.weight(.semibold)).foregroundStyle(WatchWeeksStyle.secondary)
        if !items.isEmpty {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 8), count: 3), alignment: .leading) {
                ForEach(items) { release in
                    NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            WatchWeeksStyle.control.aspectRatio(6.0 / 5.0, contentMode: .fit)
                                .overlay {
                                    ReleaseImage(url: release.displayImages.first?.resolvedURL, contentMode: .fill)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(release.displayBrandName ?? "Watch").font(.wwCaption.bold()).lineLimit(1)
                            Text(release.title).font(.wwCaption2).lineLimit(1)
                                .foregroundStyle(WatchWeeksStyle.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(release.displayBrandName ?? "Watch"), \(release.title)")
                }
            }
        }
        NavigationLink { ReleasesView(guide: guide) } label: {
            HStack(spacing: 6) {
                Text("See all new releases")
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }.font(.wwSubheadline.weight(.semibold))
                .foregroundStyle(WatchWeeksStyle.release).frame(minHeight: 44)
        }
    }
}

private func brandCount(_ guide: Guide, _ event: Event) -> Int {
    guide.brands.count { $0.eventIDs.contains(event.id) }
}

private func guideDateRange(_ guide: Guide) -> String {
    dateRange(guide.startDate, guide.endDate, zone: guide.timeZone)
}

private func dateRange(_ start: String?, _ end: String?, zone: String) -> String {
    guard let start, let first = EventDates.parse(start, zone: zone),
          let timeZone = TimeZone(identifier: zone) else { return "Dates to be confirmed" }
    let style = Date.IntervalFormatStyle(date: .abbreviated, time: .omitted, timeZone: timeZone)
    guard let end, let last = EventDates.parse(end, zone: zone), last >= first else {
        return EventDates.label(start, zone: zone)
    }
    return (first..<last).formatted(style)
}

struct CityView: View {
    @State private var recordedView = false
    @EnvironmentObject var model: AppModel
    let guide: Guide
    @State private var day: String?
    @State private var sortByDay = false

    private var dates: [String] { Array(Set(guide.events.flatMap { $0.days.map(\.date) })).sorted() }
    private var events: [Event] {
        guide.publicEvents.filter { event in day == nil || event.days.contains { $0.date == day && (sortByDay || !$0.isRestrictedAccess) } }.sorted { first, second in
            if sortByDay, first.startsAt != second.startsAt { return (first.startsAt ?? "") < (second.startsAt ?? "") }
            if sortByDay, let day,
               let firstTime = first.days.first(where: { $0.date == day })?.open,
               let secondTime = second.days.first(where: { $0.date == day })?.open,
               firstTime != secondTime { return firstTime < secondTime }
            return brandCount(guide, first) > brandCount(guide, second)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("\(guide.city) Guide").font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
                Text(guideDateRange(guide)).font(.wwHeadline).foregroundStyle(WatchWeeksStyle.secondary)
                Text("All hours are local to \(guide.city).").font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
                dayNavigation
                if !dates.isEmpty {
                    WatchSegments(selection: $day, choices: [nil] + dates.map(Optional.some), label: shortDay)
                }
                WatchSegments(selection: $sortByDay, choices: [false, true]) { $0 ? "By day" : "By # of brands" }
                if sortByDay {
                    daySchedule
                } else if guide.id == "hong-kong-2026", day == nil {
                    let past = events.filter { guide.eventStatus($0) == .past }
                    let remaining = events.filter { guide.eventStatus($0) != .past }
                    if !remaining.isEmpty {
                        Text("Current and upcoming events").font(.wwHeadline)
                        eventCards(remaining)
                    }
                    if !past.isEmpty {
                        Text("Past events").font(.wwHeadline)
                        eventCards(past)
                    }
                } else {
                    eventCards(events)
                    if events.isEmpty { Text("No public events on this day.").foregroundStyle(WatchWeeksStyle.secondary) }
                }
                let releases = guide.releaseCatalog()
                if !releases.isEmpty { GuideReleaseCarousel(guide: guide, releases: releases) }
                if let url = PublicLinks.safeExternal(guide.webURL) {
                    TrackedGuideShare(guide:guide,url:url)
                }
            }.padding(16)
        }
        .watchPage().navigationBarTitleDisplayMode(.inline).watchFindToolbar()
        .task {
            model.activeGuideID = guide.id
            if !recordedView { recordedView=true; UsageAnalytics.shared.record(.guide, guideID: guide.id) }
        }
    }

    private func eventCards(_ items: [Event]) -> some View {
        ForEach(items) { event in
            NavigationLink { EventInfo(guide: guide, event: event) } label: {
                EventPreview(guide: guide, event: event, day: day)
            }.buttonStyle(.plain).accessibilityIdentifier("event-\(event.id)")
        }
    }

    private var daySchedule: some View {
        ForEach(day.map { [$0] } ?? dates, id: \.self) { date in
            let slots = guide.events.flatMap { event in
                LocalSchedule.days(for: event, guideID: guide.id)
                    .filter { $0.date == date }.map { (event, $0) }
            }.sorted { (LocalSchedule.minute($0.1.open) ?? 1440) < (LocalSchedule.minute($1.1.open) ?? 1440) }
            if !slots.isEmpty {
                Text(LocalSchedule.dateLabel(date, zone: guide.timeZone) ?? date).font(.wwHeadline)
                ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                    let (event, hours) = slot
                    let parent = guide.parentEventID(for: event).flatMap { id in guide.events.first { $0.id == id } } ?? event
                    NavigationLink { EventInfo(guide: guide, event: parent) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(hours.session ?? event.name).font(.wwHeadline)
                            Text(LocalSchedule.label(hours, zone: guide.timeZone)).font(.wwFootnote)
                            if parent.id != event.id { Text("Access session · \(parent.name)").font(.wwCaption) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).watchCard()
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var dayNavigation: some View {
        let allDays = [nil] + dates.map(Optional.some)
        let index = allDays.firstIndex(of: day) ?? 0
        return HStack {
            dayArrow("Previous day", icon: "chevron.left", target: index - 1, days: allDays)
            VStack(spacing: 4) {
                Text(day.map { EventDates.label($0, zone: guide.timeZone) } ?? "All events").font(.wwTitle)
                Text(sortByDay ? "Schedule" : "\(events.count) \(events.count == 1 ? "event" : "events")").foregroundStyle(WatchWeeksStyle.secondary)
            }.frame(maxWidth: .infinity).multilineTextAlignment(.center)
            dayArrow("Next day", icon: "chevron.right", target: index + 1, days: allDays)
        }
    }

    private func dayArrow(_ title: String, icon: String, target: Int, days: [String?]) -> some View {
        Button { if days.indices.contains(target) { day = days[target] } } label: {
            Image(systemName: icon).font(.wwHeadline).frame(width: 48, height: 48).watchCard()
        }.buttonStyle(.plain).accessibilityLabel(title).disabled(!days.indices.contains(target))
            .opacity(days.indices.contains(target) ? 1 : 0.35)
    }

    private func shortDay(_ value: String?) -> String {
        if let value, dates.count > 7 { return LocalSchedule.dateLabel(value, zone: guide.timeZone) ?? value }
        guard let value, let date = EventDates.parse(value, zone: guide.timeZone),
              let zone = TimeZone(identifier: guide.timeZone) else { return "All" }
        var format = Date.FormatStyle().weekday(.abbreviated)
        format.timeZone = zone
        return date.formatted(format)
    }
}

private struct EventPreview: View {
    let guide: Guide
    let event: Event
    let day: String?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(event.name).font(.wwTitle3).foregroundStyle(WatchWeeksStyle.ink)
                Text(dateRange(event.startsAt, event.endsAt, zone: guide.timeZone)).font(.wwSubheadline)
                if guide.eventStatus(event) == .past { Text("Closed · retrospective").font(.wwCaption) }
                if guide.isDealerShow(event) { Text("\(guide.dealers(at: event).count) dealers · Vintage and pre-owned").font(.wwFootnote) }
                let days = LocalSchedule.days(for: event, guideID: guide.id).filter { !$0.isRestrictedAccess && (day == nil || $0.date == day) }
                let hours = days.compactMap(LocalSchedule.hours)
                if let first = hours.first, hours.count == days.count, hours.allSatisfy({ $0 == first }) {
                    Text(LocalSchedule.hoursLabel(first)).font(.wwSubheadline)
                    if let access = LocalSchedule.accessLabel(days.first?.access),
                       days.allSatisfy({ LocalSchedule.accessLabel($0.access) == access }) {
                        Text(access).font(.wwFootnote)
                    }
                } else {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        let label = LocalSchedule.label(day, zone: guide.timeZone)
                        if !label.isEmpty { Text(label).font(.wwFootnote) }
                    }
                }
            }
            .foregroundStyle(WatchWeeksStyle.secondary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").padding(.top, 3)
        }
        .padding(16).watchCard()
        .accessibilityElement(children: .combine)
    }
}

private struct DealerList: View {
    let dealers: [Dealer]
    var searchable=true
    @State private var query=""
    var body: some View {
        let visible=dealers.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        VStack(alignment:.leading,spacing:0) {
            if searchable {
                TextField("Search dealers",text:$query)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding(12).watchCard(radius:12).padding(.bottom,8)
            }
            ForEach(visible) { dealer in
                VStack(alignment:.leading,spacing:0) {
                    Text(dealer.name).font(.wwBody)
                        .frame(maxWidth:.infinity,minHeight:48,alignment:.leading)
                        .accessibilityIdentifier("dealer-\(dealer.id)")
                    Divider()
                }
            }
            if visible.isEmpty { Text("No matching dealers.").font(.wwFootnote).padding(.vertical,12) }
        }
    }
}

enum SingaporeStock {
    static let names = ["Alto", "Anoma", "Atelier Wen", "Baltic", "Dennison", "Earthen", "Formex",
                        "Holthinrichs", "Kuoe", "Nivada Grenchen", "Ophion", "Wren"]
    static let brandIDs: Set<String> = ["alto", "anoma", "atelierwen", "baltic", "dennison", "earthencompany",
                                         "formex", "holthinrichs", "kuoekyoto", "nivadagrenchen", "ophion", "wrenwatches"]
    static func applies(to guide: Guide, event: Event?) -> Bool {
        guide.id == "singapore-2026" && event?.id == "golden-hour"
    }
}

struct EventInfo: View {
    @State private var recordedView = false
    @EnvironmentObject var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var choosingMaps = false
    @State private var calendarSelection: EventCalendarSelection?
    @State private var eventTab=IAMWATCHSection.schedule
    let guide: Guide
    let event: Event

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("\(guide.city.uppercased()) GUIDE").font(.wwCaption).tracking(1)
                    .foregroundStyle(WatchWeeksStyle.link)
                Text(event.name).font(.wwTitle).accessibilityAddTraits(.isHeader)
                Text(dateRange(event.startsAt, event.endsAt, zone: guide.timeZone)).font(.wwHeadline)
                if EventProgram.source(guideID:guide.id,eventID:event.id) != nil {
                    DisclosureGroup("Location, hours & entry info") { metadata }
                        .font(.wwSubheadline)
                    WatchSegments(selection:$eventTab,choices:IAMWATCHSection.allCases) { $0.rawValue }
                    if eventTab == .schedule { NativeEventProgram(guide:guide,event:event) }
                    else { exhibitorContent }
                } else {
                    metadata
                    exhibitorContent
                }
            }.padding(16)
        }
        .watchPage().navigationBarTitleDisplayMode(.inline).watchFindToolbar()
        .sheet(item: $calendarSelection) { selection in
            EventCalendarEditor(event: event, address: address, timeZone: guide.timeZone, selection: selection) {
                calendarSelection = nil
            }
        }
        .task {
            model.activeGuideID = guide.id
            if !recordedView { recordedView=true; UsageAnalytics.shared.record(.event, guideID: guide.id, eventID: event.id) }
        }
    }

    @ViewBuilder private var exhibitorContent: some View {
        if SingaporeStock.applies(to: guide, event: event) { stock }
        let releases=guide.releaseCatalog(eventID:event.id)
        if !releases.isEmpty { GuideReleaseCarousel(guide:guide,event:event,releases:releases) }
        let dealers=guide.dealers(at:event)
        if guide.isDealerShow(event) {
            Text("\(dealers.count) dealers · A–Z").font(.wwHeadline)
            DealerList(dealers:dealers)
        } else if brandCount(guide,event) > 0 { BrandDirectory(guide:guide,event:event) }
    }

    private var calendarSlots: [EventCalendarSlot] {
        LocalSchedule.days(for: event, guideID: guide.id).compactMap { day in
            guard !day.isRestrictedAccess, let interval = LocalSchedule.interval(day, zone: guide.timeZone) else { return nil }
            return EventCalendarSlot(day: day, interval: interval)
        }
    }

    private var address: String? {
        if let address = event.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
            return address
        }
        guard guide.id == "singapore-2026" else { return nil }
        switch event.id {
        case "golden-hour": return "1 Beach Road, Singapore 189673"
        case "iamwatch": return "38 Cuscaden Road, Singapore 249731"
        case "spring-sprang-sprung": return "28 China Street, Singapore 049570"
        default: return nil
        }
    }

    private func openDirections(_ base: String, items: [URLQueryItem]) {
        var components = URLComponents(string: base)
        components?.queryItems = items
        if let url = components?.url { openURL(url) }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let venue = event.venue { Label(venue, systemImage: "mappin.and.ellipse").font(.wwHeadline) }
            if let address {
                Text(address).font(.wwSubheadline).textSelection(.enabled)
                let destination = address.localizedCaseInsensitiveContains(guide.city) ? address : "\(address), \(guide.city)"
                Button {
                    choosingMaps = true
                } label: {
                    Label("Directions", systemImage: "arrow.turn.up.right").frame(minHeight: 44)
                }
                .confirmationDialog("Open directions", isPresented: $choosingMaps, titleVisibility: .visible) {
                    Button("Apple Maps") {
                        openDirections("https://maps.apple.com/", items: [URLQueryItem(name: "daddr", value: destination)])
                    }
                    Button("Google Maps") {
                        openDirections("https://www.google.com/maps/dir/", items: [
                            URLQueryItem(name: "api", value: "1"), URLQueryItem(name: "destination", value: destination)
                        ])
                    }
                }
            }
            ForEach(Array(LocalSchedule.days(for: event, guideID: guide.id).filter { !$0.isRestrictedAccess }.enumerated()), id: \.offset) { _, day in
                let label = LocalSchedule.label(day, zone: guide.timeZone)
                if !label.isEmpty { Text(label).font(.wwSubheadline) }
            }
            if !event.days.isEmpty {
                Text("All hours are local to \(guide.city).").font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
            }
            if let url = PublicLinks.safeExternal(event.webURL) {
                Link(destination: url) {
                    Label("Official event information", systemImage: "arrow.up.right.square").frame(minHeight: 44)
                }
            }
            let slots = calendarSlots
            if !slots.isEmpty {
                Button {
                    calendarSelection = EventCalendarSelection(slots: slots)
                } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus").frame(minHeight: 44)
                }
                .accessibilityHint(slots.count > 1 ? "Adds all public days for this event" : "Adds the public session")

            }
            let sessions = guide.accessSessions(for: event)
            let specialHours = LocalSchedule.days(for: event, guideID: guide.id).filter(\.isRestrictedAccess)
            if event.note != nil || !sessions.isEmpty || !specialHours.isEmpty {
                DisclosureGroup("Good to know") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let note = event.note { Text(note) }
                        ForEach(Array(specialHours.enumerated()), id: \.offset) { _, day in
                            Text(LocalSchedule.label(day, zone: guide.timeZone))
                        }
                        ForEach(sessions) { session in
                            if !specialHours.contains(where: { $0.session == session.name }) {
                                Text(session.name).font(.wwHeadline)
                            }
                            ForEach(Array(session.days.enumerated()), id: \.offset) { _, day in
                                Text(LocalSchedule.label(day, zone: guide.timeZone))
                            }
                            if let venue = session.venue, venue != event.venue { Text(venue) }
                            if let note = session.note { Text(note) }
                        }
                    }.font(.wwFootnote).padding(.top, 4)
                }.font(.wwSubheadline)
            }
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading).watchCard()
    }

    private var stock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Watches you can buy and take home on the day", systemImage: "bag")
                .font(.wwHeadline)
            Text("At most watch fairs you can only look and talk. Golden Hour brands bring actual stock with them.")
                .font(.wwSubheadline)
            Text(SingaporeStock.names.joined(separator: ", ")).font(.wwFootnote)
                .foregroundStyle(WatchWeeksStyle.secondary)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(WatchWeeksStyle.control, in: RoundedRectangle(cornerRadius: 16))
    }
}

private enum IAMWATCHSection: String,CaseIterable { case schedule="Schedule",brands="Brands & attendance" }

private struct NativeEventProgram: View {
    let guide:Guide
    let event:Event
    @State private var program:EventProgram?
    @State private var day:String?
    @State private var query=""
    @State private var loading=false
    @State private var stale=false
    @State private var error:String?
    private var store:LocalStore {
        LocalStore(directory:FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
            .appendingPathComponent("WatchWeeks",isDirectory:true))
    }
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("IAMWATCH program").font(.wwTitle2).accessibilityAddTraits(.isHeader)
            Text("All times are local to \(guide.city).").font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
            if let program {
                WatchSegments(selection:$day,choices:[nil]+program.dates.map(Optional.some)) { value in
                    value.flatMap { LocalSchedule.dateLabel($0,zone:program.timeZone) } ?? "All days"
                }
                TextField("Search sessions, speakers or rooms",text:$query)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding(12).watchCard(radius:12)
                let filtered=program.matching(day:day,query:query)
                ForEach(day.map{[$0]} ?? program.dates,id:\.self) { date in
                    let sessions=filtered.filter{$0.date == date}
                    if !sessions.isEmpty {
                        Text(LocalSchedule.dateLabel(date,zone:program.timeZone) ?? date).font(.wwHeadline)
                        ForEach(sessions) { session in
                            VStack(alignment:.leading,spacing:8) {
                                Text(LocalSchedule.hours(session.day).map{LocalSchedule.hoursLabel($0,compact:true)} ?? "Time unconfirmed")
                                    .font(.wwSubheadline.weight(.semibold)).foregroundStyle(WatchWeeksStyle.link)
                                Text(session.title).font(.wwHeadline)
                                if session.invitationOnly { Text("Invitation only").font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary) }
                                if let category=session.category { Text(category).font(.wwCaption) }
                                if let room=session.room { Label(room,systemImage:"mappin.and.ellipse").font(.wwFootnote) }
                                if session.description != nil || !session.participants.isEmpty {
                                    DisclosureGroup("Session details") {
                                        VStack(alignment:.leading,spacing:8) {
                                            if let text=session.description { Text(text) }
                                            ForEach(session.participants,id:\.self) { Text($0) }
                                        }.font(.wwFootnote).padding(.top,6)
                                    }.font(.wwFootnote)
                                }
                            }.padding(14).frame(maxWidth:.infinity,alignment:.leading).watchCard()
                                .accessibilityIdentifier("program-\(session.id)")
                        }
                    }
                }
                if filtered.isEmpty { Text("No matching sessions.").foregroundStyle(WatchWeeksStyle.secondary) }
                Text("\(stale ? "Saved program" : "Updated") · \(EventDates.label(ISO8601DateFormatter().string(from:program.fetchedAt),zone:program.timeZone)). Check the organizer for changes.")
                    .font(.wwCaption).foregroundStyle(WatchWeeksStyle.secondary)
                WebsiteLink(title:"Program on WatchWeeks",url:program.sourceURL)
            } else if loading { ProgressView("Loading program…") }
            if let error { Text(error).font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary) }
            Button(loading ? "Refreshing…" : "Refresh program") { Task { await refresh() } }.disabled(loading)
        }.accessibilityElement(children:.contain)
            .task { await refresh() }
    }
    private func refresh() async {
        guard !loading else { return };loading=true;defer{loading=false}
        if program == nil { program=try? await store.program(guideID:guide.id,eventID:event.id);stale=program != nil }
        do {
            #if DEBUG && targetEnvironment(simulator)
            if let html=ProcessInfo.processInfo.environment["WW_SCHEDULE_QA_HTML"] {
                program=try PublishedProgramParser.parse(html,guideID:guide.id,eventID:event.id,timeZone:guide.timeZone)
                stale=false;error=nil;return
            }
            #endif
            let result=try await EventProgramRepository(store:store).load(guide:guide,event:event)
            program=result.program;stale=result.stale;error=result.warning
        } catch {
            if GuideRefreshFailure.isCancellation(error) { return }
            self.error=program == nil ? "The program is unavailable right now. Please retry when connected." : "Couldn’t refresh. Your saved program remains available."
            stale=program != nil
        }
    }
}

private struct EventCalendarSlot: Identifiable {
    let day: EventDay
    let interval: Range<Date>
    var id: String { "\(day.date)|\(day.open ?? "")|\(day.close ?? "")|\(day.session ?? "")" }
}

private struct EventCalendarSelection: Identifiable {
    let slots: [EventCalendarSlot]
    var id: String { slots.map(\.id).joined(separator: ";") }
}

private struct EventCalendarEditor: UIViewControllerRepresentable {
    let event: Event
    let address: String?
    let timeZone: String
    let selection: EventCalendarSelection
    let onDismiss: @MainActor () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = context.coordinator.store
        let draft = EKEvent(eventStore: store)
        draft.title = event.name
        let slots = selection.slots.sorted { $0.interval.lowerBound < $1.interval.lowerBound }
        if let first = slots.first {
            let zone = TimeZone(identifier: timeZone) ?? .gmt
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            draft.startDate = first.interval.lowerBound
            draft.endDate = first.interval.upperBound
            draft.timeZone = zone
            if slots.count == 1 {
                draft.notes = LocalSchedule.accessLabel(first.day.access)
            } else {
                let isDaily = zip(slots, slots.dropFirst()).allSatisfy { previous, next in
                    let previousDay = calendar.startOfDay(for: previous.interval.lowerBound)
                    let nextDay = calendar.startOfDay(for: next.interval.lowerBound)
                    return calendar.date(byAdding: .day, value: 1, to: previousDay) == nextDay
                        && previous.day.open == next.day.open && previous.day.close == next.day.close
                }
                if isDaily {
                    draft.addRecurrenceRule(EKRecurrenceRule(
                        recurrenceWith: .daily, interval: 1,
                        end: EKRecurrenceEnd(occurrenceCount: slots.count)
                    ))
                } else if let last = slots.last {
                    // Preserve varying opening hours in the notes, without reserving
                    // overnight hours as one continuous timed appointment.
                    draft.isAllDay = true
                    draft.startDate = calendar.startOfDay(for: first.interval.lowerBound)
                    let lastDay = calendar.startOfDay(for: last.interval.lowerBound)
                    draft.endDate = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? last.interval.upperBound
                    draft.availability = .free
                }
                draft.notes = (["Public hours (local time):"] + slots.map {
                    LocalSchedule.label($0.day, zone: timeZone)
                }).joined(separator: "\n")
            }
        }
        draft.location = address ?? event.venue
        draft.url = PublicLinks.safeExternal(event.webURL)

        let editor = EKEventEditViewController()
        editor.eventStore = store
        editor.event = draft
        editor.editViewDelegate = context.coordinator
        return editor
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    @MainActor final class Coordinator: NSObject, EKEventEditViewDelegate {
        let store = EKEventStore()
        let onDismiss: @MainActor () -> Void

        init(onDismiss: @escaping @MainActor () -> Void) { self.onDismiss = onDismiss }

        nonisolated func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            Task { @MainActor in self.onDismiss() }
        }
    }
}

private struct GuideReleaseCarousel: View {
    let guide: Guide
    var event: Event? = nil
    let releases: [Release]

    private var scope: String { event == nil ? "city" : "event" }

    var body: some View {
        let pictured = releases.filter { !$0.displayImages.isEmpty }
        let textOnly = releases.filter { $0.displayImages.isEmpty }
        return VStack(alignment: .leading, spacing: 10) {
            Text("New releases").font(.wwTitle2).accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                // Measure the tallest card up front. A lazy horizontal stack
                // can size the scroll view to its first card's shorter height.
                HStack(alignment: .top, spacing: 12) {
                    ForEach(pictured + textOnly) { release in
                        NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                            ReleaseCard(release: release, guide: guide, compact: true, showsEvent: event == nil)
                                .frame(width: 205, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }.buttonStyle(.plain).accessibilityIdentifier("\(scope)-release-card-\(release.id)")
                    }
                }
            }
            NavigationLink {
                ReleasesView(guide: guide, eventID: event?.id)
            } label: {
                let title = "See all \(releases.count) new releases"
                Label(event == nil ? title : "\(title) at this event", systemImage: "arrow.right")
                    .foregroundStyle(WatchWeeksStyle.release).frame(minHeight: 44)
            }.accessibilityIdentifier("\(scope)-releases")
        }
    }
}

private struct TrackedGuideShare: View {
    let guide: Guide
    let url: URL
    @State private var showing = false
    var body: some View {
        Button { showing=true } label: { Label("Share guide",systemImage:"square.and.arrow.up") }
            .sheet(isPresented:$showing) { GuideShareSheet(guideID:guide.id,url:url) }
    }
}
private struct GuideShareSheet: UIViewControllerRepresentable {
    let guideID: String
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller=UIActivityViewController(activityItems:[url],applicationActivities:nil)
        let id=guideID
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed { Task { @MainActor in UsageAnalytics.shared.record(.shared,guideID:id) } }
        }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct ForthcomingGuidesPromo: View {
    let guides: [Guide]
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var alerts = GuidePublicationAlerts.shared
    private var actionDisabled: Bool {
        alerts.isBusy || alerts.hasEnrollment || alerts.isEnabled || alerts.deletionPending
    }
    var body: some View {
        let titles=model.upcomingFeed.map { $0.planned.map(\.title) } ?? ForthcomingGuide.awaitingPublication(in:guides).map(\.title)
        if !titles.isEmpty {
            VStack(alignment:.leading,spacing:16) {
                HStack(spacing:10) {
                    Image(systemName:"bell.badge.fill")
                        .font(.title3).foregroundStyle(WatchWeeksStyle.link)
                        .frame(width:44,height:44)
                        .background(WatchWeeksStyle.link.opacity(0.12),in:Circle())
                        .accessibilityHidden(true)
                    Text("Guides in the works")
                        .font(.wwCaption.weight(.semibold)).tracking(1)
                        .textCase(.uppercase).foregroundStyle(WatchWeeksStyle.link)
                }
                VStack(alignment:.leading,spacing:8) {
                    Text("Don’t miss the next guide.").font(.wwTitle2)
                        .accessibilityAddTraits(.isHeader)
                    Text(titles.joined(separator:", ") + ".")
                        .font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                }
                Button {
                    if alerts.permissionDenied {
                        if let url=URL(string:UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } else { Task { await alerts.requestSubscription() } }
                } label: {
                    HStack(spacing:12) {
                        Text(alerts.homeActionTitle).multilineTextAlignment(.leading)
                        Spacer(minLength:0)
                        Image(systemName:alerts.isEnabled ? "checkmark.circle.fill" : actionDisabled ? "clock" : "arrow.right")
                            .accessibilityHidden(true)
                    }
                    .font(.wwHeadline)
                    .padding(.horizontal,18).padding(.vertical,12)
                    .frame(maxWidth:.infinity,minHeight:52)
                    .foregroundStyle(actionDisabled ? WatchWeeksStyle.ink : WatchWeeksStyle.paper)
                    .background(actionDisabled ? WatchWeeksStyle.control : WatchWeeksStyle.link,
                                in:RoundedRectangle(cornerRadius:12))
                    .contentShape(RoundedRectangle(cornerRadius:12))
                }.accessibilityIdentifier("guide-updates")
                    .buttonStyle(.plain)
                    .accessibilityValue(alerts.isEnabled ? "On" : alerts.hasEnrollment ? "Permission granted, connecting" : alerts.isBusy ? "Requesting permission" : "Off")
                    .disabled(actionDisabled)
            }.padding(20).frame(maxWidth:.infinity,alignment:.leading)
                .watchCard(radius:20,accent:WatchWeeksStyle.link,stripeWidth:4)
                // Avoid a container identifier propagating over the button ID.
                .accessibilityElement(children:.contain)
        }
    }
}
struct GuideUpdatesSheet: View {
    @State private var newsletterURL=PublicLinks.home
    @ObservedObject private var alerts = GuidePublicationAlerts.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("New WatchWeeks guides") {
                    Text("Get an alert when a new independent city or event guide is published.")
                    if alerts.isConfigured || alerts.hasEnrollment || alerts.isEnabled || alerts.deletionPending {
                        if alerts.isVerificationMode {
                            Text("TestFlight delivery check. Guide alerts are not yet active for App Store users.")
                                .font(.wwFootnote)
                        }
                        LabeledContent("Guide alerts",value:alerts.statusLabel)
                        if alerts.hasEnrollment || alerts.isEnabled || alerts.deletionPending || alerts.isBusy {
                            Button(alerts.deletionPending ? "Retry unsubscribe" : (alerts.isEnabled ? "Turn off guide alerts" : "Cancel pending guide alerts")) { Task { await alerts.unsubscribe() } }
                        } else {
                            Text("Notifications are optional. Apple will ask for permission after you choose Enable notifications. Analytics is a separate choice.")
                            Button("Enable notifications") { Task { await alerts.requestSubscription() } }
                                .disabled(alerts.isBusy)
                            if alerts.permissionDenied {
                                Button("Open notification settings") {
                                    if let url=URL(string:UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                                }
                            }
                        }
                        Text("If enabled, your device token, an installation credential, app version and iOS version are used to deliver guide alerts. They are not sent to analytics. Delivery is best effort.")
                            .font(.wwFootnote)
                    } else {
                        Text(alerts.availabilityMessage)
                        if alerts.isChecking { ProgressView("Checking guide alerts…") }
                        Button("Retry notification setup") { Task { _ = await alerts.refreshAvailability() } }
                            .disabled(alerts.isChecking)
                    }
                    WebsiteLink(title:"Guide updates on WatchWeeks",url:newsletterURL)
                    if let message=alerts.message { Text(message).font(.wwFootnote) }
                    if alerts.isVerificationMode, let id=alerts.installationID {
                        Text("Test installation: " + id).font(.wwCaption).textSelection(.enabled)
                        Button("Copy test installation ID") { UIPasteboard.general.string=id }
                        Text("Use this reference to target your delivery check. Your registration credential and device token are never copied.")
                            .font(.wwFootnote)
                    }
                }
            }.font(.wwBody).navigationTitle("Guide updates").navigationBarTitleDisplayMode(.inline)
                .task {
                    async let destination=PublicGuideService().newsletterDestination()
                    _ = await alerts.refreshAvailability()
                    newsletterURL=await destination
                }
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
