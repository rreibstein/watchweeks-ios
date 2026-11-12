import Foundation
import FoundationXML
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct ProgramSession: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let date: String
    public let start: String
    public let end: String
    public let title: String
    public let category: String?
    public let room: String?
    public let description: String?
    public let participants: [String]
    public var invitationOnly: Bool { title.localizedCaseInsensitiveContains("invitation only") }
    public var day: EventDay { EventDay(date:date,open:start,close:end,access:invitationOnly ? "invitation" : nil) }
}

public struct EventProgram: Codable, Equatable, Sendable {
    public let guideID: String
    public let eventID: String
    public let timeZone: String
    public let sourceURL: URL
    public let fetchedAt: Date
    public let sessions: [ProgramSession]
    public var dates: [String] { Array(Set(sessions.map(\.date))).sorted() }
    public func matching(day: String?, query: String) -> [ProgramSession] {
        sessions.filter { item in
            (day == nil || item.date == day) && (query.isEmpty ||
                ([item.title,item.category,item.room,item.description].compactMap{$0}+item.participants)
                    .joined(separator:" ").localizedCaseInsensitiveContains(query))
        }.sorted { ($0.date,$0.start,$0.id) < ($1.date,$1.start,$1.id) }
    }
    public static func source(guideID: String, eventID: String) -> URL? {
        // This is the verified published page, not an invented public API.
        guard guideID == "singapore-2026", eventID == "iamwatch" else { return nil }
        return URL(string:"https://watchweeks.com/singapore/event/iamwatch")!
    }
}

/// Narrow adapter for the site's published Program section while API v1 lacks
/// talks/workshops. It runs no scripts, reads no account state, and fails closed
/// if the section/count/times change shape, preserving the last-good cached copy.
public enum PublishedProgramParser {
    public static func parse(_ html: String, guideID: String, eventID: String,
                             timeZone: String, fetchedAt: Date = .now) throws -> EventProgram {
        guard html.utf8.count <= 2_000_000, let source=EventProgram.source(guideID:guideID,eventID:eventID),
              TimeZone(identifier:timeZone) != nil,
              let expression=try? NSRegularExpression(pattern:"<section\\b[^>]*aria-label=\"Program\"[^>]*>.*?</section>",options:[.dotMatchesLineSeparators]),
              let match=expression.firstMatch(in:html,range:NSRange(html.startIndex...,in:html)),
              let range=Range(match.range,in:html) else { throw FeedError.invalidResponse }
        var section=String(html[range])
        guard !section.localizedCaseInsensitiveContains("<!DOCTYPE"),
              !section.localizedCaseInsensitiveContains("<!ENTITY") else { throw FeedError.invalidResponse }
        // XML supports numeric entities and amp/lt/gt/quot/apos already.
        for (name,code) in ["nbsp":160,"ndash":8211,"mdash":8212,"rsquo":8217,"lsquo":8216,"rdquo":8221,"ldquo":8220] {
            section=section.replacingOccurrences(of:"&\(name);",with:"&#\(code);")
        }
        let delegate=ProgramXML(guideID:guideID,eventID:eventID,timeZone:timeZone)
        let parser=XMLParser(data:Data(section.utf8));parser.delegate=delegate
        parser.shouldResolveExternalEntities=false
        guard parser.parse(), !delegate.invalid, !delegate.sessions.isEmpty,
              delegate.sessions.count <= 300, delegate.expectedCount == delegate.sessions.count,
              Set(delegate.sessions.map(\.id)).count == delegate.sessions.count else { throw FeedError.invalidResponse }
        return EventProgram(guideID:guideID,eventID:eventID,timeZone:timeZone,sourceURL:source,
                            fetchedAt:fetchedAt,sessions:delegate.sessions)
    }
}

