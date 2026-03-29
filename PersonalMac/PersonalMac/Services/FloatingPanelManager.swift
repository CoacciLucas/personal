import AppKit
import SwiftUI

class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
class FloatingPanelManager: ObservableObject {
    private var toolbarPanel: NSPanel?
    private var chatPanel: KeyablePanel?
    private var chatPanelDelegate: ChatPanelDelegate?
    @Published var isChatVisible = false

    private let chatState: ChatState
    private let settingsService: SettingsService
    private let glmService: GlmService

    private var screenshotObserver: Any?
    private var speechObserver: Any?

    init(chatState: ChatState, settingsService: SettingsService, glmService: GlmService) {
        self.chatState = chatState
        self.settingsService = settingsService
        self.glmService = glmService

        screenshotObserver = NotificationCenter.default.addObserver(
            forName: .screenshotCaptured,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let base64 = notification.object as? String {
                Task { @MainActor in
                    self?.handleScreenshot(base64)
                }
            }
        }

        speechObserver = NotificationCenter.default.addObserver(
            forName: .toggleSpeechListening,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSpeechToggle()
            }
        }
    }

    func showToolbar() {
        guard toolbarPanel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 52, height: 210),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.sharingType = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        let toolbarView = FloatingToolbarView(
            chatState: chatState,
            onCapture: { [weak self] in
                self?.triggerCapture()
            },
            onToggleChat: { [weak self] in
                self?.toggleChat()
            },
            onToggleSpeech: { [weak self] in
                self?.handleSpeechToggle()
            },
            onSettings: { [weak self] in
                self?.showApiKeyAlert()
            }
        )

        panel.contentView = NSHostingView(rootView: toolbarView)

        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 70
            let y = screen.visibleFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        toolbarPanel = panel
    }

    func toggleChat() {
        if isChatVisible {
            chatPanel?.orderOut(nil)
            isChatVisible = false
        } else {
            showChatPanel()
        }
    }

    func handleScreenshot(_ base64: String) {
        chatState.processScreenshot(base64)
        if !isChatVisible {
            showChatPanel()
        }
    }

    func handleSpeechToggle() {
        chatState.toggleListening()
        if !isChatVisible {
            showChatPanel()
        }
    }

    func showApiKeyAlert() {
        let alert = NSAlert()
        alert.messageText = "Alterar API Key"
        alert.informativeText = "Insira sua nova chave da API do GLM:"
        alert.addButton(withTitle: "Salvar")
        alert.addButton(withTitle: "Cancelar")

        let textField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let key = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                Task {
                    try? await settingsService.saveApiKey(key)
                    await glmService.setApiKey(key)
                }
            }
        }
    }

    private func showChatPanel() {
        if chatPanel == nil {
            let panel = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 550),
                styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.sharingType = .none
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.title = "Chat GLM"
            panel.minSize = NSSize(width: 350, height: 400)

            let chatView = FloatingChatView(chatState: chatState)
            panel.contentView = NSHostingView(rootView: chatView)

            if let toolbarFrame = toolbarPanel?.frame, let screen = NSScreen.main {
                let x = toolbarFrame.minX - 440
                let y = max(screen.visibleFrame.minY, toolbarFrame.midY - 275)
                panel.setFrameOrigin(NSPoint(x: max(screen.visibleFrame.minX, x), y: y))
            }

            let delegate = ChatPanelDelegate { [weak self] in
                self?.isChatVisible = false
            }
            panel.delegate = delegate
            chatPanelDelegate = delegate

            chatPanel = panel
        }

        chatPanel?.orderFront(nil)
        isChatVisible = true
    }

    private func triggerCapture() {
        NotificationCenter.default.post(name: .triggerScreenCapture, object: nil)
    }
}

class ChatPanelDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}
