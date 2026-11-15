import Foundation

public struct GuideSnapshot: Codable, Sendable { public let fetchedAt: Date; public let guides: [Guide] }
public actor LocalStore {
    private let directory: URL
    public init(directory: URL) { self.directory = directory }
    private func read<T: Decodable>(_ file: String, as: T.Type) throws -> T? {
        let url = directory.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
    private func write<T: Encodable>(_ value: T, file: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: directory.appendingPathComponent(file), options: .atomic)
    }
    public func snapshot() throws -> GuideSnapshot? {
        guard let saved = try read("guides-v1.json", as: GuideSnapshot.self) else { return nil }
        // Decodable checks types, not stable IDs. Apply the feed's invariants
        // before cached records reach SwiftUI lists or dictionary initializers.
        try GuideRepository.validate(saved.guides)
        return saved
    }
    public func program(guideID:String,eventID:String) throws -> EventProgram? {
        try read("event-programs-v1.json",as:[EventProgram].self)?.first { $0.guideID == guideID && $0.eventID == eventID }
    }
    public func saveProgram(_ program:EventProgram) throws {
        var saved=try read("event-programs-v1.json",as:[EventProgram].self) ?? []
        saved.removeAll { $0.guideID == program.guideID && $0.eventID == program.eventID }
        saved.append(program);try write(saved,file:"event-programs-v1.json")
    }
    public func upcoming() throws -> UpcomingGuideFeed? { try read("upcoming-v1.json",as:UpcomingGuideFeed.self) }
    public func saveUpcoming(_ feed: UpcomingGuideFeed) throws { try feed.validate(); try write(feed,file:"upcoming-v1.json") }
    public func rememberedGuides() throws -> [Guide] {
        if let saved = try read("guide-library-v1.json", as: [Guide].self) {
            try GuideRepository.validate(saved)
            return saved
        }
        return try snapshot()?.guides ?? []
    }
    public func saveGuides(_ guides: [Guide], now: Date = Date()) throws {
        try GuideRepository.validate(guides)
        // A successful refresh may repair an invalid public-data cache. Retain
        // valid older editions for My list, without touching saved selections.
        let previous = try read("guide-library-v1.json", as: [Guide].self)
            ?? read("guides-v1.json", as: GuideSnapshot.self)?.guides ?? []
        var library: [String: Guide] = [:]
        for guide in previous where (try? GuideRepository.validate([guide])) != nil { library[guide.id] = guide }
        for guide in guides { library[guide.id] = guide }
        try write(library.values.sorted { $0.id < $1.id }, file: "guide-library-v1.json")
        try write(GuideSnapshot(fetchedAt: now, guides: guides), file: "guides-v1.json")
    }
    public func selections() throws -> [SelectionKey: Selection] { try read("selections-v1.json", as: [SelectionKey: Selection].self) ?? [:] }
    public func saveSelections(_ selections: [SelectionKey: Selection]) throws { try write(selections, file: "selections-v1.json") }
}
