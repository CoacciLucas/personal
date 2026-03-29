import Foundation

struct Assistant: Identifiable, Hashable {
    let id: String
    let name: String
    let prompt: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Assistant, rhs: Assistant) -> Bool {
        lhs.id == rhs.id
    }
}

class AssistantService {
    private let assistantsDirectory: URL

    init(directory: String = "~/dev/personal/Assistants") {
        self.assistantsDirectory = URL(
            fileURLWithPath: NSString(string: directory).expandingTildeInPath
        )
    }

    func loadAssistants() -> [Assistant] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: assistantsDirectory,
            includingPropertiesForKeys: nil
        ) else {
            print("[AssistantService] Could not read directory: \(assistantsDirectory.path)")
            return []
        }

        return files
            .filter { $0.pathExtension == "md" }
            .compactMap { url -> Assistant? in
                guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let filename = url.deletingPathExtension().lastPathComponent
                let name = filename
                    .replacingOccurrences(of: "-", with: " ")
                    .split(separator: " ")
                    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                    .joined(separator: " ")
                return Assistant(id: filename, name: name, prompt: content.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .sorted { $0.name < $1.name }
    }
}
