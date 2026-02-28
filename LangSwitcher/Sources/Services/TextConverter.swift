import Foundation

// MARK: - Text Converter
// High-level service that orchestrates text conversion between layouts

@MainActor
final class TextConverter {
    
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    /// Convert selected text from one layout to another
    /// Auto-detects source layout and converts to the "other" layout
    func convertSelectedText(_ text: String) -> String? {
        let layouts = settingsManager.enabledLayouts
        NSLog("[LangSwitcher] convertSelectedText: enabledLayouts count=\(layouts.count), IDs=\(layouts.map(\.id))")
        guard layouts.count >= 2 else {
            NSLog("[LangSwitcher] convertSelectedText: fewer than 2 layouts, returning nil")
            return nil
        }
        
        let layoutIDs = layouts.map(\.id)
        
        // Detect which layout the text was likely typed in
        guard let detectedSourceID = LayoutMapper.detectSourceLayout(
            text: text,
            candidateLayouts: layoutIDs
        ) else {
            NSLog("[LangSwitcher] convertSelectedText: detectSourceLayout returned nil")
            return nil
        }
        
        NSLog("[LangSwitcher] convertSelectedText: detected source layout = '\(detectedSourceID)'")
        
        // Find the target layout (the "other" one)
        guard let targetLayout = layouts.first(where: { $0.id != detectedSourceID }) else {
            NSLog("[LangSwitcher] convertSelectedText: no target layout found different from source")
            guard let firstLayout = layouts.first else { return nil }
            return LayoutMapper.convert(text: text, from: detectedSourceID, to: firstLayout.id)
        }
        
        NSLog("[LangSwitcher] convertSelectedText: converting from '\(detectedSourceID)' to '\(targetLayout.id)'")
        let result = LayoutMapper.convert(text: text, from: detectedSourceID, to: targetLayout.id)
        NSLog("[LangSwitcher] convertSelectedText: result = '\(result ?? "nil")'")
        return result
    }
    
    /// Convert text explicitly between two specified layouts
    func convertText(_ text: String, from sourceID: String, to targetID: String) -> String? {
        return LayoutMapper.convert(text: text, from: sourceID, to: targetID)
    }
    
    /// Check if text looks like it was typed in the wrong keyboard layout.
    /// For example, "ghbdtn" typed on QWERTY when meaning "привет" on Russian layout.
    /// We check: if converting the text to another layout produces something more "readable".
    func looksLikeWrongLayout(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            NSLog("[LangSwitcher] looksLikeWrongLayout: empty text")
            return false
        }
        
        let layouts = settingsManager.enabledLayouts
        guard layouts.count >= 2 else {
            NSLog("[LangSwitcher] looksLikeWrongLayout: fewer than 2 layouts")
            return false
        }
        
        let layoutIDs = layouts.map(\.id)
        
        // Detect source layout
        guard let detectedSourceID = LayoutMapper.detectSourceLayout(
            text: trimmed,
            candidateLayouts: layoutIDs
        ) else {
            NSLog("[LangSwitcher] looksLikeWrongLayout: detectSourceLayout returned nil")
            return false
        }
        
        NSLog("[LangSwitcher] looksLikeWrongLayout: detected source='\(detectedSourceID)' for '\(trimmed)'")
        
        // Try converting to each other layout and see if it "makes more sense"
        for layout in layouts where layout.id != detectedSourceID {
            if let converted = LayoutMapper.convert(text: trimmed, from: detectedSourceID, to: layout.id) {
                NSLog("[LangSwitcher] looksLikeWrongLayout: converted to '\(converted)' via layout '\(layout.id)'")
                
                let sourceHasLatinOnly = trimmed.allSatisfy { $0.isASCII || !$0.isLetter }
                let convertedHasNonLatin = converted.contains { !$0.isASCII && $0.isLetter }
                
                let sourceHasNonLatin = trimmed.contains { !$0.isASCII && $0.isLetter }
                let convertedHasLatinOnly = converted.allSatisfy { $0.isASCII || !$0.isLetter }
                
                NSLog("[LangSwitcher] looksLikeWrongLayout: srcLatinOnly=\(sourceHasLatinOnly) convNonLatin=\(convertedHasNonLatin) srcNonLatin=\(sourceHasNonLatin) convLatinOnly=\(convertedHasLatinOnly)")
                
                // Case 1: "ghbdtn" (all ASCII) -> "привет" (non-ASCII) = wrong layout
                if sourceHasLatinOnly && convertedHasNonLatin {
                    return true
                }
                
                // Case 2: "руддщ" (non-ASCII) -> "hello" (all ASCII) = wrong layout
                if sourceHasNonLatin && convertedHasLatinOnly {
                    return true
                }
            }
        }
        
        NSLog("[LangSwitcher] looksLikeWrongLayout: no wrong layout detected")
        return false
    }
}
