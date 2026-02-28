import Cocoa
import SwiftUI

// MARK: - Status Bar Controller
// Manages the menu bar icon and dropdown menu

@MainActor
final class StatusBarController {
    
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    private let settingsManager: SettingsManager
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    
    var onConvertAction: (() -> Void)?
    
    private var l10n: LocalizationManager { LocalizationManager.shared }
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.statusBar = NSStatusBar.system
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        self.menu = NSMenu()
        
        setupStatusBarButton()
        setupMenu()
    }
    
    // MARK: - Setup
    
    private func setupStatusBarButton() {
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "LangSwitcher")
            image?.isTemplate = true
            button.image = image
            let tooltip = l10n.t("menu.tooltip").replacingOccurrences(of: "%@", with: settingsManager.hotkeyDescription)
            button.toolTip = tooltip
        }
        statusItem.menu = menu
    }
    
    private func setupMenu() {
        menu.removeAllItems()
        
        // Header
        let headerItem = NSMenuItem(title: "LangSwitcher", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13)
        ]
        headerItem.attributedTitle = NSAttributedString(string: l10n.t("menu.header"), attributes: attrs)
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Convert action
        let convertItem = NSMenuItem(
            title: "\(l10n.t("menu.convertText")) (\(settingsManager.hotkeyDescription))",
            action: #selector(convertAction),
            keyEquivalent: ""
        )
        convertItem.target = self
        menu.addItem(convertItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Active layouts info
        let layoutsHeader = NSMenuItem(title: l10n.t("menu.activeLayouts"), action: nil, keyEquivalent: "")
        layoutsHeader.isEnabled = false
        menu.addItem(layoutsHeader)
        
        for layout in settingsManager.enabledLayouts {
            let item = NSMenuItem(title: "  \(layout.displayName)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Stats
        let statsItem = NSMenuItem(
            title: "\(l10n.t("menu.conversions")) \(settingsManager.conversionCount)",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: l10n.t("menu.settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // About
        let aboutItem = NSMenuItem(
            title: l10n.t("menu.about"),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: l10n.t("menu.quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func convertAction() {
        onConvertAction?()
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let settingsView = SettingsView()
            .environmentObject(settingsManager)
            .environmentObject(l10n)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = l10n.t("settings.windowTitle")
        window.center()
        window.contentView = NSHostingView(rootView: settingsView)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        
        settingsWindow = window
    }
    
    @objc private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = l10n.t("about.windowTitle")
        window.center()
        window.contentView = NSHostingView(rootView: AboutView().environmentObject(l10n))
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        aboutWindow = window
    }
    
    /// Refresh the menu (call after settings change)
    func refreshMenu() {
        setupMenu()
    }
}
