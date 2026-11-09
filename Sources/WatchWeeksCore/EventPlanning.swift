import Foundation

public enum LocalSchedule {
    public static func minute(_ time: String?) -> Int? {
        guard let time, time.count == 5 else { return nil }
        let parts = time.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, parts.allSatisfy({ $0.count == 2 && $0.utf8.allSatisfy { (48...57).contains($0) } }),
              let hours = Int(parts[0]), let minutes = Int(parts[1]), hours < 24, minutes < 60 else { return nil }
        return hours * 60 + minutes
    }

    public static func timeLabel(_ minute: Int, compact: Bool = false) -> String {
        let hour = (minute / 60) % 24
        let minutes = compact && minute % 60 == 0 ? "" : ":" + String(format: "%02d", minute % 60)
        return "\(hour % 12 == 0 ? 12 : hour % 12)\(minutes) \(hour < 12 ? "AM" : "PM")"
    }

    public static func dateLabel(_ value: String, zone: String) -> String? {
        guard let date = EventDates.parse(value, zone: zone), let timeZone = TimeZone(identifier: zone) else { return nil }
        var format = Date.FormatStyle().weekday(.abbreviated).month(.abbreviated).day()
        format.timeZone = timeZone
        return date.formatted(format)
    }

    public static func days(for event: Event, guideID: String) -> [EventDay] {
        guard guideID == "singapore-2026", event.id == "spring-sprang-sprung" else { return event.days }
        // The organizer lists 6 PM for these two dates. Apply only to the
        // conflicting 7 PM value so a refreshed feed can supply any later correction.
        return event.days.map { day in
            guard ["2026-11-14", "2026-11-15"].contains(day.date), day.close == "19:00" else { return day }
            return EventDay(date: day.date, open: day.open, close: "18:00", access: day.access, session: day.session)
        }
    }

    public static func accessLabel(_ value: String?) -> String? {
        switch value?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "invitation", "invitation only", "invite_only", "invitation_only": "Invitation only"
        case "free", "walk-in", "walk_in", "free_walk_in", "walkin": "Free walk-in"
        case "vip", "vvip": "VIP access"
        case "ticket", "ticketed", "ticket_required": "Ticket required"
        case "rsvp", "registration", "registration_required": "RSVP required"
        case "public", "open": "Open to the public"
        default: nil
        }
    }

    public static func hours(_ day: EventDay) -> Range<Int>? {
        guard let start = minute(day.open), let end = minute(day.close), start != end else { return nil }
        return start..<(end > start ? end : end + 24 * 60)
    }

    public static func hoursLabel(_ hours: Range<Int>, compact: Bool = false) -> String {
        let separator = compact ? "–" : " – "
        return timeLabel(hours.lowerBound, compact: compact) + separator + timeLabel(hours.upperBound, compact: compact)
    }

    public static func label(_ day: EventDay, zone: String) -> String {
        [dateLabel(day.date, zone: zone), day.session, hours(day).map { hoursLabel($0) }, accessLabel(day.access)]
            .compactMap { $0 }.joined(separator: " · ")
    }

    public static func interval(_ day: EventDay, zone: String) -> Range<Date>? {
        guard let date = EventDates.parse(day.date, zone: zone), let hours = hours(day),
              let timeZone = TimeZone(identifier: zone) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        func moment(_ minute: Int) -> Date? {
            guard let day = calendar.date(byAdding: .day, value: minute / 1440, to: date) else { return nil }
            return calendar.date(bySettingHour: (minute / 60) % 24, minute: minute % 60, second: 0, of: day)
        }
        guard let start = moment(hours.lowerBound), let end = moment(hours.upperBound), start < end else { return nil }
        return start..<end
    }
}

public struct LiveEvent: Sendable {
    public enum Status: String, Sendable {
        case now = "Happening now", today = "Happening today"
        case finished = "Finished today", tomorrow = "More tomorrow"
    }

    public struct Slot: Sendable {
        public let event: Event
        public let day: EventDay
        public let interval: Range<Date>
    }

    public let guide: Guide
    public let event: Event
    public let day: EventDay
    public let status: Status

