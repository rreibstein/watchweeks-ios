# Local event reminders

The event detail screen offers Remind me for future public openings only.
A user chooses a day; WatchWeeks asks for iOS notification authorization only
at that point, then schedules an on-device reminder 30 minutes before the
opening, using its absolute time in the guide's timezone. It uses no push server.

Before merging:
- Install on a physical iPhone, open without a notification prompt, set a
  reminder, test delivery while backgrounded, remove it, and verify it is gone
  after relaunch. Check denied permission and the Settings recovery path.
- Test an event in a different timezone from the phone, an invite-only slot,
  and an already-open event. Confirm that no notification is scheduled for a
  past reminder time.
- Verify the copy about organizer changes. A pending reminder does not adjust
  automatically if published hours change.
