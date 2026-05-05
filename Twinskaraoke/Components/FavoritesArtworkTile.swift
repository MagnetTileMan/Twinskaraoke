import SwiftUI

/// Static artwork tile for the synthesized "Favorites" playlist.
/// Used wherever a playlist tile would normally render `LoadingImage`,
/// since the Favorites pseudo-playlist has no remote cover URL.

struct FavoritesArtworkTile: View {
  var body: some View {
    LinearGradient(
      colors: [Color.appAccent.opacity(0.95), Color.purple.opacity(0.9)],
      startPoint: .topLeading, endPoint: .bottomTrailing
    )
    .overlay(
      Image(systemName: "star.fill")
        .font(.system(size: 44, weight: .semibold))
        .foregroundColor(.white.opacity(0.95))
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    )
  }
}
