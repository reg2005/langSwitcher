import Cocoa
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    let settingsManager = SettingsManager.shared
    private var statusBarController: StatusBarController?
    private let hotkeyManager = HotkeyManager()
    private let accessibilityService = AccessibilityService()
    private lazy var textConverter = TextConverter(settingsManager: settingsManager)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status bar
        statusBarController = StatusBarController(settingsManager: settingsManager)
        statusBarController?.onConvertAction = { [weak self] in
            self?.performConversion()
        }
        
        // Register hotkey
        registerHotkey()
        
        // Check accessibility permissions
        if !AccessibilityService.hasAccessibilityPermission {
            AccessibilityService.requestAccessibilityPermission()
        }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Listen for settings changes to re-register hotkey
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: .hotkeySettingsChanged,
            object: nil
        )
    }
    
    // MARK: - Hotkey Registration
    
    func registerHotkey() {
        if settingsManager.useDoubleShift {
            hotkeyManager.registerDoubleShift { [weak self] in
                Task { @MainActor in
                    self?.performConversion()
                }
            }
        } else {
            hotkeyManager.register(
                keyCode: settingsManager.hotkeyKeyCode,
                modifiers: settingsManager.hotkeyModifierFlags
            ) { [weak self] in
                Task { @MainActor in
                    self?.performConversion()
                }
            }
        }
    }
    
    @objc private func hotkeySettingsChanged() {
        registerHotkey()
    }
    
    // MARK: - Core Conversion Logic
    
    func performConversion() {
        guard AccessibilityService.hasAccessibilityPermission else {
            AccessibilityService.requestAccessibilityPermission()
            return
        }
        
        // Try clipboard-based approach first (works when text is selected)
        let success = accessibilityService.getAndReplaceSelectedText { [weak self] (text: String) -> String? in
            return self?.textConverter.convertSelectedText(text)
        }
        
        if success {
            settingsManager.incrementConversionCount()
            playFeedback()
        } else {
            // No text selected — try to find last typed gibberish and convert it
            performSmartConversion()
        }
    }
    
    /// When no text is selected, simulate selecting the last word/chunk,
    /// check if it looks like wrong-layout text, and convert it
    private func performSmartConversion() {
        // Strategy: select last typed word via Option+Shift+Left, then convert
        let success = accessibilityService.selectAndReplaceLastWord { [weak self] (text: String) -> String? in
            guard let self = self else { return nil }
            // Only convert if text looks like gibberish (wrong layout)
            if self.textConverter.looksLikeWrongLayout(text) {
                return self.textConverter.convertSelectedText(text)
            }
            return nil
        }
        
        if success {
            settingsManager.incrementConversionCount()
            playFeedback()
        }
    }
    
    private func playFeedback() {
        if settingsManager.playSounds {
            NSSound(named: .init("Tink"))?.play()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
}
