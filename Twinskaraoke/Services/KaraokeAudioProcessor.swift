import AVFoundation
import MediaToolbox

/// Wraps `MTAudioProcessingTap` to provide center-channel ("vocal") attenuation
/// on an `AVPlayerItem`. Stereo recordings typically pan the lead vocal dead
/// center, so subtracting the side-content's mid component reduces it.
///
/// This is a global processor (single attenuation value) because the tap's
/// process callback must be `@convention(c)` and cannot capture state.
enum KaraokeAudioProcessor {
  /// 0 = vocals untouched, 1 = vocals fully cancelled.
  static var vocalAttenuation: Float = 0
  @MainActor
  static func attachVocalCancel(to playerItem: AVPlayerItem) {
    let asset = playerItem.asset
    Task { @MainActor in
      let tracks: [AVAssetTrack]
      if #available(iOS 15.0, *) {
        tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
      } else {
        tracks = asset.tracks(withMediaType: .audio)
      }
      guard let track = tracks.first else { return }
      var callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: nil,
        finalize: nil,
        prepare: karaokeTapPrepare,
        unprepare: nil,
        process: karaokeTapProcess
      )
      var unmanagedTap: Unmanaged<MTAudioProcessingTap>?
      let status = withUnsafeMutablePointer(to: &unmanagedTap) { ptr -> OSStatus in
        ptr.withMemoryRebound(to: Optional<MTAudioProcessingTap>.self, capacity: 1) { rebound in
          MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PreEffects,
            rebound
          )
        }
      }
      guard status == noErr, let tap = unmanagedTap?.takeRetainedValue() else { return }
      let mix = AVMutableAudioMix()
      let params = AVMutableAudioMixInputParameters(track: track)
      params.audioTapProcessor = tap
      mix.inputParameters = [params]
      playerItem.audioMix = mix
    }
  }
}

/// The audio format the tap is processing. Captured in `prepare` and read in
/// `process` so we can correctly handle both interleaved and non-interleaved
/// stereo (AAC/MP3 decoders typically deliver interleaved stereo on iOS, while
/// AVAudioEngine paths often deliver non-interleaved).
private struct KaraokeTapFormat {
  var channels: Int
  var isInterleaved: Bool
  var isFloat: Bool
  var sampleRate: Double
}

private var karaokeTapFormat = KaraokeTapFormat(
  channels: 2, isInterleaved: true, isFloat: true, sampleRate: 44100)

/// One-pole filter states for the mid signal. We split the centered (mid)
/// component into three bands so that bass and air-band treble survive even
/// at full attenuation. Vocal fundamentals and harmonics live entirely inside
/// the 120 Hz–9 kHz band, so cancelling that band cleanly removes vocals
/// without gutting kick punch or cymbal sheen.
private var midLowState: Float = 0
private var midHighState: Float = 0
private let midBassCutoffHz: Double = 120
private let midTrebleCutoffHz: Double = 9000

private let karaokeTapPrepare: MTAudioProcessingTapPrepareCallback = {
  _, _, format in
  let asbd = format.pointee
  let channels = Int(asbd.mChannelsPerFrame)
  let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
  let isInterleaved = (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0
  let sr = asbd.mSampleRate > 0 ? asbd.mSampleRate : 44100
  karaokeTapFormat = KaraokeTapFormat(
    channels: channels, isInterleaved: isInterleaved, isFloat: isFloat, sampleRate: sr)
  midLowState = 0
  midHighState = 0
}

private let karaokeTapProcess: MTAudioProcessingTapProcessCallback = {
  tap, numFrames, _, bufferList, framesProcessedOut, flagsOut in
  var timeRange = CMTimeRange()
  let status = MTAudioProcessingTapGetSourceAudio(
    tap, numFrames, bufferList, flagsOut, &timeRange, framesProcessedOut)
  guard status == noErr else { return }
  let attenuation = KaraokeAudioProcessor.vocalAttenuation
  guard attenuation > 0.001 else { return }
  let abl = UnsafeMutableAudioBufferListPointer(bufferList)
  let frames = Int(framesProcessedOut.pointee)
  guard frames > 0 else { return }
  let fmt = karaokeTapFormat
  guard fmt.channels >= 2, fmt.isFloat else { return }
  let shaped = attenuation * attenuation * (3 - 2 * attenuation)
  let keep = 1.0 - shaped
  let makeupGain: Float = 1.0 + shaped
  let dt = 1.0 / fmt.sampleRate
  let alphaLow = Float(dt / (1.0 / (2.0 * .pi * midBassCutoffHz) + dt))
  let alphaHigh = Float(dt / (1.0 / (2.0 * .pi * midTrebleCutoffHz) + dt))
  var lowState = midLowState
  var highState = midHighState
  if fmt.isInterleaved {
    guard let buf = abl[0].mData?.assumingMemoryBound(to: Float.self) else { return }
    let stride = fmt.channels
    for i in 0..<frames {
      let li = i * stride
      let ri = li + 1
      let l = buf[li]
      let r = buf[ri]
      let mid = (l + r) * 0.5
      let side = (l - r) * 0.5
      lowState += alphaLow * (mid - lowState)
      highState += alphaHigh * (mid - highState)
      let bass = lowState
      let air = mid - highState
      let vocalBand = highState - lowState
      let processedMid = bass + air + vocalBand * keep
      let outL = (processedMid + side) * makeupGain
      let outR = (processedMid - side) * makeupGain
      buf[li] = tanhf(outL)
      buf[ri] = tanhf(outR)
    }
  } else {
    guard abl.count >= 2,
      let l = abl[0].mData?.assumingMemoryBound(to: Float.self),
      let r = abl[1].mData?.assumingMemoryBound(to: Float.self)
    else { return }
    for i in 0..<frames {
      let mid = (l[i] + r[i]) * 0.5
      let side = (l[i] - r[i]) * 0.5
      lowState += alphaLow * (mid - lowState)
      highState += alphaHigh * (mid - highState)
      let bass = lowState
      let air = mid - highState
      let vocalBand = highState - lowState
      let processedMid = bass + air + vocalBand * keep
      let outL = (processedMid + side) * makeupGain
      let outR = (processedMid - side) * makeupGain
      l[i] = tanhf(outL)
      r[i] = tanhf(outR)
    }
  }
  midLowState = lowState
  midHighState = highState
}
