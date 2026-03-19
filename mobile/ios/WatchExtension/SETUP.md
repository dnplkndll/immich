# Immich Watch Complication — Xcode Setup

The Swift source files here implement an Apple Watch complication that shows a
random photo from your Immich Favorites. The files are ready; you need to add a
watchOS target in Xcode and wire them up.

## Bundle IDs needed

| Target | Bundle ID |
|---|---|
| WatchExtension (complication) | `com.donkendall.immich.Watch` |

Register `com.donkendall.immich.Watch` in App Store Connect and create an App
Store provisioning profile for it (same workflow as the existing three profiles).

## Xcode steps

1. **Open** `mobile/ios/Runner.xcworkspace` in Xcode.

2. **Add target** → File > New > Target > **watchOS > Widget Extension** (not
   "Watch App" — that adds a full standalone app; we want just the WidgetKit
   complication extension paired with the existing iPhone app).

3. **Target name**: `WatchExtension`
   **Bundle identifier**: `com.donkendall.immich.Watch`
   **Team**: `6ZJTLNKLQR` (don kendall)
   Uncheck "Include Configuration Intent" (we use `StaticConfiguration`).
   Xcode will scaffold placeholder files — **delete them**.

4. **Add source files** to the new target (drag or File > Add Files):
   - `WatchExtension/ImmichWatchAPI.swift`
   - `WatchExtension/WatchEntry.swift`
   - `WatchExtension/WatchComplication.swift`
   - `WatchExtension/WatchExtensionBundle.swift`
   - **Also add** (from the project root, not copied): `ForkConfig.swift`

5. **Set deployment target** for `WatchExtension` to **watchOS 9.0** minimum
   (WidgetKit complications require 9.0+; `.accessoryRectangular` needs 9.0+).

6. **Entitlements**: In the WatchExtension target's Build Settings → Signing,
   set Code Signing Entitlements to `WatchExtension/WatchExtension.entitlements`.

7. **App Group** in the iPhone app's `Runner` target:
   Verify `group.com.donkendall.immich.share` is already in the Runner
   entitlements — it is. The Watch extension uses the same group.

8. **Build phases**: No CocoaPods dependency needed; the Watch extension is
   pure Swift + WidgetKit.

9. **Provisioning profile**: Set the WatchExtension target's provisioning profile
   to the `com.donkendall.immich.Watch AppStore` profile (create this in App Store
   Connect, then install it locally and update the GitHub secret for CI).

## CI / Fastlane

Add the `WatchExtension` target to the `fork_testflight` lane in `Fastfile`:

```ruby
{ target: "WatchExtension", bundle: "#{fork_bundle_id}.Watch", profile: watch_profile_name },
```

And add it to the `provisioningProfiles` hash and `export_options`.

## How auth works

The iPhone Immich app writes auth credentials to `UserDefaults` with suite
`group.com.donkendall.immich.share` under keys `widget_server_url` and
`widget_auth_token`. The Watch complication reads those same keys — no extra
configuration needed once the user is logged in on iPhone.

## What it shows

- Fetches a random photo from Favorites (`isFavorite: true`) on a 1-hour refresh.
- Supported complication families: `.accessoryRectangular`, `.accessoryCircular`.
- Falls back to the last cached image on network failure.
- Shows an error icon if no login is detected.
