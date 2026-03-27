using System.Runtime.InteropServices;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml.Navigation;
using PersonalWindows.Services;
using WinRT.Interop;

namespace PersonalWindows
{
    /// <summary>
    /// Provides application-specific behavior to supplement the default Application class.
    /// </summary>
    public partial class App : Application
    {
        // P/Invoke para proteção contra screen sharing
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SetWindowDisplayAffinity(IntPtr hWnd, uint dwAffinity);

        // WDA_EXCLUDEFROMCAPTURE = 0x00000011 (17) - Exclui a janela de capturas de tela e screen sharing
        // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowdisplayaffinity
        private const uint WDA_EXCLUDEFROMCAPTURE = 0x00000011;

        private Window window = Window.Current;
        private static IServiceProvider? _services;

        public static T GetService<T>() where T : class
            => _services?.GetRequiredService<T>() ?? throw new InvalidOperationException($"Service {typeof(T)} not registered");

        /// <summary>
        /// Initializes the singleton application object.  This is the first line of authored code
        /// executed, and as such is the logical equivalent of main() or WinMain().
        /// </summary>
        public App()
        {
            this.InitializeComponent();
            _services = ConfigureServices();
        }

        private static IServiceProvider ConfigureServices()
        {
            var services = new ServiceCollection();
            services.AddSingleton<GlmService>();
            services.AddSingleton<SettingsService>();
            return services.BuildServiceProvider();
        }

        /// <summary>
        /// Invoked when the application is launched normally by the end user.  Other entry points
        /// will be used such as when the application is launched to open a specific file.
        /// </summary>
        /// <param name="e">Details about the launch request and process.</param>
        protected override void OnLaunched(LaunchActivatedEventArgs e)
        {
            window ??= new Window();

            if (window.Content is not Frame rootFrame)
            {
                rootFrame = new Frame();
                rootFrame.NavigationFailed += OnNavigationFailed;
                window.Content = rootFrame;
            }

            _ = rootFrame.Navigate(typeof(MainPage), e.Arguments);
            window.Activate();

            // Protege a janela contra screen sharing (Discord, Zoom, Teams, Google Meet, etc.)
            ProtectWindowFromScreenSharing();
        }

        /// <summary>
        /// Impede que a janela seja capturada por ferramentas de screen sharing
        /// </summary>
        private void ProtectWindowFromScreenSharing()
        {
            var hWnd = WindowNative.GetWindowHandle(window);
            var success = SetWindowDisplayAffinity(hWnd, WDA_EXCLUDEFROMCAPTURE);
            if (!success)
            {
                var error = Marshal.GetLastWin32Error();
                System.Diagnostics.Debug.WriteLine($"SetWindowDisplayAffinity failed with error: {error}");
            }
        }

        /// <summary>
        /// Invoked when Navigation to a certain page fails
        /// </summary>
        /// <param name="sender">The Frame which failed navigation</param>
        /// <param name="e">Details about the navigation failure</param>
        void OnNavigationFailed(object sender, NavigationFailedEventArgs e)
        {
            throw new Exception("Failed to load Page " + e.SourcePageType.FullName);
        }
    }
}
