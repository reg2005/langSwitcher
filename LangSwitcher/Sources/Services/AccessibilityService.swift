import Foundation
import AppKit
import ApplicationServices

// MARK: - Accessibility Service
// Handles getting and replacing selected text via macOS Accessibility API & pasteboard

final class AccessibilityService {
    
    /// Check if the app has accessibility permissions
    static var hasAccessibilityPermission: Bool {
        let trusted = AXIsProcessTrusted()
        NSLog("[LangSwitcher] AXIsProcessTrusted() = \(trusted), bundle = \(Bundle.main.bundlePath)")
        return trusted
    }
    
    /// Request accessibility permissions (opens System Preferences)
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let result = AXIsProcessTrustedWithOptions(options)
        NSLog("[LangSwitcher] AXIsProcessTrustedWithOptions(prompt=true) = \(result)")
    }
    
    // MARK: - Selected Text Conversion
    
    /// Get selected text and replace it using clipboard-based approach.
    /// Returns false if no text was selected/copied.
    func getAndReplaceSelectedText(with converter: (String) -> String?) -> Bool {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard()
        
        // Copy selected text (⌘C)
        pasteboard.clearContents()
        simulateCopy()
        usleep(150_000) // 150ms — give target app time to process ⌘C
        
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty else {
            NSLog("[LangSwitcher] getAndReplaceSelectedText: no text on clipboard after ⌘C")
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] getAndReplaceSelectedText: copied text = '\(selectedText)'")
        
        guard let convertedText = converter(selectedText) else {
            NSLog("[LangSwitcher] getAndReplaceSelectedText: converter returned nil")
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] getAndReplaceSelectedText: pasting converted text = '\(convertedText)'")
        
        // Paste converted text
        pasteboard.clearContents()
        pasteboard.setString(convertedText, forType: .string)
        simulatePaste()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.restorePasteboard(savedContents)
        }
        
        return true
    }
    
    // MARK: - Smart Selection (Last Word)
    
    /// When no text is selected, select the last typed word/chunk via
    /// Option+Shift+Left (select word left), copy it, convert, paste back.
    /// This selects the word just before the cursor.
    func selectAndReplaceLastWord(with converter: (String) -> String?) -> Bool {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard()
        
        NSLog("[LangSwitcher] selectAndReplaceLastWord: selecting word left...")
        
        // First, try selecting last word: Shift+Option+Left arrow selects one word left
        simulateSelectWordLeft()
        usleep(150_000) // 150ms — give target app time to process selection
        
        // Copy the selection
        pasteboard.clearContents()
        simulateCopy()
        usleep(150_000) // 150ms — give target app time to process ⌘C
        
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty else {
            NSLog("[LangSwitcher] selectAndReplaceLastWord: no text copied after selection+copy")
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] selectAndReplaceLastWord: copied word = '\(selectedText)'")
        
        guard let convertedText = converter(selectedText) else {
            NSLog("[LangSwitcher] selectAndReplaceLastWord: converter returned nil, deselecting")
            // No conversion needed — deselect by pressing Right arrow
            simulateRightArrow()
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] selectAndReplaceLastWord: pasting converted = '\(convertedText)'")
        
        // Paste converted text (replaces the selection)
        pasteboard.clearContents()
        pasteboard.setString(convertedText, forType: .string)
        simulatePaste()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.restorePasteboard(savedContents)
        }
        
        return true
    }
    
    // MARK: - Keyboard Simulation
    
    private func simulateCopy() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Simulate Shift+Option+Left to select one word to the left
    private func simulateSelectWordLeft() {
        let source = CGEventSource(stateID: .combinedSessionState)
        // Left arrow = keyCode 0x7B
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x7B, keyDown: true)
        keyDown?.flags = [.maskShift, .maskAlternate] // Shift+Option
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x7B, keyDown: false)
        keyUp?.flags = [.maskShift, .maskAlternate]
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Simulate Right arrow to deselect (move cursor to end of selection)
    private func simulateRightArrow() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: true) // Right arrow
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Pasteboard Save/Restore
    
    private func savePasteboard() -> [(String, NSPasteboard.PasteboardType)] {
        let pasteboard = NSPasteboard.general
        return pasteboard.pasteboardItems?.compactMap { item -> (String, NSPasteboard.PasteboardType)? in
            for type in item.types {
                if let data = item.string(forType: type) {
                    return (data, type)
                }
            }
            return nil
        } ?? []
    }
    
    private func restorePasteboard(_ items: [(String, NSPasteboard.PasteboardType)]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        for (string, type) in items {
            pasteboard.setString(string, forType: type)
        }
    }
}
