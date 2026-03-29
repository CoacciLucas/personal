import SwiftUI

@MainActor
class ChatState: ObservableObject {
    @Published var messages: [ChatMessageItem] = []
    @Published var conversationHistory: [ChatMessage] = []
    @Published var isLoading = false
    @Published var selectedAssistant: Assistant?
    @Published var availableAssistants: [Assistant] = []

    // Speech
    @Published var isListening = false
    @Published var liveUserTranscript = ""
    @Published var liveInterviewerTranscript = ""

    let glmService: GlmService
    let speechService = SpeechService()
    private let assistantService = AssistantService()

    init(glmService: GlmService) {
        self.glmService = glmService
        self.availableAssistants = assistantService.loadAssistants()
        setupSpeechCallbacks()
    }

    var systemPrompt: String? {
        selectedAssistant?.prompt
    }

    // MARK: - Assistant

    func selectAssistant(_ assistant: Assistant?) {
        selectedAssistant = assistant
        messages.removeAll()
        conversationHistory.removeAll()
        if let assistant {
            messages.append(ChatMessageItem(
                content: "Assistente ativo: \(assistant.name)",
                isUser: false
            ))
        }
    }

    func clearConversation() {
        messages.removeAll()
        conversationHistory.removeAll()
    }

    func reloadAssistants() {
        availableAssistants = assistantService.loadAssistants()
    }

    // MARK: - Chat

    func sendMessage(_ text: String) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isLoading else { return }

        messages.append(ChatMessageItem(content: input, isUser: true))
        conversationHistory.append(ChatMessage(role: "user", content: input))
        isLoading = true

        Task {
            do {
                let response = try await glmService.sendMessage(
                    messages: conversationHistory,
                    systemPrompt: systemPrompt
                )
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
                let response = try await glmService.sendMessage(
                    messages: conversationHistory,
                    systemPrompt: systemPrompt
                )
                messages.append(ChatMessageItem(content: response, isUser: false))
                conversationHistory.append(ChatMessage(role: "assistant", content: response))
            } catch {
                messages.append(ChatMessageItem(content: "Erro: \(error.localizedDescription)", isUser: false))
            }
            isLoading = false
        }
    }

    // MARK: - Speech

    private func setupSpeechCallbacks() {
        speechService.onUserTranscriptUpdate = { [weak self] text in
            self?.liveUserTranscript = text
        }
        speechService.onInterviewerTranscriptUpdate = { [weak self] text in
            self?.liveInterviewerTranscript = text
        }
        speechService.onError = { [weak self] error in
            self?.messages.append(ChatMessageItem(content: "Speech: \(error)", isUser: false))
        }
    }

    func toggleListening() {
        if isListening {
            stopListeningAndSend()
        } else {
            startListening()
        }
    }

    func startListening() {
        speechService.requestPermissions { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.messages.append(ChatMessageItem(
                    content: "Permissao de microfone ou fala negada. Verifique em Ajustes > Privacidade.",
                    isUser: false
                ))
                return
            }
            self.liveUserTranscript = ""
            self.liveInterviewerTranscript = ""
            self.isListening = true
            self.speechService.startListening()
        }
    }

    func stopListeningAndSend() {
        speechService.stopListening()
        isListening = false

        let userText = liveUserTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let interviewerText = liveInterviewerTranscript.trimmingCharacters(in: .whitespacesAndNewlines)

        liveUserTranscript = ""
        liveInterviewerTranscript = ""

        guard !userText.isEmpty || !interviewerText.isEmpty else { return }

        // Build transcript message
        var transcript = "[Transcricao da conversa]\n"
        if !interviewerText.isEmpty {
            transcript += "\nEntrevistador: \(interviewerText)"
        }
        if !userText.isEmpty {
            transcript += "\nVoce: \(userText)"
        }
        transcript += "\n\nCom base nesta conversa, me ajude a responder as perguntas do entrevistador."

        messages.append(ChatMessageItem(content: transcript, isUser: true))
        conversationHistory.append(ChatMessage(role: "user", content: transcript))
        isLoading = true

        Task {
            do {
                let response = try await glmService.sendMessage(
                    messages: conversationHistory,
                    systemPrompt: systemPrompt
                )
                messages.append(ChatMessageItem(content: response, isUser: false))
                conversationHistory.append(ChatMessage(role: "assistant", content: response))
            } catch {
                messages.append(ChatMessageItem(content: "Erro: \(error.localizedDescription)", isUser: false))
            }
            isLoading = false
        }
    }

    func cancelListening() {
        speechService.stopListening()
        isListening = false
        liveUserTranscript = ""
        liveInterviewerTranscript = ""
    }
}
