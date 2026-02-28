import Foundation

// MARK: - Conversion Log Entry

/// Represents a single text conversion event, stored in SQLite for data labeling purposes.
struct ConversionLog: Identifiable {
    let id: Int64
    let timestamp: Date
    let inputText: String
    let outputText: String
    let sourceLayout: String   // e.g. "com.apple.keylayout.US"
    let targetLayout: String   // e.g. "com.apple.keylayout.Russian"
    let conversionMode: String // "direct", "lastWord", "greedyLine"
    
    /// Tri-state rating for data labeling:
    /// - nil  = unrated (default)
    /// - true = correct conversion
    /// - false = incorrect conversion
    var isCorrect: Bool?
}