private final class ProgramXML: NSObject, XMLParserDelegate {
    struct Frame { let name: String; let classes: String; var text=""; var people=false }
    let guideID: String, eventID: String, zone: String
    var stack:[Frame]=[], sessions:[ProgramSession]=[]
    var currentDate: String?, expectedCount: Int?, invalid=false, inArticle=false
    var title="", timing="", room: String?, descriptionText: String?, people:[String]=[]
    init(guideID:String,eventID:String,timeZone:String) { self.guideID=guideID;self.eventID=eventID;zone=timeZone }
    func parser(_ parser:XMLParser,didStartElement name:String,namespaceURI:String?,qualifiedName:String?,attributes:[String:String]) {
        if name == "article" { inArticle=true;title="";timing="";room=nil;descriptionText=nil;people=[] }
        let classes=attributes["class"] ?? ""
        if name == "span", classes.contains("uppercase"), classes.contains("font-bold"),
           let index=stack.lastIndex(where:{$0.name == "div" && $0.classes == "text-sm"}) { stack[index].people=true }
        stack.append(Frame(name:name,classes:classes))
    }
    func parser(_ parser:XMLParser,foundCharacters text:String) {
        for index in stack.indices { stack[index].text += text }
    }
    func parser(_ parser:XMLParser,didEndElement name:String,namespaceURI:String?,qualifiedName:String?) {
        guard let frame=stack.popLast() else { invalid=true;return }
        let text=Self.normalized(frame.text)
        if name == "h2" {
            let digits=text.split(separator:"(").last?.split(separator:")").first
            expectedCount=digits.flatMap{Int($0)}
        }
        if name == "h3", !inArticle { currentDate=date(text) }
        guard inArticle else { return }
        if name == "h4" { title=text }
        if name == "p", frame.classes.contains("font-mono") { timing=text }
        if name == "p", frame.classes.contains("flex") { room=text.isEmpty ? nil : text }
        if name == "p", frame.classes.contains("whitespace-pre-line") { descriptionText=frame.text.trimmingCharacters(in:.whitespacesAndNewlines) }
        if name == "div", frame.people, !text.isEmpty { people.append(text) }
        if name == "article" {
            inArticle=false
            let pieces=timing.components(separatedBy:" · ")
            let hours=(pieces.first ?? "").components(separatedBy:"–")
            guard let date=currentDate, hours.count == 2, let start=time(hours[0]), let end=time(hours[1]),
                  start != end, !title.isEmpty else { invalid=true;return }
            sessions.append(ProgramSession(id:[guideID,eventID,date,start,title].joined(separator:"|"),
                date:date,start:start,end:end,title:title,category:pieces.count > 1 ? pieces.dropFirst().joined(separator:" · ") : nil,
                room:room,description:descriptionText,participants:people))
        }
    }
    private static func normalized(_ text:String) -> String { text.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ") }
    private func date(_ label:String) -> String? {
        let parts=label.split(separator:" ")
        let months=["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        guard parts.count == 3, let month=months.firstIndex(of:String(parts[1])),let day=Int(parts[2]),
              let year=Int(guideID.suffix(4)) else { return nil }
        let value=String(format:"%04d-%02d-%02d",year,month+1,day)
        return EventDates.parse(value,zone:zone) == nil ? nil : value
    }
    private func time(_ value:String) -> String? {
        let parts=Self.normalized(value).split(separator:" ")
        guard parts.count == 2, ["AM","PM"].contains(parts[1]) else { return nil }
        let clock=parts[0].split(separator:":",omittingEmptySubsequences:false)
        guard (1...2).contains(clock.count), let hour=Int(clock[0]), (1...12).contains(hour),
              let minute=clock.count == 2 ? Int(clock[1]) : 0, (0...59).contains(minute) else { return nil }
        return String(format:"%02d:%02d",hour % 12 + (parts[1] == "PM" ? 12 : 0),minute)
    }
}

public protocol EventProgramService: Sendable {
    func fetch(guide:Guide,event:Event) async throws -> EventProgram
}
public struct PublishedEventProgramService: EventProgramService {
    private let session:URLSession
    public init(session:URLSession = .shared) { self.session=session }
    public func fetch(guide:Guide,event:Event) async throws -> EventProgram {
        guard let url=EventProgram.source(guideID:guide.id,eventID:event.id) else { throw FeedError.invalidResponse }
        var request=URLRequest(url:url,cachePolicy:.reloadIgnoringLocalCacheData,timeoutInterval:20)
        request.setValue("text/html",forHTTPHeaderField:"Accept")
        let (data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse else { throw FeedError.invalidResponse }
        guard http.statusCode == 200 else { throw FeedError.http(http.statusCode) }
        guard http.url == url, http.mimeType == "text/html", data.count <= 2_000_000,
              let html=String(data:data,encoding:.utf8) else { throw FeedError.invalidResponse }
        return try PublishedProgramParser.parse(html,guideID:guide.id,eventID:event.id,timeZone:guide.timeZone)
    }
}
public struct ProgramLoad: Sendable { public let program:EventProgram;public let stale:Bool }
public struct EventProgramRepository: Sendable {
    private let store:LocalStore
    private let service:any EventProgramService
    public init(store:LocalStore,service:any EventProgramService = PublishedEventProgramService()) { self.store=store;self.service=service }
    public func load(guide:Guide,event:Event) async throws -> ProgramLoad {
        do {
            let program=try await service.fetch(guide:guide,event:event)
            do { try await store.saveProgram(program);return ProgramLoad(program:program,stale:false) }
            catch { return ProgramLoad(program:program,stale:true) }
        } catch {
            if GuideRefreshFailure.isCancellation(error) { throw CancellationError() }
            if let saved=try await store.program(guideID:guide.id,eventID:event.id) { return ProgramLoad(program:saved,stale:true) }
            throw error
        }
    }
}
