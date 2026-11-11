import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum GuideRefreshFailure {
    public static func isCancellation(_ error: any Error) -> Bool {
        if error is CancellationError { return true }
        let value=error as NSError
        return value.domain == "Swift.CancellationError" ||
            (value.domain == NSURLErrorDomain && value.code == URLError.cancelled.rawValue)
    }
    public static func message(for error: any Error) -> String? {
        if isCancellation(error) { return nil }
        if error is URLError { return "Guides couldn’t refresh. Check your connection and try again. Saved guides and selections remain available." }
        return "Guide updates are temporarily unavailable. Please try again. Your saved guides and selections have been kept."
    }
}
