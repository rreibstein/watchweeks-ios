import Foundation

public struct PublicIndex: Decodable, Sendable {
    public let v: Int
    public let guides: [PublicGuideHeader]
}
public struct PublicGuideHeader: Decodable, Sendable {
    public let id: String; public let slug: String; public let city: String
    public let dates: String; public let timezone: String
    public let start_date: String; public let end_date: String; public let url: URL
    func model(events: [Event] = [], brands: [Brand] = [], releases: [Release] = []) -> Guide {
        Guide(id:id,city:city,startDate:start_date,endDate:end_date,timeZone:timezone,webURL:url,events:events,brands:brands,releases:releases)
    }
}
public struct EventDay: Codable, Equatable, Sendable {
    public let date: String; public let open: String?; public let close: String?; public let access: String?
    public var label: String { [date, [open,close].compactMap{$0}.joined(separator:"–"), access].compactMap{$0}.filter{!$0.isEmpty}.joined(separator:" · ") }
}
public struct PublicDetail: Decodable, Sendable {
    public let v: Int; public let guide: PublicGuideHeader
    public let events: [PublicEvent]; public let brands: [PublicBrand]; public let releases: [PublicRelease]
    public struct PublicEvent: Decodable, Sendable {
        let id: String; let name: String; let venue: String?; let url: URL?; let note: String?
        let days: [EventDay]; let start_date: String?; let end_date: String?
    }
    public struct PublicBrand: Decodable, Sendable {
        let name: String; let brandKey: String; let eventId: String; let website: URL?; let hasRelease: Bool
    }
    public struct PublicRelease: Decodable, Sendable {
        let brand: String; let brandKey: String; let eventId: String; let kind: String; let text: String
        let url: URL?; let source: String?; let awards: [String]; let images: [ReleaseImageData]
    }
    public func model() throws -> Guide {
        guard v == 1 else { throw FeedError.invalidResponse }
        var merged: [String:Brand] = [:]
        for b in brands {
            let previous=merged[b.brandKey]
            let ids=Array(Set((previous?.eventIDs ?? [])+[b.eventId])).sorted()
            merged[b.brandKey]=Brand(id:b.brandKey,name:b.name,eventIDs:ids,webURL:b.website ?? previous?.webURL)
        }
        let mappedEvents=events.map { e in Event(id:e.id,name:e.name,venue:e.venue,startsAt:e.start_date,endsAt:e.end_date,webURL:e.url,note:e.note,days:e.days) }
        let mappedReleases=releases.map { r in
            // API v1 lacks release IDs. This tuple is unique in observed feeds;
            // validation rejects collisions rather than silently assigning unstable indexes.
            Release(id:[r.brandKey,r.eventId,r.kind].joined(separator:"|"), title:r.text.components(separatedBy:" — ").first ?? r.brand, brandName:r.brand, details:r.text, imageURL:r.images.first?.resolvedURL,webURL:r.url,brandID:r.brandKey,eventID:r.eventId,kind:r.kind,images:r.images,awards:r.awards)
        }
        let result=guide.model(events:mappedEvents,brands:merged.values.sorted{$0.name<$1.name},releases:mappedReleases)
        try GuideRepository.validate([result]); return result
    }
}
public struct ReleaseImageData: Codable, Equatable, Sendable {
    public let url: String; public let credit: String?; public let link: String?
    public var resolvedURL: URL? { URL(string:url,relativeTo:PublicLinks.home)?.absoluteURL }
}
