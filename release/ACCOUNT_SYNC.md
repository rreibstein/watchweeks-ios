# Account sync branch

The branch contains a tested three-way merge for interest, shortlist and Seen. It preserves local feedback and buying intent. An initial import with differing picks returns a conflict for the user to resolve. The app still uses its existing local store.

Connect the merge to a staging WatchWeeks account API after the website team confirms its contract. See the same-account section of [the Lovable handoff](LOVABLE_IOS_HANDOFF.md). Before enabling it, implement secure session storage, revision checks, persisted retries, explicit deletions, per-account isolation, preview and confirmation for guest imports, sign-out, and account deletion. Test offline edits, switching accounts, conflicts across devices, and migration of existing local data.

Guest browsing should remain available. Verify the live login providers against App Review guideline 4.8 and the account deletion flow against guideline 5.1.1 before promoting this branch. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
