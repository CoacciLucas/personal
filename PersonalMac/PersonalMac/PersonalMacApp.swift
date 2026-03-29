import SwiftUI

@main
struct PersonalMacApp: App {
    @State private var currentPage = Page.main
    @State private var pendingScreenshot: String?
    private let glmService = GlmService()
    private let settingsService = SettingsService()
    private let hotkeyManager = HotkeyManager()

    var body: some Scene {
        WindowGroup {
            Group {
                switch currentPage {
                case .main:
                    MainView(onStartChat: { currentPage = .settings })
                case .settings:
                    SettingsView(
                        glmService: glmService,
                        settingsService: settingsService,
                        onGoToChat: { currentPage = .chat }
                    )
                case .chat:
                    ChatView(
                        glmService: glmService,
                        onBack: { currentPage = .settings },
                        pendingScreenshot: $pendingScreenshot
                    )
                }
            }
            .frame(minWidth: 500, minHeight: 400)
            .background(WindowAccessor { window in
                window?.sharingType = .none
            })
            .task {
                hotkeyManager.start()
            }
            .onReceive(NotificationCenter.default.publisher(for: .screenshotCaptured)) { notification in
                if let base64 = notification.object as? String {
                    pendingScreenshot = base64
                    currentPage = .chat
                }
            }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
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
