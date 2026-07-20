import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Download validation")
struct DownloadManagerTests {
    @Test("Fallback artwork selection is stable and bounded")
    func fallbackArtworkSelectionIsDeterministic() {
        let first = FallbackArtProvider.fallbackIndex(for: "song-without-art", count: 12)
        let second = FallbackArtProvider.fallbackIndex(for: "song-without-art", count: 12)
        #expect(first == second)
        #expect((0 ..< 12).contains(first))
        #expect(FallbackArtProvider.fallbackIndex(for: "song", count: 0) == 0)
    }

    @Test("Startup cleanup only removes partial files from before launch")
    func startupCleanupPreservesCurrentPartialFiles() {
        let cutoff = Date()
        #expect(
            AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3.partial",
                modifiedAt: cutoff.addingTimeInterval(-1),
                createdBefore: cutoff
            )
        )
        #expect(
            !AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3.partial",
                modifiedAt: cutoff.addingTimeInterval(1),
                createdBefore: cutoff
            )
        )
        #expect(
            !AudioCacheStore.shouldRemovePartialFile(
                named: "main.mp3",
                modifiedAt: cutoff.addingTimeInterval(-1),
                createdBefore: cutoff
            )
        )
    }

    @Test("Only uncompressed stem formats are selected for compression")
    func cacheCompressionSkipsAlreadyCompressedAudio() {
        #expect(AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/vocals.wav")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/main.mp3")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/main.m4a")))
        #expect(!AudioCacheStore.shouldCompressPlayableFile(at: URL(fileURLWithPath: "/tmp/vocals.wav.nkz")))
    }

    @Test("Catalog rounding and longer files are accepted")
    func durationAcceptsHealthyFiles() {
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 198,
                expectedDuration: 200
            )
        )
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 205,
                expectedDuration: 200
            )
        )
        #expect(
            DownloadManager.durationAppearsComplete(
                actualDuration: 180,
                expectedDuration: nil
            )
        )
    }

    @Test("Truncated and unreadable files are rejected")
    func durationRejectsBrokenFiles() {
        #expect(
            !DownloadManager.durationAppearsComplete(
                actualDuration: 120,
                expectedDuration: 200
            )
        )
        #expect(
            !DownloadManager.durationAppearsComplete(
                actualDuration: 0,
                expectedDuration: 200
            )
        )
    }

    @Test("Download status reflects only the requested song")
    func downloadStatusUsesRequestedSong() {
        let downloadedIDs: Set<String> = ["downloaded"]
        let inProgress: Set<String> = ["downloading"]

        #expect(
            SongDownloadStatus.make(
                downloadedIDs: downloadedIDs,
                inProgress: inProgress,
                songID: "downloaded"
            ) == SongDownloadStatus(isDownloaded: true, isDownloading: false)
        )
        #expect(
            SongDownloadStatus.make(
                downloadedIDs: downloadedIDs,
                inProgress: inProgress,
                songID: "downloading"
            ) == SongDownloadStatus(isDownloaded: false, isDownloading: true)
        )
        #expect(
            SongDownloadStatus.make(
                downloadedIDs: downloadedIDs,
                inProgress: inProgress,
                songID: "other"
            ) == SongDownloadStatus(isDownloaded: false, isDownloading: false)
        )
    }

    @Test("Audio cache access does not mutate persistent download files")
    func cacheTouchLeavesExternalFilesUnchanged() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("main.mp3")
        #expect(FileManager.default.createFile(atPath: fileURL.path, contents: Data([0])))

        let originalDate = Date(timeIntervalSince1970: 946_684_800)
        try FileManager.default.setAttributes(
            [.modificationDate: originalDate],
            ofItemAtPath: fileURL.path
        )

        AudioCacheStore.touch(fileURL)

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        #expect(attributes[.modificationDate] as? Date == originalDate)
    }

    @Test("Startup cleanup removes only stale promotion staging files")
    func startupCleanupRemovesStalePromotionFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let stale = directory.appendingPathComponent("main.mp3.promoting-stale")
        let current = directory.appendingPathComponent("main.source.promoting-current")
        let download = directory.appendingPathComponent("main.mp3")
        for file in [stale, current, download] {
            #expect(FileManager.default.createFile(atPath: file.path, contents: Data([0])))
        }

        let cutoff = Date()
        try FileManager.default.setAttributes(
            [.modificationDate: cutoff.addingTimeInterval(-1)],
            ofItemAtPath: stale.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: cutoff.addingTimeInterval(1)],
            ofItemAtPath: current.path
        )

        DownloadManager.removePromotionStagingFiles(in: directory, createdBefore: cutoff)

        #expect(!FileManager.default.fileExists(atPath: stale.path))
        #expect(FileManager.default.fileExists(atPath: current.path))
        #expect(FileManager.default.fileExists(atPath: download.path))
    }
}
