import Foundation

struct ChatMessage: Codable {
    var role: String
    var content: String
    var imageBase64: String?
}

struct ChatMessageItem: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    var imageBase64: String?
}
