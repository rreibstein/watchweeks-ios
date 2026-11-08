import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
final class MockProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var mime = "application/json"
    nonisolated(unsafe) static var bodies: [String: Data] = [:]
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": Self.mime])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.bodies[request.url!.path] ?? Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class NetworkingTests: XCTestCase {
    func service(status: Int, mime: String) -> PublicGuideService {
        MockProtocol.status=status; MockProtocol.mime=mime
        let config=URLSessionConfiguration.ephemeral; config.protocolClasses=[MockProtocol.self]
        return PublicGuideService(session:URLSession(configuration:config))
    }
    func testVerifiedServiceLoadsIndexAndBothDetails() async throws {
        func fixture(_ name: String) throws -> Data { try Data(contentsOf: Bundle.module.url(forResource:name,withExtension:"json",subdirectory:"Fixtures")!) }
        var index=try JSONSerialization.jsonObject(with:fixture("index")) as! [String:Any]
        index["guides"]=(index["guides"] as! [[String:Any]]).filter { ["singapore-2026","austin-2026"].contains($0["id"] as! String) }
        MockProtocol.bodies=["/api/public/guides":try JSONSerialization.data(withJSONObject:index),"/api/public/guides/singapore-2026":try fixture("singapore"),"/api/public/guides/austin-2026":try fixture("austin")]
        defer { MockProtocol.bodies=[:] }
        let result=try await service(status:200,mime:"application/json").guides()
        XCTAssertEqual(Set(result.map(\.id)),Set(["singapore-2026","austin-2026"]))
        XCTAssertTrue(result.allSatisfy{!$0.brands.isEmpty && !$0.releases.isEmpty})
    }
    func testHTTPFailure() async { do { _ = try await service(status:503,mime:"application/json").guides(); XCTFail() } catch { XCTAssertEqual(error as? FeedError,.http(503)) } }
    func testHTMLFallbackRejected() async { do { _ = try await service(status:200,mime:"text/html").guides(); XCTFail() } catch { XCTAssertEqual(error as? FeedError,.invalidContentType) } }
    func testMalformedIndexIsRejected() async { do { _ = try await service(status:200,mime:"application/json").guides(); XCTFail() } catch { XCTAssertTrue(error is DecodingError) } }
}
