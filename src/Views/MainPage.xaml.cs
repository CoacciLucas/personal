namespace PersonalWindows.Views
{
    /// <summary>
    /// Main page with navigation to chat.
    /// </summary>
    public partial class MainPage : Page
    {
        public MainPage()
        {
            this.InitializeComponent();
        }

        private void OnStartChatClicked(object sender, RoutedEventArgs e)
            => Frame.Navigate(typeof(SettingsPage));
    }
}
