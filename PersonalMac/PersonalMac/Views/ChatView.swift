import SwiftUI

struct ChatView: View {
    @State private var inputText = ""
    @State private var messages: [ChatMessageItem] = []
    @State private var conversationHistory: [ChatMessage] = []
    @State private var isLoading = false

    let glmService: GlmService
    var onBack: () -> Void
    @Binding var pendingScreenshot: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)

                Text("Chat GLM")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.purple)

                Spacer()

                Text("^E capturar tela")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 15)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                    if let imageBase64 = msg.imageBase64,
                                       let nsImage = base64ToNSImage(imageBase64) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 300, maxHeight: 200)
                                            .cornerRadius(8)
                                    }
                                    Text(msg.content)
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .background(msg.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .frame(maxWidth: 400, alignment: msg.isUser ? .trailing : .leading)
                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .padding(.vertical, 10)

            Divider()

            // Input
            HStack {
                TextField("Digite sua mensagem...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }

                Button("Enviar") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.leading, 10)
            }
            .padding(.top, 15)
        }
        .padding(20)
        .task {
            if let screenshot = pendingScreenshot {
                pendingScreenshot = nil
                processScreenshot(screenshot)
            }
        }
        .onChange(of: pendingScreenshot) {
            if let screenshot = pendingScreenshot {
                pendingScreenshot = nil
                processScreenshot(screenshot)
            }
        }
    }

    private func processScreenshot(_ base64: String) {
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

    private func sendMessage() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isLoading else { return }

        inputText = ""
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

    private func base64ToNSImage(_ base64: String) -> NSImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return NSImage(data: data)
    }
}
