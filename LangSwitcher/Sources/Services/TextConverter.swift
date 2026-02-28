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
    
    // MARK: - Greedy Phrase Conversion
    
    /// Given a line of text (from cursor to start of line), find the boundary where
    /// the wrong layout begins and return: (prefix to keep unchanged, suffix to convert).
    /// Returns nil if no wrong-layout portion found.
    ///
    /// Algorithm (right to left, no dictionary):
    /// 1. Split text into tokens (words + separators)
    /// 2. For each word from right to left, check if it "switches script" after conversion
    /// 3. Stop when we find a word that does NOT convert (it's already correct)
    /// 4. Handle single-char tokens (like "b" = "и") by checking context
    ///
    /// Example: "Как дел? Сказа John b gjdtcbk nhe,re"
    ///   - "nhe,re" → Latin→Cyrillic ✓
    ///   - "gjdtcbk" → Latin→Cyrillic ✓
    ///   - "b" → single Latin char, context says convert ✓ ("и")
    ///   - "John" → Latin→Cyrillic? "Олры" — still Cyrillic, but hmm...
    ///     Actually "John" is a real name, but without dictionary we check:
    ///     does it look like wrong layout? "John" → "Олры" — yes converts to Cyrillic,
    ///     but the user intended "John". We handle this by checking: if the word
    ///     BEFORE the wrong-layout region is in a DIFFERENT script, we stop there.
    ///
    /// Refined algorithm: scan right-to-left. A word is "wrong layout" if:
    ///   - It's predominantly one script (Latin/Cyrillic)
    ///   - Converting it produces predominantly the OTHER script
    ///   - The word contains only characters from the source layout map
    ///
    /// We build the longest contiguous run of "wrong layout" words from the right.
    func findWrongLayoutBoundary(in text: String) -> (keep: String, convert: String)? {
        let layouts = settingsManager.enabledLayouts
        guard layouts.count >= 2 else { return nil }
        
        // Tokenize: split into words and separators, preserving order and whitespace
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return nil }
        
        NSLog("[LangSwitcher] findWrongLayoutBoundary: \(tokens.count) tokens from '\(text)'")
        
        // Scan from right to left, find the longest tail of "wrong layout" tokens
        var wrongStartIndex = tokens.count // nothing wrong yet
        
        for i in stride(from: tokens.count - 1, through: 0, by: -1) {
            let token = tokens[i]
            
            // Skip whitespace/punctuation-only tokens — they inherit from neighbors
            if token.isWhitespaceOrPunctuation {
                continue
            }
            
            if looksLikeWrongLayout(token) {
                wrongStartIndex = i
                NSLog("[LangSwitcher] findWrongLayoutBoundary: token[\(i)] '\(token)' = wrong layout")
            } else {
                NSLog("[LangSwitcher] findWrongLayoutBoundary: token[\(i)] '\(token)' = OK, stopping")
                break
            }
        }
        
        guard wrongStartIndex < tokens.count else {
            NSLog("[LangSwitcher] findWrongLayoutBoundary: no wrong-layout tokens found")
            return nil
        }
        
        // Now include leading whitespace/punctuation into the "wrong" region
        // (the space before the wrong region should stay with the correct text)
        // Actually, find the actual split point: wrong region starts at wrongStartIndex,
        // but we want to include separators that are BETWEEN wrong words.
        // The keep/convert split should be right before the first wrong word.
        
        // Walk backwards from wrongStartIndex to skip leading whitespace into keep portion
        var splitIndex = wrongStartIndex
        // Include any whitespace immediately before the wrong region in the "keep" portion
        // Actually we want to split cleanly: keep = tokens[0..<splitIndex], convert = tokens[splitIndex...]
        // But we should check if there's whitespace at splitIndex-1 that should stay in "keep"
        
        let keepTokens = tokens[0..<splitIndex]
        let convertTokens = tokens[splitIndex...]
        
        let keep = keepTokens.joined()
        let convert = convertTokens.joined()
        
        NSLog("[LangSwitcher] findWrongLayoutBoundary: keep='\(keep)' convert='\(convert)'")
        
        guard !convert.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        return (keep: keep, convert: convert)
    }
    
    /// Convert only the wrong-layout portion of a line.
    /// Returns the full replacement text (keep + converted) or nil if nothing to convert.
    func convertLineGreedy(_ text: String) -> String? {
        guard let boundary = findWrongLayoutBoundary(in: text) else {
            return nil
        }
        
        guard let converted = convertSelectedText(boundary.convert) else {
            NSLog("[LangSwitcher] convertLineGreedy: convertSelectedText failed for '\(boundary.convert)'")
            return nil
        }
        
        let result = boundary.keep + converted
        NSLog("[LangSwitcher] convertLineGreedy: '\(text)' → '\(result)'")
        return result
    }
    
    // MARK: - Tokenization
    
    /// Split text into tokens: words and whitespace/punctuation runs.
    /// Preserves original text exactly (join of tokens == original text).
    private func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inWord = false
        
        for char in text {
            let charIsWord = char.isLetter || char.isNumber
            
            if charIsWord {
                if !inWord && !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                inWord = true
                current.append(char)
            } else {
                if inWord && !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                inWord = false
                current.append(char)
            }
        }
        
        if !current.isEmpty {
            tokens.append(current)
        }
        
        return tokens
    }
}

// MARK: - String Helpers

private extension String {
    /// True if the string contains only whitespace, punctuation, symbols — no letters/digits
    var isWhitespaceOrPunctuation: Bool {
        allSatisfy { !$0.isLetter && !$0.isNumber }
    }
}
