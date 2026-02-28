import SwiftUI

@main
struct LangSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar app — no main window
        // Settings window is managed manually via StatusBarController
        Settings {
            EmptyView()
        }
    }
}
