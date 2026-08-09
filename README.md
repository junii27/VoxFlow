# VoxFlow

VoxFlow is a native, privacy-focused macOS menu bar application for instant voice-to-text dictation. It transcribes audio on-device using Apple's Speech framework and cleans up raw transcriptions using Apple's FoundationModels language model framework.

Everything runs 100 percent locally on Apple Silicon hardware with zero cloud dependencies, zero subscription fees, and complete offline capability.

---

## Features

- **On-Device Speech Recognition**: Real-time microphone audio processing via Apple's Speech framework with zero external data transmission.
- **Apple Intelligence LLM Cleanup**: Automatic removal of filler words, grammar correction, and text formatting via on-device language models.
- **Global Hotkey & Double-Tap Fn Detection**: Trigger dictation system-wide via double-tapping the Function key or using the Option + Space shortcut.
- **Automatic Silence Detection**: Speech auto-finalizes and pastes automatically after a 1.5-second pause.
- **System-Wide Auto-Pasting**: Simulates Command + V to insert polished text directly into whichever desktop application is currently active.
- **Clipboard Preservation**: Preserves pre-existing clipboard contents, restoring original clipboard data after pasting dictation output.
- **Non-Activating Floating Overlay**: Real-time HUD showing animated audio levels and live transcription previews without stealing window focus.
- **Menu Bar Integration**: Unobtrusive system status item with access to preferences, permissions status, and transcription history.

---

## System Architecture

```
+-----------------------------------------------------------------------+
|                            VoxFlow Pipeline                           |
+-----------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          |                                                   |
          v                                                   v
 [Double-Tap Fn / Option+Space]                     [Menu Bar Trigger]
          |                                                   |
          +-------------------------+-------------------------+
                                    |
                                    v
                     [AudioCaptureManager (AVAudioEngine)]
                                    |
                                    v
                 [SpeechRecognitionManager (SFSpeech)]
                                    |
                        (Interim text preview)
                                    v
                   [DictationHUDPanel (Floating HUD)]
                                    |
                (0.5s Silence / Stop Hotkey Signal)
                                    v
                   [TextCleanupManager (FoundationModels)]
                                    |
                                    v
                  [TextOutputManager (NSPasteboard + CGEvent)]
                                    |
                                    v
                   [Active Focused Application Target]
```

---

## Technical Specifications

| Component | Technology | Description |
| :--- | :--- | :--- |
| **UI Framework** | SwiftUI + AppKit | MenuBarExtra window style with custom NSPanel overlay |
| **Speech-to-Text** | Apple Speech Framework | Local `SFSpeechAudioBufferRecognitionRequest` |
| **Language Model** | Apple FoundationModels | On-device `SystemLanguageModel` Swift framework |
| **Hotkey Monitoring** | AppKit NSEvent | Global `.flagsChanged` and `.keyDown` event monitors |
| **Text Injection** | AppKit NSPasteboard + CGEvent | Synthetic Command+V key events targeting HID queue |
| **Deployment Target** | macOS 26.0+ | Optimized for Apple Silicon (M1/M2/M3/M4+) |

---

## Project Structure

```
whisper/
├── VoxFlow.dmg                       # Production DMG installer
├── VoxFlow.xcodeproj                 # Xcode project manifest
├── project.yml                       # XcodeGen project specification
├── README.md                         # Documentation
└── VoxFlow/                          # Application source root
    ├── VoxFlowApp.swift              # Main application entry point
    ├── Info.plist                    # Privacy descriptions and LSUIElement config
    ├── VoxFlow.entitlements          # Audio input and sandbox entitlements
    │
    ├── Core/
    │   ├── AppState.swift            # Observable global application state
    │   ├── DictationPipeline.swift   # Primary pipeline orchestrator
    │   └── TranscriptionEntry.swift  # History data model
    │
    ├── Managers/
    │   ├── AudioCaptureManager.swift # AVAudioEngine audio capture wrapper
    │   ├── HotkeyManager.swift       # Global shortcut monitor
    │   ├── PermissionsManager.swift  # System privacy authorization checker
    │   ├── SpeechRecognitionManager.swift # On-device ASR engine
    │   ├── TextCleanupManager.swift  # FoundationModels LLM text cleaner
    │   └── TextOutputManager.swift   # Clipboard and key injection manager
    │
    ├── HUD/
    │   ├── DictationHUDPanel.swift   # Non-activating NSPanel window
    │   └── DictationHUDContentView.swift # HUD interface component
    │
    ├── Views/
    │   ├── MenuBarView.swift         # Main menu bar popup view
    │   ├── SettingsView.swift        # Tabbed preferences interface
    │   ├── OnboardingView.swift      # Permission setup workflow
    │   ├── LiveTranscriptView.swift  # Streaming transcript text view
    │   └── WaveformView.swift        # Real-time audio visualizer
    │
    ├── Utilities/
    │   ├── Constants.swift           # Application configuration constants
    │   └── Extensions.swift         # AppKit and SwiftUI extensions
    │
    └── Assets.xcassets/              # AppIcon and color assets
```

---

## Installation

### Prerequisites

- macOS 26.0 or later running on Apple Silicon (M1 series or newer).
- Apple Intelligence enabled in **System Settings -> Apple Intelligence & Siri**.

### Download DMG Installer

1. Open the included installer package: [VoxFlow.dmg](file:///Users/ameerhamza/HOBBY_CODING/whisper/VoxFlow.dmg).
2. Drag `VoxFlow.app` into your `/Applications` directory.
3. Launch VoxFlow from Launchpad or Finder.

### macOS Gatekeeper Security Note

Because VoxFlow is an open-source project built locally without a paid Apple Developer Notarization ticket, macOS Gatekeeper may show a warning when opening the app for the first time.

To open VoxFlow on macOS:

- Option A (Recommended): Right-click (or Control-click) `VoxFlow.app` in Finder, select **Open**, and click **Open** in the prompt.
- Option B: Go to **System Settings -> Privacy & Security**, scroll down to the Security section, and click **Open Anyway** next to VoxFlow.
- Option C (Terminal): Run `xattr -cr /Applications/VoxFlow.app` in Terminal to clear quarantine flags.

### Building from Source

```bash
# Clone the repository
git clone https://github.com/user/whisper.git
cd whisper

# Generate Xcode project (optional if using pre-generated VoxFlow.xcodeproj)
xcodegen generate

# Build Release application bundle
xcodebuild -project VoxFlow.xcodeproj -scheme VoxFlow -configuration Release build
```

---

## Permissions Setup

On first launch, VoxFlow requires three system authorizations to function:

1. **Microphone**: Required for capturing voice input.
2. **Speech Recognition**: Required for local on-device transcription.
3. **Accessibility**: Required for capturing global hotkey events and simulating Command + V paste actions into external applications.

Grant permissions through the onboard interface or manually in **System Settings -> Privacy & Security**.

---

## Usage

1. **Start Dictating**: Double-tap the **Function (Globe)** key, or press **Option + Space**.
2. **Speak Naturally**: Speech appears live on the floating visual HUD.
3. **Finish Dictating**: Pause for 1.5 seconds, or press **Option + Space** again.
4. **Auto-Paste**: The cleaned, formatted text is automatically pasted into the active application.

---

## Verification and Testing

To execute automated build verification and test target suites:

```bash
# Run build verification
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project VoxFlow.xcodeproj -scheme VoxFlow -destination 'platform=macOS' build
```

---

## Privacy Policy

VoxFlow does not send audio recordings, transcriptions, or application metadata to any remote servers. All processing occurs locally on your Mac using hardware-accelerated Apple Silicon engines.
