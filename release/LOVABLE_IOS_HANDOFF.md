# Paste this into Lovable: WatchWeeks iOS integration

Please do the read-only audit and draft contract first. Return a single report with
an **Urgent: Singapore** section, an **Other current guides** section, and a
**Later: links and accounts** section. Reply with exact paths and sample JSON.
Make any code changes in a preview only. Do not deploy, change production
configuration, rotate credentials, or send real user data.

On November 10, 2026, the public home page and the five unauthenticated v1 feed
responses showed these counts. The website's model count can legitimately
differ from API release rows, and some brand rows are multiple appearances.
Please show which differences are expected under the counting rules and which
public records are actually missing:

| Guide | Web brands / releases | API distinct brand keys / release rows | Events with a structured address |
| --- | --- | --- | --- |
| Singapore | 148 / 60 | 111 / 48 | 0 / 4 |
| Miami | 39 / 33 | 39 / 29 | 0 / 3 |
| Hong Kong | 38 / 14 | 38 / 13 | 0 / 8 |
| Austin | 114 / 52 | 114 / 44 | 0 / 3 |
| New York | 279 / 60 | 279 / 67 | 0 / 20 |

We read `GET /api/public/guides` and `GET /api/public/guides/{id}`. A release row
currently has `awards, brand, brandKey, eventId, images, kind, source, text, url`.
We split prose into models in the app and deduplicate by brand/model. Please
propose additive `releaseId` and model-level fields rather than changing types of
existing fields. For Singapore, confirm which fair hours are public and which are
invite-only. The iPhone app currently uses organizer-confirmed street-address
fallbacks for Golden Hour, IAMWATCH and Spring Sprang Sprung. Supply structured
addresses and canonical links for all other venues. Say whether photos are
replaceable by a changed URL and how to invalidate a withdrawn image. For email,
the home page already has a “Notify me” form; send the best URL/deep link that
gets a phone user there directly, plus the current “send a correction” target.

If you manage the existing PostHog integration, give the project **region/ingest
host only**, whether client IPs are discarded or retained, retention, and whether
native events can be reported with `platform=ios_native` without joining web user
identities or changing website replay. Can you provide an isolated non-production
test project or ingestion endpoint for QA? Do not expose tokens in the report,
change shared PostHog settings, or submit synthetic production events.

> Audit the current WatchWeeks public iOS feed and website routes. Keep the existing v1 guide response backwards compatible. Return the changes as a preview first, with production deployment as a separate owner decision.
>
> **Feed coverage.** Compare the website and the public API for every current guide, starting with Singapore. Report the guide, event, exhibitor and distinct release counts from each source, along with specific missing or duplicate IDs and why they differ. Use stable public IDs that survive editorial edits. Add optional model-level fields for availability (available, sold out, preorder, unknown), exhibition status (at show, absent, unknown), price and currency, awards, and exact model photos with original credit and source. Keep group photos distinguishable from model photos. Return explicit unknowns and preserve the existing payload for older iOS builds. Document intended filtering for brands by event and releases by availability, exhibition status and event. Include real fixtures for sold-out, absent and unknown, and verify no publication-credit imagery leaks through.
>
> **Venue and schedules.** For each public event return the organizer-confirmed venue, structured street address, optional validated coordinates, and each public opening interval in the guide's IANA time zone. Preserve invitation-only sessions separately. Report any conflict with the organizer and the public feed. Document cache freshness and how an editorial correction propagates.
>
> **Corrections and newsletter.** Identify the existing public correction and email signup URLs, or preview standalone routes that work on mobile Safari without an account. Keep the forms on the website. Supply the URLs, the confirmation behavior, and relevant privacy copy. Skip surveys.
>
> **Shared picks and universal links.** Propose an additive versioned HTTPS route such as /picks/<opaque-id>. The website should show the explicitly shared selections and provide a useful browser fallback. Define expiry, revocation and server retention. Keep personal notes, email and account identifiers out of public share payloads. Return the AASA JSON and matching allowed paths for the WatchWeeks team and bundle identifier. Scope the association to supported paths and keep development/test hosts separate. Supply sample valid, expired and malformed links. A receiving app should preview selections and request confirmation before importing anything.
>
> **Same-account sync, separate preview.** Document the existing auth providers, session refresh, sign-out, and account deletion flows. Propose a staging API for authenticated ratings, shortlist and Seen only. Scope data to the authenticated owner and use stable guide and brand IDs, revision preconditions, idempotent mutations and explicit deletion/tombstones. Document an import that retains existing guest selections and handles conflicts without overwriting either copy silently. Provide a test account through the normal secure staging process and give us a documented demo path. Keep guest browsing fully usable. Identify any existing login provider or account-deletion behavior that affects native App Review.
>
> **Privacy.** Identify whether feed and image hosts retain IP addresses or request metadata, who can access those records, how long they persist, and whether they are shared. Keep website analytics, replay, newsletter and account disclosures distinct from native app analytics. Return the data flow for each integration.
