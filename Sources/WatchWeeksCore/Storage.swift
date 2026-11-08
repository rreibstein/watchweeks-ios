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
    public func snapshot() throws -> GuideSnapshot? { try read("guides-v1.json", as: GuideSnapshot.self) }
    public func rememberedGuides() throws -> [Guide] { try read("guide-library-v1.json", as: [Guide].self) ?? snapshot()?.guides ?? [] }
    public func saveGuides(_ guides: [Guide], now: Date = Date()) throws {
        let previous = try rememberedGuides()
        var library: [String: Guide] = [:]
        for guide in previous + guides { library[guide.id] = guide }
        try write(library.values.sorted { $0.id < $1.id }, file: "guide-library-v1.json")
        try write(GuideSnapshot(fetchedAt: now, guides: guides), file: "guides-v1.json")
    }
    public func selections() throws -> [SelectionKey: Selection] { try read("selections-v1.json", as: [SelectionKey: Selection].self) ?? [:] }
    public func saveSelections(_ selections: [SelectionKey: Selection]) throws { try write(selections, file: "selections-v1.json") }
}
