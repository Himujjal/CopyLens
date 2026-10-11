import SwiftUI

@main
struct CopyLensApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var appState = AppState()

  var body: some Scene {
    MenuBarExtra {
      MenuBarView()
        .environmentObject(appState)
    } label: {
      Image(systemName: "text.viewfinder")
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .environmentObject(appState)
    }
  }
}
