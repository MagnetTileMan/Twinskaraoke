import SwiftUI

#if os(iOS)
  import UIKit
#endif

enum DisplayRefreshRate {

  static var maximumFramesPerSecond: Int {
    #if os(iOS)
      let sceneMaximum = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.screen.maximumFramesPerSecond }
        .max()
      return max(sceneMaximum ?? 60, 60)
    #else
      return 60
    #endif
  }

  static var lightweightAnimationInterval: TimeInterval {
    1.0 / Double(min(maximumFramesPerSecond, 60))
  }

  static var decorativeAnimationInterval: TimeInterval {
    1.0 / 30.0
  }
}

// MARK: - Reduce Motion EnvironmentKey

struct AppReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether reduce-motion should be respected, combining the system
    /// accessibility setting with the user's in-app preference.
    var appReduceMotion: Bool {
        get { self[AppReduceMotionKey.self] }
        set { self[AppReduceMotionKey.self] = newValue }
    }
}

extension View {
    /// Injects the computed `appReduceMotion` flag into the environment so
    /// child views can read `@Environment(\.appReduceMotion)` instead of
    /// repeating the `@AppStorage + @Environment + AppMotion.reduceMotion`
    /// boilerplate.  Apply once at the root of each view tree.
    func injectReduceMotion() -> some View {
        ReduceMotionInjector(content: self)
    }
}

private struct ReduceMotionInjector: View {
    let content: AnyView
    @AppStorage("nk.respectReducedMotion") private var respectReducedMotion: Bool = true
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    init(content: some View) {
        self.content = AnyView(content)
    }

    var body: some View {
        content.environment(\.appReduceMotion, AppMotion.reduceMotion(
            systemReduceMotion: systemReduceMotion,
            respectPreference: respectReducedMotion
        ))
    }
}

// MARK: - AppMotion

enum AppMotion {
  static func reduceMotion(systemReduceMotion: Bool, respectPreference: Bool) -> Bool {
    respectPreference && systemReduceMotion
  }

  static func duration(_ seconds: TimeInterval) -> TimeInterval {
    max(0, seconds)
  }

  static func easeInOut(duration seconds: TimeInterval) -> Animation {
    .easeInOut(duration: duration(seconds))
  }

  static func easeOut(duration seconds: TimeInterval) -> Animation {
    .easeOut(duration: duration(seconds))
  }

  static func linear(duration seconds: TimeInterval) -> Animation {
    .linear(duration: duration(seconds))
  }

  static func spring(response: TimeInterval, dampingFraction: Double) -> Animation {
    .spring(response: duration(response), dampingFraction: dampingFraction)
  }
}
