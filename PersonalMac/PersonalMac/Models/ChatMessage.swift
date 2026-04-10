import Foundation
import AppKit

struct ChatMessage: Codable {
    var role: String
    var content: String
    var imageBase64: String?
}

struct ChatMessageItem: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let imageBase64: String?
    let image: NSImage?

    init(content: String, isUser: Bool, imageBase64: String? = nil) {
        self.content = content
        self.isUser = isUser
        self.imageBase64 = imageBase64
        if let base64 = imageBase64,
           let data = Data(base64Encoded: base64) {
            self.image = NSImage(data: data)
        } else {
            self.image = nil
        }
    }
}
