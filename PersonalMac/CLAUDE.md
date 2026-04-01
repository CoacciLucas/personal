# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PersonalMac is a macOS SwiftUI desktop app that provides a floating chat interface to the GLM AI API (Zhipu AI). It features global hotkeys, speech recognition (mic + system audio), and screenshot analysis. UI text is in Brazilian Portuguese.

## Build

The project uses an Xcode project file (`PersonalMac.xcodeproj`). Build via Xcode or:

```bash
xcodebuild -project PersonalMac.xcodeproj -scheme PersonalMac build
```

Requires macOS 14.0+, Swift 5.0.

## Architecture

### Service Container

`AppServices` (`PersonalMacApp.swift`) is the `@MainActor` DI container holding all services. It's created as a `@StateObject` in the app entry point and passed down to views.

### Navigation

`PersonalMacApp` uses a `Page` enum (`main → settings → chat`). After API key is configured, the app enters "floating mode": the main window minimizes and a floating toolbar + chat panel appear via `FloatingPanelManager`.

### Key Services

- **GlmService** (actor) — API client for `https://api.z.ai/api/coding/paas/v4/chat/completions`. Auto-switches to a vision model when images are sent. Models are loaded dynamically, not hardcoded.
- **ChatState** (@MainActor, ObservableObject) — Central state for messages, model/assistant selection, and speech transcription. Drives all reactive UI updates.
- **ModelService** — Reads available models from `~/dev/personal/Models.md`. Format: `- model-id | Display Name | vision` (third field optional).
- **AssistantService** — Reads assistant prompts from `~/dev/personal/Assistants/*.md`. Filename becomes assistant name, file content becomes the system prompt.
- **SpeechService** — Dual speech recognition: microphone input (user) and system audio capture via ScreenCaptureKit (interviewer). Auto-restarts on failure.
- **HotkeyManager** — Global hotkey monitoring (requires Accessibility permission). `Ctrl+E` captures screenshot, `Cmd+D` toggles speech.
- **FloatingPanelManager** — Creates and manages NSPanel-based floating toolbar and chat panel.
- **SettingsService** (actor) — Persists API key to `~/Library/Application Support/PersonalMac/settings.json`.

### Thread Safety

`GlmService` and `SettingsService` are Swift actors. `AppServices` and `ChatState` are `@MainActor`. Background work uses `Task` blocks with `async/await`.

### Required Permissions

Accessibility (global hotkeys), Microphone, Speech Recognition, Screen Recording (screenshot + system audio capture). The app's main window has `sharingType = .none` to hide from screen sharing.
