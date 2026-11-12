import Foundation

// Internal presentation/cache models mapped from the verified v1 public contract.
public struct Guide: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let city: String
    public let summary: String?
    public let startDate: String?
    public let endDate: String?
    public let timeZone: String
    public let webURL: URL?
    public var events: [Event]
    public var brands: [Brand]
    public var releases: [Release]
    public var dealers: [Dealer]?
    public init(id: String, city: String, summary: String? = nil, startDate: String? = nil, endDate: String? = nil, timeZone: String, webURL: URL? = nil, events: [Event] = [], brands: [Brand] = [], releases: [Release] = [], dealers: [Dealer]? = nil) {
        self.id=id; self.city=city; self.summary=summary; self.startDate=startDate; self.endDate=endDate; self.timeZone=timeZone; self.webURL=webURL; self.events=events; self.brands=brands; self.releases=releases; self.dealers=dealers
    }
}
public struct Dealer: Codable, Identifiable, Equatable, Sendable {
    public let name: String
    public let eventId: String
    public var id: String { "\(eventId)|\(name)" }
    public init(name:String,eventId:String) { self.name=name;self.eventId=eventId }
}

public struct Event: Codable, Identifiable, Equatable, Sendable {
    public let note: String?
    public let days: [EventDay]
    public let id: String
    public let name: String
    public let venue: String?
    public let address: String?
    public let startsAt: String?
    public let endsAt: String?
    public let webURL: URL?
    public init(id: String, name: String, venue: String? = nil, address: String? = nil, startsAt: String? = nil, endsAt: String? = nil, webURL: URL? = nil, note: String? = nil, days: [EventDay] = []) { self.note=note; self.days=days; self.id=id; self.name=name; self.venue=venue; self.address=address; self.startsAt=startsAt; self.endsAt=endsAt; self.webURL=webURL }
}
public struct Brand: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let eventIDs: [String]
    public let summary: String?
    public let webURL: URL?
    public init(id: String, name: String, eventIDs: [String] = [], summary: String? = nil, webURL: URL? = nil) { self.id=id; self.name=name; self.eventIDs=eventIDs; self.summary=summary; self.webURL=webURL }
}
public struct Release: Codable, Identifiable, Equatable, Sendable {
    public let brandID: String?
    public let eventID: String?
    public let kind: String?
    public let images: [ReleaseImageData]
    public let awards: [String]
    public let sharedImages: [ReleaseImageData]?
    public let id: String
    public let title: String
    public let brandName: String?
    public let details: String?
    public let imageURL: URL?
    public let webURL: URL?
    public init(id: String, title: String, brandName: String? = nil, details: String? = nil, imageURL: URL? = nil, webURL: URL? = nil, brandID: String? = nil, eventID: String? = nil, kind: String? = nil, images: [ReleaseImageData] = [], awards: [String] = [], sharedImages: [ReleaseImageData]? = nil) { self.sharedImages=sharedImages; self.brandID=brandID; self.eventID=eventID; self.kind=kind; self.images=images; self.awards=awards; self.id=id; self.title=title; self.brandName=brandName; self.details=details; self.imageURL=imageURL; self.webURL=webURL }
}
public enum GuideStatus: String, Sendable { case current = "Happening now", upcoming = "Upcoming", past = "Past", unknown = "Dates to be confirmed" }
public enum EventDates {
    public static func parse(_ value: String, zone: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let result = iso.date(from: value) { return result }
        iso.formatOptions = [.withInternetDateTime]
        if let result = iso.date(from: value) { return result }
        guard value.count == 10, let timezone = TimeZone(identifier: zone) else { return nil }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.calendar = Calendar(identifier: .gregorian); f.timeZone = timezone; f.dateFormat = "yyyy-MM-dd"; f.isLenient = false
        guard let d = f.date(from: value), f.string(from: d) == value else { return nil }; return d
    }
    public static func label(_ value: String?, zone: String) -> String {
        guard let value, let date = parse(value, zone: zone), let tz = TimeZone(identifier: zone) else { return "Time to be confirmed" }
        let f = DateFormatter(); f.timeZone = tz; f.dateStyle = .medium; f.timeStyle = value.count == 10 ? .none : .short
        return f.string(from: date)
    }
    public static func status(_ guide: Guide, now: Date = Date()) -> GuideStatus {
        guard let start = guide.startDate.flatMap({ parse($0, zone: guide.timeZone) }), let endString = guide.endDate, var end = parse(endString, zone: guide.timeZone), let tz = TimeZone(identifier: guide.timeZone) else { return .unknown }
        if endString.count == 10 { var c = Calendar(identifier: .gregorian); c.timeZone = tz; end = c.date(byAdding: .day, value: 1, to: end)! }
        guard end >= start else { return .unknown }
        return now < start ? .upcoming : (now < end ? .current : .past)
    }
}
public enum PublicLinks {
    public static let home = URL(string: "https://watchweeks.com")!
    public static let newsletter = URL(string:"https://watchweeks.com/notify#newsletter")!
    public static let corrections = URL(string:"https://watchweeks.com/account#correction")!
    public static let privacy = URL(string: "https://github.com/rreibstein/watchweeks-ios/blob/development/native-launch/release/PRIVACY.md")!
    public static func apiGuide(_ id: String) -> URL? {
        guard !id.isEmpty, id != ".", id != "..", !id.contains("/"), !id.contains("\\"), !id.contains("%"), !id.contains("?"), !id.contains("#") else { return nil }
        return home.appendingPathComponent("api/public/guides").appendingPathComponent(id)
    }
    public static func safeExternal(_ url: URL?) -> URL? {
        guard let url, url.scheme?.lowercased() == "https", url.host != nil, url.user == nil, url.password == nil else { return nil }; return url
    }
}
public enum BrandFilter: String, CaseIterable, Sendable { case all = "All", mustSee = "Must see", remaining = "Must see remaining", seen = "Seen" }
public enum Interest: Int, Codable, CaseIterable, Sendable { case none, interested, mustSee, little, unfamiliar, skip
    public var priority: Int { switch self { case .mustSee: 3; case .interested: 2; case .little: 1; default: 0 } }
    public var category: String { switch self { case .none: "unrated"; case .interested: "moderate"; case .mustSee: "must"; case .little: "little"; case .unfamiliar: "unknown"; case .skip: "none" } }
    public var label: String { switch self { case .none: "No rating"; case .interested: "Interested"; case .mustSee: "Must see"; case .little: "If time"; case .unfamiliar: "Unfamiliar"; case .skip: "Skip" } }
}
public enum VisitReaction: String, Codable, CaseIterable, Sendable {
    case loved = "Loved", liked = "Liked", notForMe = "Not for me"
}

