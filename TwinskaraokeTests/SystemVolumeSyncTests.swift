import Testing
@testable import Twinskaraoke

@Suite("System volume synchronization")
struct SystemVolumeSyncTests {
    @Test("System volume replaces a stale player volume exactly")
    func systemVolumeReplacesStaleVolume() {
        let systemVolume: Float = 0.37

        let volume = SystemVolumeReconciliation.value(
            currentVolume: 0.8,
            systemVolume: systemVolume,
            isUserScrubbing: false
        )

        #expect(volume == Double(systemVolume))
    }

    @Test("System updates do not interrupt active volume scrubbing")
    func systemVolumeWaitsForScrubbingToFinish() {
        let currentVolume = 0.8

        let volume = SystemVolumeReconciliation.value(
            currentVolume: currentVolume,
            systemVolume: 0.2,
            isUserScrubbing: true
        )

        #expect(volume == currentVolume)
    }
}
