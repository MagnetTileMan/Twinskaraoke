import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Uploaded songs")
struct UploadedSongsViewModelTests {
    @Test("Duplicate uploaded songs retain API order")
    func duplicateSongsRetainAPIOrder() {
        let first = song(id: "first", title: "First")
        let duplicate = song(id: "first", title: "Duplicate")
        let second = song(id: "second", title: "Second")

        let songs = UploadedSongsViewModel.removingDuplicateSongs([first, duplicate, second])

        #expect(songs.map(\.id) == ["first", "second"])
        #expect(songs.first?.title == "First")
    }

    @Test("Task and URL cancellations use the cancellation path")
    func cancellationErrorsUseCancellationPath() {
        #expect(UploadedSongsViewModel.isCancellationError(CancellationError()))
        #expect(UploadedSongsViewModel.isCancellationError(URLError(.cancelled)))
        #expect(!UploadedSongsViewModel.isCancellationError(URLError(.timedOut)))
    }

    @Test("Resolved durations fill only missing values")
    func resolvedDurationsFillOnlyMissingValues() {
        let missingDuration = song(id: "missing", title: "Missing", duration: 0)
        let existingDuration = song(id: "existing", title: "Existing", duration: 90)

        let songs = UploadedSongsViewModel.applyingResolvedDurations(
            ["missing": 214, "existing": 999],
            to: [missingDuration, existingDuration]
        )

        #expect(songs.map(\.id) == ["missing", "existing"])
        #expect(songs.map(\.duration) == [214, 90])
        #expect(songs[0].absolutePath == missingDuration.absolutePath)
        #expect(songs[0].userUploaded == true)
    }

    private func song(id: String, title: String, duration: Int = 120) -> Song {
        Song(
            id: id,
            title: title,
            duration: duration,
            absolutePath: "uploads/\(id).m4a",
            cloudflareID: nil,
            coverArt: nil,
            originalArtists: nil,
            coverArtists: nil,
            userUploaded: true
        )
    }
}
