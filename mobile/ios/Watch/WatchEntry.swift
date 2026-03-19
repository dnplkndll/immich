import Foundation
import SwiftUI
import WidgetKit

/// Timeline entry for the Immich watch complication.
struct WatchEntry: TimelineEntry {
  let date: Date
  var image: UIImage? = nil
  var assetId: String? = nil
  var error: WatchError? = nil

  // MARK: – Disk cache (shared App Group container)

  private static func cacheURLs() -> (image: URL, meta: URL)? {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: IMMICH_WATCH_GROUP)
    else { return nil }
    return (
      image: container.appendingPathComponent("watch_complication_image.png"),
      meta: container.appendingPathComponent("watch_complication_meta.json")
    )
  }

  func persist() {
    guard let urls = Self.cacheURLs() else { return }
    try? image?.pngData()?.write(to: urls.image, options: .atomic)
    if let id = assetId {
      try? Data(id.utf8).write(to: urls.meta, options: .atomic)
    }
  }

  static func loadCached(at date: Date = .now) -> WatchEntry? {
    guard let urls = cacheURLs(),
      let imgData = try? Data(contentsOf: urls.image),
      let img = UIImage(data: imgData)
    else { return nil }
    let id = (try? String(contentsOf: urls.meta, encoding: .utf8))
    return WatchEntry(date: date, image: img, assetId: id)
  }
}
