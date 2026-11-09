# Account entry and loading behavior

**Current release:** The iPhone app has no Account section. Find is in the
header and About & privacy is in My list. The observations below describe
the website and the earlier native implementation.

The public website header bundle index-Bv2ZEtaD.js was inspected read-only on
2026-11-08. Its account control returns an empty 44×44 span while session readiness
is false. This explains the missing icon in the SSR/reference screenshots; those
captures deliberately did not execute account/auth JavaScript. The actual account
route https://watchweeks.com/account returned HTTP 200.

Native app: Account icon is created synchronously in the top-right navigation bar,
independent of network, feed loading and website authentication. It appears on the
main tabs and detail screens. Its sheet explains guest/local state and opens the
existing account website through the system URL handler. No separate native account
system, website session sharing, native sign-in or native synchronization is claimed.
Existing website account/auth/sync behavior is untouched. The website requires
connectivity; local native data remains usable offline.

The guest-navigation UI smoke test now checks account entry/sheet/dismissal; it is
prepared but unrun until Xcode is available. Validate icon visibility on fresh launch,
slow/offline network, each tab/detail and after returning from Safari.

## Proposed Lovable follow-up (not deployed by this project)

Keep the existing account control visible at its reserved 44×44 location while
session state initializes. Render the normal neutral account glyph as a keyboard-
and screen-reader-accessible link to /account immediately, without waiting for
session or avatar fetch. Label it “Account” until state is known, then “Account —
sign in” or “Account — signed in.” Treat loading/error as unknown, not signed out.
Replace only the glyph/avatar once readiness resolves; preserve the click target,
layout and existing signed-in menu. On initialization failure keep /account usable
and offer retry on that page. Test fresh SSR/hydration, slow auth, blocked storage,
expired session, offline, avatar failure and navigation. Preserve all accounts,
existing authentication providers, synchronization and analytics behavior.

This is a narrowly scoped website improvement proposal for Lovable. No website
files, users, data, deployment or analytics settings were modified here.
