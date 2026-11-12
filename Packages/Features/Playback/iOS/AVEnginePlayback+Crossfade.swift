import AVFoundation
import Foundation

extension AVEnginePlayback {
    struct CrossfadeState {
        var timer: DispatchSourceTimer?
        var rampGeneration: UInt64 = 0
        var loadGeneration: UInt64 = 0
        var preloadTask: Task<LoadedMediaTransfer<AVAudioFile>, Error>?
        var loadingURL: URL?
        var pendingURL: URL?
        var preparedURL: URL?
        var isDeferredToNaturalEnd = false
        var isFading = false
        var startMainVolume: Float = 1
        var startVocalsVolume: Float = 0
        var startInstrumentalVolume: Float = 0
    }

    var isCrossfading: Bool { crossfade.isFading }
    var pendingCrossfadeURL: URL? { crossfade.pendingURL }
    var isCrossfadePending: Bool { pendingCrossfadeURL != nil }

    func resetCrossfadePlayback() {
        cancelCrossfadeLoadTasks()
        crossfade.rampGeneration &+= 1
        crossfade.timer?.cancel()
        crossfade.timer = nil
        crossfade.pendingURL = nil
        crossfade.isDeferredToNaturalEnd = false
        crossfade.preparedURL = nil
        crossfade.isFading = false
        crossfade.startMainVolume = 1.0
        crossfade.startVocalsVolume = 0
        crossfade.startInstrumentalVolume = 0
        unloadIncomingCrossfadeDeck()
    }

    nonisolated static let crossfadeSchedulingLead: TimeInterval = 0.08

    func preloadCrossfade(url: URL) {
        guard crossfade.pendingURL == nil, crossfade.preparedURL != url, crossfade.loadingURL != url else { return }
        cancelCrossfade()
        let generation = crossfade.loadGeneration
        let task = startCrossfadeLoad(url: url, priority: .utility)
        Task { [weak self] in
            do {
                let media = try await task.value.value
                guard let self, crossfade.loadGeneration == generation else { return }
                try prepareCrossfadeMedia(media, url: url)
            } catch {
                guard let self, crossfade.loadGeneration == generation else { return }
                cancelCrossfade()
                DebugLogger.log("Crossfade preload failed for \(url.lastPathComponent): \(error)", category: .playback)
            }
        }
    }

    func beginCrossfade(
        url: URL,
        duration: TimeInterval,
        ramp: RampStyle,
        remainingTime: (() -> TimeInterval?)? = nil
    ) {
        guard crossfade.pendingURL != url || crossfade.isDeferredToNaturalEnd else { return }
        crossfade.isDeferredToNaturalEnd = false
        if crossfade.preparedURL != url, crossfade.loadingURL != url { cancelCrossfade() }
        // Take ownership from the preload observer while retaining its task.
        crossfade.loadGeneration &+= 1
        let generation = crossfade.loadGeneration
        let token = playbackIntentGeneration
        crossfade.pendingURL = url

        Task { [weak self] in
            guard let self, isCurrentCrossfade(generation: generation, token: token) else { return }
            do {
                if crossfade.preparedURL != url {
                    if crossfade.preloadTask != nil {
                        DebugLogger.log("Reusing incoming preload for \(url.lastPathComponent)", category: .playback)
                    }
                    let task = crossfade.preloadTask ?? startCrossfadeLoad(url: url, priority: .userInitiated)
                    let media = try await task.value.value
                    guard isCurrentCrossfade(generation: generation, token: token) else { return }
                    try prepareCrossfadeMedia(media, url: url)
                }
                let remaining = if let remainingTime { remainingTime() } else { self.duration - currentTime }
                guard let remaining, remaining.isFinite else {
                    cancelCrossfade()
                    return
                }
                let tick = Self.transitionTimerInterval
                let playbackLeadTime = min(Self.crossfadeSchedulingLead, max(0, remaining - 2 * tick))
                let fadeDuration = min(duration, remaining - playbackLeadTime, incomingCrossfadeDeck.duration - tick)
                guard fadeDuration >= tick else {
                    // The prepared deck remains available to the outgoing song's end callback.
                    crossfade.isDeferredToNaturalEnd = true
                    DebugLogger.log(
                        "Crossfade deferred to natural end: remaining=\(remaining), requested=\(duration), availableFade=\(fadeDuration)",
                        category: .playback
                    )
                    return
                }
                self.startEngineIfNeeded()
                guard isCurrentCrossfade(generation: generation, token: token) else { return }
                guard self.isEngineRunning else {
                    cancelCrossfade()
                    return
                }
                scheduleCrossfade(url: url, requested: duration, duration: fadeDuration, lead: playbackLeadTime, ramp: ramp)
            } catch {
                guard self.isCurrentCrossfade(generation: generation, token: token) else { return }
                self.cancelCrossfade()
                DebugLogger.log("Crossfade load failed for \(url.lastPathComponent): \(error)", category: .playback)
            }
        }
    }

