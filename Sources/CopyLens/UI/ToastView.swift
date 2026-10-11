import SwiftUI

/// A transient "Copied" pill shown inline in the menu-bar window header.
/// (A floating NSPanel HUD is a later milestone.)
struct ToastView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.callout.weight(.medium))
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(.ultraThinMaterial, in: Capsule())
      .overlay(Capsule().strokeBorder(.quaternary))
  }
}
