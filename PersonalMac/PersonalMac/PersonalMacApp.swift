import SwiftUI
import ApplicationServices

@MainActor
class AppServices: ObservableObject {
    let glmService = GlmService()
    let settingsService = SettingsService()
    let hotkeyManager = HotkeyManager()

    lazy var chatState: ChatState = ChatState(glmService: glmService)
    lazy var panelManager: FloatingPanelManager = FloatingPanelManager(
        chatState: chatState,
        settingsService: settingsService,
        glmService: glmService
    )
}

@main
struct PersonalMacApp: App {
    @StateObject private var services = AppServices()
    @State private var currentPage = Page.main

    var body: some Scene {
        WindowGroup {
            Group {
                switch currentPage {
                case .main:
                    MainView(onStartChat: { currentPage = .settings })
                case .settings:
                    SettingsView(
                        glmService: services.glmService,
                        settingsService: services.settingsService,
                        onGoToChat: { activateFloatingMode() }
                    )
                case .chat:
                    ChatView(
                        chatState: services.chatState,
                        onBack: { currentPage = .settings }
                    )
                }
            }
            .frame(minWidth: 500, minHeight: 400)
            .background(WindowAccessor { window in
                window?.sharingType = .none
            })
            .task {
                services.hotkeyManager.start()
                if let savedKey = await services.settingsService.getApiKey() {
                    await services.glmService.setApiKey(savedKey)
                    activateFloatingMode()
                }
            }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
    }

    private func activateFloatingMode() {
        currentPage = .chat
        services.panelManager.showToolbar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let mainWindow = NSApp.windows.first(where: { $0.isVisible && !($0 is NSPanel) }) {
                mainWindow.miniaturize(nil)
            }
        }
    }
}

enum Page {
    case main, settings, chat
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            callback(nsView.window)
        }
    }
}
