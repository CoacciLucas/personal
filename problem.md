# Perssua Clone - Requirements Specification

## Overview

This document describes the requirements for a Windows desktop application that provides real-time AI assistance during video calls and presentations. The application helps users respond to questions, handle objections, and maintain confidence during online meetings.

---

## Core Requirements

### 1. Screen Share Invisibility - CRITICAL

**Priority: HIGHEST**

The application window and any child windows must be completely invisible during screen sharing on all major video conferencing platforms:

- **Zoom**
- **Google Meet**
- **Microsoft Teams**
- **Google Hangouts**

**Technical Implementation:**
- Use Windows API `SetWindowDisplayAffinity` with `WDA_EXCLUDEFROMCAPTURE` flag
- This prevents the window from being captured by screen recording APIs
- Must be applied to the main window and all dialog/popup windows

**Acceptance Criteria:**
- [ ] Window does not appear in screen shares
- [ ] Window does not appear in screen recordings
- [ ] Window remains functional while invisible to capture

---

### 2. Real-Time Chat Interface

**Priority: HIGH**

A unified chat interface for communicating with the AI assistant.

**Features:**
- Single, persistent chat session
- Real-time streaming responses from AI
- Message history within session
- Clear visual distinction between user and AI messages
- Timestamps on messages
- Copy message functionality

**UI Requirements:**
- Dark theme for reduced eye strain during long sessions
- Resizable window
- Always-on-top option
- Minimize to system tray

---

### 3. Audio Transcription with Speaker Identification

**Priority: HIGH**

Transcribe audio from two sources simultaneously with speaker identification:

**Audio Sources:**
1. **System Audio** - What you hear from the meeting - other participants
2. **Microphone** - Your voice

**Requirements:**
- Separate transcription streams for each source
- Clear labeling of who is speaking - You vs Others
- Real-time transcription display
- Timestamp for each transcribed segment
- Transcription stored in session for context

**Technical Implementation:**
- NAudio library for audio capture
- `WasapiLoopbackCapture` for system audio
- `WaveInEvent` for microphone capture
- Azure Speech Services for transcription with speaker diarization

---

### 4. Transcription Control via Hotkeys

**Priority: HIGH**

| Hotkey | Action | Description |
|--------|--------|-------------|
| `CTRL + D` | Toggle Transcription | Start/stop audio capture and transcription |
| `CTRL + B` | Send to AI | Send accumulated transcription context to AI for analysis and response |

**Workflow:**
1. User presses `CTRL + D` - transcription begins
2. System captures and transcribes both audio streams
3. User presses `CTRL + B` - transcription is sent to AI
4. AI analyzes the conversation context and provides relevant response
5. Transcription continues running until `CTRL + D` is pressed again

**Context Understanding:**
- AI should understand who asked what question
- AI should provide responses appropriate to the conversation flow
- AI response appears in the unified chat interface

---

### 5. Audio Device Selection

**Priority: MEDIUM**

A settings menu for selecting audio input/output devices.

**Required Selections:**
- **Microphone Device** - Select which microphone to capture
- **Speaker Device** - Select which speaker output to capture - for loopback

**Features:**
- Dropdown list of available devices
- Device names should match Windows sound settings
- Remember last selected devices
- Visual indicator of active devices
- Test button to verify device is working

---

### 6. API Configuration

**Priority: HIGH**

Settings area for API key configuration.

**Required API Keys:**
| Service | Purpose | Storage |
|---------|---------|---------|
| GLM-4 API Key | AI reasoning and responses | Windows Credential Manager |
| Azure Speech Key | Transcription with diarization | Windows Credential Manager |
| Azure Speech Region | Azure region for speech services | App Settings |

**Security Requirements:**
- API keys must be stored securely - not in plain text
- Use Windows Credential Manager or equivalent
- Keys should not appear in logs or error messages
- Mask keys in UI - show only last 4 characters

---

### 7. Screenshot Capture and Analysis

**Priority: MEDIUM**

| Hotkey | Action |
|--------|--------|
| `CTRL + E` | Capture screenshot |

