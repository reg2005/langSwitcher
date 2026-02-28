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
    /// 2. For each word from right to left, check if it looks like gibberish
    ///    (wrong-layout text has unusual letter patterns for its script)
    /// 3. Stop when we find a word that looks like a normal word
    ///
    /// Key insight: "ghbdtn" (intended "привет") has unusual consonant clusters
    /// for English, while "John" or "the" look like normal English words.
    /// We combine script-switch detection with a gibberish score.
    func findWrongLayoutBoundary(in text: String) -> (keep: String, convert: String)? {
        let layouts = settingsManager.enabledLayouts
        guard layouts.count >= 2 else { return nil }
        
        // Tokenize: split into words and separators, preserving order and whitespace
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return nil }
        
        NSLog("[LangSwitcher] findWrongLayoutBoundary: \(tokens.count) tokens from '\(text)'")
        
        // Scan from right to left, find the longest tail of "wrong layout" tokens
        var wrongStartIndex = tokens.count // nothing wrong yet
        var foundAtLeastOneWrongWord = false
        
        for i in stride(from: tokens.count - 1, through: 0, by: -1) {
            let token = tokens[i]
            
            // Skip whitespace/punctuation-only tokens — they inherit from neighbors
            if token.isWhitespaceOrPunctuation {
                continue
            }
            
            // For boundary detection in greedy mode, use the enhanced check
            // that combines script-switch with gibberish scoring
            if looksLikeWrongLayoutForBoundary(token) {
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
    
    // MARK: - Enhanced Wrong Layout Detection (for Greedy Boundary)
    
    /// Enhanced wrong-layout check for boundary detection in greedy mode.
    /// Unlike the basic `looksLikeWrongLayout()`, this also checks if the word
    /// looks like gibberish in its source script — which helps distinguish
    /// real English words like "John" from wrong-layout gibberish like "gjdtcbk".
    ///
    /// A word is considered wrong-layout if:
    /// 1. Converting it switches script (Latin→Cyrillic or vice versa) — basic check
    /// 2. AND the word looks like gibberish in its current script (high consonant
    ///    density, unusual bigrams, etc.)
    ///
    /// Single-character words (like "b" → "и") are treated specially:
    /// they are considered wrong layout only in the context of adjacent wrong words.
    private func looksLikeWrongLayoutForBoundary(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Single character: too ambiguous on its own.
        // We allow it to be "wrong" only if the basic script-switch check passes,
        // because the right-to-left scan will only reach single chars if
        // multi-char wrong words were already found to the right.
        // However, single chars at the LEFT edge should not extend the region.
        let letterCount = trimmed.filter { $0.isLetter }.count
        if letterCount <= 1 {
            // For single chars, use the basic check but it's fine —
            // the scan stops when it hits a non-wrong word, so single chars
            // only extend an already-identified wrong region.
            return looksLikeWrongLayout(trimmed)
        }
        
        // First: must pass the basic script-switch check
        guard looksLikeWrongLayout(trimmed) else {
            return false
        }
        
        // Second: check if the word looks like gibberish in its current script.
        // Real English words have vowels, normal bigram patterns.
        // Wrong-layout gibberish like "ghbdtn", "gjdtcbk" has weird patterns.
        let isLatin = trimmed.filter({ $0.isLetter }).allSatisfy { $0.isASCII }
        
        if isLatin {
            // Check if this looks like a normal English word
            if looksLikeNormalEnglishWord(trimmed) {
                NSLog("[LangSwitcher] looksLikeWrongLayoutForBoundary: '\(trimmed)' looks like normal English, skipping")
                return false
            }
        } else {
            // For Cyrillic: check if it looks like a normal Russian/Ukrainian word
            if looksLikeNormalCyrillicWord(trimmed) {
                NSLog("[LangSwitcher] looksLikeWrongLayoutForBoundary: '\(trimmed)' looks like normal Cyrillic, skipping")
                return false
            }
        }
        
        return true
    }
    
    /// Heuristic: does this Latin word look like a plausible English word?
    /// English words have vowels, don't start with certain clusters, etc.
    /// Returns true for words like "John", "the", "hello", "said".
    /// Returns false for gibberish like "ghbdtn", "gjdtcbk", "nhe,re".
    private func looksLikeNormalEnglishWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        let letters = lower.filter { $0.isLetter }
        guard letters.count >= 2 else { return true } // single chars are ambiguous, assume OK
        
        let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
        let vowelCount = letters.filter { vowels.contains($0) }.count
        let vowelRatio = Double(vowelCount) / Double(letters.count)
        
        // English words typically have 20-60% vowels.
        // Gibberish like "ghbdtn" (0 vowels in 6 chars = 0%) or "gjdtcbk" (0/7 = 0%)
        // While "John" has 1/4 = 25%, "hello" has 2/5 = 40%
        if vowelRatio < 0.12 && letters.count >= 3 {
            NSLog("[LangSwitcher] looksLikeNormalEnglishWord: '\(word)' vowelRatio=\(vowelRatio) — gibberish")
            return false
        }
        
        // Count max consecutive consonants
        var maxConsonants = 0
        var currentConsonants = 0
        for ch in letters {
            if vowels.contains(ch) {
                maxConsonants = max(maxConsonants, currentConsonants)
                currentConsonants = 0
            } else {
                currentConsonants += 1
            }
        }
        maxConsonants = max(maxConsonants, currentConsonants)
        
        // English rarely has 4+ consecutive consonants (exceptions: "strengths" = 5)
        // But gibberish like "ghbdtn" has 6, "gjdtcbk" has 7
        if maxConsonants >= 4 && letters.count >= 4 {
            NSLog("[LangSwitcher] looksLikeNormalEnglishWord: '\(word)' maxConsonants=\(maxConsonants) — gibberish")
            return false
        }
        
        // Short words (2-3 letters) with at least one vowel are likely real words
        if letters.count <= 3 && vowelCount >= 1 {
            return true
        }
        
        NSLog("[LangSwitcher] looksLikeNormalEnglishWord: '\(word)' vowelRatio=\(vowelRatio) maxConsonants=\(maxConsonants) — normal")
        return true
    }
    
    /// Heuristic: does this Cyrillic word look like a plausible Russian/Ukrainian word?
    /// Similar vowel-ratio check adapted for Cyrillic.
    private func looksLikeNormalCyrillicWord(_ word: String) -> Bool {
        let letters = word.filter { $0.isLetter }
        guard letters.count >= 2 else { return true }
        
        let cyrillicVowels: Set<Character> = ["а", "е", "ё", "и", "о", "у", "ы", "э", "ю", "я",
                                                "і", "ї", "є"] // Ukrainian vowels
        let vowelCount = letters.filter { cyrillicVowels.contains($0) }.count
        let vowelRatio = Double(vowelCount) / Double(letters.count)
        
        // Russian words typically have ~40% vowels.
        // Gibberish typed on Russian layout when meaning English would look like:
        // "руддщ" (hello) — р,у,д,д,щ — 1 vowel in 5 = 20% — borderline
        // "ьфшт" (main) — ь,ф,ш,т — 0 vowels in 4 = 0%
        if vowelRatio < 0.10 && letters.count >= 3 {
            NSLog("[LangSwitcher] looksLikeNormalCyrillicWord: '\(word)' vowelRatio=\(vowelRatio) — gibberish")
            return false
        }
        
        // Count max consecutive consonants in Cyrillic
        var maxConsonants = 0
        var currentConsonants = 0
        for ch in letters {
            if cyrillicVowels.contains(ch) {
                maxConsonants = max(maxConsonants, currentConsonants)
                currentConsonants = 0
            } else {
                currentConsonants += 1
            }
        }
        maxConsonants = max(maxConsonants, currentConsonants)
        
        // Russian can have 3-4 consonant clusters ("встр", "здр") but rarely 5+
        if maxConsonants >= 5 && letters.count >= 4 {
            NSLog("[LangSwitcher] looksLikeNormalCyrillicWord: '\(word)' maxConsonants=\(maxConsonants) — gibberish")
            return false
        }
        
        return true
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
