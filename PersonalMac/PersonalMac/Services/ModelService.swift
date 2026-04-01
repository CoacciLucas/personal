import Foundation

class ModelService {
    private let modelsFile: URL

    init(file: String = "~/dev/personal/Models.md") {
        self.modelsFile = URL(
            fileURLWithPath: NSString(string: file).expandingTildeInPath
        )
    }

    func loadModels() -> [GlmModel] {
        guard let content = try? String(contentsOf: modelsFile, encoding: .utf8) else {
            print("[ModelService] Could not read file: \(modelsFile.path)")
            return []
        }

        return content
            .components(separatedBy: .newlines)
            .compactMap { line -> GlmModel? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("- ") else { return nil }
                let entry = String(trimmed.dropFirst(2))
                let parts = entry.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count >= 2 else { return nil }
                let id = parts[0]
                let name = parts[1]
                let supportsVision = parts.count >= 3 && parts[2].lowercased() == "vision"
                return GlmModel(id: id, name: name, supportsVision: supportsVision)
            }
    }
}
