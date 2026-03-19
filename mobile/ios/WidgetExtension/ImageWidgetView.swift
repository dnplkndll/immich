import SwiftUI
import WidgetKit


extension Image {
  @ViewBuilder
  func tintedWidgetImageModifier() -> some View {
    #if os(iOS)
    if #available(iOS 18.0, *) {
      self
        .widgetAccentedRenderingMode(.accentedDesaturated)
    } else {
      self
    }
    #elseif os(watchOS)
    if #available(watchOS 11.0, *) {
      self
        .widgetAccentedRenderingMode(.accentedDesaturated)
    } else {
      self
    }
    #endif
  }
}

struct ImmichWidgetView: View {
  var entry: ImageEntry
  @Environment(\.widgetFamily) var widgetFamily

  var body: some View {
    #if os(watchOS)
    // Handle watchOS-specific widget families
    if widgetFamily == .accessoryInline {
      InlineWidgetView(entry: entry)
    } else if widgetFamily == .accessoryCircular {
      CircularWidgetView(entry: entry)
    } else {
      StandardWidgetView(entry: entry)
    }
    #else
    // iOS standard view
    StandardWidgetView(entry: entry)
    #endif
  }
}

// MARK: - Standard Widget View (iOS and watchOS rectangular)
struct StandardWidgetView: View {
  var entry: ImageEntry
  
  var body: some View {
    if entry.image == nil {
      VStack {
        Image("LaunchImage")
          .tintedWidgetImageModifier()
        Text(entry.metadata.error?.errorDescription ?? "")
          .minimumScaleFactor(0.25)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
      }
      .padding(16)
    } else {
      ZStack(alignment: .leading) {
        Color.clear.overlay(
          Image(uiImage: entry.image!)
            .resizable()
            .tintedWidgetImageModifier()
            .scaledToFill()
        )
        VStack {
          Spacer()
          if let subtitle = entry.metadata.subtitle {
            Text(subtitle)
              .foregroundColor(.white)
              .padding(8)
              .background(Color.black.opacity(0.6))
              .cornerRadius(8)
              #if os(iOS)
              .font(.system(size: 16))
              #elseif os(watchOS)
              .font(.system(size: 12))
              #endif
          }
        }
        #if os(iOS)
        .padding(16)
        #elseif os(watchOS)
        .padding(8)
        #endif
      }
      .widgetURL(entry.metadata.deepLink)
    }
  }
}

#if os(watchOS)
// MARK: - watchOS Inline Widget (Text Only)
struct InlineWidgetView: View {
  var entry: ImageEntry
  
  var body: some View {
    if let subtitle = entry.metadata.subtitle {
      Text(subtitle)
    } else if entry.image != nil {
      Text("Memory")
    } else {
      Text("No photos")
    }
  }
}

// MARK: - watchOS Circular Widget (Round Photo)
struct CircularWidgetView: View {
  var entry: ImageEntry
  
  var body: some View {
    if let image = entry.image {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
    } else {
      Image(systemName: "photo.circle.fill")
        .font(.title2)
        .foregroundStyle(.secondary)
    }
  }
}
#endif

#Preview(
  as: .systemMedium,
  widget: {
    ImmichRandomWidget()
  },
  timeline: {
    let date = Date()
    ImageEntry(
      date: date,
      image: UIImage(named: "ImmichLogo"),
      metadata: EntryMetadata(
        subtitle: "1 year ago"
      )
    )
  }
)
