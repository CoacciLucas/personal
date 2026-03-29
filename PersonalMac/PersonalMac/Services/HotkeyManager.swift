import AppKit
import CoreImage
import ScreenCaptureKit

extension Notification.Name {
    static let screenshotCaptured = Notification.Name("screenshotCaptured")
}

class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isStarted = false

    func start() {
        guard !isStarted else { return }
        isStarted = true

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        isStarted = false
    }

    deinit { stop() }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.control),
              event.charactersIgnoringModifiers?.lowercased() == "e" else {
            return false
        }
        captureAndNotify()
        return true
    }

    private func captureAndNotify() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                guard let display = content.displays.first else { return }

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
                ) else { return }

                let base64 = jpegData.base64EncodedString()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .screenshotCaptured, object: base64)
                }
            } catch {
                print("Screen capture failed: \(error)")
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
