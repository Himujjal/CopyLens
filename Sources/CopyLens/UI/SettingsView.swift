import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Form {
      Section("Shortcut") {
        LabeledContent("Capture text") {
          Text("⇧⌘2")
        }
      }

      Section("OCR") {
        LabeledContent("Languages") {
          Text(appState.settings.ocrLanguages.joined(separator: ", "))
        }
      }

      Section("History") {
        LabeledContent("Limit") {
          Text("\(appState.settings.historyLimit)")
        }
      }

      Section("Privacy") {
        LabeledContent("Storage") {
          Text("On this Mac only")
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 440, height: 360)
  }
}
