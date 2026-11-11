import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum APNSEnvironment: String, Codable, Sendable { case sandbox, production }
public enum PushServiceError: Error, LocalizedError, Equatable {
    case invalidRequest, invalidResponse, http(Int), busy
    public var errorDescription: String? {
        switch self {
        case .invalidRequest: "Guide alerts could not be configured safely."
        case .invalidResponse: "The alert service returned an unreadable response. Please retry."
        case .http(409): "This device registration needs recovery. Your existing subscription has not been replaced."
        case .http(429): "Too many attempts. Please try again later."
        case .http: "The alert service is unavailable. Please retry."
        case .busy: "Guide alerts are already connecting."
        }
    }
}
public struct PushInstallationState: Decodable, Sendable {
    public let installation_id: UUID
    public let state: String
    public let environment: APNSEnvironment
    public let guides: [String]?
}
public struct PushRegistration: Decodable, Sendable {
    public let installation_id: UUID
    public let credential: String
    public let state: String
    public let environment: APNSEnvironment
    public let guides: [String]?
}
public protocol PushInstallationService: Sendable {
    func register(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushRegistration
    func rotate(id: UUID, credential: String, token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushInstallationState
    func read(id: UUID, credential: String) async throws -> PushInstallationState
    func delete(id: UUID, credential: String) async throws
}

/// Production calls use a dedicated ephemeral session. Never forward credentials
/// to redirects, persist URL caches, or attach analytics to these requests.
public struct PushInstallationClient: PushInstallationService {
    private let session: URLSession
    public init() {
        let configuration=URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage=nil
        configuration.urlCache=nil
        configuration.httpShouldSetCookies=false
        session=URLSession(configuration:configuration,delegate:RejectPushRedirects(),delegateQueue:nil)
    }
    init(session: URLSession) { self.session=session }
    private struct Body: Encodable {
        let platform="ios"
        let apns_token: String
        let environment: APNSEnvironment
        let app_version: String
        let os_version: String
        enum CodingKeys: String, CodingKey { case platform,apns_token,environment,app_version,os_version,guides }
        func encode(to encoder: any Encoder) throws {
            var values=encoder.container(keyedBy:CodingKeys.self)
            try values.encode(platform,forKey:.platform);try values.encode(apns_token,forKey:.apns_token)
            try values.encode(environment,forKey:.environment);try values.encode(app_version,forKey:.app_version)
            try values.encode(os_version,forKey:.os_version);try values.encodeNil(forKey:.guides)
        }
        init(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) throws {
            guard (32...100).contains(token.count), appVersion.count <= 32, osVersion.count <= 32 else { throw PushServiceError.invalidRequest }
            apns_token=token.map { String(format:"%02x",$0) }.joined()
            self.environment=environment;app_version=appVersion;os_version=osVersion
        }
    }
    private func request(_ method: String, id: UUID? = nil, credential: String? = nil, body: Data? = nil) async throws -> (Data,Int) {
        var url=PublicLinks.home.appendingPathComponent("api/public/push/installations")
        if let id { url.appendPathComponent(id.uuidString.lowercased()) }
        var request=URLRequest(url:url,cachePolicy:.reloadIgnoringLocalCacheData,timeoutInterval:25)
        request.httpMethod=method;request.httpBody=body
        request.setValue("application/json",forHTTPHeaderField:"Accept")
        if body != nil { request.setValue("application/json",forHTTPHeaderField:"Content-Type") }
        if let credential {
            guard Self.validCredential(credential) else { throw PushServiceError.invalidRequest }
            request.setValue("Bearer " + credential,forHTTPHeaderField:"Authorization")
        }
        let (data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse, http.url?.host == PublicLinks.home.host,
              http.url?.scheme == "https", data.count <= 64_000 else { throw PushServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw PushServiceError.http(http.statusCode) }
        if http.statusCode != 204 {
            guard http.mimeType == "application/json" else { throw PushServiceError.invalidResponse }
        }
        return (data,http.statusCode)
    }
    private static func validCredential(_ value: String) -> Bool {
        value.hasPrefix("wwpi_") && (6...512).contains(value.utf8.count) &&
            value.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "-" }
    }
    public func register(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushRegistration {
        let body=try JSONEncoder().encode(Body(token:token,environment:environment,appVersion:appVersion,osVersion:osVersion))
        let (data,status)=try await request("POST",body:body)
        let registration=try JSONDecoder().decode(PushRegistration.self,from:data)
        guard status == 201, registration.state == "active", registration.environment == environment,
              Self.validCredential(registration.credential) else { throw PushServiceError.invalidResponse }
        return registration
    }
    public func rotate(id: UUID, credential: String, token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushInstallationState {
        let body=try JSONEncoder().encode(Body(token:token,environment:environment,appVersion:appVersion,osVersion:osVersion))
        let (data,status)=try await request("PATCH",id:id,credential:credential,body:body)
        let result=try JSONDecoder().decode(PushInstallationState.self,from:data)
        guard status == 200, result.installation_id == id, result.state == "active", result.environment == environment else { throw PushServiceError.invalidResponse }
        return result
    }
    public func read(id: UUID, credential: String) async throws -> PushInstallationState {
        let (data,status)=try await request("GET",id:id,credential:credential)
        let result=try JSONDecoder().decode(PushInstallationState.self,from:data)
        guard status == 200, result.installation_id == id else { throw PushServiceError.invalidResponse }
        return result
    }
    public func delete(id: UUID, credential: String) async throws {
        do {
            let (_,status)=try await request("DELETE",id:id,credential:credential)
            guard status == 204 else { throw PushServiceError.invalidResponse }
        } catch PushServiceError.http(404) { return }
    }
}
private final class RejectPushRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) { completionHandler(nil) }
}

/// Only the platform adapter may persist this object, in ThisDeviceOnly Keychain.
public struct PushCredential: Codable, Sendable {
    public let id: UUID
    public let secret: String
    public let environment: APNSEnvironment
    public var wantsAlerts: Bool
    public init(id: UUID, secret: String, environment: APNSEnvironment, wantsAlerts: Bool = true) {
        self.id=id;self.secret=secret;self.environment=environment;self.wantsAlerts=wantsAlerts
    }
}
@MainActor public protocol PushCredentialStore: AnyObject {
    func load() throws -> PushCredential?
    func save(_ credential: PushCredential) throws
    func remove() throws
}
@MainActor public final class PushSubscription {
    public enum State: Equatable { case off, on, connecting, deletionPending }
    public private(set) var state: State = .off
    public private(set) var isBusy=false
    private var desired=false
    private let service: any PushInstallationService
    private let store: any PushCredentialStore
    public init(service: any PushInstallationService, store: any PushCredentialStore) { self.service=service;self.store=store }
    public func hasSavedSubscription() throws -> Bool { try store.load()?.wantsAlerts == true }
    public func register(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws {
        guard !isBusy else { throw PushServiceError.busy }
        isBusy=true;desired=true;state = .connecting
        defer { isBusy=false }
        do {
            var saved=try store.load()
            if let old=saved, !old.wantsAlerts {
                try await service.delete(id:old.id,credential:old.secret);try store.remove();saved=nil
            }
            let record: PushCredential
            if let saved {
                _ = try await service.rotate(id:saved.id,credential:saved.secret,token:token,environment:environment,appVersion:appVersion,osVersion:osVersion)
                record=PushCredential(id:saved.id,secret:saved.secret,environment:environment,wantsAlerts:desired)
            } else {
                let result=try await service.register(token:token,environment:environment,appVersion:appVersion,osVersion:osVersion)
                record=PushCredential(id:result.installation_id,secret:result.credential,environment:environment,wantsAlerts:desired)
            }
            do { try store.save(record) }
            catch {
                // A server subscription must not appear On when Keychain failed.
                try? await service.delete(id:record.id,credential:record.secret)
                throw error
            }
            if !desired {
                state = .deletionPending
                try await service.delete(id:record.id,credential:record.secret);try store.remove();state = .off
            } else { state = .on }
        } catch {
            if let record=try? store.load(), !record.wantsAlerts { state = .deletionPending }
            else { state = .off }
            throw error
        }
    }
    public func disable() async throws {
        desired=false
        if var record=try store.load() {
            record.wantsAlerts=false;try store.save(record);state = .deletionPending
            // In-flight registration will acknowledge and remove its own result.
            guard !isBusy else { return }
            try await service.delete(id:record.id,credential:record.secret);try store.remove();state = .off
        } else { state = isBusy ? .deletionPending : .off }
    }
    public func reconcile() async throws {
        guard !isBusy else { return }
        guard let record=try store.load() else { state = .off; return }
        desired=record.wantsAlerts
        if !record.wantsAlerts { try await disable(); return }
        isBusy=true;defer { isBusy=false }
        do {
            let remote=try await service.read(id:record.id,credential:record.secret)
            if remote.state != "active" { try store.remove();state = .off;return }
            if !desired {
                try await service.delete(id:record.id,credential:record.secret);try store.remove();state = .off
            } else { state = .on }
        } catch PushServiceError.http(let code) where code == 404 || code == 410 {
            try store.remove();state = .off
        }
    }
}
