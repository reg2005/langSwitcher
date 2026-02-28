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
            let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "LayoutSwitcher")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "LayoutSwitcher — \(settingsManager.hotkeyDescription) to convert"
        }
        statusItem.menu = menu
    }
    
    private func setupMenu() {
        menu.removeAllItems()
        
        // Header
        let headerItem = NSMenuItem(title: "LayoutSwitcher", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13)
        ]
        headerItem.attributedTitle = NSAttributedString(string: "⌨ LayoutSwitcher", attributes: attrs)
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Convert action
        let convertItem = NSMenuItem(
            title: "Convert Text (\(settingsManager.hotkeyDescription))",
            action: #selector(convertAction),
            keyEquivalent: ""
        )
        convertItem.target = self
        menu.addItem(convertItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Active layouts info
        let layoutsHeader = NSMenuItem(title: "Active Layouts:", action: nil, keyEquivalent: "")
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
            title: "Conversions: \(settingsManager.conversionCount)",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // About
        let aboutItem = NSMenuItem(
            title: "About LayoutSwitcher",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit LayoutSwitcher",
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
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LayoutSwitcher Settings"
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
        window.title = "About LayoutSwitcher"
        window.center()
        window.contentView = NSHostingView(rootView: AboutView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        aboutWindow = window
    }
    
    /// Refresh the menu (call after settings change)
    func refreshMenu() {
        setupMenu()
    }
}