    public static func citySchedule(in guide: Guide, now: Date = .now) -> (status: Status, today: [Slot])? {
        guard let calendar = calendar(for: guide) else { return nil }
        let start = calendar.startOfDay(for: now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: start),
              let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow) else { return nil }
        let slots = publicSlots(in: guide)
        let today = slots.filter { $0.interval.overlaps(start..<tomorrow) }
            .sorted { $0.interval.lowerBound < $1.interval.lowerBound }
        if today.contains(where: { $0.interval.contains(now) }) { return (.now, today) }
        if today.contains(where: { $0.interval.lowerBound > now }) { return (.today, today) }
        if slots.contains(where: { (tomorrow..<dayAfter).contains($0.interval.lowerBound) }) {
            return (.tomorrow, today)
        }
        return today.isEmpty ? nil : (.finished, today)
    }

    public static func next(in guides: [Guide], now: Date = .now) -> LiveEvent? {
        var candidates: [(LiveEvent, Date)] = []
        for guide in guides {
            guard let calendar = calendar(for: guide) else { continue }
            for slot in publicSlots(in: guide) where slot.interval.upperBound > now {
                let interval = slot.interval
                let status: Status
                if interval.contains(now) { status = .now }
                else if calendar.isDate(interval.lowerBound, inSameDayAs: now) { status = .today }
                else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                        calendar.isDate(interval.lowerBound, inSameDayAs: tomorrow) { status = .tomorrow }
                else { continue }
                candidates.append((LiveEvent(guide: guide, event: slot.event, day: slot.day, status: status),
                                   status == .now ? interval.upperBound : interval.lowerBound))
            }
        }
        for status in [Status.now, .today, .tomorrow] {
            if let first = candidates.filter({ $0.0.status == status }).min(by: { $0.1 < $1.1 }) { return first.0 }
        }
        return nil
    }

    private static func calendar(for guide: Guide) -> Calendar? {
        guard let zone = TimeZone(identifier: guide.timeZone) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    private static func publicSlots(in guide: Guide) -> [Slot] {
        guide.publicEvents.flatMap { event in
            LocalSchedule.days(for: event, guideID: guide.id).compactMap { day in
                guard !day.isRestrictedAccess, let interval = LocalSchedule.interval(day, zone: guide.timeZone) else { return nil }
                return Slot(event: event, day: day, interval: interval)
            }
        }
    }
}

public enum SingaporeItinerary {
    public struct Talk: Hashable, Sendable {
        public let title: String
        public let date: String
        public let hours: Range<Int>

        public init(title: String, date: String, hours: Range<Int>) {
            self.title = title; self.date = date; self.hours = hours
        }
    }

    public struct Stop: Equatable, Sendable {
        public let title: String
        public let eventID: String
        public let hours: Range<Int>
        public let transit: Int
        public let isTalk: Bool
    }

    public static let fairIDs = ["spring-sprang-sprung", "golden-hour", "iamwatch"]

    // Transit estimates from the WatchWeeks itinerary brief, in minutes.
    public static func travel(from: String, to: String) -> Int {
        switch Set([from, to]) {
        case Set(["spring-sprang-sprung", "golden-hour"]): 12
        case Set(["golden-hour", "iamwatch"]): 20
        case Set(["spring-sprang-sprung", "iamwatch"]): 25
        default: 0
        }
    }

    public static func plan(events: [Event], date: String, window: Range<Int>, talk: Talk? = nil) -> [Stop] {
        struct Visit {
            let eventID: String
            let title: String
            let hours: Range<Int>
            let duration: Int
            let isTalk: Bool
        }
        var visits = events.compactMap { event -> Visit? in
            guard fairIDs.contains(event.id), let day = LocalSchedule.days(for: event, guideID: "singapore-2026").first(where: { $0.date == date }),
                  LocalSchedule.accessLabel(day.access) != "Invitation only",
                  let hours = LocalSchedule.hours(day) else { return nil }
            return Visit(eventID: event.id, title: event.name, hours: hours, duration: 60, isTalk: false)
        }
        if let talk {
            guard talk.date == date, talk.hours.lowerBound >= window.lowerBound,
                  talk.hours.upperBound <= window.upperBound else { return [] }
            visits.append(Visit(eventID: "iamwatch", title: talk.title, hours: talk.hours,
                                duration: talk.hours.count, isTalk: true))
        }

        var best: [Stop] = []
        func consider(_ itinerary: [Stop], remaining: [Visit]) {
            if talk == nil || itinerary.contains(where: \.isTalk) {
                if itinerary.count > best.count ||
                    (itinerary.count == best.count &&
                     (itinerary.last?.hours.upperBound ?? Int.max) < (best.last?.hours.upperBound ?? Int.max)) {
                    best = itinerary
                }
            }
            for index in remaining.indices {
                let visit = remaining[index]
                let transit = itinerary.last.map { travel(from: $0.eventID, to: visit.eventID) } ?? 0
                let available = (itinerary.last?.hours.upperBound ?? window.lowerBound) + transit
                let start = max(available, visit.hours.lowerBound)
                let end = start + visit.duration
                guard end <= min(visit.hours.upperBound, window.upperBound) else { continue }
                let stop = Stop(title: visit.title, eventID: visit.eventID, hours: start..<end, transit: transit, isTalk: visit.isTalk)
                var rest = remaining
                rest.remove(at: index)
                consider(itinerary + [stop], remaining: rest)
            }
        }
        consider([], remaining: visits)
        return best
    }
}
