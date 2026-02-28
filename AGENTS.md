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
