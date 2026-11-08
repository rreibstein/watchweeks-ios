# Product fidelity audit, 2026-11-08

Source is the live public WatchWeeks site, read-only SSR pages and publicly served
JS/CSS/assets. No private web repository or backend was accessed. Mobile SSR
captures (390×844) are in docs/identity; JavaScript/third parties were blocked to
avoid analytics writes, and curl verified TLS for page/style resources because
this Chromium profile lacked the cloud CA. These are website references, not app
screenshots or proof of interactive parity. Compare real simulator output on Mac.

| Website feature/behavior | Native adaptation | Difference / acceptance |
|---|---|---|
| City guides with event dates | Feed-driven discovery, current/upcoming/past | Worldwide landing instead of permanent New York page; dates use API fields |
| Events with venue, daily access/schedule and notes | Native city event list and details | Daily local HH:mm shown literally with timezone, includes invitation-only day |
| Brands A–Z | Native searchable brand list grouped within city | Brands A–Z tab selects city then opens directory; verify exact flow against web |
| Must see / Interested / If time / Unfamiliar / Skip | Same five categories plus clearing rating | Native adaptive buttons support Dynamic Type and tap-again clearing; raw categories must/moderate/little/unknown/none preserved |
| Seen separate from interest; duplicate appearances mirror seen | Separate toggle, guide+brandKey key | Both event appearances share same brand selection; city isolation |
| My list visiting shortlist | Native My list with progress and remaining toggle | Earlier My Visit label removed; no new planning algorithm |
| New releases with editorial classification, pictures, source | Native releases and detail from public API | Image credits preserved; confirm all links/awards and multiple images on Mac |
| Plan My Day | Full website access | Explicitly omitted natively; do not advertise native itinerary |
| Comparison and private notes | Full website access | Not implemented natively; no private notes in analytics |
| Share | Native guide share sheet | Completed share tracked once; canceled share not counted |
| Optional web account synchronization | Guest-only on-device | No automatic web sync; disclosed throughout |
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
Native visual and large-text validation still requires Xcode/simulator.