public enum BuyingIntent: String, Codable, CaseIterable, Sendable {
    case secondLook = "Second look", considerBuying = "Consider buying"
}

public struct Selection: Codable, Equatable, Sendable {
    public var interest: Interest = .none
    public var seen = false
    // Missing in v1 saves. Keep existing ratings-based lists until the user
    // explicitly adds or removes this brand from the shortlist.
    public var shortlisted: Bool?
    public var reaction: VisitReaction?
    public var buyingIntent: BuyingIntent?
    public var isShortlisted: Bool { shortlisted ?? (interest.priority > 0) }
    public init(interest: Interest = .none, seen: Bool = false, shortlisted: Bool? = nil) {
        self.interest = interest
        self.seen = seen
        self.shortlisted = shortlisted
    }
}
public struct SelectionKey: Codable, Hashable, Sendable {
    public let guideID: String
    public let brandID: String
    public init(guideID: String, brandID: String) { self.guideID=guideID; self.brandID=brandID }
}
public enum Browsing {
    public static func brands(_ brands: [Brand], query: String, filter: BrandFilter, selection: (Brand) -> Selection) -> [Brand] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return brands.filter { brand in
            let s = selection(brand)
            let matches = search.isEmpty || brand.displayName.localizedCaseInsensitiveContains(search) || brand.name.localizedCaseInsensitiveContains(search)
            return matches && (filter == .all || (filter == .mustSee && s.interest == .mustSee) || (filter == .remaining && s.interest == .mustSee && !s.seen) || (filter == .seen && s.seen))
        }.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}
