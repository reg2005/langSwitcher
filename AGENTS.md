# AGENTS.md — Instructions for AI Agents and Contributors

## Testing Requirements

**Tests MUST be run after every edit that modifies Swift source files.**

### Running Tests Locally

```bash
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### Rules

1. **After every code change**: Run the full test suite before considering the task complete.
2. **All tests must pass**: Do not commit or push code with failing tests.
3. **New functionality requires tests**: Any new feature, bug fix, or behavioral change must include corresponding unit tests.
4. **CI enforces tests**: GitHub Actions runs `xcodebuild test` on every push and pull request. Merges are blocked if tests fail.

### Test Structure

- Test target: `LangSwitcherTests`
- Test files are in `LangSwitcherTests/`
- Tests use `XCTest` framework
- `LayoutMapper` and `TextConverter` are the primary units under test
- `SettingsManager` is `@MainActor` — tests that use it need `@MainActor` context
- `TextConverter` is `@MainActor` — also needs main actor context in tests

### What to Test

- `LayoutMapper.convert()` — character mapping between all supported layout pairs (EN, RU, UK, DE, FR, ES)
- `LayoutMapper.detectSourceLayout()` — layout detection from text content
- `LayoutCharacterMap.characterMap(for:)` — correct pattern matching for layout IDs
- `TextConverter.looksLikeWrongLayout()` — gibberish detection (script-switch heuristic)
- `TextConverter.findWrongLayoutBoundary()` — greedy line boundary detection
- `TextConverter.convertLineGreedy()` — greedy conversion of wrong-layout tails
- `TextConverter.convertSelectedText()` — full conversion pipeline
- Tokenization edge cases (punctuation, mixed scripts, empty strings)

### Important Notes

- The Xcode project uses hand-crafted PBX IDs in the format `E1000000XXXXXXXXXXXX`. New entries must follow this pattern.
- LSP cross-file errors ("Cannot find in scope") are expected and NOT real errors — they resolve at Xcode build time.
- `"russian"` contains `"us"` as a substring — pattern ordering in `allMaps` is critical. Do not reorder.

## Localization Guidelines

LangSwitcher uses a custom runtime localization system (NOT Apple `.lproj`/`.strings`). All UI strings go through `LocalizationManager`.

### Rules

1. **All new user-facing strings** must use `LocalizationManager.shared.t("key")` — never hardcode UI text.
2. **String keys use namespace prefixes**: `menu.*`, `settings.*`, `general.*`, `smartMode.*`, `layoutSwitchMode.*`, `layouts.*`, `hotkey.*`, `hotkeyRecorder.*`, `permissions.*`, `log.*`, `about.*`, `alert.*`, `common.*`.
3. **When adding a new string key**: Add it to **both** `Strings_en.swift` and `Strings_ru.swift` (and any other `Strings_xx.swift` files).
4. **`LocalizationManager` is `@MainActor`** — it is used as `@EnvironmentObject` in SwiftUI views. Any code that calls `LocalizationManager.shared.t()` must run on the main actor.
5. **Enum computed properties** (e.g. `SmartConversionMode.displayName`) that call `t()` must be annotated with `@MainActor`.
6. **Adding a new language**: Copy `Strings_en.swift` → `Strings_xx.swift`, translate values, register in `LangSwitcherApp.swift`, add to `availableLanguages` in `LocalizationManager.swift`, add to `project.pbxproj`. See README for detailed steps.
7. **Fallback**: If a key is missing in the current language, `t()` falls back to English, then returns the raw key.

### File Structure

```
LangSwitcher/Sources/Localization/
├── LocalizationManager.swift   # ObservableObject, t() lookup, language persistence
├── Strings_en.swift            # English strings (~113 keys)
└── Strings_ru.swift            # Russian translations
```
