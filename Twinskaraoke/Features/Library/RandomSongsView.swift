import SwiftUI

struct RandomSongsView: View {
  @StateObject var viewModel = RandomSongsViewModel()
  @EnvironmentObject var audioManager: AudioPlayerManager
  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        artworkMosaic
          .frame(width: 240, height: 240)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        VStack(spacing: 4) {
          Text("Random Songs")
            .font(.title2.bold())
            .multilineTextAlignment(.center)
          Text(viewModel.songs.isEmpty ? "Tap refresh to roll" : "\(viewModel.songs.count) songs")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        if !viewModel.songs.isEmpty {
          HStack(spacing: 12) {
            Button {
              if let first = viewModel.songs.first {
                audioManager.playInOrder(song: first, context: viewModel.songs)
              }
            } label: {
              actionLabel(symbol: "play.fill", text: "Play")
            }
            .buttonStyle(PressableButtonStyle())
            Button {
              audioManager.playShuffled(from: viewModel.songs)
            } label: {
              actionLabel(symbol: "shuffle", text: "Shuffle")
            }
            .buttonStyle(PressableButtonStyle())
          }
          .padding(.horizontal)
          LazyVStack(spacing: 0) {
            ForEach(viewModel.songs) { song in
              Button {
                audioManager.play(song: song, context: viewModel.songs)
              } label: {
                SongRow(song: song, size: .regular)
                  .padding(.horizontal)
                  .padding(.vertical, 8)
              }
              .buttonStyle(PressableButtonStyle())
              Divider().padding(.leading, 76)
            }
          }
        } else if viewModel.isLoading {
          LoadingIndicator(size: 48)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
      }
      .padding(.top, 12)
      .padding(.bottom, 16)
    }
    .navigationTitle("Random")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          viewModel.fetch()
        } label: {
          Image(systemName: "arrow.triangle.2.circlepath")
        }
      }
    }
    .refreshable { viewModel.fetch() }
    .onAppear {
      if viewModel.songs.isEmpty { viewModel.fetch() }
    }
  }
  @ViewBuilder
  private var artworkMosaic: some View {
    let firstArt = viewModel.songs.compactMap { $0.imageURL }.first
    ZStack {
      if let url = firstArt {
        LoadingImage(url: url, cornerRadius: 0, showsLoading: false)
      } else {
        Color(.systemGray5)
      }
      if viewModel.isLoading && viewModel.songs.isEmpty {
        Color.black.opacity(0.15)
        LoadingIndicator(size: 56)
      }
    }
  }
  private func actionLabel(symbol: String, text: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: symbol)
      Text(text).fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .foregroundColor(.appAccent)
    .background(Color(.tertiarySystemFill))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}
