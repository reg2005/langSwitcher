import Foundation

// MARK: - Layout Mapper
// Maps characters from one keyboard layout to another based on physical key positions

final class LayoutMapper {
    
    /// Convert text typed in `sourceLayout` to what it would be in `targetLayout`
    /// by mapping each character through physical key position
    static func convert(
        text: String,
        from sourceLayoutID: String,
        to targetLayoutID: String
    ) -> String? {
        guard let sourceMap = LayoutCharacterMap.characterMap(for: sourceLayoutID) else {
            NSLog("[LangSwitcher] LayoutMapper.convert: no characterMap for source '\(sourceLayoutID)'")
            return nil
        }
        guard let targetMap = LayoutCharacterMap.characterMap(for: targetLayoutID) else {
            NSLog("[LangSwitcher] LayoutMapper.convert: no characterMap for target '\(targetLayoutID)'")
            return nil
        }
        
        // Build reverse source map: character -> physical key position (QWERTY index)
        // Source map is: qwerty_char -> source_layout_char
        // We need: source_layout_char -> qwerty_char
        let reverseSource = Dictionary(sourceMap.map { ($0.value, $0.key) }, uniquingKeysWith: { first, _ in first })
        
        // For each character in input:
        // 1. Find which physical key produced it in source layout (reverse lookup)
        // 2. Map that physical key to target layout character
        var result = ""
        var unmappedCount = 0
        for char in text {
            if let physicalKey = reverseSource[char],
               let targetChar = targetMap[physicalKey] {
                result.append(targetChar)
            } else {
                // Character not in mapping (e.g., space, numbers that don't change, emoji)
                result.append(char)
                if char.isLetter {
                    unmappedCount += 1
                }
            }
        }
        
        NSLog("[LangSwitcher] LayoutMapper.convert: '\(text)' -> '\(result)' (unmappedLetters=\(unmappedCount))")
        return result
    }
    
    /// Try to detect which layout a text was likely typed in
    /// Returns the layout ID with the highest confidence
    static func detectSourceLayout(
        text: String,
        candidateLayouts: [String]
    ) -> String? {
        // Simple heuristic: check which layout's character set contains most of the characters
        var bestMatch: String?
        var bestScore = 0
        
        for layoutID in candidateLayouts {
            guard let map = LayoutCharacterMap.characterMap(for: layoutID) else {
                NSLog("[LangSwitcher] detectSourceLayout: no characterMap for '\(layoutID)'")
                continue
            }
            let layoutChars = Set(map.values)
            let score = text.filter { layoutChars.contains($0) }.count
            NSLog("[LangSwitcher] detectSourceLayout: layout '\(layoutID)' score=\(score) for '\(text)'")
            if score > bestScore {
                bestScore = score
                bestMatch = layoutID
            }
        }
        
        NSLog("[LangSwitcher] detectSourceLayout: best match = '\(bestMatch ?? "nil")' (score=\(bestScore))")
        return bestMatch
    }
}
