# Immich Watch Complication — Xcode Setup

The Swift source in this `Watch/` folder implements an Apple Watch complication
that shows a random photo from your Immich Favorites:

- `WatchBundle.swift` — the `@main` widget bundle
- `WatchComplication.swift` — the `TimelineProvider` + complication views
- `ImmichWatchAPI.swift` — networking (reads shared credentials from the App Group)
- `WatchEntry.swift` — the timeline entry + disk cache
- `WatchExtension.entitlements` — App Group `group.com.donkendall.immich.share`

## ⚠️ Status: target committed, wiring INCOMPLETE — needs an Xcode session

A `WatchExtension` target is committed in `Runner.xcodeproj`, and its placeholder
bundle id / deployment target have been corrected (`com.donkendall.immich.Watch`,
watchOS `10.0`). **But the complication will NOT install or run until the items
below are done in Xcode** — they can't be hand-edited into the `.pbxproj` safely:

1. **Add a watchOS App host target and embed the widget extension in it.** A
   WidgetKit complication extension cannot be embedded directly in the iOS app —
   watchOS requires a watchOS **App** target to host it. Today `WatchExtension.appex`
   is not embedded in any shippable target (Runner only embeds the Widget + Share
   extensions), so nothing packages it onto the watch. Add a minimal watchOS App
   target, embed `WatchExtension` in it, and embed that Watch App in the iPhone
   `Runner` target via an "Embed Watch Content" copy-files phase (+ target dependency).
2. **Wire the entitlements.** In the `WatchExtension` target → Build Settings →
   Signing, set **Code Signing Entitlements** to `Watch/WatchExtension.entitlements`.
   Without this the App Group isn't applied, so `UserDefaults(suiteName:)` and the
   App Group container return nil at runtime and the complication only ever renders
   "Login to Immich on iPhone".
3. **Provisioning.** Register `com.donkendall.immich.Watch` in App Store Connect,
   create an App Store provisioning profile, install it, and update the CI secret.

## Already done (committed)

- Source files in `Watch/` (folder is a synchronized group → Watch target).
- `WatchExtension` target with corrected `PRODUCT_BUNDLE_IDENTIFIER =
  com.donkendall.immich.Watch` and `WATCHOS_DEPLOYMENT_TARGET = 10.0`.
- The iPhone `Runner` target already declares the App Group
  `group.com.donkendall.immich.share` (the Watch extension reuses it).

## Bundle IDs

| Target | Bundle ID |
|---|---|
| WatchExtension (complication) | `com.donkendall.immich.Watch` |
| Team | `6ZJTLNKLQR` (don kendall) |

## CI / Fastlane

Add the `WatchExtension` target to the `fork_testflight` lane in `Fastfile`
(and to `provisioningProfiles` + `export_options`) once the target wiring above
is complete:

```ruby
{ target: "WatchExtension", bundle: "#{fork_bundle_id}.Watch", profile: watch_profile_name },
```

## How auth works

The iPhone Immich app writes auth credentials to `UserDefaults` with suite
`group.com.donkendall.immich.share` under keys `widget_server_url` and
`widget_auth_token`. The Watch complication reads those same keys — no extra
configuration once the user is logged in on iPhone (and the entitlements above
are wired).

## What it shows

- Fetches a random photo from Favorites (`isFavorite: true`) on a 1-hour refresh.
- Supported complication families: `.accessoryRectangular`, `.accessoryCircular`.
- Falls back to the last cached image on network failure.
- Shows an error state if no login is detected.
