import Cocoa
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    let settingsManager = SettingsManager.shared
    let conversionLogStore = ConversionLogStore.shared
    private var statusBarController: StatusBarController?
    private let hotkeyManager = HotkeyManager()
    private let accessibilityService = AccessibilityService()
    private lazy var textConverter = TextConverter(settingsManager: settingsManager)
    
    private var l10n: LocalizationManager { LocalizationManager.shared }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[LangSwitcher] App launched. Bundle: \(Bundle.main.bundlePath)")
        NSLog("[LangSwitcher] Executable: \(Bundle.main.executablePath ?? "unknown")")
        NSLog("[LangSwitcher] PID: \(ProcessInfo.processInfo.processIdentifier)")
        
        // Setup status bar
        statusBarController = StatusBarController(settingsManager: settingsManager)
        statusBarController?.onConvertAction = { [weak self] in
            self?.performConversion()
        }
        
        // Register hotkey
        registerHotkey()
        
        // Check accessibility permissions and log status
        let trusted = AccessibilityService.hasAccessibilityPermission
        NSLog("[LangSwitcher] Initial AXIsProcessTrusted = \(trusted)")
        if !trusted {
            NSLog("[LangSwitcher] Requesting accessibility permission prompt...")
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
    
    /// Track whether we've already shown the permission alert this session
    private var hasShownPermissionAlert = false
    
    func performConversion() {
        let hasPerm = AccessibilityService.hasAccessibilityPermission
        NSLog("[LangSwitcher] performConversion() called, hasAccessibilityPermission=\(hasPerm)")
        
        if !hasPerm {
            NSLog("[LangSwitcher] AXIsProcessTrusted=false. Will attempt conversion anyway (CGEvent may work with Input Monitoring).")
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                NSLog("[LangSwitcher] TIP: If conversion doesn't work, remove the app from Accessibility list in System Settings and re-add it. Also check Input Monitoring.")
            }
        }
        
        // Try clipboard-based approach first (works when text is selected)
        var capturedInput: String?
        var capturedOutput: String?
        let success = accessibilityService.getAndReplaceSelectedText { [weak self] (text: String) -> String? in
            NSLog("[LangSwitcher] getAndReplaceSelectedText got text: '\(text)' (len=\(text.count))")
            capturedInput = text
            let result = self?.textConverter.convertSelectedText(text)
            capturedOutput = result
            NSLog("[LangSwitcher] convertSelectedText returned: \(result ?? "nil")")
            return result
        }
        
        if success {
            NSLog("[LangSwitcher] Direct conversion succeeded")
            settingsManager.incrementConversionCount()
            logConversion(input: capturedInput, output: capturedOutput, mode: "direct")
            playFeedback()
        } else {
            NSLog("[LangSwitcher] No selected text, trying smart conversion after short delay...")
            usleep(50_000) // 50ms
            performSmartConversion()
        }
    }
    
    /// When no text is selected, use the configured smart conversion mode
    private func performSmartConversion() {
        let mode = settingsManager.smartConversionMode
        NSLog("[LangSwitcher] performSmartConversion() mode=\(mode.displayName)")
        
        switch mode {
        case .disabled:
            NSLog("[LangSwitcher] Smart conversion is disabled")
            return
            
        case .lastWord:
            performLastWordConversion()
            
        case .greedyLine:
            performGreedyLineConversion()
        }
    }
    
    /// Last Word mode: select one word left, convert if it looks wrong
    private func performLastWordConversion() {
        var capturedInput: String?
        var capturedOutput: String?
        let success = accessibilityService.selectAndReplaceLastWord { [weak self] (text: String) -> String? in
            guard let self = self else { return nil }
            NSLog("[LangSwitcher] lastWord got: '\(text)'")
            
            if self.textConverter.looksLikeWrongLayout(text) {
                capturedInput = text
                let result = self.textConverter.convertSelectedText(text)
                capturedOutput = result
                return result
            }
            return nil
        }
        
        if success {
            settingsManager.incrementConversionCount()
            logConversion(input: capturedInput, output: capturedOutput, mode: "lastWord")
            playFeedback()
        }
    }
    
    /// Greedy Line mode: select to line start, find boundary, convert wrong-layout tail
    private func performGreedyLineConversion() {
        var capturedInput: String?
        var capturedOutput: String?
        let success = accessibilityService.selectLineAndReplace { [weak self] (lineText: String) -> String? in
            guard let self = self else { return nil }
            NSLog("[LangSwitcher] greedyLine got line: '\(lineText)' (len=\(lineText.count))")
            
            capturedInput = lineText
            let result = self.textConverter.convertLineGreedy(lineText)
            capturedOutput = result
            return result
        }
        
        if success {
            settingsManager.incrementConversionCount()
            logConversion(input: capturedInput, output: capturedOutput, mode: "greedyLine")
            playFeedback()
        }
    }
    
    // MARK: - Conversion Logging
    
    private func logConversion(input: String?, output: String?, mode: String) {
        guard let input = input, let output = output else { return }
        
        let layouts = settingsManager.enabledLayouts
        let layoutIDs = layouts.map(\.id)
        
        let sourceLayout = LayoutMapper.detectSourceLayout(text: input, candidateLayouts: layoutIDs) ?? "unknown"
        let targetLayout = layouts.first(where: { $0.id != sourceLayout })?.id ?? "unknown"
        
        conversionLogStore.log(
            inputText: input,
            outputText: output,
            sourceLayout: sourceLayout,
            targetLayout: targetLayout,
            conversionMode: mode
        )
    }
    
    private func playFeedback() {
        if settingsManager.playSounds {
            NSSound(named: .init("Tink"))?.play()
        }
    }
    
    private func showAccessibilityAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = l10n.t("alert.accessibilityTitle")
        alert.informativeText = l10n.t("alert.accessibilityMessage")
        alert.alertStyle = .warning
        alert.addButton(withTitle: l10n.t("alert.openSystemSettings"))
        alert.addButton(withTitle: l10n.t("alert.continueAnyway"))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
}
