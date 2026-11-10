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

    /// One current or upcoming public slot per guide, ordered by urgency.
    public static func highlights(in guides: [Guide], now: Date = .now) -> [LiveEvent] {
        func priority(_ status: Status) -> Int {
            switch status {
            case .now: 0
            case .today: 1
            case .tomorrow: 2
            case .finished: 3
            }
        }
        func precedes(_ first: (event: LiveEvent, time: Date),
                      _ second: (event: LiveEvent, time: Date)) -> Bool {
            let left = priority(first.event.status), right = priority(second.event.status)
            if left != right { return left < right }
            if first.time != second.time { return first.time < second.time }
            return first.event.guide.id < second.event.guide.id
        }
        let candidates = guides.compactMap { guide -> (event: LiveEvent, time: Date)? in
            guard let calendar = calendar(for: guide),
                  let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            return publicSlots(in: guide).compactMap { slot -> (event: LiveEvent, time: Date)? in
                let interval = slot.interval
                guard interval.upperBound > now else { return nil }
                let status: Status
                if interval.contains(now) { status = .now }
                else if calendar.isDate(interval.lowerBound, inSameDayAs: now) { status = .today }
                else if calendar.isDate(interval.lowerBound, inSameDayAs: tomorrow) { status = .tomorrow }
                else { return nil }
                return (LiveEvent(guide: guide, event: slot.event, day: slot.day, status: status),
                        status == .now ? interval.upperBound : interval.lowerBound)
            }.min(by: precedes)
        }
        return candidates.sorted(by: precedes).map(\.event)
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
