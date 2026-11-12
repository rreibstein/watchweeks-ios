import Foundation

public struct AnnouncedRelease: Codable, Equatable, Identifiable, Sendable {
    public let id:String
    public let brand:String
    public let brandKey:String
    public let model:String
    public let variant:String?
    public let eventId:String
    public let eventName:String?
    public let date:String
    public let imageUrl:URL
    public let credit:String?
    public var title:String { [model,variant].compactMap{$0}.filter{!$0.isEmpty}.joined(separator:" · ") }
}

/// Decode optional editorial additions independently: malformed items must never
/// make an otherwise valid guide disappear. Array order is retained exactly.
struct AnnouncedItems: Decodable {
    let items:[AnnouncedRelease]
    private struct Item:Decodable { let value:AnnouncedRelease?;init(from decoder:Decoder) throws { value=try? AnnouncedRelease(from:decoder) } }
    init(from decoder:Decoder) throws {
        let values=try decoder.singleValueContainer().decode([Item].self)
        items=values.compactMap(\.value)
    }
}

public enum AnnouncedSurface:String,Codable,Sendable { case home,guide,newReleases="new_releases" }
public struct AnnouncementInteraction:Sendable {
    public let source:AnnouncedSurface
    public let brandKey:String?
    public let position:Int?
    public let count:Int
    public let date:String?
    public init(source:AnnouncedSurface,brandKey:String?,position:Int?,count:Int,date:String?) {
        self.source=source;self.brandKey=brandKey;self.position=position;self.count=count;self.date=date
    }
}
public struct ReleaseNavigationRequest:Equatable,Identifiable,Sendable {
    public let id=UUID()
    public let guideID:String
    public let brandKey:String?
    public let eventID:String?
    public init(guideID:String,brandKey:String?,eventID:String?) { self.guideID=guideID;self.brandKey=brandKey;self.eventID=eventID }
}

public extension Guide {
    /// Seven local calendar dates: today plus the previous six. Future dates and
    /// invalid/unsafe items are excluded; source order is never changed.
    func recentAnnounced(now:Date = .now,eventID:String? = nil) -> [AnnouncedRelease] {
        guard let zone=TimeZone(identifier:timeZone) else { return [] }
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=zone
        let today=calendar.startOfDay(for:now)
        guard let first=calendar.date(byAdding:.day,value:-6,to:today),let tomorrow=calendar.date(byAdding:.day,value:1,to:today) else { return [] }
        var ids:Set<String>=[]
        return (announced ?? []).filter { item in
            guard !item.id.isEmpty,!item.brandKey.isEmpty,!item.model.isEmpty,
                  eventID == nil || item.eventId == eventID,
                  item.imageUrl.scheme?.lowercased() == "https",PublicLinks.safeExternal(item.imageUrl) != nil,
                  item.date.count == 10,let date=EventDates.parse(item.date,zone:timeZone),
                  date >= first,date < tomorrow else { return false }
            return ids.insert(item.id).inserted
        }
    }
    func announcedPhotoExclusions(surface:AnnouncedSurface,now:Date = .now,eventIDs:Set<String>? = nil) -> Set<String> {
        let items=recentAnnounced(now:now).filter{eventIDs == nil || eventIDs!.contains($0.eventId)}
        guard surface != .home || items.count >= 2 else { return [] }
        return Set(items.map(\.brandKey))
    }
    func isJustAdded(_ release:Release,now:Date = .now) -> Bool {
        isJustAdded(release,items:recentAnnounced(now:now,eventID:release.eventID))
    }
    func justAddedReleaseIDs(in releases:[Release],now:Date = .now) -> Set<String> {
        let items=recentAnnounced(now:now)
        return Set(releases.filter{isJustAdded($0,items:items)}.map(\.id))
    }
    private func isJustAdded(_ release:Release,items:[AnnouncedRelease]) -> Bool {
        let text=Self.announcementMatchText([release.title,release.details].compactMap{$0}.joined(separator:" "))
        return items.contains { item in
            let model=Self.announcementMatchText(item.model)
            return item.brandKey == release.brandID && item.eventId == release.eventID && !model.isEmpty && text.contains(model)
        }
    }
    func eventChipBrands(eventID:String,seed:String,limit:Int=8) -> (brands:[Brand],remaining:Int) {
        var ids:Set<String>=[]
        let brands=brands.filter{$0.eventIDs.contains(eventID) && ids.insert($0.id).inserted}
        guard brands.count > 1 else { return ([],0) }
        let releaseKeys=Set(releases.filter{$0.eventID == eventID}.compactMap(\.brandID))
        func hasRelease(_ brand:Brand) -> Bool {
            brand.releaseEventIDs?.contains(eventID) ?? releaseKeys.contains(brand.id)
        }
        func rank(_ brand:Brand) -> UInt64 {
            var hash:UInt64=14695981039346656037
            for byte in (seed+eventID+brand.id).utf8 { hash=(hash ^ UInt64(byte)) &* 1099511628211 }
            return hash
        }
        let sorted=brands.sorted { left,right in
            if hasRelease(left) != hasRelease(right) { return hasRelease(left) }
            let l=rank(left),r=rank(right);return l == r ? left.id < right.id : l < r
        }
        let shown=Array(sorted.prefix(max(0,limit)))
        return (shown,max(0,brands.count-shown.count))
    }
    private static func announcementMatchText(_ text:String) -> String {
        text.folding(options:[.caseInsensitive,.diacriticInsensitive],locale:Locale(identifier:"en_US_POSIX"))
            .filter{$0.isLetter || $0.isNumber}
    }
}