    private func scheduleCrossfade(
        url: URL, requested: TimeInterval, duration fadeDuration: TimeInterval,
        lead playbackLeadTime: TimeInterval, ramp: RampStyle
    ) {
        self.crossfade.isFading = true
        self.crossfade.startMainVolume = self.outgoingCrossfadeDeck.volume
        self.crossfade.startVocalsVolume = self.stemVocals.volume
        self.crossfade.startInstrumentalVolume = self.stemInstrumental.volume
        self.incomingCrossfadeDeck.volume = 0
        let scheduledStart = AVAudioTime.now().offset(seconds: playbackLeadTime)
        let startUptime = ProcessInfo.processInfo.systemUptime + playbackLeadTime
        self.incomingCrossfadeDeck.play(from: 0, at: scheduledStart)
        DebugLogger.log(
            "Crossfade playback scheduled for \(url.lastPathComponent), requested=\(requested), fade=\(fadeDuration)",
            category: .playback
        )
        self.crossfade.rampGeneration &+= 1
        let rampGeneration = self.crossfade.rampGeneration
        let mainNode = self.outgoingCrossfadeDeck.playerNode
        let vocalsNode = self.stemVocals.playerNode
        let instrumentalNode = self.stemInstrumental.playerNode
        let incomingNode = self.incomingCrossfadeDeck.playerNode
        let fadesStems = self.mode == .aiStems
        let startMainVolume = self.crossfade.startMainVolume
        let startVocalsVolume = self.crossfade.startVocalsVolume
        let startInstrumentalVolume = self.crossfade.startInstrumentalVolume
        // AVEnginePlayback and its player nodes are main-actor
        // isolated. Keep the ramp handler on that executor too.
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + playbackLeadTime,
            repeating: min(Self.transitionTimerInterval, fadeDuration / 4),
            leeway: .milliseconds(2)
        )
        timer.setEventHandler { [weak self] in
            guard let self,
                  self.crossfade.rampGeneration == rampGeneration,
                  self.crossfade.isFading
            else { return }

            let elapsed = max(0, ProcessInfo.processInfo.systemUptime - startUptime)
            let t = Float(min(1, elapsed / fadeDuration))
            let outVolume: Float
            let inVolume: Float
            switch ramp {
            case .equalPower:
                outVolume = cos(t * .pi / 2)
                inVolume = sin(t * .pi / 2)
            case .linear:
                outVolume = 1 - t
                inVolume = t
            }
            mainNode.volume = max(0, startMainVolume * outVolume)
            if fadesStems {
                vocalsNode.volume = max(0, startVocalsVolume * outVolume)
                instrumentalNode.volume = max(0, startInstrumentalVolume * outVolume)
            }
            incomingNode.volume = max(0, inVolume)
            guard t >= 1 else { return }
            if self.hasPlayableIncomingMedia {
                self.finalizeCrossfade()
            } else {
                self.abortExhaustedCrossfade()
            }
        }
        self.crossfade.timer = timer
        timer.resume()
        self.onCrossfadeScheduled?(playbackLeadTime + fadeDuration)
    }

    private func isCurrentCrossfade(generation: UInt64, token: UInt64) -> Bool {
        guard crossfade.loadGeneration == generation else { return false }
        guard playbackIntentGeneration == token else {
            cancelCrossfade()
            return false
        }
        return true
    }

    var hasPlayableMainMedia: Bool {
        isEngineRunning && isPlaying && hasScheduledMedia && currentTime < duration
    }

    private var hasPlayableIncomingMedia: Bool {
        incomingCrossfadeDeck.hasScheduledMedia && incomingCrossfadeDeck.currentTime < incomingCrossfadeDeck.duration
    }

    var hasAudibleCrossfade: Bool {
        crossfade.isFading && hasPlayableIncomingMedia
            && incomingCrossfadeDeck.currentTime > 0 && incomingCrossfadeDeck.volume > 0
    }

    func abortExhaustedCrossfade() {
        DebugLogger.log("Crossfade incoming deck exhausted before promotion", category: .playback)
        cancelCrossfade()
        onCrossfadeAborted?()
    }

    @discardableResult
    func finishPreparedCrossfade(to url: URL, reason: String = "handoff") -> Bool {
        guard crossfade.preparedURL == url, incomingCrossfadeDeck.duration > 0.1, isEngineRunning else {
            DebugLogger.log("Crossfade promotion refused at \(reason): deck not ready or engine stopped", category: .playback)
            return false
        }
        guard !crossfade.isFading || hasPlayableIncomingMedia else {
            DebugLogger.log("Crossfade promotion refused at \(reason): incoming deck exhausted", category: .playback)
            return false
        }

        // Preserve the position of a deck that already started rendering.
        if !crossfade.isFading || incomingCrossfadeDeck.currentTime <= 0 {
            incomingCrossfadeDeck.volume = 1
            incomingCrossfadeDeck.play(from: 0)
        }
        guard hasPlayableIncomingMedia else { return false }
        DebugLogger.log("Crossfade promotion accepted at \(reason)", category: .playback)
        crossfade.pendingURL = url
        finalizeCrossfade()
        return true
    }

    func cancelCrossfade() {
        cancelCrossfadeLoadTasks()
        crossfade.rampGeneration &+= 1
        crossfade.timer?.cancel()
        crossfade.timer = nil
        crossfade.preparedURL = nil
        crossfade.pendingURL = nil
        crossfade.isDeferredToNaturalEnd = false
        guard crossfade.isFading else {
            unloadIncomingCrossfadeDeck()
            return
        }
        crossfade.isFading = false
        unloadIncomingCrossfadeDeck()
        outgoingCrossfadeDeck.volume = crossfade.startMainVolume
        if mode == .aiStems {
            setStemVolumes(
                vocals: crossfade.startVocalsVolume,
                instrumental: crossfade.startInstrumentalVolume
            )
        }
    }

    private func finalizeCrossfade() {
        crossfade.rampGeneration &+= 1
        crossfade.timer?.cancel()
        crossfade.timer = nil
        crossfade.isFading = false

        cancelCrossfadeLoadTasks()
        promoteCrossfadeDeck(url: crossfade.pendingURL)
        crossfade.pendingURL = nil
        crossfade.isDeferredToNaturalEnd = false
        crossfade.preparedURL = nil
        onCrossfadeCompleted?()
    }

    private func cancelCrossfadeLoadTasks() {
        crossfade.loadGeneration &+= 1
        crossfade.preloadTask?.cancel()
        crossfade.preloadTask = nil
        crossfade.loadingURL = nil
    }

    private func startCrossfadeLoad(
        url: URL,
        priority: TaskPriority
    ) -> Task<LoadedMediaTransfer<AVAudioFile>, Error> {
        DebugLogger.log("Starting incoming load for \(url.lastPathComponent)", category: .playback)
        let loader = crossfadeFileLoader
        let task = Task.detached(priority: priority) {
            try Task.checkCancellation()
            return LoadedMediaTransfer(value: try loader(url))
        }
        crossfade.loadingURL = url
        crossfade.preloadTask = task
        return task
    }

    private func prepareCrossfadeMedia(_ media: AVAudioFile, url: URL) throws {
        try loadIncomingCrossfadeDeck(media)
        crossfade.preloadTask = nil
        crossfade.loadingURL = nil
        crossfade.preparedURL = url
        incomingCrossfadeDeck.volume = 0
    }
}
