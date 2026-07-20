#if canImport(UIKit)
    import UIKit

    @MainActor
    final class ImageSaver: NSObject {
        static let shared = ImageSaver()

        private struct SaveRequest {
            let image: UIImage
            let completion: (Result<Void, Error>) -> Void
        }

        private var pendingRequests: [SaveRequest] = []
        private var activeCompletion: ((Result<Void, Error>) -> Void)?

        func save(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
            pendingRequests.append(SaveRequest(image: image, completion: completion))
            startNextRequestIfNeeded()
        }

        private func startNextRequestIfNeeded() {
            guard activeCompletion == nil, !pendingRequests.isEmpty else { return }

            let request = pendingRequests.removeFirst()
            activeCompletion = request.completion
            UIImageWriteToSavedPhotosAlbum(
                request.image,
                self,
                #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }

        @objc private func didFinishSaving(
            _: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer?
        ) {
            let completion = activeCompletion
            activeCompletion = nil

            if let error {
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }

            startNextRequestIfNeeded()
        }
    }
#endif
