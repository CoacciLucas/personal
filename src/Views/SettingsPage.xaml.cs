using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PersonalWindows.Services;

namespace PersonalWindows.Views;

public sealed partial class SettingsPage : Page
{
    private readonly GlmService _glmService;
    private readonly SettingsService _settingsService;

    public SettingsPage()
    {
        this.InitializeComponent();
        _glmService = App.GetService<GlmService>();
        _settingsService = App.GetService<SettingsService>();
    }

    protected override async void OnNavigatedTo(Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        var apiKey = await _settingsService.GetApiKeyAsync();
        if (!string.IsNullOrEmpty(apiKey))
        {
            ApiKeyBox.Password = apiKey;
            _glmService.ApiKey = apiKey;
        }
    }

    private async void OnSaveClicked(object sender, RoutedEventArgs e)
    {
        var apiKey = ApiKeyBox.Password;
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            StatusText.Text = "Por favor, insira uma API Key válida.";
            StatusText.Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Microsoft.UI.Colors.Red);
            return;
        }

        try
        {
            await _settingsService.SaveApiKeyAsync(apiKey);
            _glmService.ApiKey = apiKey;
            StatusText.Text = "API Key salva com sucesso!";
            StatusText.Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Microsoft.UI.Colors.Green);
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Erro ao salvar: {ex.Message}";
            StatusText.Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Microsoft.UI.Colors.Red);
        }
    }

    private void OnGoToChatClicked(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(_glmService.ApiKey))
        {
            StatusText.Text = "Salve a API Key primeiro.";
            StatusText.Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Microsoft.UI.Colors.Red);
            return;
        }
        Frame.Navigate(typeof(ChatPage));
    }
}
