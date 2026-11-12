import XCTest
@testable import WatchWeeksCore

final class EventProgramTests:XCTestCase {
    private func html() throws -> String {
        try String(contentsOf:XCTUnwrap(Bundle.module.url(forResource:"iamwatch-program-2026-11-12",withExtension:"html",subdirectory:"Fixtures")),encoding:.utf8)
    }
    private func program(_ html:String? = nil) throws -> EventProgram {
        try PublishedProgramParser.parse(try html ?? self.html(),guideID:"singapore-2026",eventID:"iamwatch",timeZone:"Asia/Singapore",fetchedAt:Date(timeIntervalSince1970:1000))
    }
    func testPublishedSiteProgramAllTwentyFiveSessionsAndAccessLabels() throws {
        let p=try program()
        XCTAssertEqual(p.sessions.count,25)
        XCTAssertEqual(p.dates,["2026-11-12","2026-11-13","2026-11-14","2026-11-15"])
        XCTAssertEqual(p.sessions.filter(\.invitationOnly).count,2)
        let ogs=try XCTUnwrap(p.sessions.first{$0.title == "The OGs"})
        XCTAssertEqual(ogs.start,"09:00");XCTAssertEqual(ogs.end,"10:00");XCTAssertEqual(ogs.room,"Penthouse")
        XCTAssertTrue(ogs.participants.joined().contains("Kari Voutilainen"))
        XCTAssertTrue(ogs.description?.contains("No agenda") == true)
        XCTAssertEqual(Set(p.sessions.map(\.id)).count,25)
    }
    func testDaysSearchAndSingaporeTimesDoNotFollowPhoneTimeZone() throws {
        let p=try program(), friday=p.matching(day:"2026-11-13",query:"")
        XCTAssertEqual(friday.count,8)
        XCTAssertEqual(p.matching(day:"2026-11-13",query:"KARI").map(\.title),["The OGs"])
        let start=try XCTUnwrap(LocalSchedule.interval(friday[0].day,zone:p.timeZone)?.lowerBound)
        XCTAssertEqual(ISO8601DateFormatter().string(from:start),"2026-11-13T01:00:00Z")
        XCTAssertEqual(p.matching(day:"2026-11-14",query:"Sunset").first?.end,"22:00")
    }
    func testParserRejectsPartialBadOrUnsupportedContentWithoutGuessing() throws {
        let original=try html()
        for bad in [original.replacingOccurrences(of:"<!-- -->25<!-- -->",with:"26"),
                    original.replacingOccurrences(of:"2 PM–5 PM",with:"unknown"),
                    "<html>Login or bot challenge</html>",
                    original.replacingOccurrences(of:"<article",with:"<!ENTITY surprise SYSTEM 'file:///etc/passwd'><article")] {
            XCTAssertThrowsError(try program(bad))
        }
        XCTAssertNil(EventProgram.source(guideID:"singapore-2027",eventID:"iamwatch"))
        XCTAssertNil(EventProgram.source(guideID:"miami-2026",eventID:"coconut-grove"))
    }
    func testStableIdentityDoesNotDependOnEditedDescriptions() throws {
        let html=try html(), first=try program(html)
        let edited=try program(html.replacingOccurrences(of:"No agenda, no formal discussion.",with:"Updated public description."))
        XCTAssertEqual(first.sessions.map(\.id),edited.sessions.map(\.id))
    }
    func testDealerSortingSearchAndEventIsolation() throws {
        let json=Data("[{\"name\":\"Zebra\",\"eventId\":\"coconut-grove\"},{\"name\":\"Aaron Faber\",\"eventId\":\"coconut-grove\"},{\"name\":\"Another\",\"eventId\":\"other\"}]".utf8)
        let g=Guide(id:"miami-2026",city:"Miami",timeZone:"America/New_York",dealers:try JSONDecoder().decode([Dealer].self,from:json))
        let e=Event(id:"coconut-grove",name:"Coconut Grove")
        XCTAssertEqual(g.dealers(at:e).map(\.name),["Aaron Faber","Zebra"])
        XCTAssertEqual(g.dealers(at:e,matching:"faber").map(\.name),["Aaron Faber"])
    }
    func testOfflineRepositoryRetainsProgramAndPersonalSelections() async throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store=LocalStore(directory:root)
        defer { try? FileManager.default.removeItem(at:root) }
        let p=try program(), g=Guide(id:p.guideID,city:"Singapore",timeZone:p.timeZone), e=Event(id:p.eventID,name:"IAMWATCH")
        let key=SelectionKey(guideID:g.id,brandID:"maker")
        let saved=[key:Selection(interest:.mustSee,seen:true)]
        try await store.saveSelections(saved)
        let online=try await EventProgramRepository(store:store,service:ProgramServiceStub(result:p)).load(guide:g,event:e)
        XCTAssertFalse(online.stale)
        let offline=try await EventProgramRepository(store:store,service:ProgramServiceStub(result:nil)).load(guide:g,event:e)
        XCTAssertTrue(offline.stale);XCTAssertEqual(offline.program,p)
        let selections=try await store.selections();XCTAssertEqual(selections,saved)
    }
}
private struct ProgramServiceStub:EventProgramService {
    let result:EventProgram?
    func fetch(guide:Guide,event:Event) async throws -> EventProgram {
        guard let result else { throw URLError(.notConnectedToInternet) };return result
    }
}
