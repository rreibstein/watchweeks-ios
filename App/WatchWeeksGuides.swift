import SwiftUI
import UIKit
import WatchWeeksCore

struct DiscoveryView: View {
    @EnvironmentObject var model: AppModel
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
            VStack(spacing: 0) {
                WatchHeader()
                ScrollViewReader { scroll in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Text("Make the most of every watch fair.")
                                .font(.wwLargeTitle).accessibilityAddTraits(.isHeader)
                            Text("The independent guide to watch events around the world. Discover the brands exhibiting, explore the new releases, and plan your must-sees.")
                                .foregroundStyle(WatchWeeksStyle.secondary)
                            LiveStatusCard(guides: model.guides)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(ordered) { guide in
                                        Button(guide.city) { withAnimation { scroll.scrollTo(guide.id, anchor: .top) } }
                                            .font(.wwSubheadline).padding(.horizontal, 12).frame(minHeight: 44)
                                            .watchCard(radius: 22).buttonStyle(.plain)
                                    }
                                }
                            }
                            Text("Guides").font(.wwTitle).accessibilityAddTraits(.isHeader)
                            if model.loading && model.guides.isEmpty { ProgressView("Loading guides…") }
                            if let message = model.message {
                                Text(message).font(.wwCallout)
                                Button("Try again") { Task { await model.refresh() } }
                            }
                            if model.stale && !model.loading, let date = model.savedAt {
                                Label("Offline copy · updated \(date.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock.arrow.circlepath").font(.wwCaption)
                            }
                            ForEach(ordered.filter { EventDates.status($0) != .past && $0.id != "austin-2026" }) {
                                GuidePreview(guide: $0, past: false).id($0.id)
                            }
                            let past = ordered.filter { EventDates.status($0) == .past || $0.id == "austin-2026" }
                            if !past.isEmpty {
                                Text("Past guides").font(.wwTitle).accessibilityAddTraits(.isHeader)
                                ForEach(past) { GuidePreview(guide: $0, past: true).id($0.id) }
                            }
                            if ordered.isEmpty && !model.loading {
                                ContentUnavailableView("No guides loaded", systemImage: "globe", description: Text("Pull to refresh. Previously loaded guides are available offline."))
                            }
                        }.padding(16)
                    }
                    .refreshable { await model.refresh() }
                }
            }.watchPage().toolbar(.hidden, for: .navigationBar)
                .onAppear { model.activeGuideID = nil }
        }
    }
}

