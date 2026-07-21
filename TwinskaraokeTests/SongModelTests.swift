import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Song model")
struct SongModelTests {
    private func useGlobalStorageRegion() {
        UserDefaults.standard.set("global", forKey: "nk.storageRegion")
    }

    @Test("Artwork prefetch signatures ignore ordering and duplicates")
    @MainActor
    func artworkPrefetchSignatureUsesURLSets() {
        useGlobalStorageRegion()
        let first = Song(
            id: "song-1",
            title: "First",
            duration: 180,
            absolutePath: "/audio/first.mp3",
            cloudflareID: "first-image",
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: false
        )
        let second = Song(
            id: "song-2",
            title: "Second",
            duration: 180,
            absolutePath: "/audio/second.mp3",
            cloudflareID: "second-image",
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: false
        )

        let ordered = ArtworkPrefetchSignature(songs: [first, second, first], playlists: [])
        let reordered = ArtworkPrefetchSignature(songs: [second, first], playlists: [])

        #expect(ordered == reordered)
        #expect(ordered.songURLs.count == 2)
    }

    @Test("Cloudflare artwork URLs use the image CDN")
    func songImageURLWithCloudflareId() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-1",
            title: "Test Song",
            duration: 185,
            absolutePath: "/audio/test.mp3",
            cloudflareID: "image-id",
            coverArt: Media(absolutePath: "/covers/test.jpg"),
            originalArtists: ["Original Artist"],
            coverArtists: ["Cover Artist"],
            userUploaded: false
        )

        #expect(
            song.imageURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=480,quality=85,format=webp/image-id/public"
        )
        #expect(
            song.rowImageURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=180,quality=78,format=webp/image-id/public"
        )
        #expect(
            song.thumbnailURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=240,quality=80,format=webp/image-id/public"
        )
        #expect(
            song.heroImageURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=960,quality=88,format=webp/image-id/public"
        )
        #expect(
            song.fullHDImageURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=1920,quality=90,format=webp/image-id/public"
        )
    }

    @Test("downloadCoverImageURL produces a WebP URL for songs with artwork")
    func downloadCoverImageURLWithArtwork() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-1",
            title: "Test Song",
            duration: 185,
            absolutePath: "/audio/test.mp3",
            cloudflareID: "image-id",
            coverArt: Media(absolutePath: "/covers/test.jpg"),
            originalArtists: ["Original Artist"],
            coverArtists: ["Cover Artist"],
            userUploaded: false
        )

        #expect(
            song.downloadCoverImageURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=1920,quality=90,format=webp/image-id/public"
        )
    }

    @Test("ArtworkURLBuilder upgrades Cloudflare delivery URLs to the resize route")
    func artworkVariantURLUsesCloudflareResizeRoute() throws {
        useGlobalStorageRegion()
        let legacyURL = try #require(
            URL(string: "https://images.neurokaraoke.com/account-hash/image-id/width=180,quality=78,format=webp")
        )
        let resizedURL = ArtworkURLBuilder.variantURL(from: legacyURL, variant: .card)

        #expect(
            resizedURL?.absoluteString
                == "https://images.neurokaraoke.com/cdn-cgi/image/width=480,quality=85,format=webp/account-hash/image-id/public"
        )
    }

    @Test("ArtworkURLBuilder keeps storage artwork on the storage resize route")
    func artworkVariantURLKeepsStorageResizeRoute() throws {
        useGlobalStorageRegion()
        let storageURL = try #require(
            URL(string: "https://storage.neurokaraoke.com/cdn-cgi/image/width=180,quality=78,format=webp/media/artist/example.png")
        )
        let resizedURL = ArtworkURLBuilder.variantURL(from: storageURL, variant: .card)

        #expect(
            resizedURL?.absoluteString
                == "https://storage.neurokaraoke.com/cdn-cgi/image/width=480,quality=85,format=webp/media/artist/example.png"
        )
    }

    @Test("ArtworkURLBuilder leaves unsupported artwork hosts unchanged")
    func artworkVariantURLLeavesUnsupportedHostsUnchanged() throws {
        let externalURL = try #require(
            URL(string: "https://cdn.example.com/artwork/image.jpg")
        )
        let resizedURL = ArtworkURLBuilder.variantURL(from: externalURL, variant: .thumbnail)

        #expect(resizedURL == externalURL)
    }

    @Test("downloadCoverImageURL is nil for songs without their own artwork")
    func downloadCoverImageURLWithoutArtwork() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-2",
            title: "Test Song",
            duration: 61,
            absolutePath: "/songs/test.mp3",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: false
        )

        #expect(song.downloadCoverImageURL == nil)
    }

    @Test("Audio URLs trim leading slashes")
    func songAudioURLNormalizesAbsolutePath() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-2",
            title: "Test Song",
            duration: 61,
            absolutePath: "/songs/test.mp3",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: false
        )

        #expect(song.audioURL?.absoluteString == "https://storage.neurokaraoke.com/songs/test.mp3")
        #expect(song.durationText == "1:01")
    }

    @Test("audioURL falls back to oss when absolutePath is nil")
    func songAudioURLFallsBackToOss() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-oss",
            title: "Uploaded Song",
            duration: 200,
            absolutePath: nil,
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: ["Uploader"],
            coverArtists: nil,
            userUploaded: true,
            oss: "audio/Uploaded Song (live).mp3"
        )

        let url = song.audioURL?.absoluteString
        #expect(url != nil)
        #expect(url?.hasPrefix("https://storage.neurokaraoke.com/audio/") == true)
        #expect(url?.contains("Uploaded") == true)
        #expect(url?.contains("%20") == true)
    }

    @Test("audioURL falls back to oss when absolutePath is blank")
    func songAudioURLFallsBackToOssWhenAbsolutePathIsBlank() {
        useGlobalStorageRegion()
        let song = Song(
            id: "song-blank-path",
            title: "Uploaded File",
            duration: 90,
            absolutePath: "  ",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: true,
            oss: "uploads/My Song.mp3"
        )

        #expect(
            song.audioURL?.absoluteString
                == "https://storage.neurokaraoke.com/uploads/My%20Song.mp3"
        )
    }

    @Test("audioURL preserves complete remote URLs")
    func songAudioURLPreservesRemoteURL() {
        let song = Song(
            id: "song-remote",
            title: "Remote Upload",
            duration: 90,
            absolutePath: "https://uploads.example.com/audio/My%20Song.mp3?token=abc",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: true
        )

        #expect(
            song.audioURL?.absoluteString
                == "https://uploads.example.com/audio/My%20Song.mp3?token=abc"
        )
    }

    @Test("audioURL is nil when both absolutePath and oss are nil")
    func songAudioURLNilWithoutAnyPath() {
        let song = Song(
            id: "song-nopath",
            title: "No Path",
            duration: 10,
            absolutePath: nil,
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: true
        )

        #expect(song.audioURL == nil)
    }

    @Test("Song decodes oss field from JSON")
    func songDecodesOssField() {
        useGlobalStorageRegion()
        let json = """
        {"id":"s1","title":"T","duration":5,"absolutePath":null,"oss":"audio/test.mp3","userUploaded":true}
        """.data(using: .utf8)!
        let song = try? JSONDecoder().decode(Song.self, from: json)
        #expect(song != nil)
        #expect(song?.oss == "audio/test.mp3")
        #expect(song?.audioURL?.absoluteString == "https://storage.neurokaraoke.com/audio/test.mp3")
    }

    @Test("Song decodes flexible metadata used by uploaded YouTube songs")
    func songDecodesFlexibleUploadedMetadata() throws {
        let json = """
        {
          "id": "youtube-1",
          "title": "Imported Song",
          "duration": "213.8",
          "absolutePath": "youtube/Imported Song.mp3",
          "cloudflareId": "artwork-id",
          "originalArtists": [{"name": "Original Artist"}],
          "coverArtists": "Uploader",
          "userUploaded": 1
        }
        """.data(using: .utf8)!

        let song = try JSONDecoder().decode(Song.self, from: json)

        #expect(song.duration == 213)
        #expect(song.originalArtists == ["Original Artist"])
        #expect(song.coverArtists == ["Uploader"])
        #expect(song.userUploaded == true)
        #expect(song.cloudflareID == "artwork-id")
    }

    @Test("Favorite responses decode uploaded songs wrapped in an envelope")
    func favoriteEnvelopeDecodesUploadedSong() throws {
        let json = """
        {
          "items": [
            {
              "song": {
                "id": "favorite-upload",
                "title": "Uploaded Favorite",
                "duration": 123.4,
                "absolutePath": null,
                "oss": "uploads/Uploaded Favorite.mp3",
                "userUploaded": "true"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let songs = try #require(SongPayloadDecoder.decodeSongs(from: json))

        #expect(songs.map(\.id) == ["favorite-upload"])
        #expect(songs.first?.userUploaded == true)
        #expect(
            songs.first?.audioURL?.absoluteString
                == "https://storage.neurokaraoke.com/uploads/Uploaded%20Favorite.mp3"
        )
    }

    @Test("Playlist detail skips malformed songs instead of failing the playlist")
    func playlistDetailSkipsMalformedSong() throws {
        let json = """
        {
          "id": "playlist-1",
          "name": "Uploads",
          "songListDTOs": [
            {
              "id": "youtube-1",
              "title": "YouTube Upload",
              "duration": "180",
              "absolutePath": "youtube/song.mp3",
              "originalArtists": [{"artistName": "Artist"}],
              "userUploaded": true
            },
            {
              "title": "Missing ID"
            }
          ]
        }
        """.data(using: .utf8)!

        let playlist = try JSONDecoder().decode(PlaylistDetail.self, from: json)

        #expect(playlist.songListDTOs.map(\.id) == ["youtube-1"])
    }

    @Test("Display artist combines original and cover artists")
    func displayArtistUsesOriginalAndCoverMetadata() {
        let song = Song(
            id: "song-3",
            title: "Test Song",
            duration: 180,
            absolutePath: nil,
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: ["Original"],
            coverArtists: ["Neuro"],
            userUploaded: false
        )

        #expect(song.displayTitle == "Test Song - Original")
        #expect(song.displayArtist == "Original · Cover by Neuro")
        #expect(song.hasArtistMetadata)
    }
}
