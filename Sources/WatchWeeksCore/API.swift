import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
public enum FeedError: Error, LocalizedError, Equatable {
    case invalidResponse, http(Int), invalidContentType, oversizedResponse
    public var errorDescription: String? { switch self {
    case .invalidResponse: "The guide service returned an unreadable response."
    case .http(let status): "The guide service returned HTTP \(status). Please try again later."
    case .invalidContentType: "The guide service did not return JSON."
    case .oversizedResponse: "The guide response is too large to load safely."
    } }
}
public struct GuideFetch: Sendable {
    public let guides: [Guide]
    public let failedIDs: Set<String>
    public let publishedIDs: Set<String>
    public init(guides: [Guide], failedIDs: Set<String> = [], publishedIDs: Set<String>? = nil) {
        self.guides=guides; self.failedIDs=failedIDs; self.publishedIDs=publishedIDs ?? Set(guides.map(\.id))
    }
}
public protocol GuideService: Sendable {
    func guides() async throws -> [Guide]
    func fetch(retaining cached: [Guide]) async throws -> GuideFetch
}
public extension GuideService {
    func fetch(retaining cached: [Guide]) async throws -> GuideFetch { GuideFetch(guides: try await guides()) }
}
public struct PublicGuideService: GuideService {
    private let session: URLSession
    public init(session: URLSession = .shared) { self.session=session }
    private func json(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse else { throw FeedError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw FeedError.http(http.statusCode) }
        guard http.mimeType == "application/json" || http.mimeType?.hasSuffix("+json") == true else { throw FeedError.invalidContentType }
        guard data.count <= 20_000_000 else { throw FeedError.oversizedResponse }; return data
    }
    public func guides() async throws -> [Guide] {
        try await fetch(retaining: []).guides
    }
    public func fetch(retaining cached: [Guide]) async throws -> GuideFetch {
        let index=try JSONDecoder().decode(PublicIndex.self,from:await json(PublicLinks.home.appendingPathComponent("api/public/guides")))
        guard index.v == 1, Set(index.guides.map(\.id)).count == index.guides.count else { throw FeedError.invalidResponse }
        var results:[Guide]=[]
        var failed: Set<String>=[]
        var firstFailure: (any Error)?
        for header in index.guides {
            guard let url=PublicLinks.apiGuide(header.id) else { throw FeedError.invalidResponse }
            do {
                let detail = try JSONDecoder().decode(PublicDetail.self, from: await json(url))
                guard detail.guide.id == header.id else { throw FeedError.invalidResponse }
                results.append(try detail.model())
            } catch {
                try Task.checkCancellation()
                failed.insert(header.id); firstFailure = firstFailure ?? error
                if let lastGood=cached.first(where: { $0.id == header.id }) { results.append(lastGood) }
            }
        }
        if !index.guides.isEmpty && results.isEmpty { throw firstFailure ?? FeedError.invalidResponse }
        return GuideFetch(guides:results,failedIDs:failed,publishedIDs:Set(index.guides.map(\.id)))
    }
    public func upcoming() async throws -> UpcomingGuideFeed {
        let feed=try JSONDecoder().decode(UpcomingGuideFeed.self,from:await json(PublicLinks.home.appendingPathComponent("api/public/guides/upcoming")))
        try feed.validate(); return feed
    }
}
public struct GuideLoad: Sendable {
    public let guides: [Guide]
    public let fetchedAt: Date
    public let stale: Bool
    public let warning: String?
    public let publishedIDs: Set<String>
}
public struct GuideRepository: Sendable {
    let service: any GuideService
    let store: LocalStore
    public init(service: any GuideService, store: LocalStore) { self.service=service; self.store=store }
    public func load() async throws -> GuideLoad {
        do {
            let snapshot=try? await store.snapshot()
            let fetch = try await service.fetch(retaining:snapshot?.guides ?? [])
            let guides=fetch.guides
            try Self.validate(guides)
            let stale = !fetch.failedIDs.isEmpty
            // Keep the conservative timestamp while any last-good detail is retained.
            let date = stale ? (snapshot?.fetchedAt ?? Date()) : Date()
            let warning = stale ? "Some guides could not refresh. Last saved content remains available; retrying shortly." : nil
            do { try await store.saveGuides(guides, now: date) }
            catch { return GuideLoad(guides: guides, fetchedAt: date, stale: stale, warning: "Guides loaded but could not be saved for offline use.",publishedIDs:fetch.publishedIDs) }
            return GuideLoad(guides: guides, fetchedAt: date, stale: stale, warning: warning,publishedIDs:fetch.publishedIDs)
        } catch {
            try Task.checkCancellation()
            if let snapshot = try? await store.snapshot() {
                return GuideLoad(guides: snapshot.guides, fetchedAt: snapshot.fetchedAt, stale: true, warning: error.localizedDescription,publishedIDs:[])
            }
            throw error
        }
    }
    public static func validate(_ guides: [Guide]) throws {
        guard Set(guides.map(\.id)).count == guides.count else { throw FeedError.invalidResponse }
        for g in guides {
            guard !g.id.isEmpty, !g.city.isEmpty, TimeZone(identifier: g.timeZone) != nil,
                  Set(g.brands.map(\.id)).count == g.brands.count,
                  Set(g.events.map(\.id)).count == g.events.count,
                  Set(g.releases.map(\.id)).count == g.releases.count,
                  g.brands.allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty }),
                  g.events.allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty }),
                  g.releases.allSatisfy({ !$0.id.isEmpty && !$0.title.isEmpty }) else { throw FeedError.invalidResponse }
        }
    }
}
