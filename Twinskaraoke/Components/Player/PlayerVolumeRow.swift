import SwiftUI

struct PlayerVolumeRow: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.scenePhase) private var scenePhase
    var horizontalPadding: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            AppleMusicProgressBar(
                progress: $audioManager.volume,
                isScrubbing: $audioManager.isUserScrubbingVolume,
                onSeekEnd: { _ in },
                trackColor: Color.primary.opacity(0.18),
                fillColor: .primary,
                idleHeight: 7,
                activeHeight: 12,
                accessibilityLabel: "Volume",
                accessibilityValueText: "\(Int(audioManager.volume * 100)) percent",
                accessibilityHint: "Drag or swipe up and down to adjust volume."
            )
            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, horizontalPadding)
        #if canImport(UIKit)
            .background(
                SystemVolumeBridge(
                    volume: $audioManager.volume,
                    isUserScrubbing: $audioManager.isUserScrubbingVolume
                )
                .id(scenePhase)
                .frame(width: 1, height: 1)
            )
        #endif
    }
}
