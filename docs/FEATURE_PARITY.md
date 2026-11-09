# Product fidelity audit, 2026-11-08

Source is the live public WatchWeeks site, read-only SSR pages and publicly served
JS/CSS/assets. No private web repository or backend was accessed. Mobile SSR
captures (390×844) are in docs/identity; JavaScript/third parties were blocked to
avoid analytics writes, and curl verified TLS for page/style resources because
this Chromium profile lacked the cloud CA. These are website references, not app
screenshots or proof of interactive parity. Compare real simulator output on Mac.

| Website feature/behavior | Native adaptation | Difference / acceptance |
|---|---|---|
| City guides with event dates | Feed-driven discovery, current/upcoming/past | Worldwide landing follows the current public homepage; dates use event-local time |
| Events with venue, daily access/schedule and notes | Native city event list and details | Validated local day, opening and closing times, and readable access labels |
| Brands A–Z | Native searchable brand list grouped within city | Catalog follows the active guide; global entry offers a city picker |
| Five interest categories | Must-see / Moderate / A little / Not for me / Unfamiliar | Native labels follow the latest brief; wire categories and tap-again clearing are preserved |
| Seen separate from interest; duplicate appearances mirror seen | Separate toggle, guide+brandKey key | Both event appearances share same brand selection; city isolation |
| My list visiting shortlist | Native My list with progress and remaining toggle | Earlier My Visit label removed; no new planning algorithm |
| New releases with editorial classification, pictures, source | Native releases and detail from public API | Image credits preserved; confirm all links/awards and multiple images on Mac |
| Plan My Day | Native Singapore time-window planner and website planning tools | The native planner covers the three specified Singapore fairs and the timed IAMWATCH conversations |
| Comparison and private notes | Full website access | Not implemented natively; no private notes in analytics |
| Share | Native guide share sheet | Completed share tracked once; canceled share not counted |
| Header account control / optional web account sync | Always-visible native top-right Account entry opens existing /account | No native sign-in or automatic web sync; local/website state distinction disclosed |
| WatchWeeks identity | Actual first-party clock icon, warm accent direction | No organizer logos. Typography/layout comparison remains a Mac release gate |

Observed CSS uses Space Grotesk (400–700), JetBrains Mono 500; warm neutral
background, near-black foreground and orange accent (OKLCH 66% .2 38). Native now bundles licensed Space Grotesk static instances derived from Google Fonts
variable source (OFL included). System fallback/secondary fonts and final metrics
need actual mobile/simulator comparison; no parity claim is made. First-party SVG
favicon source retained with retrieval provenance. No unrelated organizer assets.

Public Singapore API currently has 47 release entries while mobile page advertises
56; do not fabricate missing releases. Ask backend owner to reconcile public-feed
coverage only after documenting the discrepancy. Website display date New York
Oct 14 differs from API start_date Oct 13; native currently trusts machine dates.

Typography follow-up: all explicit native body/caption/heading/consent styles now
use Space Grotesk with Dynamic Type-relative sizes. UIKit navigation titles and
tab labels use the bundled font as well. Debug startup asserts all four weights
register. Web reference screenshots were regenerated with local Space Grotesk.
The original implementation was subsequently reviewed on the simulator and the
presentation was revised to follow the mobile site more closely.

## Native design and interactions

- Warm paper, bordered event and brand cards, the typographic WatchWeeks wordmark,
  prominent Find and the four labeled destinations follow the mobile site.
  The system tab bar handles icon spacing and the bottom safe area. UIKit navigation retains the system back gesture; the guide share button uses
  the native share sheet. Large accessibility text stacks rating buttons.
- City guides expose local day and sort controls. Event cards and detail use the
  same validated local hours and access labels. The home status refreshes every
  minute and uses the event's local calendar. Invitation-only hours are excluded
  from public live status and the Singapore planner.
- Event detail combines venue, hours and official link. Its release carousel uses
  available watch photographs and links to the event-filtered directory. Prices
  and availability badges appear only when supported by the public record.
  Miami dealer names come from the v1 feed. Golden Hour Singapore stock uses the
  supplied 12-brand list with canonical feed keys.
- My list groups saved brands by city and event. Ratings, shortlist and seen
  state are local and independent. Legacy ratings-based shortlist membership is
  preserved until edited. Seen shortlist rows collapse with a reversible tap.
- Singapore planning reserves 60 minutes per fair, uses the three supplied travel
  estimates and compares the selected talk with a no-talk itinerary. Six timed
  conversations are from the organizer's November 2026 Wonder Room program.
  Confirm admission and the current program with the organizer.
- Spring Sprang Sprung's official site lists 6 PM on November 14–15, while the
  public WatchWeeks feed returns 7 PM. The native display and planner use the
  organizer's 6 PM closing for those two known conflicting entries. No website
  changes were made. Singapore addresses are supplied for the three planner fairs.

Sources: [WatchWeeks home](https://watchweeks.com/),
[Singapore guide](https://watchweeks.com/singapore),
[IAMWATCH program](https://www.iamwatch.com/event/2026/programmes),
[Golden Hour](https://goldenhour.delugs.com/singapore),
[Spring Sprang Sprung](https://www.spring-sprang-sprung.com/),
[The Singapore EDITION](https://www.marriott.com/en-us/hotels/sineb-the-singapore-edition/overview/).

The public feed does not expose all model-level stock, sellout, structured price
or award data shown on the website, nor every release, appointment, or
comparison. The native app uses the actual feed and verified edition details.
Existing website tools remain available through the guide and account links.

## Guide and release data follow-up

- The New York past card displays the fixed public snapshot `nyww-2026-event-v1`
  for October 14–20, 2026. Its ordering uses the production bundle's frozen
  scores and tie breakers. Austin has no published frozen snapshot in the
  public sources reviewed, so the past card reports that gap.
- The edition-specific Austin and Miami access entries are folded into their
  parent events. The day schedule preserves those entries, including named
  slots embedded in the public feed. VIP hours are excluded from public live
  status. Coconut Grove shows the 24 dealer records from the public feed.
- The feed still delivers editorial release blocks. The app splits explicit
  model headings, reads the price and availability for each model, and shows
  unmatched photographs as release-group photos. The app does not infer
  missing awards, prices, or model-specific image associations.

[New York guide](https://watchweeks.com/newyork#audience-favorites) ·
[Published ranking bundle](https://watchweeks.com/assets/topBrands-ihB13dQ1.js) ·
[Miami guide](https://watchweeks.com/miami) ·
[Austin new releases](https://watchweeks.com/austin/new-releases)
