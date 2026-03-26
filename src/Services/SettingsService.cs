using System.Text.Json;
using Windows.Storage;

namespace PersonalWindows.Services;

public class SettingsService
{
    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "PersonalWindows",
        "settings.json"
    );

    public async Task<string?> GetApiKeyAsync()
    {
        if (!File.Exists(SettingsPath))
            return null;

        try
        {
            var json = await File.ReadAllTextAsync(SettingsPath);
            var settings = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            return settings?.GetValueOrDefault("ApiKey");
        }
        catch
        {
            return null;
        }
    }

    public async Task SaveApiKeyAsync(string apiKey)
    {
        var directory = Path.GetDirectoryName(SettingsPath)!;
        if (!Directory.Exists(directory))
            Directory.CreateDirectory(directory);

        var settings = new Dictionary<string, string> { ["ApiKey"] = apiKey };
        var json = JsonSerializer.Serialize(settings);
        await File.WriteAllTextAsync(SettingsPath, json);
    }
}
