import SwiftUI

struct FloatingToolbarView: View {
    var onCapture: () -> Void
    var onToggleChat: () -> Void
    var onSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            toolbarButton(icon: "camera.fill", color: .purple, action: onCapture)
            toolbarButton(icon: "message.fill", color: .purple, action: onToggleChat)
            toolbarButton(icon: "key.fill", color: .gray, action: onSettings)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
    }

    private func toolbarButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 40, height: 40)
                .background(color.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
