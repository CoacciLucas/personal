import SwiftUI

struct FloatingChatView: View {
    @ObservedObject var chatState: ChatState
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header with assistant selector
            HStack {
                Menu {
                    Button {
                        chatState.selectAssistant(nil)
                    } label: {
                        HStack {
                            Text("Sem Assistente")
                            if chatState.selectedAssistant == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(chatState.availableAssistants) { assistant in
                        Button {
                            chatState.selectAssistant(assistant)
                        } label: {
                            HStack {
                                Text(assistant.name)
                                if chatState.selectedAssistant == assistant {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        chatState.reloadAssistants()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Recarregar")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 14))
                        Text(chatState.selectedAssistant?.name ?? "Sem Assistente")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Model selector
                Menu {
                    ForEach(chatState.availableModels) { model in
                        Button {
                            chatState.selectModel(model)
                        } label: {
                            HStack {
                                Text(model.name)
                                if model.supportsVision {
                                    Text("(vision)")
                                        .foregroundStyle(.secondary)
                                }
                                if chatState.selectedModel == model {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        chatState.reloadModels()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Recarregar")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12))
                        Text(chatState.selectedModel?.name ?? "Modelo")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    chatState.clearConversation()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Limpar conversa")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(chatState.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }

                        // Live transcript while listening
                        if chatState.isListening {
                            liveTranscriptView
                                .id("live-transcript")
                        }
                    }
                    .padding(10)
                }
                .onChange(of: chatState.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: chatState.liveUserTranscript) {
                    if chatState.isListening {
                        withAnimation { proxy.scrollTo("live-transcript", anchor: .bottom) }
                    }
                }
                .onChange(of: chatState.liveInterviewerTranscript) {
                    if chatState.isListening {
                        withAnimation { proxy.scrollTo("live-transcript", anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Recording bar or input
            if chatState.isListening {
                recordingBar
            } else {
                inputBar
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessageItem) -> some View {
        HStack {
            if msg.isUser { Spacer() }
            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                if let nsImage = msg.image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 200)
                        .cornerRadius(8)
                }
                if msg.isUser {
                    Text(msg.content)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                } else {
                    MarkdownContentView(content: msg.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: 350, alignment: msg.isUser ? .trailing : .leading)
            if !msg.isUser { Spacer() }
        }
    }

    // MARK: - Live Transcript

    private var liveTranscriptView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !chatState.liveInterviewerTranscript.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entrevistador")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text(chatState.liveInterviewerTranscript)
                            .font(.system(size: 12))
                            .textSelection(.enabled)
                    }
                }
            }

            if !chatState.liveUserTranscript.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voce")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.blue)
                        Text(chatState.liveUserTranscript)
                            .font(.system(size: 12))
                            .textSelection(.enabled)
                    }
                }
            }

            if chatState.liveUserTranscript.isEmpty && chatState.liveInterviewerTranscript.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Aguardando fala...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Recording Bar

    private var recordingBar: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)

            Text("Ouvindo...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)

            Spacer()

            Button("Cancelar") {
                chatState.cancelListening()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.system(size: 12))

            Button("Enviar (CMD+D)") {
                chatState.stopListeningAndSend()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
        }
        .padding(10)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack {
            TextField("Mensagem...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { send() }

            Button("Enviar") { send() }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(chatState.isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(10)
    }

    // MARK: - Helpers

    private func send() {
        let text = inputText
        inputText = ""
        chatState.sendMessage(text)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = chatState.messages.last {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }
}
