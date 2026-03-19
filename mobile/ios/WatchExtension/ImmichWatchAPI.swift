import Foundation
import SwiftUI

// Reads credentials from the same shared App Group that the iOS app and
// WidgetExtension write to. Keys mirror ImmichAPI.swift in WidgetExtension.
let IMMICH_WATCH_GROUP = ForkConfig.appGroup

enum WatchError: Error, Codable {
  case noLogin
  case fetchFailed
  case noAssetsAvailable
}

extension WatchError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .noLogin: return "Login to Immich on iPhone"
    case .fetchFailed: return "Unable to connect to Immich"
    case .noAssetsAvailable: return "No photos available"
    }
  }
}

enum WatchAssetType: String, Codable {
  case image = "IMAGE"
  case video = "VIDEO"
  case audio = "AUDIO"
  case other = "OTHER"
}

struct WatchAsset: Codable {
  let id: String
  let type: WatchAssetType
}

struct WatchSearchFilter: Codable {
  var type = WatchAssetType.image
  var size = 1
  var isFavorite: Bool? = true  // default to Favorites for watch
}

class ImmichWatchAPI {
  typealias CustomHeaders = [String: String]

  struct ServerConfig {
    let serverEndpoint: String
    let sessionKey: String
    let customHeaders: CustomHeaders
  }

  let serverConfig: ServerConfig

  init() async throws {
    guard let defaults = UserDefaults(suiteName: IMMICH_WATCH_GROUP),
      let serverURL = defaults.string(forKey: "widget_server_url"),
      let sessionKey = defaults.string(forKey: "widget_auth_token"),
      !serverURL.isEmpty, !sessionKey.isEmpty
    else {
      throw WatchError.noLogin
    }

    var customHeaders: CustomHeaders = [:]
    if let headersJSON = defaults.string(forKey: "widget_custom_headers"),
      !headersJSON.isEmpty,
      let parsedHeaders = try? JSONDecoder().decode(
        CustomHeaders.self, from: headersJSON.data(using: .utf8)!)
    {
      customHeaders = parsedHeaders
    }

    serverConfig = ServerConfig(
      serverEndpoint: serverURL,
      sessionKey: sessionKey,
      customHeaders: customHeaders
    )
  }

  private func buildRequestURL(endpoint: String, params: [URLQueryItem] = []) -> URL? {
    guard let baseURL = URL(string: serverConfig.serverEndpoint) else { return nil }
    let fullPath = baseURL.appendingPathComponent(
      endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    )
    var components = URLComponents(url: fullPath, resolvingAgainstBaseURL: false)
    components?.queryItems = [URLQueryItem(name: "sessionKey", value: serverConfig.sessionKey)]
    components?.queryItems?.append(contentsOf: params)
    return components?.url
  }

  private func applyHeaders(to request: inout URLRequest) {
    for (header, value) in serverConfig.customHeaders {
      request.addValue(value, forHTTPHeaderField: header)
    }
  }

  func fetchFavoriteAsset() async throws -> WatchAsset {
    guard let url = buildRequestURL(endpoint: "/search/random") else {
      throw WatchError.fetchFailed
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(WatchSearchFilter())
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    applyHeaders(to: &request)

    let (data, _) = try await URLSession.shared.data(for: request)
    let assets = try JSONDecoder().decode([WatchAsset].self, from: data)

    guard let asset = assets.first(where: { $0.type == .image }) else {
      throw WatchError.noAssetsAvailable
    }
    return asset
  }

  /// Fetches a thumbnail as SwiftUI-compatible image data.
  /// Watch screens are small — max 300px is plenty.
  func fetchThumbnail(assetId: String) async throws -> UIImage {
    let endpoint = "/assets/\(assetId)/thumbnail"
    let params = [
      URLQueryItem(name: "size", value: "preview"),
      URLQueryItem(name: "edited", value: "true"),
    ]
    guard let url = buildRequestURL(endpoint: endpoint, params: params) else {
      throw WatchError.fetchFailed
    }

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
      throw WatchError.fetchFailed
    }

    let opts: [NSString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: 300,
      kCGImageSourceCreateThumbnailWithTransform: true,
    ]
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, opts as CFDictionary)
    else {
      throw WatchError.fetchFailed
    }

    return UIImage(cgImage: thumbnail)
  }
}
