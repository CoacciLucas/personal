import SwiftUI

struct MainView: View {
    var onStartChat: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Text("GLM Chat")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.purple)

            Text("Chat com a API GLM da Zhipu AI")
                .font(.system(size: 16))
                .foregroundStyle(.gray)

            Button(action: onStartChat) {
                Text("Iniciar Chat")
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
