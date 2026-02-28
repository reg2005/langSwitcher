import Foundation
import Carbon
import Cocoa

// MARK: - Keyboard Layout Detector
// Detects installed keyboard layouts from the system

final class KeyboardLayoutDetector {
    
    /// Get all keyboard layouts currently enabled in System Preferences
    static func getInstalledLayouts() -> [KeyboardLayout] {
        var layouts: [KeyboardLayout] = []
        
        guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return layouts
        }
        
        for source in inputSources {
            guard let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else { continue }
            let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue() as String
            guard category == kTISPropertyInputSourceCategory as String ||
                  category == (kTISCategoryKeyboardInputSource as String) else { continue }
            
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { continue }
            let type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            guard type == (kTISTypeKeyboardLayout as String) else { continue }
            
            guard let sourceIDPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue() as String
            
            guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { continue }
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            
            var langCode = "unknown"
            if let langsPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
                let langs = Unmanaged<CFArray>.fromOpaque(langsPtr).takeUnretainedValue() as? [String]
                langCode = langs?.first ?? "unknown"
            }
            
            // Only include if we have a character map for it
            if LayoutCharacterMap.characterMap(for: sourceID) != nil {
                layouts.append(KeyboardLayout(
                    id: sourceID,
                    localizedName: name,
                    languageCode: langCode
                ))
            }
        }
        
        // If no supported layouts found, provide defaults
        if layouts.isEmpty {
            layouts = defaultLayouts()
        }
        
        return layouts
    }
    
    /// Get the currently active keyboard layout
    static func getCurrentLayout() -> KeyboardLayout? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        
        guard let sourceIDPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue() as String
        
        guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
        let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        
        var langCode = "unknown"
        if let langsPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
            let langs = Unmanaged<CFArray>.fromOpaque(langsPtr).takeUnretainedValue() as? [String]
            langCode = langs?.first ?? "unknown"
        }
        
        return KeyboardLayout(id: sourceID, localizedName: name, languageCode: langCode)
    }
    
    /// Switch the active keyboard layout to the one matching the given source ID.
    /// Uses TISSelectInputSource from the Carbon Input Source API.
    static func switchToLayout(_ targetID: String) {
        guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            NSLog("[LangSwitcher] switchToLayout: failed to get input source list")
            return
        }
        
        for source in inputSources {
            guard let sourceIDPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue() as String
            
            if sourceID == targetID {
                let status = TISSelectInputSource(source)
                if status == noErr {
                    NSLog("[LangSwitcher] switchToLayout: switched to '\(targetID)'")
                } else {
                    NSLog("[LangSwitcher] switchToLayout: TISSelectInputSource failed with status \(status)")
                }
                return
            }
        }
        
        NSLog("[LangSwitcher] switchToLayout: layout '\(targetID)' not found in system sources")
    }
    
    /// Default fallback layouts
    private static func defaultLayouts() -> [KeyboardLayout] {
        [
            KeyboardLayout(id: "com.apple.keylayout.US", localizedName: "U.S.", languageCode: "en"),
            KeyboardLayout(id: "com.apple.keylayout.Russian", localizedName: "Russian", languageCode: "ru"),
        ]
    }
}
