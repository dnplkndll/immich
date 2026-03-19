// Fork-specific configuration — shared across Runner, WidgetExtension, and ShareExtension.
// Change these values for your own fork build, or override via Fork.xcconfig + Info.plist.
//
// The Info.plist approach (via ForkAppGroup/ForkBundlePrefix keys) works for the main app
// but extensions have their own bundles. This file provides a compile-time fallback that
// all targets can reference.

import Foundation

enum ForkConfig {
    static let appGroup: String = {
        // Try Info.plist first (set via Fork.xcconfig in main app)
        if let value = Bundle.main.infoDictionary?["ForkAppGroup"] as? String, !value.isEmpty {
            return value
        }
        // Compile-time constant fallback — update this for your fork
        return "group.com.donkendall.immich.share"
    }()

    static let bundlePrefix: String = {
        if let value = Bundle.main.infoDictionary?["ForkBundlePrefix"] as? String, !value.isEmpty {
            return value
        }
        return "com.donkendall.immich"
    }()
}
