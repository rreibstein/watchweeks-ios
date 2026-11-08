import Foundation
import XCTest
@testable import WatchWeeksCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
final class MockProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var mime = "application/json"
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": Self.mime])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
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
    func testHTTPFailure() async { do { _ = try await service(status:503,mime:"application/json").guides(); XCTFail() } catch { XCTAssertEqual(error as? FeedError,.http(503)) } }
    func testHTMLFallbackRejected() async { do { _ = try await service(status:200,mime:"text/html").guides(); XCTFail() } catch { XCTAssertEqual(error as? FeedError,.invalidContentType) } }
    func testUnverifiedJSONIsNotAssumedProductionData() async { do { _ = try await service(status:200,mime:"application/json").guides(); XCTFail() } catch { XCTAssertEqual(error as? FeedError,.contractUnverified) } }
}
