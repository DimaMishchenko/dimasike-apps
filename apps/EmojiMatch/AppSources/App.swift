import SwiftUI

@main
struct App: SwiftUI.App {
  var body: some Scene {
    MenuBarExtra("Emoji Match", systemImage: "face.smiling") {
      ContentView()
        .frame(width: 320, height: 240)
    }
  }
}
