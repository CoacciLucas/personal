# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PersonalWindows is a WinUI 3 desktop application for Windows that provides a chat interface to interact with the GLM AI API (Zhipu AI). Built on .NET 8 with the Windows App SDK.

## Build Commands

```bash
# Build the project
dotnet build src/PersonalWindows.csproj

# Run the application
dotnet run --project src/PersonalWindows.csproj

# Build for specific platform
dotnet build src/PersonalWindows.csproj -p:Platform=x64
```

## Architecture

### Dependency Injection
Services are registered in `App.xaml.cs` and accessed via `App.GetService<T>()`:
- `GlmService` - Handles API communication with GLM AI
- `SettingsService` - Manages persistent settings storage

### Navigation Flow
`MainPage` → `SettingsPage` → `ChatPage`

Frame-based navigation using `Frame.Navigate(typeof(PageType))`.

### Services
- **GlmService**: Sends chat messages to `https://api.z.ai/api/coding/paas/v4/chat/completions` using the `glm-5` model
- **SettingsService**: Stores API key in `%AppData%\PersonalWindows\settings.json`

### UI Styling
Custom styles defined in `App.xaml`:
- `MyLabel` - Purple text for headers
- `PrimaryAction` - Purple button with white text, rounded corners
- `Action` - Base button style

### Project Structure
```
src/
├── App.xaml(.cs)          # Application entry, DI setup, global styles
├── Imports.cs             # Global usings
├── Models/
│   └── ChatMessage.cs     # Chat message model
├── Services/
│   ├── GlmService.cs      # GLM API client
│   └── SettingsService.cs # Settings persistence
└── Views/
    ├── MainPage.xaml(.cs)     # Landing page
    ├── SettingsPage.xaml(.cs) # API key configuration
    └── ChatPage.xaml(.cs)     # Chat interface
```

## Key Notes

- UI text is in Portuguese (Brazilian)
- The app uses unpackaged deployment (`WindowsPackageType=None`)
- Minimum Windows version: 10.0.17763
- Target Windows version: 10.0.19041
