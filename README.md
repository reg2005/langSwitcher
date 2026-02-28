# LangSwitcher

[English](README.md) | [Русский](README.ru.md)

**Open-source keyboard layout text converter for macOS.**

Typed text in the wrong keyboard layout? Select it, press a hotkey, and LangSwitcher instantly converts it to the correct layout. No more retyping `ghbdtn` when you meant `привет`.

An open-source alternative to [Caramba Switcher](https://caramba-switcher.com/mac) and [Punto Switcher](https://yandex.ru/soft/punto/).

[![Build](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml/badge.svg)](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen.svg)](https://www.apple.com/macos/)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org/)

## Screenshot

![LangSwitcher Settings — General](screenshots/general.png)

## Key Features

- **Instant text conversion** — select text and press a hotkey to convert between layouts
- **Smart Conversion modes** — works even without manual text selection:
  - **Greedy Line (default)** — selects to line start, finds where wrong layout begins, converts the entire wrong-layout phrase
  - **Last Word** — auto-selects and converts only the last typed word
  - **Disabled** — only works with explicit text selection
- **Auto-detection** — automatically detects which layout the text was typed in
- **System keyboard integration** — uses your installed system keyboard layouts
- **Double Shift hotkey** — press `⇧⇧` (Shift twice quickly) to convert, or set a custom shortcut
- **Conversion Log** — optionally log conversions to a local SQLite database (disabled by default for privacy). Review and label entries (correct/incorrect) for future ML training
- **JSON export** — export conversion logs for data analysis or model training
- **Menu bar app** — lives quietly in your status bar, always ready
- **Multiple layouts** — supports English, Russian, German, French, Spanish (5 layouts)
- **Punctuation preservation** — `?`, `!`, `/` and other punctuation stay unchanged during conversion
- **Zero dependencies** — pure Swift, no external libraries, no dictionaries
- **Privacy first** — no data leaves your Mac, no analytics, no network access
- **Open source** — MIT licensed, contributions welcome

## How It Works

```
1. You type "ghbdtn" (meant to type "привет" but had English layout active)
2. Select the mistyped text (or just press the hotkey — Smart Conversion handles it)
3. Press ⇧⇧ (double Shift)
4. Text is replaced with "привет"
```

LangSwitcher maps characters based on **physical key positions** on the keyboard. The same physical key produces different characters depending on the active layout — LangSwitcher reverses this mapping.

## Download

### DMG (Recommended)

Go to [Releases](https://github.com/reg2005/langSwitcher/releases/latest) and download:

| Architecture | File |
|---|---|
| **Apple Silicon (M1/M2/M3/M4)** | `LangSwitcher-*-arm64.dmg` |
| **Intel** | `LangSwitcher-*-x86_64.dmg` |
| **Universal (both)** | `LangSwitcher-*-universal.dmg` |

1. Open the DMG and drag **LangSwitcher** to **Applications**
2. Launch LangSwitcher
3. Grant **Accessibility** permission when prompted

### Build from Source

#### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later

#### Steps

```bash
# Clone the repository
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Run tests
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Build (universal binary)
xcodebuild -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -configuration Release \
  -derivedDataPath build \
  -arch arm64 -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

# The app is at build/Build/Products/Release/LangSwitcher.app
```

Or open `LangSwitcher.xcodeproj` in Xcode and press `⌘R`.

## Usage

### Basic Workflow

1. **Type text** in any application
2. **Realize** you had the wrong keyboard layout active
3. **Press** `⇧⇧` (double Shift) — Smart Conversion auto-selects and converts
4. Or **select** the mistyped text manually, then press the hotkey
5. The text is **instantly converted** to the correct layout

### Smart Conversion Modes

| Mode | Behavior |
|------|----------|
| **Greedy Line** (default) | Selects to line start, finds where wrong layout begins, converts the entire wrong-layout phrase. Handles `"ghbdtn rfr ltkf lheu"` -> `"привет как дела друг"` |
| **Last Word** | Auto-selects only the last word before the cursor, converts if it looks like wrong layout |
| **Disabled** | Only works with explicit manual text selection |

### Menu Bar

LangSwitcher lives in your menu bar with a keyboard icon. Click it to:

- Convert selected text manually
- See active keyboard layouts
- View conversion statistics
- Open settings
- Quit the app

### Settings

Access settings from the menu bar icon -> **Settings** (or `⌘,`):

| Tab | Description |
|-----|-------------|
| **General** | Launch at login, sounds, notifications, Smart Conversion mode, Layout Switch mode |
| **Layouts** | View and refresh detected keyboard layouts |
| **Hotkey** | Toggle double-shift or record a custom shortcut |
| **Permissions** | Check and grant Accessibility access |
| **Log** | View conversion history, label entries as correct/incorrect, export to JSON |

### Conversion Log

Conversion logging is **disabled by default** for your privacy. You can enable it in **Settings -> General -> Conversion Logging**.

When enabled, conversions are saved to a local SQLite database (`~/Library/Application Support/LangSwitcher/conversion_log.sqlite`). You can configure the maximum number of stored entries (default: 100, or 0 for unlimited). In the **Log** tab you can:

- Browse all past conversions (input -> output, layouts, mode, timestamp)
- Rate each conversion as correct or incorrect (tri-state: unrated / correct / incorrect)
- Export the labeled data as JSON for ML training or analysis
- Delete individual entries or clear the entire log

**No data ever leaves your Mac.** The conversion log is stored purely locally and is never transmitted anywhere.

## Supported Layouts

LangSwitcher detects layouts from your **System Settings > Keyboard > Input Sources**. Currently supported:

| Layout | Language Code | Physical Layout |
|--------|--------------|-----------------|
| U.S. (QWERTY) | `en` | QWERTY |
| ABC | `en` | QWERTY |
| Russian | `ru` | ЙЦУКЕН |
| German | `de` | QWERTZ |
| French | `fr` | AZERTY |
| Spanish | `es` | QWERTY (Spanish) |

Adding a new layout is straightforward — see [Contributing](#contributing).

## Architecture

```
LangSwitcher/
├── Sources/
│   ├── App/
│   │   ├── LangSwitcherApp.swift       # SwiftUI App entry point
│   │   ├── AppDelegate.swift           # App lifecycle, hotkey, conversion orchestration
│   │   └── StatusBarController.swift   # Menu bar icon and menu
│   ├── Views/
│   │   ├── SettingsView.swift          # Settings window (5 tabs)
│   │   ├── ConversionLogView.swift     # Conversion log with data labeling
│   │   ├── HotkeyRecorderView.swift    # Custom hotkey recorder
│   │   ├── AboutView.swift             # About window
│   │   └── PermissionsView.swift       # Accessibility permissions
│   ├── Services/
│   │   ├── LayoutMapper.swift          # Character mapping engine
│   │   ├── KeyboardLayoutDetector.swift # System layout detection (Carbon TIS)
│   │   ├── TextConverter.swift         # Conversion orchestrator + greedy algorithm
│   │   ├── ConversionLogStore.swift    # SQLite-based conversion log storage
│   │   ├── HotkeyManager.swift         # Global hotkey (double-shift + custom)
│   │   ├── AccessibilityService.swift  # Clipboard-based text replacement
│   │   └── SettingsManager.swift       # UserDefaults persistence
│   ├── Localization/
│   │   ├── LocalizationManager.swift   # Runtime i18n engine
│   │   ├── Strings_en.swift            # English strings (~113 keys)
│   │   └── Strings_ru.swift            # Russian strings
│   └── Models/
│       ├── KeyboardLayout.swift        # Layout model & character maps
│       └── ConversionLog.swift         # Conversion log entry model
├── Resources/
│   └── Assets.xcassets                 # App icons and colors
├── LangSwitcherTests/
│   ├── LayoutMapperTests.swift         # 58 mapping tests
│   └── TextConverterTests.swift        # 35 converter tests
├── .github/workflows/
│   ├── build.yml                       # CI: test + build DMGs (Intel/ARM/Universal) + release
│   └── pages.yml                       # GitHub Pages deployment
├── screenshots/
│   └── general.png                     # Settings General tab
└── docs/
    ├── index.html                      # Locale router (redirects to en/ru)
    ├── en.html                         # English project page
    ├── ru.html                         # Russian project page
    └── screenshots/
        └── general.png                 # Screenshot for Pages
```

### How Conversion Works

```
Input: "ghbdtn" (typed on US layout when Russian was intended)

1. Detect source layout -> "US" (characters match US keyboard map)
2. For each character, find physical key position:
   g -> key at position [0x05]
   h -> key at position [0x04]
   ...
3. Map physical key to target layout (Russian):
   [0x05] -> п
   [0x04] -> р
   ...
4. Apply punctuation preservation (non-letter -> non-letter stays as-is)
5. Result: "привет"
```

### Key Design Decisions

- **Clipboard-based replacement**: Uses `⌘C` -> transform -> `⌘V` approach for maximum app compatibility. Works in virtually any text field.
- **No CGEvent tap**: Avoids `CGEventTap` which requires special entitlements. Instead uses `NSEvent.addGlobalMonitorForEvents` for hotkey detection and `CGEvent` with `.hidSystemState` for keyboard simulation.
- **Physical key mapping**: Maps characters through their physical key position, not Unicode translation tables. This is more reliable for non-standard layouts.
- **No sandbox**: The app requires Accessibility access which is incompatible with App Sandbox.
- **SQLite for logging**: Direct SQLite3 C API — no external dependencies. Data stays local for privacy.
- **Greedy two-pass algorithm**: Pass 1 checks if the whole line is wrong-layout (all words switch script). Pass 2 scans right-to-left for mixed lines. The 70% threshold handles ambiguous cases.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Swift 5 |
| **UI Framework** | SwiftUI |
| **Platform** | macOS 13+ (Ventura) |
| **Input Detection** | Carbon (TISInputSource) |
| **Text Manipulation** | Accessibility API + Pasteboard |
| **Hotkey** | NSEvent global monitor + CGEvent |
| **Settings** | UserDefaults |
| **Conversion Log** | SQLite3 (C API, no dependencies) |
| **Localization** | Custom runtime i18n (English, Russian) |
| **CI/CD** | GitHub Actions |
| **Distribution** | DMG (Intel + ARM + Universal) via GitHub Releases |
| **Website** | GitHub Pages |
| **Tests** | XCTest (93 tests) |

## Permissions

LangSwitcher requires **Accessibility** access to:
- Read selected text (via simulated `⌘C`)
- Replace text (via simulated `⌘V`)

Grant access in **System Settings -> Privacy & Security -> Accessibility**.

The app does **not**:
- Log keystrokes
- Send data to any server — **all data stays on your Mac**
- Access files or network
- Run in the background when quit
- Collect any analytics or telemetry

**Conversion logging is disabled by default.** When you enable it, all data is stored locally in `~/Library/Application Support/LangSwitcher/`. Nothing is ever uploaded or shared.

## Contributing

Contributions are welcome! Here's how to add a new keyboard layout:

1. Open `LangSwitcher/Sources/Models/KeyboardLayout.swift`
2. Add a new static property to `LayoutCharacterMap` with the character mapping
3. Add the pattern to `allMaps` array (**order matters** — specific patterns before generic ones)
4. Add tests in `LangSwitcherTests/LayoutMapperTests.swift`
5. Run tests: all 93+ must pass

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

### Adding a New Language (i18n)

LangSwitcher uses a custom localization system — no `.lproj` / `.strings` files. Language can be switched at runtime without restarting the app.

1. **Copy the English template**:
   ```bash
   cp LangSwitcher/Sources/Localization/Strings_en.swift \
      LangSwitcher/Sources/Localization/Strings_xx.swift
   ```
   Replace `xx` with the language code (e.g. `de`, `fr`, `es`).

2. **Translate** every value in the `strings` dictionary. Keys stay the same — only change the values.

3. **Update `register()`** at the bottom of your new file:
   ```swift
   @MainActor static func register() {
       LocalizationManager.shared.register(language: "xx", strings: strings)
   }
   ```

4. **Register the new file** in `LangSwitcherApp.swift`:
   ```swift
   private func initializeLocalization() {
       Strings_en.register()
       Strings_ru.register()
       Strings_xx.register()  // <-- add this
   }
   ```

5. **Add to available languages** in `LocalizationManager.swift`:
   ```swift
   let availableLanguages: [(code: String, name: String)] = [
       ("en", "English"),
       ("ru", "Русский"),
       ("xx", "Your Language"),  // <-- add this
   ]
   ```

6. **Add the file to Xcode project** — add a `PBXBuildFile`, `PBXFileReference`, add to the Localization group, and add to `PBXSourcesBuildPhase` in `project.pbxproj`. Follow the existing `E1000001...` PBX ID pattern.

7. **Run tests** — all must pass.

String keys use namespace prefixes: `menu.*`, `settings.*`, `general.*`, `smartMode.*`, `layouts.*`, `hotkey.*`, `permissions.*`, `log.*`, `about.*`, `alert.*`, `common.*`.

### Code Signing & Notarization (CI/CD)

Release builds can be signed with an Apple Developer ID certificate and notarized via GitHub Actions. Without secrets configured, builds use ad-hoc signing (works for local use, but macOS Gatekeeper will warn users).

**Required secrets** (Settings > Secrets and variables > Actions):

| Secret | Description |
|---|---|
| `MACOS_CERTIFICATE_P12` | Developer ID Application certificate exported as `.p12`, then base64-encoded: `base64 -i cert.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` file |
| `MACOS_KEYCHAIN_PASSWORD` | Any random string (used for the temporary CI keychain) |
| `MACOS_SIGNING_IDENTITY` | Full identity string, e.g. `Developer ID Application: Your Name (TEAMID)` |

**Optional secrets** (for notarization — recommended for public distribution):

| Secret | Description |
|---|---|
| `MACOS_NOTARIZATION_APPLE_ID` | Your Apple ID email |
| `MACOS_NOTARIZATION_PASSWORD` | App-specific password ([appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords) |
| `MACOS_NOTARIZATION_TEAM_ID` | Your 10-character Apple Developer Team ID |

**How to get the certificate:**

1. Open Keychain Access on your Mac
2. In the login keychain, find your "Developer ID Application" certificate
3. Right-click > Export Items > save as `.p12` with a password
4. Base64-encode it: `base64 -i DeveloperID.p12 | pbcopy`
5. Paste the result into the `MACOS_CERTIFICATE_P12` GitHub secret

**Behavior:**
- If `MACOS_CERTIFICATE_P12` is set: builds are signed with your Developer ID + hardened runtime
- If notarization secrets are also set: DMGs are submitted to Apple for notarization and stapled
- If no secrets are set: ad-hoc signing (forks and PRs work without any setup)

### Development

```bash
# Clone
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Run tests (required after every code change)
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Open in Xcode
open LangSwitcher.xcodeproj
```

See [AGENTS.md](AGENTS.md) for AI agent / contributor guidelines.

## License

[MIT License](LICENSE) — free for personal and commercial use.

## Acknowledgments

Inspired by [Caramba Switcher](https://caramba-switcher.com/mac) and [Punto Switcher](https://yandex.ru/soft/punto/). Built as a free, open-source alternative.