private struct LiveStatusCard: View {
    let guides: [Guide]
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if let item = LiveEvent.next(in: guides, now: context.date),
               let hours = LocalSchedule.hours(item.day) {
                NavigationLink { EventInfo(guide: item.guide, event: item.event) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today").font(.wwHeadline)
                        Text(item.status.rawValue).font(.wwCaption.weight(.bold))
                            .foregroundStyle(Color(red: 0.24, green: 0.15, blue: 0.05))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color(red: 1, green: 0.83, blue: 0.53), in: Capsule())
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

private struct SingaporePlanner: View {
    let guide: Guide
    @State private var day = "2026-11-13"
    @State private var window: Window = .allDay
    @State private var includeTalk = false
    @State private var selectedTalk: SingaporeItinerary.Talk?
    @State private var copied = false
    @State private var expanded = false
    @State private var customized = false

    private enum Window: String, CaseIterable {
        case morning = "Morning", afternoon = "Afternoon", late = "Late afternoon", allDay = "All day"
        var hours: Range<Int> {
            switch self {
            case .morning: 660..<780
            case .afternoon: 780..<1020
            case .late: 1020..<1200
            case .allDay: 660..<1200
            }
        }
    }

    private static let program = URL(string: "https://www.iamwatch.com/event/2026/programmes")!
    // Organizer's Wonder Room conversation schedule, local to Singapore.
    private static let talks: [SingaporeItinerary.Talk] = [
        .init(title: "I Want to Make My Own Watch. Now What?", date: "2026-11-13", hours: 840..<900),
        .init(title: "The Morteau Generation", date: "2026-11-13", hours: 960..<1020),
        .init(title: "Who Actually Invents Anything Anymore?", date: "2026-11-14", hours: 720..<780),
        .init(title: "GD100 Screening & Conversation", date: "2026-11-14", hours: 960..<1020),
        .init(title: "What Should Watches Made in 2026 and Beyond Look Like?", date: "2026-11-15", hours: 870..<930),
        .init(title: "Does Independence Need the Groups?", date: "2026-11-15", hours: 960..<1020)
    ]

    var body: some View {
        let days = ["2026-11-13", "2026-11-14", "2026-11-15"]
        let talks = Self.talks.filter { $0.date == day }
        let talk = includeTalk ? (talks.first { $0 == selectedTalk } ?? talks.first) : nil
        let noTalk = SingaporeItinerary.plan(events: guide.events, date: day, window: window.hours)
        let stops = talk.map { SingaporeItinerary.plan(events: guide.events, date: day, window: window.hours, talk: $0) } ?? noTalk
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Times are in Singapore, with one hour at each fair plus estimated travel.")
                    .font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
                WatchSegments(selection: $day, choices: days) { LocalSchedule.dateLabel($0, zone: guide.timeZone) ?? "Day" }
                WatchSegments(selection: $window, choices: Window.allCases, columns: 2) { $0.rawValue }
                Text(LocalSchedule.hoursLabel(window.hours)).font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
                Toggle("Build around a talk", isOn: $includeTalk)
                if includeTalk {
                    Menu {
                        ForEach(talks, id: \.self) { session in
                            Button("\(LocalSchedule.timeLabel(session.hours.lowerBound)) · \(session.title)") { selectedTalk = session }
                        }
                        Link("Official IAMWATCH program", destination: Self.program)
                    } label: {
                        Label(talk?.title ?? "Choose an IAMWATCH talk", systemImage: "chevron.up.chevron.down")
                            .font(.wwSubheadline).multilineTextAlignment(.leading).frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("planner-talk-menu")
                    Text(tradeOff(keeping: stops, skipping: noTalk)).font(.wwFootnote)
                    if let talk {
                        Text("Talk: \(LocalSchedule.hoursLabel(talk.hours)) · Wonder Room")
                            .font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
                    }
                }
                if stops.isEmpty { Text("No itinerary fits this time window.").font(.wwSubheadline) }
                ForEach(Array(stops.enumerated()), id: \.offset) { _, stop in
                    if stop.transit > 0 {
                        Label("\(stop.transit) min travel", systemImage: "figure.walk").font(.wwCaption)
                            .foregroundStyle(WatchWeeksStyle.secondary)
                    }
                    Text(stop.title).font(.wwHeadline)
                    Text(LocalSchedule.hoursLabel(stop.hours)).font(.wwSubheadline)
                }
                Button {
                    let date = LocalSchedule.dateLabel(day, zone: guide.timeZone) ?? "Singapore"
                    let lines = stops.flatMap { stop in
                        (stop.transit > 0 ? ["\(stop.transit) min travel"] : [])
                            + ["\(LocalSchedule.hoursLabel(stop.hours)) · \(stop.title)"]
                    }
                    UIPasteboard.general.string = (["Singapore · \(date) · local time"] + lines).joined(separator: "\n")
                    copied = true
                } label: {
                    Label(copied ? "Plan copied" : "Copy plan", systemImage: copied ? "checkmark" : "document.on.document")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("copy-plan")
                .disabled(stops.isEmpty)
            }.padding(.top, 12)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Plan your fair day").font(.wwTitle2).accessibilityAddTraits(.isHeader)
                Text("Pick a day and how much time you have — see which of the 3 fairs fit, in what order, with travel time.")
                    .font(.wwFootnote).foregroundStyle(WatchWeeksStyle.secondary)
                if customized && !expanded, let date = LocalSchedule.dateLabel(day, zone: guide.timeZone) {
                    Text("\(date) · \(window.rawValue)").font(.wwCaption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(WatchWeeksStyle.control, in: Capsule())
                }
            }
        }.padding(14).watchCard()
            .onChange(of: day) { _, _ in selectedTalk = nil; copied = false; customized = true }
            .onChange(of: window) { _, _ in copied = false; customized = true }
            .onChange(of: includeTalk) { _, _ in copied = false; customized = true }
            .onChange(of: selectedTalk) { _, _ in copied = false }
    }

    private func tradeOff(keeping: [SingaporeItinerary.Stop], skipping: [SingaporeItinerary.Stop]) -> String {
        let keepIDs = Set(keeping.filter { !$0.isTalk }.map(\.eventID))
        let skipFairs = skipping.filter { !$0.isTalk }
        let misses = skipFairs.filter { !keepIDs.contains($0.eventID) }.map(\.title)
        let keep = keeping.isEmpty ? "Talk is outside this window" :
            (misses.isEmpty ? "Keep the talk (same fairs)" : "Keep the talk (misses \(misses.joined(separator: ", ")))")
        let skip = skipFairs.count == 3 ? "fits all 3 fairs" : "fits \(skipFairs.count) \(skipFairs.count == 1 ? "fair" : "fairs")"
        return "\(keep) vs. Skip the talk (\(skip))"
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
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink { CityView(guide: guide) } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guide.city).font(.wwTitle)
                        Text(homeDates).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.wwHeadline)
                }
            }.buttonStyle(.plain)
            Text("\(guide.brands.count) brands · \(guide.publicEvents.count) events · \(guide.newReleases.count) new releases")
                .font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
            if past {
                Label("Enthusiasts’ favorites", systemImage: "star").font(.wwHeadline)
                if guide.id == "nyww-2026", let snapshot = URL(string: "https://watchweeks.com/newyork#audience-favorites") {
                    NewYorkFavorites(guide: guide)
                    WebsiteLink(title: "View the published snapshot", url: snapshot, guide: guide)
                } else {
                    Text("A frozen audience snapshot hasn’t been published here.").font(.wwFootnote)
                }
            } else {
                ForEach(guide.publicEvents.sorted { brandCount(guide, $0) > brandCount(guide, $1) }.prefix(3)) { event in
                    if guide.isDealerShow(event) {
                        Text("\(event.name) · \(guide.dealers(at: event).count) dealers").font(.wwFootnote)
                        DealerChips(dealers: guide.dealers(at: event))
                    } else if brandCount(guide, event) > 0 {
                        Text("\(event.name) · \(brandCount(guide, event)) brands").font(.wwFootnote)
                    }
                }
            }
            if !guide.newReleases.isEmpty {
                Divider()
                NavigationLink { ReleasesView(guide: guide).navigationTitle("New releases").accountAccess() } label: {
                    Label("See all new releases", systemImage: "sparkles").foregroundStyle(WatchWeeksStyle.release)
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).watchCard()
    }
}

