import SwiftUI

struct PlaylistActionsMenuItems: View {
    let playlist: Playlist
    let songs: [Song]
    private let isSaved: Bool
    private let pendingSongs: [Song]
    private let inFlightCount: Int

    init(playlist: Playlist, songs: [Song]) {
        self.playlist = playlist
        self.songs = songs
        isSaved = SavedPlaylistsStore.shared.isSaved(playlist)

        let downloads = DownloadManager.shared
        let state = songs.reduce(into: (pendingSongs: [Song](), inFlightCount: 0)) { state, song in
            if downloads.isDownloading(song.id) {
                state.inFlightCount += 1
            } else if !downloads.isDownloaded(song.id) {
                state.pendingSongs.append(song)
            }
        }
        pendingSongs = state.pendingSongs
        inFlightCount = state.inFlightCount
    }

    private var canSaveToLibrary: Bool {
        !playlist.isFavorites && !playlist.isPersonal
    }

    var body: some View {
        let pendingCount = pendingSongs.count
        let allDownloaded = !songs.isEmpty
            && pendingCount == 0
            && inFlightCount == 0

        if !songs.isEmpty {
            Button {
                AppHaptic.selection.play()
                if let first = songs.first {
                    AudioPlayerManager.shared.playInOrder(song: first, context: songs)
                }
            } label: {
                Label("Play", systemImage: "play.fill")
            }

            Button {
                AppHaptic.selection.play()
                AudioPlayerManager.shared.playShuffled(from: songs)
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }

            Divider()
        }

        if canSaveToLibrary {
            Button {
                AppHaptic.selection.play()
                SavedPlaylistsStore.shared.toggle(playlist)
            } label: {
                if isSaved {
                    Label("Remove from Library", systemImage: "checkmark.circle.fill")
                } else {
                    Label("Add to Library", systemImage: "plus.circle")
                }
            }
        }

        if !songs.isEmpty {
            if inFlightCount > 0 {
                Label("Downloading \(inFlightCount)…", systemImage: "arrow.down.circle")
            } else if allDownloaded {
                Button(role: .destructive) {
                    AppHaptic.warning.play()
                    DownloadManager.shared.remove(songIDs: songs.map(\.id))
                } label: {
                    Label("Remove Downloads", systemImage: "trash")
                }
            } else {
                Button {
                    AppHaptic.success.play()
                    DownloadManager.shared.download(songs: pendingSongs)
                } label: {
                    let label = pendingCount < songs.count ? "Download Remaining" : "Download"
                    Label(label, systemImage: "arrow.down.circle")
                }
            }
        }
    }
}
