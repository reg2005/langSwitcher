import Foundation
import Carbon
import Cocoa

// MARK: - Hotkey Manager
// Registers and manages global keyboard shortcuts
// Supports both regular hotkeys (modifier+key) and double-tap modifier keys

enum DoubleTapModifier: Int, CaseIterable, Codable {
    case shift = 0
    case option = 1

    var eventFlag: NSEvent.ModifierFlags {
        switch self {
        case .shift: return .shift
        case .option: return .option
        }
    }
}

/// Pure state machine for recognizing two clean modifier taps.
/// Kept separate from NSEvent monitoring so edge cases can be unit tested.
struct DoubleTapModifierDetector {
    let modifier: DoubleTapModifier
    let maximumInterval: TimeInterval

    private(set) var lastTapTime: TimeInterval?
    private(set) var isModifierDownAlone = false

    init(modifier: DoubleTapModifier, maximumInterval: TimeInterval = 0.4) {
        self.modifier = modifier
        self.maximumInterval = maximumInterval
    }

    mutating func handleModifierFlags(
        _ flags: NSEvent.ModifierFlags,
        at timestamp: TimeInterval
    ) -> Bool {
        let relevantFlags = flags.intersection(.deviceIndependentFlagsMask)
        let targetFlag = modifier.eventFlag
        let targetIsDown = relevantFlags.contains(targetFlag)
        let targetIsDownAlone = targetIsDown && relevantFlags == targetFlag

        if targetIsDownAlone && !isModifierDownAlone {
            isModifierDownAlone = true
            return false
        }

        if !targetIsDown && isModifierDownAlone {
            isModifierDownAlone = false

            if let previousTap = lastTapTime,
               timestamp - previousTap <= maximumInterval {
                lastTapTime = nil
                return true
            }

            lastTapTime = timestamp
            return false
        }

        if !targetIsDownAlone {
            reset()
        }

        return false
    }

    mutating func handleOtherKeyDown() {
        reset()
    }

    mutating func reset() {
        lastTapTime = nil
        isModifierDownAlone = false
    }
}

final class HotkeyManager {
    
    typealias HotkeyAction = () -> Void
    
    private var action: HotkeyAction?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var flagsGlobalMonitor: Any?
    private var flagsLocalMonitor: Any?
    
    private var doubleTapDetector: DoubleTapModifierDetector?
    
    // Configuration
    private(set) var registeredDoubleTapModifier: DoubleTapModifier?
    
    deinit {
        unregister()
    }
    
    // MARK: - Double-Tap Modifier Registration
    
    /// Register a double-tapped modifier as the hotkey trigger.
    func registerDoubleTap(
        modifier: DoubleTapModifier,
        action: @escaping HotkeyAction
    ) {
        unregister()
        self.action = action
        self.registeredDoubleTapModifier = modifier
        self.doubleTapDetector = DoubleTapModifierDetector(modifier: modifier)
        
        // Modifier-only presses arrive as flagsChanged events.
        flagsGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        flagsLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        // A regular key between modifier taps invalidates the sequence.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.doubleTapDetector?.handleOtherKeyDown()
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.doubleTapDetector?.handleOtherKeyDown()
            return event
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        if doubleTapDetector?.handleModifierFlags(event.modifierFlags, at: event.timestamp) == true {
            action?()
        }
    }
    
    // MARK: - Regular Hotkey Registration
    
    /// Register a regular global hotkey (modifier + key)
    func register(
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags,
        action: @escaping HotkeyAction
    ) {
        unregister()
        self.action = action
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let targetMods = modifiers.intersection(.deviceIndependentFlagsMask)
            
            if event.keyCode == keyCode && eventMods == targetMods {
                self.action?()
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let targetMods = modifiers.intersection(.deviceIndependentFlagsMask)
            
            if event.keyCode == keyCode && eventMods == targetMods {
                self.action?()
                return nil
            }
            return event
        }
    }
    
    /// Unregister all monitors
    func unregister() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        if let m = flagsGlobalMonitor { NSEvent.removeMonitor(m); flagsGlobalMonitor = nil }
        if let m = flagsLocalMonitor { NSEvent.removeMonitor(m); flagsLocalMonitor = nil }
        action = nil
        registeredDoubleTapModifier = nil
        doubleTapDetector = nil
    }
    
    // MARK: - Display Helpers
    
    static func modifierFlagsToString(_ flags: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        return parts.joined()
    }
    
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
            0x2E: "M", 0x31: "Space", 0x24: "Return", 0x30: "Tab",
            0x33: "Delete", 0x35: "Escape",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
            0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
}
