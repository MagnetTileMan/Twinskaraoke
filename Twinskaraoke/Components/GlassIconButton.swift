import SwiftUI

struct GlassXButton: View {
  var action: () -> Void
  var size: CGFloat = 44
  var iconSize: CGFloat = 16
  var accessibilityLabel = "Close"

  var body: some View {
    Button(action: action) {
      icon
        .frame(width: size, height: size)
        .background { GlassIconButtonDisc() }
        .contentShape(Circle())
    }
    .buttonStyle(PressableButtonStyle(scale: 0.88, dim: 0.6))
    .buttonBorderShape(.circle)
  }

  private var icon: some View {
    Label(accessibilityLabel, systemImage: "xmark")
      .labelStyle(.iconOnly)
      .font(.system(size: iconSize, weight: .semibold))
      .foregroundStyle(Color.appGlassForeground)
  }
}

private struct GlassIconButtonDisc: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Circle()
      .fill(.regularMaterial)
      .overlay {
        Circle()
          .fill(
            LinearGradient(
              stops: [
                .init(color: sheenColor, location: 0),
                .init(color: .clear, location: 0.56),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
      }
      .overlay {
        Circle()
          .strokeBorder(
            LinearGradient(
              colors: [rimHighlight, rimShadow],
              startPoint: .top,
              endPoint: .bottom
            ),
            lineWidth: 0.8
          )
      }
      .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
  }

  private var sheenColor: Color {
    colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.55)
  }

  private var rimHighlight: Color {
    colorScheme == .dark ? Color.white.opacity(0.24) : Color.white.opacity(0.90)
  }

  private var rimShadow: Color {
    colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.06)
  }

  private var shadowColor: Color {
    colorScheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.10)
  }
}

struct GlassCheckmarkButton: View {
  var action: () -> Void
  var size: CGFloat = 44
  var iconSize: CGFloat = 16
  var isEnabled: Bool = true
  var accessibilityLabel = "Done"

  var body: some View {
    Button(action: action) {
      icon
        .frame(width: size, height: size)
        .modifier(GlassCircle())
        .contentShape(Circle())
    }
    .disabled(!isEnabled)
    .buttonStyle(PressableButtonStyle(scale: 0.88, dim: 0.6))
    .buttonBorderShape(.circle)
  }

  private var icon: some View {
    Label(accessibilityLabel, systemImage: "checkmark")
      .labelStyle(.iconOnly)
      .font(.system(size: iconSize, weight: .semibold))
      .foregroundStyle(isEnabled ? Color.appGlassForeground : Color.secondary)
  }
}
