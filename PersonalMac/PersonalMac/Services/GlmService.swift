import Foundation

struct GlmModel: Identifiable, Hashable {
    let id: String
    let name: String
    let supportsVision: Bool
}

actor GlmService {
    private let apiUrl = URL(string: "https://api.z.ai/api/coding/paas/v4/chat/completions")!

    private(set) var availableModels: [GlmModel] = []

    private var apiKey: String?
    private var selectedModelId: String = "glm-5"

    func setAvailableModels(_ models: [GlmModel]) {
        availableModels = models
        if !models.isEmpty, !models.contains(where: { $0.id == selectedModelId }) {
            selectedModelId = models[0].id
        }
    }

    func setApiKey(_ key: String) { apiKey = key }
    func getApiKey() -> String? { apiKey }

    func setModel(_ modelId: String) { selectedModelId = modelId }
    func getModel() -> String { selectedModelId }

    func sendMessage(messages: [ChatMessage], systemPrompt: String? = nil) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw GlmError.apiKeyNotConfigured
        }

        let hasImage = messages.contains { $0.imageBase64 != nil }
        let selectedModel = availableModels.first { $0.id == selectedModelId }

        // If message has image but selected model doesn't support vision, use a vision model
        let model: String
        if hasImage, selectedModel?.supportsVision != true,
           let visionModel = availableModels.first(where: { $0.supportsVision }) {
            model = visionModel.id
        } else {
            model = selectedModelId
        }

        var encodedMessages: [[String: Any]] = []

        if let systemPrompt, !systemPrompt.isEmpty {
            encodedMessages.append(["role": "system", "content": systemPrompt])
        }

        encodedMessages.append(contentsOf: messages.map { msg -> [String: Any] in
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
        })

        let body: [String: Any] = [
            "model": model,
            "messages": encodedMessages
        ]

        print("[GlmService] Using model: \(model)")

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