private struct NewYorkFavorites: View {
    let guide: Guide
    private struct Favorite: Identifiable {
        let id: String
        let name: String
        let count: Int
    }

    // Published WatchWeeks snapshot nyww-2026-event-v1, including the tie
    // at the website's top-20 cutoff. Keep the published order frozen.
    private static let ranking: [Favorite] = [
        .init(id: "chopard", name: "Chopard", count: 5),
        .init(id: "ming", name: "Ming", count: 5),
        .init(id: "fears", name: "Fears", count: 5),
        .init(id: "traska", name: "TRASKA", count: 5),
        .init(id: "arminstrom", name: "Armin Strom", count: 4),
        .init(id: "ressence", name: "Ressence", count: 4),
        .init(id: "angelusmayexhibitwitharnoldson", name: "Angelus", count: 4),
        .init(id: "gshock", name: "G-SHOCK", count: 4),
        .init(id: "kollokium", name: "Kollokium", count: 4),
        .init(id: "straum", name: "Straum", count: 4),
        .init(id: "autodromo", name: "Autodromo", count: 4),
        .init(id: "hron", name: "Héron", count: 4),
        .init(id: "marathonwatchcompany", name: "Marathon Watch Company", count: 4),
        .init(id: "oris", name: "Oris", count: 4),
        .init(id: "christopherward", name: "Christopher Ward", count: 3),
        .init(id: "czapek", name: "Czapek", count: 3),
        .init(id: "arnoldson", name: "Arnold & Son", count: 3),
        .init(id: "frederiqueconstant", name: "Frederique Constant", count: 3),
        .init(id: "pequignet", name: "Pequignet", count: 3),
        .init(id: "mauricelacroix", name: "Maurice Lacroix", count: 3),
        .init(id: "ulyssenardin", name: "Ulysse Nardin", count: 3),
    ]

