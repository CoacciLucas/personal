import AppKit
import ApplicationServices
import CoreImage
import ScreenCaptureKit

extension Notification.Name {
    static let screenshotCaptured = Notification.Name("screenshotCaptured")
    static let triggerScreenCapture = Notification.Name("triggerScreenCapture")
    static let toggleSpeechListening = Notification.Name("toggleSpeechListening")
}

class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var triggerObserver: Any?
    private var permissionTimer: Timer?
    private var isStarted = false

    func start() {
        guard !isStarted else { return }
        isStarted = true

        // Local monitor (works when app is focused, no permission needed)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }

        // Trigger from floating toolbar camera button
        triggerObserver = NotificationCenter.default.addObserver(
            forName: .triggerScreenCapture,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.captureAndNotify()
        }

        // Global monitor (needs Accessibility permission)
        setupGlobalMonitoring()
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let triggerObserver { NotificationCenter.default.removeObserver(triggerObserver) }
        permissionTimer?.invalidate()
        globalMonitor = nil
        localMonitor = nil
        triggerObserver = nil
        permissionTimer = nil
        isStarted = false
    }

    deinit { stop() }

    // MARK: - Global Hotkey Setup

    private func setupGlobalMonitoring() {
        if AXIsProcessTrusted() {
            registerGlobalMonitor()
        } else {
            // Show system prompt asking for Accessibility permission
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)

            // Poll every 2s until permission is granted, then register the monitor
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                if AXIsProcessTrusted() {
                    DispatchQueue.main.async {
                        self?.registerGlobalMonitor()
                        self?.permissionTimer?.invalidate()
                        self?.permissionTimer = nil
                    }
                }
            }
        }
    }

    private func registerGlobalMonitor() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        print("[HotkeyManager] Global hotkey (Ctrl+E) active")
    }

    // MARK: - Key Handling

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""

        // Ctrl+E → Screenshot
        if event.modifierFlags.contains(.control), chars == "e" {
            captureAndNotify()
            return true
        }

        // Cmd+D → Toggle speech listening
        if event.modifierFlags.contains(.command), chars == "d" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .toggleSpeechListening, object: nil)
            }
            return true
        }

        return false
    }

    // MARK: - Screen Capture

    private func captureAndNotify() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                guard let display = content.displays.first else {
                    print("[HotkeyManager] No display found")
                    return
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )

                let finalImage = resizeImage(image, maxWidth: 1280) ?? image
                let bitmapRep = NSBitmapImageRep(cgImage: finalImage)
                guard let jpegData = bitmapRep.representation(
                    using: .jpeg,
                    properties: [.compressionFactor: 0.7]
                ) else {
                    print("[HotkeyManager] Failed to create JPEG")
                    return
                }

                let base64 = jpegData.base64EncodedString()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .screenshotCaptured, object: base64)
                }
            } catch {
                print("[HotkeyManager] Screen capture failed: \(error)")
            }
        }
    }

    private func resizeImage(_ image: CGImage, maxWidth: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        guard width > maxWidth else { return nil }

        let scale = maxWidth / width
        let ciImage = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: Float(scale)), forKey: kCIInputScaleKey)
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        return context.createCGImage(output, from: output.extent)
    }
}
