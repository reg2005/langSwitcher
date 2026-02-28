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
        // Menu bar app — no main window.
        // Settings window is managed manually via StatusBarController.openSettings()
        // using NSWindow + NSHostingView, so we don't need a Settings scene.
        //
        // NOTE: We must provide at least one Scene. Using a WindowGroup with
        // an empty ID and hidden content avoids the grey Settings window that
        // Settings { EmptyView() } would auto-open on first launch.
        WindowGroup(id: "langswitcher-placeholder") {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .defaultSize(width: 0, height: 0)
    }
}
