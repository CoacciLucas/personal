import SwiftUI

struct SettingsView: View {
    @State private var apiKey = ""
    @State private var statusText = ""
    @State private var isError = false

    let glmService: GlmService
    let settingsService: SettingsService
    var onGoToChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configura\u{00e7}\u{00f5}es")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.purple)

            Text("Insira sua chave da API do GLM (Zhipu AI):")
                .font(.system(size: 14))

            SecureField("Digite sua API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 10) {
                Button("Salvar") {
                    saveApiKey()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.regular)

                Button("Ir para Chat") {
                    goToChat()
                }
                .controlSize(.regular)
            }

            if !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(isError ? .red : .green)
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
        .task {
            if let savedKey = await settingsService.getApiKey() {
                apiKey = savedKey
                await glmService.setApiKey(savedKey)
            }
        }
    }

    private func saveApiKey() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            statusText = "Por favor, insira uma API Key v\u{00e1}lida."
            isError = true
            return
        }
        Task {
            do {
                try await settingsService.saveApiKey(key)
                await glmService.setApiKey(key)
                statusText = "API Key salva com sucesso!"
                isError = false
            } catch {
                statusText = "Erro ao salvar: \(error.localizedDescription)"
                isError = true
            }
        }
    }

    private func goToChat() {
        Task {
            let currentKey = await glmService.getApiKey()
            guard let currentKey, !currentKey.isEmpty else {
                statusText = "Salve a API Key primeiro."
                isError = true
                return
            }
            onGoToChat()
        }
    }
}
