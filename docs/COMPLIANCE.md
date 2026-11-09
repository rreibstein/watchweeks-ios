# Release review checks

Current source: [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

- **2.1 Completeness.** Simulator and physical iPhone tests must cover guest
  launch, the live Singapore guide, opening hours, navigation, checklist
  persistence, cached browsing and the support/privacy links.
- **2.3 Metadata.** Use real iPhone screenshots from the candidate and describe
  only working flows. List WatchWeeks as independent of the events.
- **4.1 and 5.2 Identity and content rights.** Keep the first-party clock icon,
  typographic brand names and bundled font license. The launch candidate includes
  credited watch photographs. Confirm the right to show them in the app.
- **4.2 Minimum functionality.** Review notes should point to the native visit
  checklist, event schedules and offline guide.
- **4.8 and 5.1.1 Account and privacy.** Guest use is complete. My list links
  to About & privacy. There is no native registration, login or synchronization.
  The launch build contains no product analytics
  SDK or replay. Verify the native policy and actual request log retention
  before setting App Store privacy answers.

See [App Store handoff](../release/APP_STORE.md) for owner actions and the gate.
