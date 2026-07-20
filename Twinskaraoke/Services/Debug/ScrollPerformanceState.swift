import Combine
import SwiftUI

@MainActor
final class ScrollPerformanceState: ObservableObject {
    static let shared = ScrollPerformanceState()

    @Published private(set) var isScrolling = false

    private var activeScrollIDs = Set<UUID>()
    private var scrollEndWorkItem: DispatchWorkItem?
    private var scrollEndGeneration: UInt = 0

    private init() {}

    func update(id: UUID, isScrolling scrolling: Bool) {
        if scrolling {
            cancelPendingScrollEnd()
            activeScrollIDs.insert(id)
        } else {
            activeScrollIDs.remove(id)
        }
        scheduleScrollStateUpdate()
    }

    private func scheduleScrollStateUpdate() {
        cancelPendingScrollEnd()
        if !activeScrollIDs.isEmpty {
            setScrolling(true)
            return
        }

        let generation = scrollEndGeneration
        let workItem = DispatchWorkItem { @MainActor [weak self] in
            guard let self, self.scrollEndGeneration == generation else { return }
            self.scrollEndWorkItem = nil
            self.setScrolling(false)
        }
        scrollEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14, execute: workItem)
    }

    private func cancelPendingScrollEnd() {
        scrollEndGeneration &+= 1
        scrollEndWorkItem?.cancel()
        scrollEndWorkItem = nil
    }

    private func setScrolling(_ scrolling: Bool) {
        guard isScrolling != scrolling else { return }
        isScrolling = scrolling
    }
}
