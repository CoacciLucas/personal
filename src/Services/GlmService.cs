using System.Net.Http;
using System.Text;
using System.Text.Json;
using PersonalWindows.Models;

namespace PersonalWindows.Services;

public class GlmService
{
    private const string ApiUrl = "https://api.z.ai/api/coding/paas/v4/chat/completions";
    private readonly HttpClient _httpClient = new();

    public string? ApiKey { get; set; }

    public async Task<string> SendMessageAsync(List<ChatMessage> messages, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(ApiKey))
            throw new InvalidOperationException("API Key não configurada");

        var requestBody = new
        {
            model = "glm-5",
            messages = messages.Select(m => new { role = m.Role, content = m.Content }).ToList()
        };

        var request = new HttpRequestMessage(HttpMethod.Post, ApiUrl)
        {
            Content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json")
        };
        request.Headers.Add("Authorization", $"Bearer {ApiKey}");

        var response = await _httpClient.SendAsync(request, cancellationToken);
        var jsonResponse = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
            throw new Exception($"Erro na API ({response.StatusCode}): {jsonResponse}");

        using var doc = JsonDocument.Parse(jsonResponse);
        return doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? string.Empty;
    }
}
