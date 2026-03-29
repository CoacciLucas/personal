import Foundation

actor GlmService {
    private let apiUrl = URL(string: "https://api.z.ai/api/coding/paas/v4/chat/completions")!
    private let textModel = "glm-5"
    private let visionModel = "glm-4.6v-flash"

    private var apiKey: String?

    func setApiKey(_ key: String) { apiKey = key }
    func getApiKey() -> String? { apiKey }

    func sendMessage(messages: [ChatMessage]) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw GlmError.apiKeyNotConfigured
        }

        let hasImage = messages.contains { $0.imageBase64 != nil }
        let model = hasImage ? visionModel : textModel

        let encodedMessages = messages.map { msg -> [String: Any] in
            if let imageBase64 = msg.imageBase64 {
                return [
                    "role": msg.role,
                    "content": [
                        ["type": "text", "text": msg.content],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
                    ]
                ]
            }
            return ["role": msg.role, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": encodedMessages
        ]

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = hasImage ? 120 : 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GlmError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GlmError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String

        return content ?? ""
    }
}

enum GlmError: LocalizedError {
    case apiKeyNotConfigured
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "API Key n\u{00e3}o configurada"
        case .invalidResponse:
            return "Resposta inv\u{00e1}lida da API"
        case .apiError(let statusCode, let message):
            return "Erro na API (\(statusCode)): \(message)"
        }
    }
}
