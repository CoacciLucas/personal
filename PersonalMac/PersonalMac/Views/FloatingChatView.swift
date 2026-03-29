import SwiftUI

struct FloatingChatView: View {
    @ObservedObject var chatState: ChatState
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(chatState.messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                    if let imageBase64 = msg.imageBase64,
                                       let data = Data(base64Encoded: imageBase64),
                                       let nsImage = NSImage(data: data) {
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
                            .id(msg.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: chatState.messages.count) {
                    if let last = chatState.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

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
    }

    private func send() {
        let text = inputText
        inputText = ""
        chatState.sendMessage(text)
    }
}
