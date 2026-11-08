# First-party identity provenance

Retrieved read-only on 2026-11-08: https://watchweeks.com/favicon.svg (clock logo),
https://watchweeks.com/assets/styles-BN-2ODJ7.css (warm neutral/black/orange palette),
public mobile Singapore guide and Golden Hour event. Screenshots are SSR website
references, not native screenshots. Web JS/third parties were blocked during
capture and TLS verified through curl using the cloud CA. External Google font requests were blocked during read-only capture; the reference
images now load the bundled licensed Space Grotesk locally so the correct font
is visible. Compare with the fully hydrated website and actual native app on Mac.

App Fonts: Space Grotesk variable source from
https://github.com/google/fonts/tree/main/ofl/spacegrotesk, OFL.txt bundled alongside
static 400/500/600/700 instances generated with fonttools 4.60.1. No glyphs changed;
static PostScript names set for deterministic iOS registration. Check registration
and Dynamic Type in Xcode. JetBrains Mono is not yet bundled; secondary monospace
style can use native fallback until mobile comparison establishes need.

Actual clock icon replaces the earlier temporary W. PNG rendered from the source
SVG on an opaque #faf8f4 field, 1024×1024. No organizer logo is used. Final native
screenshot comparison and App Store asset validation remain release gates.
