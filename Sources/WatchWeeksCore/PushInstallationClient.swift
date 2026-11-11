import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum APNSEnvironment: String, Codable, Sendable { case sandbox, production }
public enum PushServiceError: Error, LocalizedError, Equatable {
    case invalidRequest, invalidResponse, http(Int), busy, retryable(Int, Date?), retryLater(Date)
    public var errorDescription: String? {
        switch self {
        case .invalidRequest: "Guide alerts could not be configured safely."
        case .invalidResponse: "The alert service returned an unreadable response. Please retry."
        case .http(409): "This device registration needs recovery. Your existing subscription has not been replaced."
        case .http(429): "Too many attempts. Please try again later."
        case .http: "The alert service is unavailable. Please retry."
        case .busy: "Guide alerts are already connecting."
        case .retryable, .retryLater: "Guide alerts will retry after a short wait. Your saved registration is preserved."
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
    public let state: String
    public let environment: APNSEnvironment
    public let guides: [String]?
}
public protocol PushInstallationService: Sendable {
    func register(request: PushRegistrationRequest, credential: String) async throws -> PushRegistration
    func rotate(id: UUID, credential: String, token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushInstallationState
    func read(id: UUID, credential: String) async throws -> PushInstallationState
    func delete(id: UUID, credential: String) async throws
}

public struct PushRegistrationRequest: Codable, Equatable, Sendable {
        let platform="ios"
        let apns_token: String
        let environment: APNSEnvironment
        let app_version: String
        let os_version: String
        enum CodingKeys: String, CodingKey { case platform,apns_token,environment,app_version,os_version,guides }
        public func encode(to encoder: any Encoder) throws {
            var values=encoder.container(keyedBy:CodingKeys.self)
            try values.encode(platform,forKey:.platform);try values.encode(apns_token,forKey:.apns_token)
            try values.encode(environment,forKey:.environment);try values.encode(app_version,forKey:.app_version)
            try values.encode(os_version,forKey:.os_version);try values.encodeNil(forKey:.guides)
        }
        public init(from decoder: any Decoder) throws {
            let values=try decoder.container(keyedBy:CodingKeys.self)
            guard try values.decode(String.self,forKey:.platform) == "ios", try values.decodeIfPresent([String].self,forKey:.guides) == nil else { throw PushServiceError.invalidRequest }
            apns_token=try values.decode(String.self,forKey:.apns_token)
            environment=try values.decode(APNSEnvironment.self,forKey:.environment)
            app_version=try values.decode(String.self,forKey:.app_version)
            os_version=try values.decode(String.self,forKey:.os_version)
            try validate()
        }
        public func validate() throws {
            guard (64...200).contains(apns_token.utf8.count), apns_token.count % 2 == 0,
                  apns_token.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
                  app_version.utf8.count <= 32, os_version.utf8.count <= 32 else { throw PushServiceError.invalidRequest }
        }
        public var token: Data {
            var result=Data();var index=apns_token.startIndex
            while index < apns_token.endIndex {
                let end=apns_token.index(index,offsetBy:2)
                if let byte=UInt8(apns_token[index..<end],radix:16) { result.append(byte) };index=end
            }
            return result
        }
        public init(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) throws {
            guard (32...100).contains(token.count), appVersion.utf8.count <= 32, osVersion.utf8.count <= 32 else { throw PushServiceError.invalidRequest }
            apns_token=token.map { String(format:"%02x",$0) }.joined()
            self.environment=environment;app_version=appVersion;os_version=osVersion
        }
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
        if http.statusCode == 429 || http.statusCode == 503 {
            var retry: Date?
            if let raw=http.value(forHTTPHeaderField:"Retry-After") {
                if let seconds=Double(raw), seconds.isFinite, seconds >= 0 { retry=Date().addingTimeInterval(seconds) }
                else {
                    let formatter=DateFormatter();formatter.locale=Locale(identifier:"en_US_POSIX");formatter.timeZone=TimeZone(secondsFromGMT:0)
                    formatter.dateFormat="EEE, dd MMM yyyy HH:mm:ss zzz";retry=formatter.date(from:raw)
                }
            }
            throw PushServiceError.retryable(http.statusCode,retry)
        }
        // An HTML routing error is not confirmation that an installation is gone.
        if http.statusCode == 404 && http.mimeType != "application/json" { throw PushServiceError.invalidResponse }
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
    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys];return try encoder.encode(value)
    }
    public func register(request: PushRegistrationRequest, credential: String) async throws -> PushRegistration {
        try request.validate()
        guard credential.utf8.count == 48, Self.validCredential(credential) else { throw PushServiceError.invalidRequest }
        let body=try Self.encode(request)
        let (data,status)=try await self.request("POST",credential:credential,body:body)
        let registration=try JSONDecoder().decode(PushRegistration.self,from:data)
        guard [200,201].contains(status), registration.state == "active", registration.environment == request.environment else { throw PushServiceError.invalidResponse }
        return registration
    }
    public func rotate(id: UUID, credential: String, token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws -> PushInstallationState {
        let pending=try PushRegistrationRequest(token:token,environment:environment,appVersion:appVersion,osVersion:osVersion)
        // PATCH has a strict schema; preserve subscription preferences and omit
        // registration-only platform/guides fields during token rotation.
        let body=try Self.encode(["apns_token":pending.apns_token,"environment":environment.rawValue,
                                  "app_version":appVersion,"os_version":osVersion])
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

/// Stored only in ThisDeviceOnly Keychain. Pending requests include the token
/// solely for exact, authenticated recovery; they are removed after acknowledgement.
public struct PushCredential: Codable, Sendable {
    public var id: UUID?
    public let secret: String
    public var environment: APNSEnvironment
    public var wantsAlerts: Bool
    public var pendingRequest: PushRegistrationRequest?
    public var retryAt: Date?
    public var retryAttempts: Int?
    public init(id: UUID? = nil, secret: String, environment: APNSEnvironment, wantsAlerts: Bool = true,
                pendingRequest: PushRegistrationRequest? = nil) {
        self.id=id;self.secret=secret;self.environment=environment;self.wantsAlerts=wantsAlerts;self.pendingRequest=pendingRequest
    }
    public static func format(randomBytes: Data) throws -> String {
        guard randomBytes.count == 32 else { throw PushServiceError.invalidRequest }
        return "wwpi_" + randomBytes.base64EncodedString().replacingOccurrences(of:"+",with:"-").replacingOccurrences(of:"/",with:"_").replacingOccurrences(of:"=",with:"")
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
    private let makeCredential: @MainActor () throws -> String
    private let now: @MainActor () -> Date
    public init(service: any PushInstallationService, store: any PushCredentialStore,
                makeCredential: @escaping @MainActor () throws -> String = {
                    var generator=SystemRandomNumberGenerator()
                    return try PushCredential.format(randomBytes:Data((0..<32).map { _ in UInt8.random(in:0...255,using:&generator) }))
                }, now: @escaping @MainActor () -> Date = { Date() }) {
        self.service=service;self.store=store;self.makeCredential=makeCredential;self.now=now
    }
    public func hasSavedSubscription() throws -> Bool { try store.load()?.wantsAlerts == true }
    public func installationID() throws -> UUID? { try store.load()?.id }
    public func retryDate() throws -> Date? { try store.load()?.retryAt }
    private func checkBackoff(_ record: PushCredential) throws {
        if let retry=record.retryAt, retry > now() { throw PushServiceError.retryLater(retry) }
    }
    private func failed(_ error: any Error) {
        guard var record=try? store.load() else { state = .off;return }
        state=record.wantsAlerts ? .off : .deletionPending
        if case PushServiceError.retryLater = error { return }
        let retryable: Bool
        var serverRetry: Date?
        if case PushServiceError.retryable(_,let date) = error { retryable=true;serverRetry=date }
        else if case PushServiceError.http(let code) = error { retryable=code == 429 || code >= 500 }
        else { retryable=error is URLError }
        guard retryable else { record.retryAt=nil;try? store.save(record);return }
        let attempt=record.retryAttempts ?? 0
        let interval: TimeInterval=[30,120,600,1800][min(attempt,3)]
        record.retryAt=max(now().addingTimeInterval(interval),serverRetry ?? .distantPast)
        record.retryAttempts=attempt+1
        try? store.save(record)
    }
    private func acknowledged(_ input: PushCredential) throws -> PushCredential {
        var record=input;record.pendingRequest=nil;record.retryAt=nil;record.retryAttempts=nil;record.wantsAlerts=desired
        try store.save(record);return record
    }
    private func complete(_ input: PushCredential) async throws {
        var record=input
        if let pending=record.pendingRequest {
            if let id=record.id {
                _ = try await service.rotate(id:id,credential:record.secret,token:pending.token,environment:pending.environment,appVersion:pending.app_version,osVersion:pending.os_version)
            } else {
                let result=try await service.register(request:pending,credential:record.secret)
                record.id=result.installation_id
            }
            record.environment=pending.environment
            record=try acknowledged(record)
        }
        guard let id=record.id else { throw PushServiceError.invalidResponse }
        if !desired {
            record.wantsAlerts=false;try store.save(record);state = .deletionPending
            try await service.delete(id:id,credential:record.secret);try store.remove();state = .off
        } else { state = .on }
    }
    public func register(token: Data, environment: APNSEnvironment, appVersion: String, osVersion: String) async throws {
        guard !isBusy else { throw PushServiceError.busy }
        let latest=try PushRegistrationRequest(token:token,environment:environment,appVersion:appVersion,osVersion:osVersion)
        if let saved=try store.load(), !saved.wantsAlerts { try await disable() }
        isBusy=true;desired=true;state = .connecting;defer { isBusy=false }
        do {
            var record: PushCredential
            if let saved=try store.load() { record=saved;try checkBackoff(record) }
            else {
                record=PushCredential(secret:try makeCredential(),environment:environment,pendingRequest:latest)
                // Both the credential and exact initial request MUST be durable
                // before even attempting the first POST.
                try store.save(record)
            }
            if record.id == nil {
                let original=record.pendingRequest
                try await complete(record)
                guard desired else { return }
                guard let saved=try store.load() else { throw PushServiceError.invalidResponse }
                record=saved
                if original == latest { return }
            }
            record.pendingRequest=latest;record.wantsAlerts=desired;try store.save(record)
            try await complete(record)
        } catch { failed(error);throw error }
    }
    public func permissionChanged(granted: Bool) async throws { if !granted { try await disable() } }
    public func disable() async throws {
        desired=false
        guard var record=try store.load() else { state=isBusy ? .deletionPending : .off;return }
        record.wantsAlerts=false;try store.save(record);state = .deletionPending
        guard !isBusy else { return }
        isBusy=true;defer { isBusy=false }
        do {
            try checkBackoff(record)
            if let id=record.id {
                try await service.delete(id:id,credential:record.secret);try store.remove();state = .off
            } else { try await complete(record) }
        } catch { failed(error);throw error }
    }
    public func reconcile(allowEnrollment: Bool = true) async throws {
        guard !isBusy else { return }
        guard let record=try store.load() else { state = .off;return }
        if !record.wantsAlerts { try await disable();return }
        desired=true
        if record.id == nil && !allowEnrollment { state = .off;return }
        isBusy=true;defer { isBusy=false }
        do {
            try checkBackoff(record)
            if record.pendingRequest != nil { try await complete(record);return }
            guard let id=record.id else { throw PushServiceError.invalidResponse }
            let remote=try await service.read(id:id,credential:record.secret)
            if remote.state != "active" { try store.remove();state = .off;return }
            if !desired { try await service.delete(id:id,credential:record.secret);try store.remove();state = .off }
            else { state = .on }
        } catch PushServiceError.http(let code) where (code == 404 || code == 410) && record.id != nil && record.pendingRequest == nil {
            try store.remove();state = .off
        } catch { failed(error);throw error }
    }
}
