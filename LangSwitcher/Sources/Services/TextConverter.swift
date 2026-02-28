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
    /// Algorithm (two-pass):
    ///
    /// Pass 1 — Whole-line check:
    ///   If the entire line converts to a different script (all Latin→Cyrillic or
    ///   all Cyrillic→Latin), convert the whole thing. This handles the common case
    ///   "ghbdtn rfr ltkf lheu" where every word is wrong-layout.
    ///
    /// Pass 2 — Right-to-left boundary scan:
    ///   If only some words switch script, scan from right to left using the basic
    ///   script-switch check (looksLikeWrongLayout). Stop at the first word that
    ///   does NOT switch. This handles mixed lines like "Привет ghbdtn rfr".
    ///
    /// Key insight: per-word gibberish scoring doesn't work because many
    /// wrong-layout words (like "lheu" = "друг") look like valid English
    /// (50% vowels, no consonant clusters). Instead, when ALL words on a line
    /// switch script, that's strong enough signal to convert everything.
    func findWrongLayoutBoundary(in text: String) -> (keep: String, convert: String)? {
        let layouts = settingsManager.enabledLayouts
        guard layouts.count >= 2 else { return nil }
        
        // Tokenize: split into words and separators, preserving order and whitespace
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return nil }
        
        let wordTokens = tokens.filter { !$0.isWhitespaceOrPunctuation }
        guard !wordTokens.isEmpty else { return nil }
        
        NSLog("[LangSwitcher] findWrongLayoutBoundary: \(tokens.count) tokens (\(wordTokens.count) words) from '\(text)'")
        
        // --- Pass 1: Check if the whole line is wrong-layout ---
        // Count how many word tokens pass the basic script-switch check
        var wrongCount = 0
        for word in wordTokens {
            if looksLikeWrongLayout(word) {
                wrongCount += 1
            }
        }
        
        NSLog("[LangSwitcher] findWrongLayoutBoundary: \(wrongCount)/\(wordTokens.count) words look wrong-layout")
        
        // If ALL words (or all but maybe one short word) switch script, convert the whole line
        if wrongCount == wordTokens.count {
            NSLog("[LangSwitcher] findWrongLayoutBoundary: ALL words are wrong-layout, converting entire line")
            return (keep: "", convert: text)
        }
        
        // If most words switch (>=70% and at least 2), also convert the whole line.
        // This handles cases where one ambiguous word doesn't trip the check.
        if wordTokens.count >= 3 && Double(wrongCount) / Double(wordTokens.count) >= 0.7 {
            NSLog("[LangSwitcher] findWrongLayoutBoundary: \(wrongCount)/\(wordTokens.count) words wrong (>=70%%), converting entire line")
            return (keep: "", convert: text)
        }
        
        // --- Pass 2: Right-to-left scan to find boundary ---
        // Some words are correct, some are wrong. Find where wrong region starts.
        var wrongStartIndex = tokens.count
        var foundAtLeastOneWrongWord = false
        
        for i in stride(from: tokens.count - 1, through: 0, by: -1) {
            let token = tokens[i]
            
            if token.isWhitespaceOrPunctuation {
                continue
            }
            
            // Use basic script-switch check (no gibberish scoring — that's too fragile)
            if looksLikeWrongLayout(token) {
                wrongStartIndex = i
                foundAtLeastOneWrongWord = true
                NSLog("[LangSwitcher] findWrongLayoutBoundary: token[\(i)] '\(token)' = wrong layout")
            } else {
                NSLog("[LangSwitcher] findWrongLayoutBoundary: token[\(i)] '\(token)' = OK, stopping")
                break
            }
        }
        
        guard foundAtLeastOneWrongWord, wrongStartIndex < tokens.count else {
            NSLog("[LangSwitcher] findWrongLayoutBoundary: no wrong-layout tokens found")
            return nil
        }
        
        let keepTokens = tokens[0..<wrongStartIndex]
        let convertTokens = tokens[wrongStartIndex...]
        
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
