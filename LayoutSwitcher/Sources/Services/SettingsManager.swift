import Foundation
import SwiftUI

// MARK: - Settings Manager
// Persists user preferences via UserDefaults

@MainActor
final class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    @Published var enabledLayouts: [KeyboardLayout] {
        didSet { saveLayouts() }
    }
    
    /// true = double-shift mode, false = regular modifier+key hotkey
    @Published var useDoubleShift: Bool {
        didSet {
            defaults.set(useDoubleShift, forKey: Keys.useDoubleShift)
            NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
        }
    }
    
    @Published var hotkeyKeyCode: UInt16 {
        didSet {
            defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
            if !useDoubleShift {
                NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
            }
        }
    }
    
    @Published var hotkeyModifiers: UInt {
        didSet {
            defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
            if !useDoubleShift {
                NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
            }
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    @Published var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: Keys.showNotifications) }
    }
    
    @Published var playSounds: Bool {
        didSet { defaults.set(playSounds, forKey: Keys.playSounds) }
    }
    
    @Published var conversionCount: Int {
        didSet { defaults.set(conversionCount, forKey: Keys.conversionCount) }
    }
    
    // MARK: - Computed
    
    var hotkeyModifierFlags: NSEvent.ModifierFlags {
        get { NSEvent.ModifierFlags(rawValue: hotkeyModifiers) }
        set { hotkeyModifiers = newValue.rawValue }
    }
    
    var hotkeyDescription: String {
        if useDoubleShift {
            return "⇧⇧ (Double Shift)"
        }
        let mods = HotkeyManager.modifierFlagsToString(hotkeyModifierFlags)
        let key = HotkeyManager.keyCodeToString(hotkeyKeyCode)
        return "\(mods)\(key)"
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let enabledLayouts = "enabledLayouts"
        static let useDoubleShift = "useDoubleShift"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let playSounds = "playSounds"
        static let conversionCount = "conversionCount"
    }
    
    // MARK: - Init
    
    private init() {
        // Default: double-shift mode
        let savedUseDoubleShift = defaults.object(forKey: Keys.useDoubleShift) as? Bool
        self.useDoubleShift = savedUseDoubleShift ?? true  // Default ON
        
        // Fallback hotkey settings (Option+S) for regular mode
        let savedKeyCode = defaults.object(forKey: Keys.hotkeyKeyCode) as? Int
        self.hotkeyKeyCode = UInt16(savedKeyCode ?? 0x01) // 0x01 = S key
        
        let savedMods = defaults.object(forKey: Keys.hotkeyModifiers) as? UInt
        self.hotkeyModifiers = savedMods ?? NSEvent.ModifierFlags.option.rawValue
        
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = defaults.object(forKey: Keys.showNotifications) as? Bool ?? true
        self.playSounds = defaults.object(forKey: Keys.playSounds) as? Bool ?? true
        self.conversionCount = defaults.integer(forKey: Keys.conversionCount)
        
        // Load layouts
        if let data = defaults.data(forKey: Keys.enabledLayouts),
           let layouts = try? JSONDecoder().decode([KeyboardLayout].self, from: data),
           !layouts.isEmpty {
            self.enabledLayouts = layouts
        } else {
            self.enabledLayouts = KeyboardLayoutDetector.getInstalledLayouts()
        }
    }
    
    // MARK: - Methods
    
    func refreshSystemLayouts() {
        enabledLayouts = KeyboardLayoutDetector.getInstalledLayouts()
    }
    
    func incrementConversionCount() {
        conversionCount += 1
    }
    
    private func saveLayouts() {
        if let data = try? JSONEncoder().encode(enabledLayouts) {
            defaults.set(data, forKey: Keys.enabledLayouts)
        }
    }
}
