import SwiftUI

extension Color {
  static let appAccent = Color(red: 1.00, green: 0.29, blue: 0.40)
}

struct WatchLoadingIndicator: View {
  var size: CGFloat = 18
  var tint: Color = .secondary
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @AppStorage("nk.respectReducedMotion") private var respectReducedMotion: Bool = true
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      ForEach(0..<tickCount, id: \.self) { index in
        Capsule(style: .continuous)
          .fill(tint.opacity(opacity(for: index)))
          .frame(width: tickWidth, height: tickLength)
          .offset(y: -tickRadius)
          .rotationEffect(.degrees(Double(index) * tickAngle))
      }
    }
    .rotationEffect(.degrees(isAnimating ? 360 : 0))
    .frame(width: containerSize, height: containerSize)
    .animation(
      reduceMotion ? nil : .linear(duration: 0.82).repeatForever(autoreverses: false),
      value: isAnimating
    )
    .onAppear {
      isAnimating = !reduceMotion
    }
    .onChange(of: reduceMotion) { reduceMotion in
      isAnimating = !reduceMotion
    }
    .accessibilityLabel("Loading")
  }

  private var containerSize: CGFloat {
    min(max(size, 14), 28)
  }

  private var tickCount: Int {
    12
  }

  private var tickAngle: Double {
    360 / Double(tickCount)
  }

  private var tickWidth: CGFloat {
    max(containerSize * 0.07, 1.2)
  }

  private var tickLength: CGFloat {
    max(containerSize * 0.23, 3.4)
  }

  private var tickRadius: CGFloat {
    containerSize * 0.31
  }

  private func opacity(for index: Int) -> Double {
    let progress = Double(index) / Double(max(tickCount - 1, 1))
    return reduceMotion ? 0.58 : 0.16 + progress * 0.62
  }

  private var reduceMotion: Bool {
    WatchMotion.reduceMotion(
      systemReduceMotion: systemReduceMotion,
      respectPreference: respectReducedMotion
    )
  }
}
