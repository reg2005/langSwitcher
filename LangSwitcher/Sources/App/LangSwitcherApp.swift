import SwiftUI

/// Initialize localization dictionaries before the app launches.
/// Each Strings_xx file registers its dictionary with LocalizationManager.
@MainActor private func initializeLocalization() {
    Strings_en.register()
    Strings_ru.register()
}

@main
struct LangSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        initializeLocalization()
    }
    
    var body: some Scene {
        // Menu bar app — no main window
        // Settings window is managed manually via StatusBarController
        Settings {
            EmptyView()
        }
    }
}
