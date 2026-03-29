import Foundation

actor SettingsService {
    private let settingsDirectory: URL
    private let settingsFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        settingsDirectory = appSupport.appendingPathComponent("PersonalMac", isDirectory: true)
        settingsFile = settingsDirectory.appendingPathComponent("settings.json")
    }

    func getApiKey() -> String? {
        guard FileManager.default.fileExists(atPath: settingsFile.path) else { return nil }
        guard let data = try? Data(contentsOf: settingsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return nil }
        return json["ApiKey"]
    }

    func saveApiKey(_ apiKey: String) throws {
        try FileManager.default.createDirectory(at: settingsDirectory, withIntermediateDirectories: true)
        let json = ["ApiKey": apiKey]
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: settingsFile, options: .atomic)
    }
}
