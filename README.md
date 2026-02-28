# LayoutSwitcher

**Open-source keyboard layout text converter for macOS.**

Typed text in the wrong keyboard layout? Select it, press a hotkey, and LayoutSwitcher instantly converts it to the correct layout. No more retyping `ghbdtn` when you meant `привет`.

[![Build](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml/badge.svg)](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen.svg)](https://www.apple.com/macos/)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org/)

## Key Features

- **Instant text conversion** — select text and press a hotkey to convert between layouts
- **Auto-detection** — automatically detects which layout the text was typed in
- **System keyboard integration** — uses your installed system keyboard layouts
- **Double Shift hotkey** — press `⇧⇧` (Shift twice) to convert, or set a custom shortcut
- **Menu bar app** — lives quietly in your status bar, always ready
- **Multiple layouts** — supports English, Russian, Ukrainian, German, French, Spanish
- **Zero dependencies** — pure Swift, no external libraries
- **Open source** — MIT licensed, contributions welcome

## How It Works

```
1. You type "ghbdtn" (meant to type "привет" but had English layout active)
2. Select the mistyped text
3. Press ⇧⇧ (double Shift)
4. Text is replaced with "привет"
```

LayoutSwitcher maps characters based on **physical key positions** on the keyboard. The same physical key produces different characters depending on the active layout — LayoutSwitcher reverses this mapping.

## Installation

### Download DMG (Recommended)

1. Go to [Releases](https://github.com/reg2005/langSwitcher/releases/latest)
2. Download `LayoutSwitcher-x.x.x.dmg`
3. Open the DMG and drag **LayoutSwitcher** to **Applications**
4. Launch LayoutSwitcher
5. Grant **Accessibility** permission when prompted

### Build from Source

#### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later

#### Steps

```bash
# Clone the repository
git clone https://github.com/reg2005/langSwitcher.git
cd LayoutSwitcher

# Build with xcodebuild
xcodebuild -project LayoutSwitcher.xcodeproj \
  -scheme LayoutSwitcher \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  build

# The app is at build/Build/Products/Release/LayoutSwitcher.app
```

Or open `LayoutSwitcher.xcodeproj` in Xcode and press `⌘R`.

## Usage

### Basic Workflow

1. **Type text** in any application
2. **Realize** you had the wrong keyboard layout active
3. **Select** the mistyped text (`⌘A` or drag to select)
4. **Press** `⇧⇧` (double Shift) — or your custom hotkey
5. The text is **instantly converted** to the correct layout

### Menu Bar

LayoutSwitcher lives in your menu bar with a keyboard icon (⌨). Click it to:

- Convert selected text manually
- See active keyboard layouts
- View conversion statistics
- Open settings
- Quit the app

### Settings

Access settings from the menu bar icon → **Settings** (or `⌘,`):

| Tab | Description |
|-----|-------------|
| **General** | Launch at login, sounds, notifications |
| **Layouts** | View and refresh detected keyboard layouts |
| **Hotkey** | Toggle double-shift or record a custom shortcut |
| **Permissions** | Check and grant Accessibility access |

## Supported Layouts

LayoutSwitcher detects layouts from your **System Settings > Keyboard > Input Sources**. Currently supported:

| Layout | Language Code | Physical Layout |
|--------|--------------|-----------------|
| U.S. (QWERTY) | `en` | QWERTY |
| ABC | `en` | QWERTY |
| Russian | `ru` | ЙЦУКЕН |
| Ukrainian | `uk` | ЙЦУКЕН (Ukrainian) |
| German | `de` | QWERTZ |
| French | `fr` | AZERTY |
| Spanish | `es` | QWERTY (Spanish) |

Adding a new layout is straightforward — see [Contributing](#contributing).

## Architecture

```
LayoutSwitcher/
├── Sources/
│   ├── App/
│   │   ├── LayoutSwitcherApp.swift    # SwiftUI App entry point
│   │   ├── AppDelegate.swift          # App lifecycle, hotkey registration
│   │   └── StatusBarController.swift  # Menu bar icon and menu
│   ├── Views/
│   │   ├── SettingsView.swift         # Settings window (tabs)
│   │   ├── HotkeyRecorderView.swift   # Custom hotkey recorder
│   │   ├── AboutView.swift            # About window
│   │   └── PermissionsView.swift      # Accessibility permissions
│   ├── Services/
│   │   ├── LayoutMapper.swift         # Character mapping engine
│   │   ├── KeyboardLayoutDetector.swift # System layout detection
│   │   ├── TextConverter.swift        # High-level conversion orchestrator
│   │   ├── HotkeyManager.swift        # Global hotkey registration
│   │   ├── AccessibilityService.swift # Clipboard-based text replacement
│   │   └── SettingsManager.swift      # UserDefaults persistence
│   └── Models/
│       └── KeyboardLayout.swift       # Layout model & character maps
├── Resources/
│   └── Assets.xcassets                # App icons and colors
├── .github/workflows/
│   ├── build.yml                      # CI: build + DMG + release
│   └── pages.yml                      # GitHub Pages deployment
└── docs/
    └── index.html                     # Project website
```

### How Conversion Works

```
Input: "ghbdtn" (typed on US layout when Russian was intended)

1. Detect source layout → "US" (characters match US keyboard)
2. For each character, find physical key position:
   g → key at position [0x05]
   h → key at position [0x04]
   ...
3. Map physical key to target layout (Russian):
   [0x05] → п
   [0x04] → р
   ...
4. Result: "привет"
```

### Key Design Decisions

- **Clipboard-based replacement**: Uses `⌘C` → transform → `⌘V` approach for maximum app compatibility. Works in virtually any text field.
- **No CGEvent tap**: Avoids `CGEventTap` which requires special entitlements and can be blocked by apps. Instead uses `NSEvent.addGlobalMonitorForEvents` for hotkey detection.
- **Physical key mapping**: Maps characters through their physical key position, not Unicode translation tables. This is more reliable for non-standard layouts.
- **No sandbox**: The app requires Accessibility access which is incompatible with App Sandbox.

## Permissions

LayoutSwitcher requires **Accessibility** access to:
- Read selected text (via simulated `⌘C`)
- Replace text (via simulated `⌘V`)

Grant access in **System Settings → Privacy & Security → Accessibility**.

The app does **not**:
- Log keystrokes
- Send data to any server
- Access files or network
- Run in the background when quit

## Contributing

Contributions are welcome! Here's how to add a new keyboard layout:

1. Open `LayoutSwitcher/Sources/Models/KeyboardLayout.swift`
2. Add a new static property to `LayoutCharacterMap` with the character mapping
3. Add the pattern to `allMaps` array
4. Test with the actual keyboard layout installed

```swift
// Example: adding Italian layout
static let italian: [Character: Character] = {
    let qwerty  = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./...")
    let italian = Array("\\1234567890'ìqwertyuiopè+ùasdfghjklòàzxcvbnm,.-...")
    var map: [Character: Character] = [:]
    for i in 0..<min(qwerty.count, italian.count) {
        map[qwerty[i]] = italian[i]
    }
    return map
}()
```

### Development

```bash
# Clone
git clone https://github.com/reg2005/langSwitcher.git
cd LayoutSwitcher

# Open in Xcode
open LayoutSwitcher.xcodeproj

# Build & Run
# Press ⌘R in Xcode
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Swift 5 |
| **UI Framework** | SwiftUI |
| **Platform** | macOS 13+ (Ventura) |
| **Input Detection** | Carbon (TISInputSource) |
| **Text Manipulation** | Accessibility API + Pasteboard |
| **Hotkey** | NSEvent global monitor |
| **Persistence** | UserDefaults |
| **CI/CD** | GitHub Actions |
| **Distribution** | DMG via GitHub Releases |

## License

[MIT License](LICENSE) — free for personal and commercial use.

## Acknowledgments

Inspired by [Caramba Switcher](https://caramba-switcher.com/mac) and [Punto Switcher](https://yandex.ru/soft/punto/). Built as a free, open-source alternative.
