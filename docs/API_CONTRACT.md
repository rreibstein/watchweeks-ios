# Observed public API v1 — 2026-11-08

Cloud proxy restriction is resolved after environment publication. GET index and
all five guide details returned JSON; Singapore and Austin fixtures are saved
only in the test target. API requests use no authentication. No account records,
private notes, user selections or credentials appeared in inspected public data.
Event notes include publicly advertised organizer contact information; do not send
those notes through analytics. No website data was changed.

Index: `{v:1,guides:[...]}`. Headers include public Cache-Control max-age=300 and
Access-Control-Allow-Origin *. No pagination fields, cursor, total or next link
were observed. New York, Austin, Miami, Singapore and Hong Kong were listed at
inspection. The app discovers guide IDs from the index. A configured city can
appear before its published detail exists, with null start and end dates.

Guide fields: id, slug, city, dates, timezone, start_date, end_date, url.
`id` is the stable guide key (e.g. singapore-2026); New York slug is empty and
canonical URL is /. start/end are YYYY-MM-DD; timezone is IANA. `dates` is an
editorial display label (can disagree with machine fields; New York differs).

Detail: `{v:1,guide:{...},events:[],brands:[],releases:[],dealers:[]}`.
Events: id/name, venue/url/note nullable, days array, start_date/end_date. Days:
date, open/close HH:mm (event local), optional access, observed invitation/rsvp.
Do not describe November 12 IAMWATCH as public attendance: first public day is 13.

Brands: name, brandKey (canonical cross-appearance key), eventId, website nullable,
hasRelease boolean. Atelier Wen appears twice in Singapore across two events;
we merge event memberships and keep one city-scoped selection. Website ratings
use must/moderate/little/unknown/none for Must see/Interested/If time/Unfamiliar/Skip;
unrated means absent/cleared. Seen is distinct, mirrored across brand appearances.

Releases: brand, brandKey, eventId, kind, text, url/source nullable, awards array,
images array. Observed awards arrays are empty in inspected responses; only string
awards currently decode, so a future non-string award shape is an integration gate.
Images: url, credit/link nullable. Relative image URLs resolve at watchweeks.com.
Kinds include recent/debut, displayed factually. Feed has no explicit release ID;
we use brandKey|eventId|kind, reject duplicate tuple IDs rather than inventing stable
identity. New content with repeated tuples requires contract enhancement. No user
selection is keyed by release ID. Dealers currently not rendered natively.

Unknown guide probe returned HTTP 404 JSON `{"error":"not_found"}`, also cacheable
300 seconds. No ETag/Last-Modified observed in index/404 probes. Refresh requests
bypass the device's URL cache, while server and CDN caching still apply. Local
snapshots support offline browsing.
A guide detail returning 404 is skipped so a configured city awaiting publication
does not block the rest. If a nonempty index yields no details, or any other
request or decode fails, the last good snapshot is used with a warning. The app
refreshes at launch, on return to the foreground, on pull to refresh, and every
five minutes while active. Per-guide live status uses public slots in that
guide's local timezone.

Observed counts: Singapore 4 events, 112 brand appearances, 47 releases; Austin
3/119/44. Mobile Singapore website advertised 56 releases at inspection time.
Public feed coverage discrepancy documented; native must not invent missing items.
First-party public docs/ios-handoff.md was not available in this repository; no
private source was requested. Typed models follow actual observed fields.
