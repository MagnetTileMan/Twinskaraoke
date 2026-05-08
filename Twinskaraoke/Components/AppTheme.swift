import SwiftUI

extension Color {
  static let appAccent = Color(red: 0.98, green: 0.176, blue: 0.282)
}

enum AM {
  enum Radius {
    static let thumb: CGFloat = 6
    static let card: CGFloat = 6
    static let hero: CGFloat = 8
    static let tile: CGFloat = 8
    static let popup: CGFloat = 6
    static let sheet: CGFloat = 14
  }

  enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let screenMargin: CGFloat = 16
    static let shelfSpacing: CGFloat = 28
    static let shelfTile: CGFloat = 170
  }

  enum Font {
    static let sectionHeader = SwiftUI.Font.system(size: 22, weight: .bold)
    static let groupHeader = SwiftUI.Font.system(size: 17, weight: .bold)
    static let tileTitle = SwiftUI.Font.system(size: 15, weight: .semibold)
    static let tileCaption = SwiftUI.Font.system(size: 13)
    static let rowTitle = SwiftUI.Font.system(size: 16, weight: .regular)
    static let rowSubtitle = SwiftUI.Font.system(size: 13)
    static let nowPlayingTitle = SwiftUI.Font.system(size: 22, weight: .bold)
    static let nowPlayingArtist = SwiftUI.Font.system(size: 17)
    static let timecode = SwiftUI.Font.system(size: 12, weight: .medium, design: .monospaced)
    static let chevron = SwiftUI.Font.system(size: 14, weight: .bold)
  }

  enum Shadow {
    static let card = ShadowStyle(color: .black.opacity(0.18), radius: 10, y: 4)
    static let heroIdle = ShadowStyle(color: .black.opacity(0.22), radius: 16, y: 10)
    static let heroPlaying = ShadowStyle(color: .black.opacity(0.45), radius: 28, y: 18)
  }

  struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
  }
}

extension View {
  func amShadow(_ style: AM.ShadowStyle) -> some View {
    self.shadow(color: style.color, radius: style.radius, y: style.y)
  }
}

struct AMSectionHeader<Destination: View>: View {
  let title: String
  let destination: Destination?
  init(_ title: String, destination: Destination) {
    self.title = title
    self.destination = destination
  }
  init(_ title: String) where Destination == EmptyView {
    self.title = title
    self.destination = nil
  }
  var body: some View {
    Group {
      if let destination {
        NavigationLink(destination: destination) {
          headerRow(showChevron: true)
        }
        .buttonStyle(.plain)
      } else {
        headerRow(showChevron: false)
      }
    }
    .padding(.horizontal, AM.Spacing.screenMargin)
  }
  private func headerRow(showChevron: Bool) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: AM.Spacing.xs) {
      Text(title)
        .font(AM.Font.sectionHeader)
        .foregroundColor(.primary)
      if showChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(.secondary.opacity(0.7))
      }
      Spacer()
    }
    .contentShape(Rectangle())
  }
}