**Features:**
- Capture current screen or active window
- Store screenshot in session memory
- Screenshots are available for AI analysis
- When user asks a question, AI can reference screenshots

**Use Cases:**
- Capture a problem or error message
- Capture a question displayed on screen
- Capture visual context for AI to analyze

**Technical Implementation:**
- Use GLM-4V - vision model - for image analysis
- Screenshots converted to base64 for API
- Screenshots cleared when session ends
- Optional: Save screenshots to disk with user permission

---

## User Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Perssua Assistant - Always Ready                    [_][□][X]│
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [Settings] [Audio Devices]                    [Minimize]│ │
│ └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ CHAT AREA                                          │   │
│  │                                                     │   │
│  │ [14:32:15] You: What should I say about the budget?│   │
│  │                                                     │   │
│  │ [14:32:16] AI: Based on the conversation, the     │   │
│  │ interviewer is asking about Q3 budget allocation. │   │
│  │ You should mention the 15% increase in marketing  │   │
│  │ and explain the ROI justification...              │   │
│  │                                                     │   │
│  │ [14:33:45] TRANSCRIPTION - Others:                │   │
│  │ Can you explain your experience with cloud arch?  │   │
│  │                                                     │   │
│  │ [14:33:50] TRANSCRIPTION - You:                   │   │
│  │ I have worked with AWS and Azure for 5 years...   │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Type your message here...              ] [Send]   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Status: ● Recording | Mic: USB Mic | Speaker: Speakers     │
│ Screenshots: 2 | Transcription: Active | CTRL+B to send    │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Stack

| Component | Technology | Reason |
|-----------|------------|--------|
| Language | C# | User preference, native Windows integration |
| UI Framework | WPF | Modern UI, good MVVM support |
| Audio Capture | NAudio | Mature library for Windows audio |
| Transcription | Azure Speech Services | Real-time with speaker diarization |
| AI - Text | GLM-4-Flash | Fast responses, good reasoning |
| AI - Vision | GLM-4V | Image analysis for screenshots |
| HTTP Client | HttpClient | Built-in, good async support |
| Storage | Windows Credential Manager | Secure API key storage |

---

## Keyboard Shortcuts Summary

| Shortcut | Action | Context |
|----------|--------|---------|
| `CTRL + D` | Toggle transcription | Global - works anywhere in Windows |
| `CTRL + B` | Send transcription to AI | Global - works anywhere in Windows |
| `CTRL + E` | Capture screenshot | Global - works anywhere in Windows |
| `CTRL + H` | Hide/Show main window | Global - works anywhere in Windows |
| `Escape` | Clear input field | Only when window is focused |

---

## Session Management

**Session Data:**
- Chat history
- Transcription history with timestamps
- Captured screenshots
- Current context for AI

**Session Lifecycle:**
- Session starts when application launches
- Session ends when application closes
- All session data cleared on exit - no persistence

---

## Error Handling

**Required Error Messages:**
- API key invalid or expired
- Network connection lost
- Audio device not available
- Transcription service unavailable
- AI rate limit exceeded

**Error Display:**
- Non-intrusive notifications
- Status bar indicators
- Optional: Sound alert for critical errors

---

## Performance Requirements

| Metric | Target |
|--------|--------|
| Application startup | < 3 seconds |
| Transcription latency | < 1 second from speech |
| AI response start | < 2 seconds |
| Memory usage | < 200 MB baseline |
| CPU usage | < 10% when idle |

---

## Future Considerations

These features are not required for initial version but may be added later:

- [ ] Multi-language support for transcription
- [ ] Custom system prompts for AI behavior
- [ ] Export chat history
- [ ] Multiple session tabs
- [ ] Voice commands
- [ ] Integration with calendar apps

---

## References

- [Perssua Research Document](perssua_research.md) - Original product research
- [Architecture Plan](plans/architecture.md) - Technical implementation details
- [GLM-4 API Documentation](https://bigmodel.cn/dev/api/normal-model/glm-4)
- [GLM-4V Vision API](https://bigmodel.cn/dev/api/multimodal-model/glm-4v)
- [Azure Speech Services](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/)
