# NotchPrompter

A macOS teleprompter app that lives directly under your MacBook's camera notch, mimicking Apple's Dynamic Island UI. Read your scripts while maintaining natural eye contact during video calls, presentations, and recordings.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Dynamic Island Interface
- Collapsed state: a sleek black pill with a green "camera active" indicator, seamlessly integrated with the notch
- Expanded state: a full teleprompter panel with smooth spring animations
- Hover effects: pill subtly expands on mouse hover, matching Apple's Dynamic Island behavior

### Teleprompter
- Smooth auto-scrolling at 60fps with adjustable speed (0.25x to 3.0x)
- Hover-to-pause: scrolling automatically pauses when you hover over the panel and resumes when you move away
- Manual scroll with trackpad or mouse wheel while hovering
- Rewind to start with a single click
- Elapsed time counter while scrolling
- Progress bar with percentage display

### Markdown Support
- Rich rendering of Markdown documents with syntax highlighting
- Styled headers (H1, H2, H3) with distinct colors
- Bold, italic, and inline code formatting
- Code blocks with monospaced font and dark background
- Blockquotes, bullet lists, numbered lists, and horizontal rules
- Toggle between Markdown and plain text rendering

### File Support
- Drag and drop `.md`, `.txt`, `.rtf`, `.markdown`, `.text`, `.strings` files
- Paste text directly with Cmd+V
- Open files via the built-in file browser or menu bar
- Automatic format detection

### Header Navigation
- Jump between Markdown headers with left/right arrow keys
- Navigation buttons in the controls bar
- Smooth animated transitions between sections

### Settings
- Persistent settings stored in UserDefaults
- Default scroll speed, font size (16pt to 48pt), and auto-play toggle
- Set a default script file to load on launch
- Settings apply dynamically as you adjust them
- Reset to defaults button

### Window Management
- Precisely positioned under the MacBook's physical notch
- Always stays on the built-in display, even with external monitors connected
- Floats above all other windows including the menu bar
- Click-through: transparent areas pass mouse events to apps behind
- Resizable panel with drag handle
- Panel height persists across restarts

### System Integration
- Menu bar status item for quick access (Toggle Panel, Open File, Quit)
- Launches at login via LaunchAgent
- Runs as an accessory app (no dock icon)
- Keyboard shortcuts for all major actions

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Click on pill | Expand / Collapse |
| Space | Play / Pause scrolling |
| Up Arrow | Increase speed |
| Down Arrow | Decrease speed |
| Left Arrow | Jump to previous header |
| Right Arrow | Jump to next header |
| Escape | Collapse panel |
| Cmd+V | Paste text from clipboard |
| Cmd+= / Cmd+- | Increase / Decrease font size |
| Cmd+0 | Reset font size |

## Requirements

- macOS 13.0 or later
- MacBook with a notch (for optimal positioning; works on non-notch Macs as well)

## Installation

### From DMG (Recommended)
1. Download the latest `.dmg` from [Releases](https://github.com/bsahane/Notch-Prompter/releases)
2. Open the DMG and drag `NotchPrompter.app` to `Applications`
3. Launch from Applications or Spotlight

### Build from Source
1. Clone the repository:
   ```bash
   git clone git@github.com:bsahane/Notch-Prompter.git
   cd Notch-Prompter
   ```
2. Build with Xcode:
   ```bash
   xcodebuild -project NotchPrompter.xcodeproj -scheme NotchPrompter -configuration Release build
   ```
3. The built app will be in:
   ```
   ~/Library/Developer/Xcode/DerivedData/NotchPrompter-*/Build/Products/Release/NotchPrompter.app
   ```
4. Copy to Applications:
   ```bash
   cp -R "$(find ~/Library/Developer/Xcode/DerivedData/NotchPrompter-*/Build/Products/Release -name 'NotchPrompter.app' -maxdepth 1)" /Applications/
   ```

### Launch at Login (Optional)
Create a LaunchAgent to start NotchPrompter automatically:

```bash
cat > ~/Library/LaunchAgents/bSahane.NotchPrompter.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>bSahane.NotchPrompter</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>/Applications/NotchPrompter.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/bSahane.NotchPrompter.plist
```

To disable auto-launch:
```bash
launchctl unload ~/Library/LaunchAgents/bSahane.NotchPrompter.plist
```

## Architecture

The app uses a hybrid SwiftUI + AppKit architecture with a pure AppKit entry point for full lifecycle control.

```
NotchPrompter/
├── main.swift                          # AppKit entry point (NSApplication.shared.run())
├── AppDelegate.swift                   # Window management, event handling, menu bar
├── Models/
│   ├── PrompterState.swift             # @Observable state: scroll, playback, settings
│   └── AppSettings.swift               # UserDefaults persistence layer
├── Views/
│   ├── DynamicIslandView.swift         # Main morphing container with animations
│   └── Components/
│       ├── ScrollingTextView.swift     # 60fps auto-scroll teleprompter engine
│       ├── MarkdownTextView.swift      # Custom Markdown parser and renderer
│       ├── ControlsBarView.swift       # Playback, speed, navigation controls
│       ├── SettingsView.swift          # Settings popover UI
│       ├── NotchShape.swift            # Animatable shape with variable corner radii
│       ├── GreenDotIndicator.swift     # Pulsing "camera active" indicator
│       ├── MiniProgressBar.swift       # Collapsed-state progress bar
│       └── SpeedIndicator.swift        # Speed display badge
└── Utilities/
    ├── FloatingPanel.swift             # NSPanel subclass for key/main window support
    └── ScreenPositioning.swift         # Window frame calculations
```

### Key Design Decisions

**Pure AppKit Entry Point** — The app uses `main.swift` with `NSApplication.shared.run()` instead of SwiftUI's `@main App` struct. This prevents SwiftUI from terminating the app when it believes no scenes are active, which is critical for a floating panel app with no standard windows.

**NSPanel at Menu Bar Level** — The window uses `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)` to position above the menu bar, directly behind the notch. A custom `FloatingPanel` (NSPanel subclass) overrides `canBecomeKey` and `canBecomeMain` to receive keyboard and mouse events.

**Click-Through Transparency** — A 30fps timer polls mouse position and dynamically toggles `panel.ignoresMouseEvents`. When the cursor is outside the visible content area (pill or expanded panel), mouse events pass through to whatever is behind the window.

**NSHostingView Sizing Disabled** — `hostingView.sizingOptions = []` prevents AppKit's `NSHostingView` from auto-resizing the window, which previously caused crashes. The window stays fixed at 500x500pt, and SwiftUI handles all size animations internally.

**Built-in Display Detection** — The app detects the MacBook's built-in screen by checking `NSScreen.safeAreaInsets.top > 0` and uses `auxiliaryTopLeftArea`/`auxiliaryTopRightArea` to calculate the exact notch dimensions.

## Tech Stack

- **Swift 5** with **SwiftUI** for the interface and animations
- **AppKit** (NSPanel, NSApplication, NSEvent) for window management and system integration
- **Combine** for timer-based scroll updates
- **UserDefaults** for settings persistence
- No third-party dependencies

## Inspiration

UI and animation patterns inspired by [boring.notch](https://github.com/TheBoredTeam/boring.notch) — an open-source macOS app that brings Dynamic Island-style interactions to the MacBook notch.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Built by [@bsahane](https://github.com/bsahane)
