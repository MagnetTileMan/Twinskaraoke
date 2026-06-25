import SwiftUI

struct PlaylistActionsMenuItems: View {
    let playlist: Playlist
    let songs: [Song]
    @ObservedObject private var savedStore: SavedPlaylistsStore = .shared
    @ObservedObject private var downloads = DownloadManager.shared

    private var downloadState: (pendingSongs: [Song], inFlightCount: Int) {
        songs.reduce(into: (pendingSongs: [], inFlightCount: 0)) { state, song in
            if downloads.isDownloading(song.id) {
                state.inFlightCount += 1
            } else if !downloads.isDownloaded(song.id) {
                state.pendingSongs.append(song)
            }
        }
    }

    private var canSaveToLibrary: Bool {
        !playlist.isFavorites && !playlist.isPersonal
    }

    private var isSaved: Bool {
        savedStore.isSaved(playlist)
    }

    var body: some View {
        let downloadState = downloadState
        let pendingCount = downloadState.pendingSongs.count
        let allDownloaded = !songs.isEmpty
            && pendingCount == 0
            && downloadState.inFlightCount == 0

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
                savedStore.toggle(playlist)
            } label: {
                if isSaved {
                    Label("Remove from Library", systemImage: "checkmark.circle.fill")
                } else {
                    Label("Add to Library", systemImage: "plus.circle")
                }
            }
        }

        if !songs.isEmpty {
            if downloadState.inFlightCount > 0 {
                Label("Downloading \(downloadState.inFlightCount)…", systemImage: "arrow.down.circle")
            } else if allDownloaded {
                Button(role: .destructive) {
                    AppHaptic.warning.play()
                    for s in songs {
                        DownloadManager.shared.remove(songID: s.id)
                    }
                } label: {
                    Label("Remove Downloads", systemImage: "trash")
                }
            } else {
                Button {
                    AppHaptic.success.play()
                    for s in downloadState.pendingSongs {
                        DownloadManager.shared.download(song: s)
                    }
                } label: {
                    let label = pendingCount < songs.count ? "Download Remaining" : "Download"
                    Label(label, systemImage: "arrow.down.circle")
                }
            }
        }
    }
}
