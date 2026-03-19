import SwiftUI
import WidgetKit

// MARK: – Timeline Provider

struct ImmichWatchProvider: TimelineProvider {
  func placeholder(in context: Context) -> WatchEntry {
    WatchEntry(date: .now)
  }

  func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
    Task {
      if context.isPreview, let cached = WatchEntry.loadCached() {
        completion(cached)
        return
      }
      let entry = await fetchEntry(at: .now)
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
    Task {
      let entry = await fetchEntry(at: .now)
      entry.persist()

      // Refresh every hour
      let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
      let timeline = Timeline(entries: [entry], policy: .after(refresh))
      completion(timeline)
    }
  }

  private func fetchEntry(at date: Date) async -> WatchEntry {
    do {
      let api = try await ImmichWatchAPI()
      let asset = try await api.fetchFavoriteAsset()
      let image = try await api.fetchThumbnail(assetId: asset.id)
      return WatchEntry(date: date, image: image, assetId: asset.id)
    } catch let err as WatchError {
      // Return cached image on network failure so the face isn't blank
      if err == .fetchFailed || err == .noAssetsAvailable,
        let cached = WatchEntry.loadCached(at: date)
      {
        return cached
      }
      return WatchEntry(date: date, error: err)
    } catch {
      if let cached = WatchEntry.loadCached(at: date) { return cached }
      return WatchEntry(date: date, error: .fetchFailed)
    }
  }
}

// MARK: – Complication Views

/// Rectangular (widest layout, best for showing a photo strip)
struct WatchRectangularView: View {
  let entry: WatchEntry

  var body: some View {
    if let image = entry.image {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    } else {
      errorView
    }
  }

  private var errorView: some View {
    ZStack {
      Color.black
      VStack(spacing: 2) {
        Image(systemName: "photo.badge.exclamationmark")
          .font(.caption)
        if let err = entry.error {
          Text(err.errorDescription ?? "Error")
            .font(.system(size: 8))
            .multilineTextAlignment(.center)
        }
      }
      .foregroundStyle(.secondary)
    }
  }
}

/// Circular (for corner/circular watch face slots)
struct WatchCircularView: View {
  let entry: WatchEntry

  var body: some View {
    if let image = entry.image {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .clipShape(Circle())
    } else {
      Image(systemName: "photo")
        .foregroundStyle(.secondary)
    }
  }
}

/// Entry point view — dispatches to the right layout based on complication family.
struct WatchComplicationView: View {
  @Environment(\.widgetFamily) var family
  let entry: WatchEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      WatchCircularView(entry: entry)
    default:
      WatchRectangularView(entry: entry)
    }
  }
}

// MARK: – Widget Declaration

struct ImmichWatchComplication: Widget {
  let kind = "com.donkendall.immich.WatchComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ImmichWatchProvider()) { entry in
      WatchComplicationView(entry: entry)
        .containerBackground(.black, for: .widget)
    }
    .configurationDisplayName("Immich Favorites")
    .description("Shows a random photo from your Immich Favorites.")
    .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    .contentMarginsDisabled()
  }
}
