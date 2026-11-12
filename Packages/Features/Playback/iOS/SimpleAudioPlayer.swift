import AVFoundation
import Foundation

@MainActor
final class SimpleAudioPlayer {
    let playerNode = AVAudioPlayerNode()
    let sourceMixer = AVAudioMixerNode()
    var completionHandler: (() -> Void)?

    private var loadedFile: AVAudioFile?
    private var seekOffset: TimeInterval = 0
    private var pausedPosition: TimeInterval?
    private var _isPaused = false
    private var scheduleGeneration: UInt64 = 0
    // True while the node holds a not-yet-consumed scheduled segment. A pause
    // after natural playback end leaves the segment fully played out, and
    // resuming such a node would report isPlaying while rendering silence
    // with no completion ever firing.
    private(set) var hasScheduledMedia = false

    var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = newValue }
    }

    var isPlaying: Bool {
        playerNode.isPlaying
    }

    var duration: TimeInterval {
        if let file = loadedFile {
            guard file.fileFormat.sampleRate > 0 else { return 0 }
            return Double(file.length) / file.fileFormat.sampleRate
        }
        return 0
    }

    var currentTime: TimeInterval {
        guard playerNode.isPlaying,
              let nodeTime = playerNode.lastRenderTime,
              nodeTime.isSampleTimeValid,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return pausedPosition ?? seekOffset }
        return seekOffset + max(0, Double(playerTime.sampleTime) / playerTime.sampleRate)
    }

    func load(file: AVAudioFile) throws {
        invalidateScheduledPlayback()
        loadedFile = file
        seekOffset = 0
        pausedPosition = nil
        _isPaused = false
    }

    func unload() {
        invalidateScheduledPlayback()
        loadedFile = nil
        seekOffset = 0
        pausedPosition = nil
        _isPaused = false
    }

    func play() {
        if _isPaused {
            _isPaused = false
            pausedPosition = nil
            playerNode.play()
            return
        }
        play(from: 0)
    }

    func play(from seconds: TimeInterval, at time: AVAudioTime? = nil) {
        _isPaused = false
        invalidateScheduledPlayback()
        seekOffset = max(0, seconds)
        pausedPosition = nil

        let generation = scheduleGeneration
        guard let file = loadedFile, scheduleFileSegment(file, at: time) else {
            // Preserve the asynchronous shape of a natural node completion.
            // A later stop/load invalidates this generation before delivery.
            Task { @MainActor [weak self] in
                self?.deliverCompletion(for: generation)
            }
            return
        }

        if let time {
            playerNode.play(at: time)
        } else {
            playerNode.play()
        }
    }

    func pause() {
        pausedPosition = currentTime
        playerNode.pause()
        _isPaused = true
    }

    func stop() {
        invalidateScheduledPlayback()
        _isPaused = false
        seekOffset = 0
        pausedPosition = nil
    }

    private func invalidateScheduledPlayback() {
        scheduleGeneration &+= 1
        hasScheduledMedia = false
        // Completion handlers can run when stop() unschedules media. Incrementing
        // first makes those callbacks stale by construction.
        playerNode.stop()
    }

    @discardableResult
    private func scheduleFileSegment(_ file: AVAudioFile, at time: AVAudioTime?) -> Bool {
        let sampleRate = file.fileFormat.sampleRate
        let startFrame = AVAudioFramePosition(seekOffset * sampleRate)
        let remaining = AVAudioFrameCount(max(0, file.length - startFrame))
        guard remaining > 0 else { return false }
        let generation = scheduleGeneration
        playerNode.scheduleSegment(
            file, startingFrame: startFrame, frameCount: remaining, at: time,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.deliverCompletion(for: generation)
            }
        }
        hasScheduledMedia = true
        return true
    }

    private func deliverCompletion(for generation: UInt64) {
        guard scheduleGeneration == generation else { return }
        hasScheduledMedia = false
        completionHandler?()
    }

    #if DEBUG
        var scheduleGenerationForTesting: UInt64 { scheduleGeneration }
        var loadedFileFormatForTesting: AVAudioFormat? { loadedFile?.processingFormat }

        func deliverCompletionForTesting(scheduledGeneration: UInt64) {
            deliverCompletion(for: scheduledGeneration)
        }
    #endif
}
