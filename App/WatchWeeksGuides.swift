import SwiftUI
import UIKit
import WatchWeeksCore

struct DiscoveryView: View {
    @EnvironmentObject var model: AppModel
    var ordered: [Guide] {
        // The home page highlights these guides editorially. Newly published guides
        // retain feed order within their active or past group.
        let featured = ["austin-2026", "hong-kong-2026", "miami-2026", "singapore-2026"]
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
                            ForEach(ordered) { guide in GuidePreview(guide: guide).id(guide.id) }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("How much time do you have?").font(.wwTitle2).accessibilityAddTraits(.isHeader)
            Text("Plan around the three overlapping fairs. Times are in Singapore, with one hour at each fair plus estimated travel.")
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
                    .frame(minHeight: 44)
            }.disabled(stops.isEmpty)
        }.padding(14).watchCard()
            .onChange(of: day) { _, _ in selectedTalk = nil; copied = false }
            .onChange(of: window) { _, _ in copied = false }
            .onChange(of: includeTalk) { _, _ in copied = false }
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink { CityView(guide: guide) } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guide.city).font(.wwTitle)
                        Text(guideDateRange(guide)).font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.wwHeadline)
                }
            }.buttonStyle(.plain)
            Text("\(guide.brands.count) brands · \(guide.events.count) events · \(guide.releases.count) new releases")
                .font(.wwSubheadline).foregroundStyle(WatchWeeksStyle.secondary)
            ForEach(guide.events.sorted { brandCount(guide, $0) > brandCount(guide, $1) }.prefix(3)) { event in
                Text("\(event.name) · \(brandCount(guide, event)) brands").font(.wwFootnote)
            }
            if !guide.releases.isEmpty {
                Divider()
                NavigationLink { ReleasesView(guide: guide).navigationTitle("New releases").accountAccess() } label: {
                    Label("See all new releases", systemImage: "sparkles").foregroundStyle(WatchWeeksStyle.release)
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).watchCard()
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
        guide.events.filter { event in day == nil || event.days.contains { $0.date == day } }.sorted { first, second in
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
                dayNavigation
                if !dates.isEmpty {
                    WatchSegments(selection: $day, choices: [nil] + dates.map(Optional.some), label: shortDay)
                }
                WatchSegments(selection: $sortByDay, choices: [false, true]) { $0 ? "By day" : "By # of brands" }
                if guide.id == "singapore-2026" { SingaporePlanner(guide: guide) }
                ForEach(events) { event in
                    NavigationLink { EventInfo(guide: guide, event: event) } label: {
                        EventPreview(guide: guide, event: event, day: day)
                    }.buttonStyle(.plain).accessibilityIdentifier("event-\(event.id)")
                }
                if events.isEmpty { Text("No events on this day.").foregroundStyle(WatchWeeksStyle.secondary) }
                if !guide.releases.isEmpty {
                    NavigationLink { ReleasesView(guide: guide).navigationTitle("New releases").accountAccess() } label: {
                        Label("See all \(guide.releases.count) new releases", systemImage: "sparkles")
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

    private var dayNavigation: some View {
        let allDays = [nil] + dates.map(Optional.some)
        let index = allDays.firstIndex(of: day) ?? 0
        return HStack {
            dayArrow("Previous day", icon: "chevron.left", target: index - 1, days: allDays)
            VStack(spacing: 4) {
                Text(day.map { EventDates.label($0, zone: guide.timeZone) } ?? "All events").font(.wwTitle)
                Text("\(events.count) \(events.count == 1 ? "event" : "events")").foregroundStyle(WatchWeeksStyle.secondary)
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
                let days = LocalSchedule.days(for: event, guideID: guide.id).filter { day == nil || $0.date == day }
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
                let releases = guide.releases.filter { $0.eventID == event.id }
                if !releases.isEmpty { releasePreviews(releases) }
                let dealers = (guide.dealers ?? []).filter { $0.eventId == event.id }
                if !dealers.isEmpty {
                    DisclosureGroup("Dealers (\(dealers.count))") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(dealers) { dealer in Text(dealer.name) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                    }.padding(14).watchCard()
                }
                if brandCount(guide, event) > 0 { BrandDirectory(guide: guide, event: event) }
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
            ForEach(Array(LocalSchedule.days(for: event, guideID: guide.id).enumerated()), id: \.offset) { _, day in
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
            if let note = event.note {
                DisclosureGroup("Entry and appointment notes") {
                    Text(note).font(.wwFootnote).padding(.top, 4)
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
