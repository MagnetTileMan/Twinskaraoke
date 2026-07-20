#if canImport(UIKit)
    import MediaPlayer
    import SwiftUI

    enum SystemVolumeReconciliation {
        static func value(
            currentVolume: Double,
            systemVolume: Float,
            isUserScrubbing: Bool
        ) -> Double {
            isUserScrubbing ? currentVolume : Double(systemVolume)
        }
    }

    struct SystemVolumeBridge: UIViewRepresentable {
        @Binding var volume: Double
        @Binding var isUserScrubbing: Bool
        func makeUIView(context _: Context) -> MPVolumeView {
            let view = MPVolumeView(frame: .zero)
            view.alpha = 0.0001
            synchronizeVolume(from: view)
            return view
        }

        func updateUIView(_ uiView: MPVolumeView, context _: Context) {
            guard isUserScrubbing else { return }
            DispatchQueue.main.async {
                guard let slider = uiView.subviews.compactMap({ $0 as? UISlider }).first else { return }
                let target = Float(max(0, min(1, volume)))
                if abs(slider.value - target) > 0.005 {
                    slider.setValue(target, animated: false)
                    slider.sendActions(for: .valueChanged)
                }
            }
        }

        private func synchronizeVolume(from view: MPVolumeView) {
            DispatchQueue.main.async {
                view.layoutIfNeeded()
                guard let slider = view.subviews.compactMap({ $0 as? UISlider }).first else { return }
                let reconciledVolume = SystemVolumeReconciliation.value(
                    currentVolume: volume,
                    systemVolume: slider.value,
                    isUserScrubbing: isUserScrubbing
                )
                if volume != reconciledVolume {
                    volume = reconciledVolume
                }
            }
        }
    }
#endif