    var body: some View {
        DisclosureGroup("Oct 14–20, 2026 · Frozen rankings") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Self.ranking) { row in
                    HStack {
                        if let brand = guide.brands.first(where: { $0.id == row.id }) {
                            NavigationLink(brand.displayName) { BrandInfo(guide: guide, brand: brand) }
                        } else {
                            Text(row.name)
                        }
                        Spacer()
                        Text("\(row.count)").monospacedDigit()
                            .accessibilityLabel("\(row.count) must-see or highlight votes")
                    }
                }
            }.font(.wwSubheadline).padding(.top, 8)
        }.font(.wwSubheadline)
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
    @EnvironmentObject var model: AppModel
    let guide: Guide
    @State private var tracked = false
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
                if guide.id == "singapore-2026" { SingaporePlanner(guide: guide) }
                if !guide.newReleases.isEmpty {
                    NavigationLink { ReleasesView(guide: guide).navigationTitle("New releases").accountAccess() } label: {
                        Label("See all \(guide.newReleases.count) new releases", systemImage: "sparkles")
                            .foregroundStyle(WatchWeeksStyle.release)
                    }.padding(.vertical, 8)
                }
                if let url = PublicLinks.safeExternal(guide.webURL) {
                    WebsiteLink(title: "Full guide and planning tools", url: url, guide: guide)
                    ShareGuideButton(guide: guide, url: url)
                }
            }.padding(16)
        }
        .watchPage().navigationTitle("WatchWeeks").navigationBarTitleDisplayMode(.inline).guideToolbar()
        .task {
            model.activeGuideID = guide.id
            if !tracked { tracked = true; NativeAnalytics.shared.track(.guideViewed, guide: guide) }
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

private struct DealerChips: View {
    let dealers: [Dealer]
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(dealers) { dealer in
                    Text(dealer.name).font(.wwFootnote).padding(10).watchCard(radius: 20)
                }
            }
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
    @EnvironmentObject var model: AppModel
    let guide: Guide
    let event: Event
    @State private var tracked = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("\(guide.city.uppercased()) GUIDE").font(.wwCaption).tracking(1)
                    .foregroundStyle(WatchWeeksStyle.link)
                Text(event.name).font(.wwTitle).accessibilityAddTraits(.isHeader)
                Text(dateRange(event.startsAt, event.endsAt, zone: guide.timeZone)).font(.wwHeadline)
                metadata
                if SingaporeStock.applies(to: guide, event: event) { stock }
                let releases = guide.newReleases.filter { $0.eventID == event.id }
                if !releases.isEmpty { releasePreviews(releases) }
                let dealers = guide.dealers(at: event)
                if guide.isDealerShow(event) {
                    Text("\(dealers.count) dealers").font(.wwHeadline)
                    DealerChips(dealers: dealers)
                } else if brandCount(guide, event) > 0 {
                    BrandDirectory(guide: guide, event: event)
                }
            }.padding(16)
        }
        .watchPage().navigationTitle("WatchWeeks").navigationBarTitleDisplayMode(.inline).guideToolbar()
        .task {
            model.activeGuideID = guide.id
            if !tracked { tracked = true; NativeAnalytics.shared.track(.eventViewed, guide: guide, eventID: event.id) }
        }
    }

    private var address: String? {
        if let address = event.address { return address }
        guard guide.id == "singapore-2026" else { return nil }
        switch event.id {
        case "golden-hour": return "1 Beach Road, Singapore 189673"
        case "iamwatch": return "38 Cuscaden Road, Singapore 249731"
        case "spring-sprang-sprung": return "28 China Street, Singapore 049570"
        default: return nil
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let venue = event.venue { Label(venue, systemImage: "mappin.and.ellipse").font(.wwHeadline) }
            if let address { Text(address).font(.wwSubheadline).textSelection(.enabled) }
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

    private func releasePreviews(_ releases: [Release]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New releases").font(.wwTitle2).accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(releases) { release in
                        NavigationLink { ReleaseDetail(guide: guide, release: release) } label: {
                            ReleaseCard(release: release, guide: guide, compact: true)
                                .frame(width: 205, alignment: .leading)
                        }.buttonStyle(.plain)
                    }
                }
            }
            NavigationLink {
                ReleasesView(guide: guide, eventID: event.id).navigationTitle("New releases").guideToolbar()
            } label: {
                Label("See all \(releases.count) new releases at this event", systemImage: "arrow.right")
                    .foregroundStyle(WatchWeeksStyle.release).frame(minHeight: 44)
            }.accessibilityIdentifier("event-releases")
        }
    }
}
