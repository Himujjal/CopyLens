import SwiftUI

struct MenuBarView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Divider()
      if appState.items.isEmpty {
        emptyState
      } else {
        itemList
      }
      Divider()
      footer
    }
    .frame(width: 360)
  }

  private var header: some View {
    HStack(spacing: 8) {
      Text("CopyLens")
        .font(.headline)
      Spacer()
      if let toast = appState.toastMessage {
        ToastView(message: toast)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "text.viewfinder")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text("No captures yet")
        .foregroundStyle(.secondary)
      Text("Press ⇧⌘2 to capture text on screen")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 28)
  }

  private var itemList: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 2) {
        ForEach(appState.items) { item in
          MenuBarItemRow(
            item: item,
            onCopy: { appState.reCopy(item) },
            onDelete: { appState.delete(item) }
          )
        }
      }
      .padding(8)
    }
    .frame(height: 320)
  }

  private var footer: some View {
    HStack {
      Button("Clear All") {
        appState.clearAll()
      }
      .buttonStyle(.plain)
      .disabled(appState.items.isEmpty)

      Spacer()

      SettingsLink {
        Image(systemName: "gearshape")
      }
      .buttonStyle(.plain)
      .help("Settings")
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }
}

private struct MenuBarItemRow: View {
  let item: CaptureItem
  let onCopy: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(item.text)
          .lineLimit(2)
          .font(.callout)
        Text(item.createdAt, style: .relative)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }

      Spacer(minLength: 4)

      Button(action: onCopy) {
        Image(systemName: "doc.on.doc")
      }
      .buttonStyle(.borderless)
      .help("Copy")

      Button(action: onDelete) {
        Image(systemName: "trash")
      }
      .buttonStyle(.borderless)
      .help("Delete")
    }
    .padding(8)
    .contentShape(Rectangle())
    .onTapGesture(perform: onCopy)
  }
}
