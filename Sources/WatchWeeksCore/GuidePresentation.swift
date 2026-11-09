import Foundation

public extension Guide {
    var publicEvents: [Event] { events.filter { parentEventID(for: $0) == nil } }

    func parentEventID(for event: Event) -> String? {
        // The v1 feed does not expose parent IDs. These are verified edition relationships.
        switch (id, event.id) {
        case ("miami-2026", "coconut-vip"): "coconut-grove"
        case ("austin-2026", "minutes-preview"): "minutes-hours"
        default: nil
        }
    }

    func accessSessions(for event: Event) -> [Event] {
        events.filter { parentEventID(for: $0) == event.id }
    }

    func isDealerShow(_ event: Event) -> Bool {
        id == "miami-2026" && event.id == "coconut-grove"
    }

    func dealers(at event: Event) -> [Dealer] {
        (dealers ?? []).filter { $0.eventId == event.id }
    }

    var newReleases: [Release] { newReleases(for: nil) }

    func newReleases(for brandID: String?) -> [Release] {
        let dealerIDs = Set(events.filter(isDealerShow).flatMap { [$0.id] + accessSessions(for: $0).map(\.id) })
        return releases.filter { (brandID == nil || $0.brandID == brandID) && !dealerIDs.contains($0.eventID ?? "") }.flatMap(\.individualModels)
    }

    func eventStatus(_ event: Event, now: Date = .now) -> GuideStatus {
        let days = LocalSchedule.days(for: event, guideID: id).filter { !$0.isRestrictedAccess }
        let intervals = days.compactMap { LocalSchedule.interval($0, zone: timeZone) }
        if let start = intervals.map(\.lowerBound).min(), let end = intervals.map(\.upperBound).max() {
            return now < start ? .upcoming : (now < end ? .current : .past)
        }
        return EventDates.status(Guide(id: id, city: city, startDate: event.startsAt, endDate: event.endsAt, timeZone: timeZone), now: now)
    }
}

public extension EventDay {
    var isRestrictedAccess: Bool {
        let code = access?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return LocalSchedule.accessLabel(access) == "Invitation only"
            || ["vip", "vvip", "preview", "early access", "early_access", "private"].contains(code ?? "")
    }
}

public extension Brand {
    static func canonicalName(_ name: String, id: String?) -> String {
        switch id {
        case "geo": return "GeO"
        case "christopherward": return "Christopher Ward"
        case "prestex", "duckworthprestex": return "Prestex"
        case "toolwatchco", "twco": return "TWCO. (Tool Watch Co.)"
        default: break
        }
        switch name.lowercased() {
        case "geo": return "GeO"
        case "cw", "christopher ward": return "Christopher Ward"
        case "prestex", "duckworth prestex", "duckworth pressdex": return "Prestex"
        case "twco", "twco.", "tool watch co.", "twco. (tool watch co.)": return "TWCO. (Tool Watch Co.)"
        default: return name
        }
    }

    var displayName: String { Self.canonicalName(name, id: id) }
}
