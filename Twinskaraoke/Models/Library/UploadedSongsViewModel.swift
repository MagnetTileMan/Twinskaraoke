import AVFoundation
import Combine
import Foundation

@MainActor
final class UploadedSongsViewModel: ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var displayedSongs: [Song] = []
    @Published private(set) var isLoading = false
    @Published private(set) var requiresSignIn = false
    @Published private(set) var loadFailed = false
    @Published var sort: LibrarySongSort = .recentlyAdded {
        didSet { rebuildDisplayedSongs() }
    }
    @Published var searchText = "" {
        didSet { rebuildDisplayedSongs() }
    }

    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?
    private var requestGeneration = 0

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        startLoad()
    }

    func refresh() async {
        startLoad()
        let task = loadTask
        await task?.value
    }

    private func startLoad() {
        loadTask?.cancel()
        loadTask = nil
        requestGeneration &+= 1
        let generation = requestGeneration
        loadFailed = false

        guard CredentialStore.token != nil else {
            requiresSignIn = true
            isLoading = false
            hasLoaded = true
            songs = []
            rebuildDisplayedSongs()
            return
        }

        requiresSignIn = false
        isLoading = true
        loadTask = Task { [weak self] in
            do {
                let loadedSongs = try await KaraokeAPIClient.uploadedSongs()
                let uniqueSongs = Self.removingDuplicateSongs(loadedSongs)
                try Task.checkCancellation()
                guard let self, generation == requestGeneration else { return }

                songs = uniqueSongs
                hasLoaded = true
                isLoading = false
                rebuildDisplayedSongs()

                let songsWithDurations = await Self.fillingMissingDurations(in: uniqueSongs)
                try Task.checkCancellation()
                guard generation == requestGeneration else { return }

                songs = songsWithDurations
                loadTask = nil
                rebuildDisplayedSongs()
            } catch {
                guard !Self.isCancellationError(error) else { return }
                guard let self, generation == requestGeneration else { return }
                DebugLogger.log(
                    "Uploaded songs fetch failed: \(error.localizedDescription)",
                    category: .network
                )
                hasLoaded = true
                isLoading = false
                loadFailed = true
                loadTask = nil
            }
        }
    }

    private func rebuildDisplayedSongs() {
        let sorted: [Song] = switch sort {
        case .recentlyAdded:
            songs
        case .title:
            songs.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .artist:
            songs.sorted {
                $0.displayArtist.localizedStandardCompare($1.displayArtist) == .orderedAscending
            }
        case .duration:
            songs.sorted { $0.duration < $1.duration }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            displayedSongs = sorted
            return
        }
        displayedSongs = sorted.filter { song in
            song.title.localizedCaseInsensitiveContains(query)
                || song.displayArtist.localizedCaseInsensitiveContains(query)
                || song.displayTitle.localizedCaseInsensitiveContains(query)
        }
    }

    nonisolated static func removingDuplicateSongs(_ songs: [Song]) -> [Song] {
        var seenIDs = Set<String>()
        return songs.filter { seenIDs.insert($0.id).inserted }
    }

    nonisolated static func applyingResolvedDurations(
        _ durations: [String: Int],
        to songs: [Song]
    ) -> [Song] {
        songs.map { song in
            guard song.duration <= 0,
                  let duration = durations[song.id],
                  duration > 0 else {
                return song
            }
            return Song(
                id: song.id,
                title: song.title,
                duration: duration,
                absolutePath: song.absolutePath,
                cloudflareID: song.cloudflareID,
                coverArt: song.coverArt,
                originalArtists: song.originalArtists,
                coverArtists: song.coverArtists,
                userUploaded: song.userUploaded,
                oss: song.oss
            )
        }
    }

    private nonisolated static func fillingMissingDurations(in songs: [Song]) async -> [Song] {
        let songsNeedingDuration = songs.filter { $0.duration <= 0 && $0.audioURL != nil }
        guard !songsNeedingDuration.isEmpty else { return songs }

        let maximumConcurrentLookups = 4
        var resolvedDurations: [String: Int] = [:]

        for batchStart in stride(
            from: 0,
            to: songsNeedingDuration.count,
            by: maximumConcurrentLookups
        ) {
            guard !Task.isCancelled else { return songs }
            let batchEnd = min(
                batchStart + maximumConcurrentLookups,
                songsNeedingDuration.count
            )
            let batch = songsNeedingDuration[batchStart..<batchEnd]

            await withTaskGroup(of: (String, Int?).self) { group in
                for song in batch {
                    group.addTask {
                        (song.id, await resolvedDuration(for: song))
                    }
                }
                for await (songID, duration) in group {
                    if let duration {
                        resolvedDurations[songID] = duration
                    }
                }
            }
        }

        return applyingResolvedDurations(resolvedDurations, to: songs)
    }

    private nonisolated static func resolvedDuration(for song: Song) async -> Int? {
        guard !Task.isCancelled, let audioURL = song.audioURL else { return nil }
        do {
            let duration = try await AVURLAsset(url: audioURL).load(.duration)
            try Task.checkCancellation()
            let seconds = duration.seconds
            guard seconds.isFinite, seconds > 0 else { return nil }
            return max(1, Int(seconds.rounded()))
        } catch {
            return nil
        }
    }

    nonisolated static func isCancellationError(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    deinit {
        loadTask?.cancel()
    }
}
