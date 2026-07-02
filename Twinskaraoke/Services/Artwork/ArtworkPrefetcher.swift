import Foundation
import SDWebImage
import SDWebImageSwiftUI

@MainActor
final class ArtworkPrefetcher {
    static let shared = ArtworkPrefetcher()

    private let prefetcher = SDWebImagePrefetcher.shared
    private var recentlyRequested: [String: Date] = [:]
    private let reuseWindow: TimeInterval = 45

    private init() {
        prefetcher.maxConcurrentPrefetchCount = 3
    }

    func prefetchSongs(
        _ songs: [Song],
        limit: Int = 18,
        reason: String,
        variant: ArtworkImageVariant = .card
    ) {
        let urls = songs.compactMap { song -> URL? in
            switch variant {
            case .row:
                song.rowImageURL
            case .thumbnail:
                song.thumbnailURL
            case .hero:
                song.heroImageURL
            case .fullHD:
                song.fullHDImageURL
            default:
                song.imageURL
            }
        }
        prefetch(urls: urls, limit: limit, reason: reason, variant: variant)
    }

    func prefetchPlaylists(
        _ playlists: [Playlist],
        limit: Int = 12,
        reason: String,
        variant: ArtworkImageVariant = .card
    ) {
        let urls = playlists.flatMap { playlist -> [URL] in
            var values: [URL] = []
            if let imageURL = playlist.imageURL(variant: variant) {
                values.append(imageURL)
            }
            values.append(contentsOf: playlist.initialMosaicArtworkURLs.compactMap {
                ArtworkURLBuilder.variantURL(from: $0, variant: variant)
            })
            return values
        }
        prefetch(urls: urls, limit: limit, reason: reason, variant: variant)
    }

    func prefetch(
        urls: [URL],
        limit: Int = 18,
        reason: String,
        variant: ArtworkImageVariant = .card
    ) {
        let variantURLs = urls.map { url in
            ArtworkURLBuilder.variantURL(from: url, variant: variant) ?? url
        }
        let selected = freshUniqueURLs(from: variantURLs, limit: adjustedLimit(limit, reason: reason))
        guard !selected.isEmpty else { return }

        DebugLogger.log(
            "Prefetching \(selected.count) artwork images for \(reason)",
            category: .cache
        )

        prefetcher.prefetchURLs(
            selected,
            options: [],
            context: ImageCacheConfig.prefetchContext,
            progress: nil
        ) { finished, skipped in
            DebugLogger.log(
                "Artwork prefetch complete for \(reason): finished=\(finished), skipped=\(skipped)",
                category: .cache
            )
        }
    }

    private func adjustedLimit(_ limit: Int, reason: String) -> Int {
        guard limit > 0 else { return 0 }
        if DownloadManager.shared.hasActiveQueue {
            return min(limit, reason == "radio metadata" ? 3 : 2)
        }
        if AudioPlayerManager.shared.isPlaying {
            return min(limit, reason == "radio metadata" ? 4 : 4)
        }
        return min(limit, reason == "radio metadata" ? 6 : 8)
    }

    private func freshUniqueURLs(from urls: [URL], limit: Int) -> [URL] {
        guard limit > 0 else { return [] }
        let now = Date()
        recentlyRequested = recentlyRequested.filter { now.timeIntervalSince($0.value) < reuseWindow }

        var seen = Set<String>()
        var result: [URL] = []
        for url in urls {
            let key = url.absoluteString
            guard seen.insert(key).inserted else { continue }
            guard recentlyRequested[key] == nil else { continue }
            guard !ArtworkFailureBackoff.shared.isBlocked(url) else { continue }
            recentlyRequested[key] = now
            result.append(url)
            if result.count == limit { break }
        }
        return result
    }
}
