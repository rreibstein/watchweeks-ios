# Launch-crash investigation — November 15, 2026

The friend's root cause remains **unconfirmed**. Reported device: iPhone 17,
iOS 27.3 beta. Installed app version/build, crash stack, and whether a guide ever
loaded successfully have not been established. Do not attribute the crash to the
beta or advertise this patch as a confirmed fix for that phone.

## Executed checks

Read startup, global navigation/font setup, cache/network error handling, Home
rendering, date calculations and release-model construction. Inspected historical
source ab289bf (1.0 submission), 7e8547c (1.0.1 candidate), 008d689 (later 1.0.1
cloud baseline), and the current rapid branch based on ef408fe (cloud run 41).
These are source references; the friend's exact installed revision is unknown.

On Nov 15, the index and all five detail endpoints returned HTTP 200. Their
bodies decoded and passed identity validation with all four source references.
Release-optimized Linux probes also completed cache serialization, date/range
formatting, release splitting, price/badge extraction, photo filtering and
release-menu dictionary construction. Five presentation passes per reference
completed without failure. The later 1.0.1 baseline additionally exercised live
schedule aggregation. This checks today's content, not historical Nov 13 bytes.

All four bundled font files parsed with matching PostScript names and 1,001 glyphs
each. Sampled Home-photo sources returned HTTP 200; parsed raster sizes ranged
from 600×960 to 2000×2000. These are file/network checks, not iOS CoreText/ImageIO
validation, memory measurements or evidence excluding a beta OS defect.

## Reproduced weakness and patch

Network guides are validated, but decoded cached snapshots/libraries previously
bypassed that validation. A synthetic cache containing two releases with the same
ID and different titles reached the native release menu's
`Dictionary(uniqueKeysWithValues:)` initializer and terminated the optimized
probe with `Swift/NativeDictionary.swift: Fatal error: Duplicate values for key`
(exit 132). This is a core-code reproduction of the unsafe menu operation, not a
reproduction of first-tab startup or the friend's iPhone crash. Normal cache
writes validate the feed; no evidence shows that this app naturally generated
such a cache on his phone. It does not explain a first installation with no cache.

`LocalStore.snapshot()` and `rememberedGuides()` now enforce the same invariants
as the feed before records reach the UI. Reads do not modify any files. Offline
failure cannot return a malformed decoded snapshot. A healthy refresh can repair
this identity-invalid public-data cache while retaining valid older editions;
ratings and Seen selections are untouched. Syntactically unreadable JSON still
uses the existing safe read/write-error paths rather than being silently erased.

Seven regression tests cover rejection, offline fallback, valid legacy caches,
repair with/without an existing library, retention of older editions and exact
selection preservation. Three failed before the guard. After the patch, all
108 tests passed with `scripts/swift-linux test -c release --jobs 4`.
The formerly crashing optimized probe exits successfully with
`SAFELY REJECTED invalidResponse`. Source/resource validation also passed.

## Limits and next diagnostic

No iOS 27.3 beta runtime or physical device was available. No new Xcode/simulator
build, TestFlight upload, App Review submission or publication was performed.
Changes are isolated on `fix/launch-cache-safety`, without other feature branches.

A crash stack is still needed to connect this finding to the friend's phone.
`NativeDictionary` / `_assertionFailure` / release-menu frames would support the
reproduced failure. UIKit/SwiftUI/CoreText frames or an OS termination require a
different investigation. Absence of a normal WatchWeeks crash file does not
exclude memory pressure or a watchdog termination. There is insufficient evidence
to rank those causes, recommend a beta-only workaround, or ask for reinstallation.
