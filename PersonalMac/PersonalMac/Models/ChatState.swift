import SwiftUI

@MainActor
class ChatState: ObservableObject {
    @Published var messages: [ChatMessageItem] = []
    @Published var conversationHistory: [ChatMessage] = []
    @Published var isLoading = false

    let glmService: GlmService

    init(glmService: GlmService) {
        self.glmService = glmService
    }

    func sendMessage(_ text: String) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isLoading else { return }

        messages.append(ChatMessageItem(content: input, isUser: true))
        conversationHistory.append(ChatMessage(role: "user", content: input))
        isLoading = true

        Task {
            do {
                let response = try await glmService.sendMessage(messages: conversationHistory)
                messages.append(ChatMessageItem(content: response, isUser: false))
                conversationHistory.append(ChatMessage(role: "assistant", content: response))
            } catch {
                messages.append(ChatMessageItem(content: "Erro: \(error.localizedDescription)", isUser: false))
            }
            isLoading = false
        }
    }

    func processScreenshot(_ base64: String) {
        let prompt = "Analise o conteudo desta captura de tela e me ajude com base nele."
        messages.append(ChatMessageItem(content: prompt, isUser: true, imageBase64: base64))
        conversationHistory.append(ChatMessage(role: "user", content: prompt, imageBase64: base64))
        isLoading = true

        Task {
            do {
                let response = try await glmService.sendMessage(messages: conversationHistory)
                messages.append(ChatMessageItem(content: response, isUser: false))
                conversationHistory.append(ChatMessage(role: "assistant", content: response))
            } catch {
                messages.append(ChatMessageItem(content: "Erro: \(error.localizedDescription)", isUser: false))
            }
            isLoading = false
        }
    }
}
