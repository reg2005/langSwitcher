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
    
    // MARK: - Smart Selection (Greedy Line)
    
    /// Select from cursor to start of line (⌘⇧←), copy, pass to converter,
    /// paste the result back. The converter is responsible for determining
    /// which portion to convert and returning the full replacement text.
    func selectLineAndReplace(with converter: (String) -> String?) -> Bool {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard()
        
        NSLog("[LangSwitcher] selectLineAndReplace: selecting to line start (⌘⇧←)...")
        
        // Select from cursor to beginning of line: Cmd+Shift+Left
        simulateSelectToLineStart()
        usleep(150_000) // 150ms
        
        // Copy the selection
        pasteboard.clearContents()
        simulateCopy()
        usleep(150_000) // 150ms
        
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty else {
            NSLog("[LangSwitcher] selectLineAndReplace: no text copied")
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] selectLineAndReplace: copied line = '\(selectedText)' (len=\(selectedText.count))")
        
        guard let convertedText = converter(selectedText) else {
            NSLog("[LangSwitcher] selectLineAndReplace: converter returned nil, deselecting")
            simulateRightArrow()
            restorePasteboard(savedContents)
            return false
        }
        
        NSLog("[LangSwitcher] selectLineAndReplace: pasting = '\(convertedText)'")
        
        // Paste (replaces the entire selection from cursor to line start)
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
    
    /// Helper: post a key event with modifiers.
    /// Uses .hidSystemState to avoid interference with current keyboard state
    /// (e.g., if Shift is still physically held from double-shift trigger).
    private func postKeyEvent(virtualKey: CGKeyCode, keyDown: Bool, modifiers: CGEventFlags = []) {
        // Use .hidSystemState instead of .combinedSessionState to create events
        // independent of the current modifier state (avoids Shift bleed from double-tap)
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: keyDown) else {
            NSLog("[LangSwitcher] ERROR: Failed to create CGEvent (key=\(virtualKey), down=\(keyDown))")
            return
        }
        
        // Set flags explicitly — this overrides any current keyboard state
        event.flags = modifiers
        event.post(tap: .cgAnnotatedSessionEventTap)
        
        NSLog("[LangSwitcher] Posted key event: key=0x\(String(virtualKey, radix: 16)), down=\(keyDown), mods=\(modifiers.rawValue)")
    }
    
    /// Simulate a full keystroke (key down + key up) with modifiers
    private func simulateKeystroke(virtualKey: CGKeyCode, modifiers: CGEventFlags = []) {
        postKeyEvent(virtualKey: virtualKey, keyDown: true, modifiers: modifiers)
        postKeyEvent(virtualKey: virtualKey, keyDown: false, modifiers: modifiers)
    }
    
    private func simulateCopy() {
        NSLog("[LangSwitcher] Simulating ⌘C...")
        simulateKeystroke(virtualKey: 0x08, modifiers: .maskCommand) // C key
    }
    
    private func simulatePaste() {
        NSLog("[LangSwitcher] Simulating ⌘V...")
        simulateKeystroke(virtualKey: 0x09, modifiers: .maskCommand) // V key
    }
    
    /// Simulate Cmd+Shift+Left to select from cursor to start of line
    private func simulateSelectToLineStart() {
        NSLog("[LangSwitcher] Simulating ⌘⇧←...")
        simulateKeystroke(virtualKey: 0x7B, modifiers: [.maskShift, .maskCommand]) // Left arrow + Cmd+Shift
    }
    
    /// Simulate Shift+Option+Left to select one word to the left
    private func simulateSelectWordLeft() {
        NSLog("[LangSwitcher] Simulating ⇧⌥←...")
        simulateKeystroke(virtualKey: 0x7B, modifiers: [.maskShift, .maskAlternate]) // Left arrow
    }
    
    /// Simulate Right arrow to deselect (move cursor to end of selection)
    private func simulateRightArrow() {
        NSLog("[LangSwitcher] Simulating →...")
        simulateKeystroke(virtualKey: 0x7C) // Right arrow, no modifiers
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
