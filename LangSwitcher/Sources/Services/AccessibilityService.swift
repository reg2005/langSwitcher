import Foundation
import AppKit
import ApplicationServices

// MARK: - Accessibility Service
// Handles getting and replacing selected text via macOS Accessibility API & pasteboard

final class AccessibilityService {
    
    /// Pending clipboard restore from the previous conversion (if any).
    private var pendingRestore: DispatchWorkItem?
    /// Clipboard snapshot that the pending restore is going to put back.
    private var pendingSnapshot: [NSPasteboardItem]?
    /// How long to wait after ⌘V before restoring the user's clipboard.
    /// Electron/browsers/remote desktops may read the pasteboard 300ms+ later.
    private let restoreDelay: TimeInterval = 1.0
    
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
        let copyBase = pasteboard.changeCount
        simulateCopy()
        waitForPasteboardChange(since: copyBase, timeout: 0.5)
        
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
        pasteAndScheduleRestore(convertedText, saved: savedContents)
        
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
        let copyBase = pasteboard.changeCount
        simulateCopy()
        waitForPasteboardChange(since: copyBase, timeout: 0.5)
        
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty else {
            NSLog("[LangSwitcher] selectLineAndReplace: no text copied, deselecting")
            simulateRightArrow()
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
        pasteAndScheduleRestore(convertedText, saved: savedContents)
        
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
        let copyBase = pasteboard.changeCount
        simulateCopy()
        waitForPasteboardChange(since: copyBase, timeout: 0.5)
        
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty else {
            NSLog("[LangSwitcher] selectAndReplaceLastWord: no text copied after selection+copy, deselecting")
            simulateRightArrow()
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
        pasteAndScheduleRestore(convertedText, saved: savedContents)
        
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
    
    /// Put converted text on the pasteboard, press ⌘V and restore the user's
    /// clipboard later — but only if nobody changed the pasteboard meanwhile.
    private func pasteAndScheduleRestore(_ text: String, saved: [NSPasteboardItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let ourChangeCount = pasteboard.changeCount
        simulatePaste()
        
        pendingSnapshot = saved
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.pendingRestore = nil
            self.pendingSnapshot = nil
            // The user (or another app) copied something new — don't clobber it.
            guard NSPasteboard.general.changeCount == ourChangeCount else {
                NSLog("[LangSwitcher] Pasteboard changed since paste, skipping restore")
                return
            }
            self.restorePasteboard(saved)
        }
        pendingRestore = work
        DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay, execute: work)
    }
    
    /// Poll until the target app has written to the pasteboard (⌘C processed).
    private func waitForPasteboardChange(since base: Int, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while NSPasteboard.general.changeCount == base && Date() < deadline {
            usleep(10_000)
        }
        // Small grace period: some apps write several types one after another.
        usleep(20_000)
    }
    
    /// Snapshot the user's clipboard (all items, all types, as raw data).
    /// If a previous conversion hasn't restored the clipboard yet, the
    /// pasteboard currently holds *our* converted text — so cancel that
    /// restore and reuse its snapshot as the real original.
    private func savePasteboard() -> [NSPasteboardItem] {
        if let work = pendingRestore, let snapshot = pendingSnapshot {
            work.cancel()
            pendingRestore = nil
            pendingSnapshot = nil
            return snapshot
        }
        return NSPasteboard.general.pasteboardItems?.map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
    }
    
    private func restorePasteboard(_ items: [NSPasteboardItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
