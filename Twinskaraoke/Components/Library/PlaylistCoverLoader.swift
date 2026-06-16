import Combine
import Foundation
import SwiftUI

@MainActor
final class PlaylistCoverLoader: ObservableObject {
  @Published var artworkURLs: [URL] = []
  private var loadedID: String?
  private var fallbackSongs: [Song] = []
  private var loadedPlaylist: Playlist?

  func load(playlistID: String, fallback: [Song]? = nil) {
    if loadedID == playlistID {
      fallbackSongs = fallback ?? fallbackSongs
      refreshFallbackArtwork()
      return
    }
    loadedID = playlistID
    fallbackSongs = fallback ?? []
    loadedPlaylist = nil
    artworkURLs = Self.extractArtworkURLs(fromSongs: fallbackSongs)

    let urlString = "\(StorageHost.api)/api/playlist/\(playlistID)"
    guard let url = URL(string: urlString) else { return }

    var request = URLRequest(url: url)
    if let token = UserDefaults.standard.string(forKey: "nk.token"), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    GuestIdentity.applyIfNeeded(to: &request)

    URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
      guard let self, let data else { return }
      Task { @MainActor in
        guard self.loadedID == playlistID else { return }
        self.loadedPlaylist = try? JSONDecoder().decode(Playlist.self, from: data)
        self.fallbackSongs = self.loadedPlaylist?.songListDTOs ?? SongPayloadDecoder.decodeSongs(from: data) ?? self.fallbackSongs
        self.refreshFallbackArtwork()
      }
    }.resume()
  }

  func refreshFallbackArtwork() {
    var urls: [URL] = []
    if let loadedPlaylist {
      urls.append(contentsOf: Self.extractMosaicURLs(from: loadedPlaylist))
    }
    urls.append(contentsOf: Self.extractArtworkURLs(fromSongs: fallbackSongs))
    artworkURLs = Self.uniqueURLs(urls, limit: 4)
  }

  private static func extractMosaicURLs(from playlist: Playlist) -> [URL] {
    let mediaURLs = playlist.mosaicMedia?.compactMap(mediaURL) ?? []
    if !mediaURLs.isEmpty { return uniqueURLs(mediaURLs, limit: 4) }
    return extractArtworkURLs(fromSongs: playlist.songListDTOs ?? [])
  }

  private static func extractArtworkURLs(fromSongs songs: [Song]) -> [URL] {
    uniqueURLs(songs.compactMap(\.imageURL), limit: 4)
  }

  private static func mediaURL(from media: Media) -> URL? {
    guard let path = media.absolutePath, !path.isEmpty else { return nil }
    let normalized = path.hasPrefix("/") ? path : "/\(path)"
    return URL(string: "\(StorageHost.images)\(normalized)/width=480,quality=85,format=auto")
  }

  private static func uniqueURLs(_ urls: [URL], limit: Int) -> [URL] {
    var seen = Set<String>()
    var result: [URL] = []
    for url in urls {
      guard seen.insert(url.absoluteString).inserted else { continue }
      result.append(url)
      if result.count == limit { break }
    }
    return result
  }
}
