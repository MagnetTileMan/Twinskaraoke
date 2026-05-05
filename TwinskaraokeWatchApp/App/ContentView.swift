import SwiftUI

struct ContentView: View {
  @StateObject var audioManager = AudioManager.shared
  var body: some View {
    HomeView()
      .environmentObject(audioManager)
  }
}

#Preview {
  ContentView()
}
