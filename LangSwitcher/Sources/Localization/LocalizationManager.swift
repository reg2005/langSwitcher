import Foundation

// MARK: - Localization Manager
// Custom runtime localization system — no Apple .lproj/.strings.
// Allows instant language switching without app restart.
// Contributors add new languages by copying Strings_en.swift.

@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    /// Available languages: code + native name
    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("ru", "Русский"),
    ]

    /// Currently active language code
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }

    /// Registry: language code -> [key: localized string]
    private var registry: [String: [String: String]] = [:]

    // MARK: - Init

    private init() {
        // Read persisted choice, or detect system language
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           Self.availableLanguages.contains(where: { $0.code == saved }) {
            self.currentLanguage = saved
        } else {
            // Auto-detect: check preferred languages for "ru"
            let preferred = Locale.preferredLanguages // e.g. ["ru-RU", "en-US"]
            let isRussian = preferred.first(where: {
                $0.lowercased().hasPrefix("ru")
            }) != nil
            self.currentLanguage = isRussian ? "ru" : "en"
            // Persist the initial choice
            UserDefaults.standard.set(self.currentLanguage, forKey: "appLanguage")
        }
    }

    // MARK: - Registration

    /// Called by each Strings_xx file to register its dictionary
    func register(language: String, strings: [String: String]) {
        registry[language] = strings
    }

    // MARK: - Lookup

    /// Translate a key. Falls back to English, then returns the key itself.
    func t(_ key: String) -> String {
        if let value = registry[currentLanguage]?[key] {
            return value
        }
        if let value = registry["en"]?[key] {
            return value
        }
        return key
    }
}
