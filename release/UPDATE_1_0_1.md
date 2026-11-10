# WatchWeeks 1.0.1 submission text and QA

Select the exact build that completed TestFlight QA. This copy is for the
candidate without native analytics.

**What's New**

Get directions in Apple Maps or Google Maps, add a fair’s public dates to
Calendar, and use Find from guide and event screens. A haptic confirms when
you check off a brand, and you can report corrections from About & privacy.

**App Review notes**

WatchWeeks is an independent guide to watch events, exhibitors, and new
releases. No login is needed. Ratings, shortlist, and Seen are stored on
the device and do not sync. Previously loaded guides can be opened offline.
The app shows feed-supplied editorial photos with their credits.

From Events, open Singapore and then Golden Hour Singapore. Directions
opens the selected map provider without asking for location access. Add to
Calendar opens Apple’s editor for the public event dates, or Choose a day
opens a single day. The system handles saving to the user’s calendar. Find
is in the top-right navigation bar on detail screens. About & privacy is
under My list. This build has no native usage analytics or session replay.

**Device checks before review**

- Open on an iPad through internal TestFlight and confirm its exact version.
- Prefer a physical iPhone too. Open both map choices and verify the pin.
- Add all event days, check every date and local time in Calendar, then
  remove the QA entry. Repeat for a single day.
- Check launch, photos with credits, Find from a detail page, saved picks and
  Seen after relaunch, haptics, and reopening a loaded guide offline.
- Tap About & privacy and confirm the policy and corrections links work.

Do not use these analytics statements or the existing App Privacy answers
for a build that includes the separate PostHog feature. Verify and disclose
that build's actual collection before submitting it.
