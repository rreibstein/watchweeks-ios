import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
public enum FeedError: Error, LocalizedError, Equatable {
    case contractUnverified, invalidResponse, http(Int), invalidContentType, oversizedResponse
    public var errorDescription: String? { switch self {
    case .contractUnverified: "The public feed integration is awaiting verification. No guide data has been substituted."
    case .invalidResponse: "The guide service returned an unreadable response."
    case .http(let status): "The guide service returned HTTP \(status). Please try again later."
    case .invalidContentType: "The guide service did not return JSON."
    case .oversizedResponse: "The guide response is too large to load safely."
    } }
}
public protocol GuideService: Sendable { func guides() async throws -> [Guide] }
public protocol FeedContract: Sendable { func decodeIndex(_ data: Data) throws -> [Guide] }
// Intentionally fail closed until actual public responses can be inspected.
// Do not wire internal cache models directly to an assumed backend envelope.
public struct UnverifiedContract: FeedContract {
    public init() {}
    public func decodeIndex(_ data: Data) throws -> [Guide] { throw FeedError.contractUnverified }
}
public struct PublicGuideService: GuideService {
    private let session: URLSession
    private let contract: any FeedContract
    public init(session: URLSession = .shared, contract: any FeedContract = UnverifiedContract()) { self.session=session; self.contract=contract }
    public func guides() async throws -> [Guide] {
        var request = URLRequest(url: PublicLinks.home.appendingPathComponent("api/public/guides"))
        request.setValue("application/json", forHTTPHeaderField: "Accept"); request.timeoutInterval = 25
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FeedError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw FeedError.http(http.statusCode) }
        guard http.mimeType == "application/json" || http.mimeType?.hasSuffix("+json") == true else { throw FeedError.invalidContentType }
        guard data.count <= 20_000_000 else { throw FeedError.oversizedResponse }
        return try contract.decodeIndex(data)
    }
}
public struct GuideLoad: Sendable {
    public let guides: [Guide]
    public let fetchedAt: Date
    public let stale: Bool
    public let warning: String?
}
public struct GuideRepository: Sendable {
    let service: any GuideService
    let store: LocalStore
    public init(service: any GuideService, store: LocalStore) { self.service=service; self.store=store }
    public func load() async throws -> GuideLoad {
        do {
            let guides = try await service.guides()
            try Self.validate(guides)
            let date = Date()
            do { try await store.saveGuides(guides, now: date) }
            catch { return GuideLoad(guides: guides, fetchedAt: date, stale: false, warning: "Guides loaded but could not be saved for offline use.") }
            return GuideLoad(guides: guides, fetchedAt: date, stale: false, warning: nil)
        } catch {
            if let snapshot = try? await store.snapshot() {
                return GuideLoad(guides: snapshot.guides, fetchedAt: snapshot.fetchedAt, stale: true, warning: error.localizedDescription)
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
