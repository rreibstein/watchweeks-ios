# Release review worksheet

Apple live guideline pages could not be retrieved in cloud (developer.apple.com
blocked). Re-read current https://developer.apple.com/app-store/review/guidelines/
on Mac before signing off. These are engineering checks, not Apple's approval.

- 2.1 completeness: BLOCKED by unverified feed adapter and no Xcode/device test.
- 2.3 metadata: draft feature claims must match observed release behavior; replace
  temporary icon, actual screenshots only, no fabricated event content.
- 4.1 impersonation: independent statement in app and listing; no organizer logo;
  first-party WatchWeeks identity still must be verified.
- 4.2 utility: native interest/seen controls, My Visit progress and cached guide
  browsing implemented; actual working end-to-end functionality still required.
- 4.8 login: guest-only, no third-party login or account creation added.
- 5.1 privacy: no analytics/ad SDKs, local selections; verify native policy, backup,
  image host behavior and Apple disclosure definitions. No automatic website sync.

Do not submit until API_CONTRACT.md checklist, Mac build/QA, policy, icon/license,
support contact, seller/legal decisions and owner release approval are complete.
