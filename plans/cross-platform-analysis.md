# Personal - Cross-Platform Strategy Analysis

## Overview

This document analyzes the technical options for building a Personal clone that works on both Windows and macOS, focusing on the critical requirement of hiding the application window from screen sharing.

---

## Critical Finding: macOS Limitation

From the official Electron documentation for `setContentProtection()`:

> **macOS limitation**: "Unfortunately, due to an intentional change in macOS, newer Mac applications that use `ScreenCaptureKit` will capture your window despite `win.setContentProtection(true)`."

This means:
- **Zoom app on macOS**: Uses ScreenCaptureKit → **may capture your window**
- **Google Meet in Chrome on macOS**: Uses ScreenCaptureKit → **may capture your window**
- **Teams app on macOS**: Uses ScreenCaptureKit → **may capture your window**

**This is not a framework limitation - it is an Apple design decision.**

---

## Platform-Specific Screen Capture Exclusion APIs

### Windows ✅
```csharp
// Native Windows API - Well documented and reliable
SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE);
```
- **Availability**: Windows 10 version 2004+ (May 2020), Windows 11
- **Reliability**: ✅ **Excellent** - works with Zoom, Teams, Meet, Discord
- **Implementation Complexity**: Low - single API call

### macOS ⚠️
```swift
// macOS approach - Has limitations
window.sharingType = .none  // NSWindowSharingNone
```
- **Availability**: macOS 10.15+ (Catalina)
- **Reliability**: ⚠️ **Problematic**
  - Works for: Older screen recording apps
  - **Does NOT work for**: Apps using ScreenCaptureKit (macOS 12.3+)
    - Zoom (recent versions)
    - Google Meet (Chrome)
    - Microsoft Teams
    - OBS Studio

---

## Potential macOS Solutions (Research Findings)

Based on my research, there are several potential approaches for macOS, but none are guaranteed:

### Option 1: NSWindowSharingNone (Standard)
```swift
window.sharingType = .none
```
- **Pros**: Simple, built-in
- **Cons**: Does NOT work with ScreenCaptureKit apps (Zoom, Teams, Meet)

### Option 2: Secondary Window on separate display
Create a secondary window that renders content off-screen
- Position it at a very high level (above other windows)
- Use transparency to make it invisible
- The window is not captured, but the content is still visible on the secondary display

### Option 3: Secure Text field
Only works for individual text fields, not entire windows

```swift
textField.isSecure = true
```
- **Pros**: Simple, built-in
- **Cons**: Only works for text fields, not entire windows

### Option 4: Special window level
macOS has different window level classes that may bypass capture

```swift
window.level = CGShieldWindowLevel
```
- **Pros**: May work in some cases
- **Cons**: Not guaranteed to work with all screen sharing apps
- **Cons**: May interfere with other windows

### Option 5: Metal/OpenGL rendering
Render content directly to GPU, bypassing the standard window capture APIs

```swift
// Using Metal or OpenGL
let metalLayer = CAMetalLayer()
metalLayer.framebufferOnly = true
metalLayer.isOpaque = true
```
- **Pros**: Potentially bypasses ScreenCaptureKit
- **Cons**: Complex implementation
- **Cons**: May not work with all screen sharing apps

---

## Summary of macOS Approaches

| Approach | Reliability | Complexity | Best For |
|--------|-------------|------------|-------|
| NSWindowSharingNone | ⚠️ Low | Simple | General |
| Secondary Window | ⚠️ Medium | Medium | Specific cases |
| Secure Text Field | ✅ High | Simple | Text only |
| Special window level | ⚠️ Low-Medium | Advanced | Advanced |
| Metal/OpenGL | ⚠️ Experimental | High | Advanced |

**Important**: The most reliable approaches (Secure Text Field, Special window level, and Metal/OpenGL) may not work with ScreenCaptureKit-based apps like Zoom, Teams, and Meet. However, NSWindowSharingNone may still be useful for older apps and browser-based sharing that doesn't use ScreenCaptureKit.

---

## My Honest Assessment

For macOS, the limitation is a fundamental issue that cannot be bypassed. However, there are some approaches that might help:

### 1. Accept the limitation
The macOS version will have the same limitation as the original Personal has. Add a clear disclaimer in the app about this

### 2. Implement fallback mechanism
Add a **quick-hide hotkey** (Ctrl+H) for when the user needs to hide the window quickly during screen sharing on macOS

### 3. Test thoroughly
The user should test the app with their specific video conferencing setup on macOS to understand the actual behavior

### 4. Document clearly
Let users know that the feature may not work reliably in some scenarios

---

## Recommended Architecture: Two native apps

Based on this analysis, I recommend

### Windows App: C# + WinUI 3
- **Technology**: C# with WinUI 3 (Windows App SDK)
- **Screen hide**: `SetWindowDisplayAffinity` - reliable
- **Audio**: NAudio library
- **Distribution**: .exe installer / MSIX package
- **Development**: Visual Studio 2022+

### macOS App: Swift/SwiftUI
- **Technology**: Swift with SwiftUI
- **Screen hide**: `NSWindowSharingNone` + fallback
- **Audio**: CoreAudio/AVAudioEngine
- **Distribution**: .app bundle
- **Development**: Xcode

This architecture gives you
- Maximum reliability on Windows
- Direct control over macOS implementation
- Ability to test and iterate quickly on each platform
- Clear expectations about macOS limitations
- Two codebases to maintain (but shared business logic can be extracted to common modules)

---

## Development Phases

### Phase 1: Windows MVP with WinUI 3
- [ ] Project setup with WinUI 3 (Windows App SDK)
- [ ] Window exclusion implementation (`SetWindowDisplayAffinity`)
- [ ] Test with Zoom, Teams, Meet on Windows
- [ ] Basic UI with chat interface
- [ ] Settings storage
- [ ] GLM-4 API integration

### Phase 2: Audio system (Windows)
- [ ] NAudio integration
- [ ] Audio device enumeration
- [ ] Microphone capture
- [ ] System audio loopback capture
- [ ] Audio buffering

### Phase 3: Transcription (Windows)
- [ ] Azure Speech SDK integration
- [ ] Real-time transcription display
- [ ] Speaker diarization
- [ ] Transcription history

### Phase 4: macOS MVP with Swift/SwiftUI
- [ ] Project setup with SwiftUI
- [ ] Window exclusion implementation (`NSWindowSharingNone`)
- [ ] Test with Zoom, Teams, Meet on macOS
- [ ] Basic UI (same as Windows)
- [ ] Settings storage
- [ ] GLM-4 API integration

### Phase 5: Audio system (macOS)
- [ ] CoreAudio/AVAudioEngine integration
- [ ] Audio device enumeration
- [ ] Microphone capture
- [ ] System audio capture (may require BlackHole/Loopback)
### Phase 6: Transcription (macOS)
- [ ] Azure Speech SDK integration
- [ ] Real-time transcription display
- [ ] Speaker diarization
- [ ] Transcription history

### Phase 7: Polish
- [ ] Global hotkeys
- [ ] System tray
- [ ] Error handling
- [ ] Performance optimization
- [ ] Auto-update

### Phase 8: Testing
- [ ] Test with real Zoom, Teams, Meet calls on both platforms
- [ ] Document any limitations discovered
    - [ ] Update user documentation
