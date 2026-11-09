# App Store screenshot handoff

Use the actual iPhone 17 simulator captures in
`release/screenshots/app-store/`. These are 1206 × 2622 portrait screenshots
for the **iPhone with Dynamic Island (medium display)** slot. The app targets
iPhone only. Apple's current size reference applies.

For the listing, start with **02-singapore**, **03-golden-hour**, and
**05-my-list**, in that order.
The updated home screen now includes brand photos. Upload **01-home**,
**01b-release**, or **06-new-releases** after confirming rights for the
featured photos in App Store marketing. **04-rating** is a QA reference.

[Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

To recapture, run the live UI test via `scripts/verify-macos.sh` with
`TEST_RUNNER_WW_CAPTURE=1` and an iPhone 17 or 17 Pro simulator destination.
Use the attached real screenshots in the resulting `.xcresult`, exported with
`xcrun xcresulttool export attachments`. Check the PNG dimensions and alpha
with `sips -g pixelWidth -g pixelHeight -g hasAlpha`. Upload opaque files.
