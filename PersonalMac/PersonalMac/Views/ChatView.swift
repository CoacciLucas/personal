import SwiftUI

struct ChatView: View {
    @ObservedObject var chatState: ChatState
    @State private var inputText = ""
    var onBack: () -> Void

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
                        ForEach(chatState.messages) { msg in
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
                                .frame(maxWidth: 400, alignment: msg.isUser ? .trailing : .leading)
                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: chatState.messages.count) {
                    if let last = chatState.messages.last {
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
                .disabled(chatState.isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.leading, 10)
            }
            .padding(.top, 15)
        }
        .padding(20)
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        chatState.sendMessage(text)
    }

}
