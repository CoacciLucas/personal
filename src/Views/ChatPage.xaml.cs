using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using PersonalWindows.Models;
using PersonalWindows.Services;
using System.Collections.ObjectModel;

namespace PersonalWindows.Views;

public class ChatMessageItem
{
    public string Content { get; set; } = string.Empty;
    public HorizontalAlignment Alignment { get; set; }
    public SolidColorBrush Background { get; set; } = new(Microsoft.UI.Colors.LightGray);

    public static ChatMessageItem FromUser(string content) => new()
    {
        Content = content,
        Alignment = HorizontalAlignment.Right,
        Background = new SolidColorBrush(Microsoft.UI.Colors.LightBlue)
    };

    public static ChatMessageItem FromAssistant(string content) => new()
    {
        Content = content,
        Alignment = HorizontalAlignment.Left,
        Background = new SolidColorBrush(Microsoft.UI.Colors.LightGray)
    };
}

public sealed partial class ChatPage : Page
{
    private readonly GlmService _glmService;
    private readonly List<ChatMessage> _conversationHistory = [];
    public ObservableCollection<ChatMessageItem> Messages { get; } = [];

    public ChatPage()
    {
        this.InitializeComponent();
        _glmService = App.GetService<GlmService>();
        MessagesList.ItemsSource = Messages;
    }

    private void OnBackClicked(object sender, RoutedEventArgs e)
    {
        Frame.GoBack();
    }

    private void OnInputKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter)
        {
            OnSendClicked(sender, e);
        }
    }

    private async void OnSendClicked(object sender, RoutedEventArgs e)
    {
        var input = InputBox.Text.Trim();
        if (string.IsNullOrEmpty(input) || SendButton.IsEnabled == false)
            return;

        // Add user message
        Messages.Add(ChatMessageItem.FromUser(input));
        _conversationHistory.Add(new ChatMessage { Role = "user", Content = input });
        InputBox.Text = string.Empty;

        // Disable input while processing
        SendButton.IsEnabled = false;
        InputBox.IsEnabled = false;

        try
        {
            var response = await _glmService.SendMessageAsync(_conversationHistory);
            Messages.Add(ChatMessageItem.FromAssistant(response));
            _conversationHistory.Add(new ChatMessage { Role = "assistant", Content = response });
        }
        catch (Exception ex)
        {
            Messages.Add(ChatMessageItem.FromAssistant($"Erro: {ex.Message}"));
        }
        finally
        {
            SendButton.IsEnabled = true;
            InputBox.IsEnabled = true;
            InputBox.Focus(FocusState.Programmatic);
        }
    }
}
