import Foundation

/// Editorial titles verified against watchweeks.com. No launch dates are invented.
public struct ForthcomingGuide: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    private let terms: [String]
    public static let announced: [ForthcomingGuide] = [
        .init(id:"geneva",title:"Geneva (W&W)",terms:["geneva"]),
        .init(id:"bwd",title:"British Watchmakers’ Day",terms:["british-watchmakers","british watchmakers","bwd"]),
        .init(id:"las-vegas",title:"Las Vegas",terms:["las-vegas","las vegas"])
    ]
    public static func awaitingPublication(in guides: [Guide]) -> [ForthcomingGuide] {
        announced.filter { upcoming in
            !guides.contains { guide in
                let eventNames = upcoming.id == "bwd" ? guide.events.map(\.name) : []
                let identity=([guide.id,guide.city]+eventNames).joined(separator:" ").lowercased()
                return upcoming.terms.contains(where:identity.contains)
            }
        }
    }
}

/// Proposed push v1 contract. Treat all payload URLs as untrusted; route using
/// only a bounded ID that will be looked up in the authoritative public feed.
public enum GuidePublicationPush {
    public static func guideID(type: String?, version: Int?, id: String?) -> String? {
        guard type == "guide_published", version == 1, let id, !id.isEmpty, id.utf8.count <= 128,
              id.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }) else { return nil }
        return id
    }
}
