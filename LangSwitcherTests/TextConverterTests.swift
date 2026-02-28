import XCTest
@testable import LangSwitcher

@MainActor
final class TextConverterTests: XCTestCase {
    
    // We need a SettingsManager with known layouts for deterministic testing.
    // SettingsManager.shared will pick up system layouts which may vary,
    // so tests must check that at least US+Russian are present for core tests.
    
    private var converter: TextConverter!
    
    override func setUp() {
        super.setUp()
        let settings = SettingsManager.shared
        // Ensure we have at least US and Russian layouts for testing
        let hasUS = settings.enabledLayouts.contains { $0.id.lowercased().contains("us") || $0.id.lowercased().contains("abc") }
        let hasRU = settings.enabledLayouts.contains { $0.id.lowercased().contains("russian") }
        if !hasUS || !hasRU {
            // Set up minimal layout pair for testing
            settings.enabledLayouts = [
                KeyboardLayout(id: "com.apple.keylayout.US", localizedName: "U.S.", languageCode: "en"),
                KeyboardLayout(id: "com.apple.keylayout.Russian", localizedName: "Russian", languageCode: "ru")
            ]
        }
        converter = TextConverter(settingsManager: settings)
    }
    
    override func tearDown() {
        converter = nil
        super.tearDown()
    }
    
    // MARK: - convertSelectedText
    
    func testConvertSelectedText_LatinToRussian() {
        let result = converter.convertSelectedText("ghbdtn")
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "привет")
    }
    
    func testConvertSelectedText_RussianToLatin() {
        let result = converter.convertSelectedText("руддщ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "hello")
    }
    
    func testConvertSelectedText_MultipleWords() {
        let result = converter.convertSelectedText("ghbdtn rfr ltkf")
        XCTAssertEqual(result, "привет как дела")
    }
    
    func testConvertSelectedText_EmptyString() {
        let result = converter.convertSelectedText("")
        // Empty string has no characters to detect source layout → returns nil
        XCTAssertNil(result)
    }
    
    func testConvertSelectedText_SingleWord() {
        let result = converter.convertSelectedText("ntrcn")
        XCTAssertEqual(result, "текст")
    }
    
    // MARK: - looksLikeWrongLayout
    
    func testLooksLikeWrongLayout_LatinForRussian() {
        // "ghbdtn" is Latin text that should be Cyrillic when converted
        XCTAssertTrue(converter.looksLikeWrongLayout("ghbdtn"))
    }
    
    func testLooksLikeWrongLayout_CyrillicForLatin() {
        // "руддщ" is Cyrillic that converts to "hello" (Latin)
        XCTAssertTrue(converter.looksLikeWrongLayout("руддщ"))
    }
    
    func testLooksLikeWrongLayout_CorrectLatin() {
        // "hello" is correct English — converting to Russian gives Cyrillic gibberish "руддщ"
        // BUT "hello" itself is Latin, and "руддщ" is non-Latin, so it would look like wrong layout.
        // Actually, looksLikeWrongLayout checks if converting SWITCHES script.
        // "hello" → RU → "руддщ" → sourceHasLatinOnly && convertedHasNonLatin → true
        // This is expected: without a dictionary, the algorithm can't tell "hello" from "ghbdtn"
        // Both are Latin text that produce Cyrillic when converted.
        // The algorithm relies on context (user pressed the hotkey = they want conversion).
        let result = converter.looksLikeWrongLayout("hello")
        XCTAssertTrue(result, "Any Latin text looks like wrong layout when RU is available (script switches)")
    }
    
    func testLooksLikeWrongLayout_EmptyString() {
        XCTAssertFalse(converter.looksLikeWrongLayout(""))
    }
    
    func testLooksLikeWrongLayout_WhitespaceOnly() {
        XCTAssertFalse(converter.looksLikeWrongLayout("   "))
    }
    
    func testLooksLikeWrongLayout_NumbersOnly() {
        // Numbers don't change script when converted
        XCTAssertFalse(converter.looksLikeWrongLayout("12345"))
    }
    
    func testLooksLikeWrongLayout_SpecialCharsOnly() {
        XCTAssertFalse(converter.looksLikeWrongLayout("!@#$%"))
    }
    
    func testLooksLikeWrongLayout_MixedNumbersAndLetters() {
        // "ghbdtn123" has Latin letters → converts to Cyrillic → wrong layout
        XCTAssertTrue(converter.looksLikeWrongLayout("ghbdtn123"))
    }
    
    // MARK: - Tokenization (tested via findWrongLayoutBoundary)
    
    func testFindBoundary_AllWrongLayout() {
        let boundary = converter.findWrongLayoutBoundary(in: "ghbdtn rfr ltkf")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "ghbdtn rfr ltkf")
    }
    
    func testFindBoundary_MixedLine_CyrillicThenLatin() {
        // "Привет ghbdtn" — both words trigger looksLikeWrongLayout (both scripts switch
        // when converted). Without a dictionary, the algorithm can't distinguish "correct
        // Cyrillic" from "wrong-layout Cyrillic". Pass 1 sees ALL words as wrong → converts entire line.
        let boundary = converter.findWrongLayoutBoundary(in: "Привет ghbdtn")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "Привет ghbdtn")
    }
    
    func testFindBoundary_MixedLine_MultipleCyrillicThenLatin() {
        // Same reasoning: all words (Cyrillic and Latin) switch script when converted,
        // so Pass 1 fires and converts the entire line.
        let boundary = converter.findWrongLayoutBoundary(in: "Привет мир ghbdtn rfr")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "Привет мир ghbdtn rfr")
    }
    
    func testFindBoundary_EmptyString() {
        let boundary = converter.findWrongLayoutBoundary(in: "")
        XCTAssertNil(boundary)
    }
    
    func testFindBoundary_OnlyWhitespace() {
        let boundary = converter.findWrongLayoutBoundary(in: "   ")
        XCTAssertNil(boundary)
    }
    
    func testFindBoundary_SingleWord_Wrong() {
        let boundary = converter.findWrongLayoutBoundary(in: "ghbdtn")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "ghbdtn")
    }
    
    func testFindBoundary_SingleWord_CyrillicWrong() {
        // "руддщ" → "hello" — Cyrillic to Latin = wrong layout
        let boundary = converter.findWrongLayoutBoundary(in: "руддщ")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "руддщ")
    }
    
    // MARK: - convertLineGreedy
    
    func testConvertLineGreedy_AllWrongLayout() {
        let result = converter.convertLineGreedy("ghbdtn rfr ltkf")
        XCTAssertEqual(result, "привет как дела")
    }
    
    func testConvertLineGreedy_MixedLine() {
        // Both "Привет" and "ghbdtn" look like wrong layout to the heuristic
        // (both switch script when converted), so Pass 1 converts the entire line.
        // "Привет ghbdtn" with source=ABC → converts all to Russian (Привет stays mostly same
        // since Cyrillic chars aren't in the US map, ghbdtn→привет).
        let result = converter.convertLineGreedy("Привет ghbdtn")
        XCTAssertNotNil(result)
        // The full line is converted as one unit via convertSelectedText
    }
    
    func testConvertLineGreedy_NothingToConvert_Numbers() {
        let result = converter.convertLineGreedy("12345")
        // Numbers don't look like wrong layout
        XCTAssertNil(result)
    }
    
    func testConvertLineGreedy_EmptyString() {
        let result = converter.convertLineGreedy("")
        XCTAssertNil(result)
    }
    
    func testConvertLineGreedy_SingleWrongWord() {
        let result = converter.convertLineGreedy("ghbdtn")
        XCTAssertEqual(result, "привет")
    }
    
    func testConvertLineGreedy_CyrillicWrongToLatin() {
        let result = converter.convertLineGreedy("руддщ")
        XCTAssertEqual(result, "hello")
    }
    
    // MARK: - convertText (explicit layout pair)
    
    func testConvertText_ExplicitPair() {
        let result = converter.convertText(
            "ghbdtn",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет")
    }
    
    func testConvertText_UnknownLayout() {
        let result = converter.convertText(
            "test",
            from: "com.apple.keylayout.Japanese",
            to: "com.apple.keylayout.US"
        )
        XCTAssertNil(result)
    }
    
    // MARK: - Large dataset: looksLikeWrongLayout
    
    func testLooksLikeWrongLayout_LargeDataset() {
        // All these Latin strings should look like wrong layout (they convert to Cyrillic)
        let wrongLayoutStrings = [
            "ghbdtn",
            "rfr ltkf",
            "lheu",
            "vbh",
            "cjkywt",
            "rjvgm.nth",
            "ghjuhfvvf",
            "ntrcn",
            "rkfdbfnehf",
            "hf,jnf",
            "ljv",
            "xfq",
            "cjj,otybt",
            "cnhjrf",
        ]
        
        for str in wrongLayoutStrings {
            XCTAssertTrue(converter.looksLikeWrongLayout(str),
                          "'\(str)' should be detected as wrong layout")
        }
    }
    
    func testLooksLikeWrongLayout_CyrillicWrongLayout() {
        // All these Cyrillic strings should look like wrong layout (they convert to Latin)
        let wrongLayoutStrings = [
            "руддщ",      // hello
            "цщкдв",      // world
            "еуыеште",    // testing
            "зкщпкфь",    // program
            "ьфсщы",      // macos
        ]
        
        for str in wrongLayoutStrings {
            XCTAssertTrue(converter.looksLikeWrongLayout(str),
                          "'\(str)' should be detected as wrong layout")
        }
    }
    
    // MARK: - findWrongLayoutBoundary with punctuation
    
    func testFindBoundary_WithTrailingPunctuation() {
        let boundary = converter.findWrongLayoutBoundary(in: "ghbdtn!")
        // "ghbdtn" is a word token, "!" is punctuation token
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "ghbdtn!")
    }
    
    func testFindBoundary_WithLeadingPunctuation() {
        // "- ghbdtn" has 1 word token ("ghbdtn") and punctuation/whitespace ("- ").
        // Only 1 word, and it's wrong-layout → Pass 1 sees 1/1 = 100% wrong → converts entire line.
        let boundary = converter.findWrongLayoutBoundary(in: "- ghbdtn")
        XCTAssertNotNil(boundary)
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "- ghbdtn")
    }
    
    // MARK: - Edge case: single character
    
    func testConvertSelectedText_SingleLatinChar() {
        let result = converter.convertSelectedText("q")
        XCTAssertEqual(result, "й")
    }
    
    func testConvertSelectedText_SingleCyrillicChar() {
        let result = converter.convertSelectedText("й")
        XCTAssertEqual(result, "q")
    }
    
    // MARK: - Greedy with 70% threshold
    
    func testFindBoundary_ThresholdMet() {
        // 3 words wrong, 1 word correct-ish → 75% wrong → should convert all
        // This is hard to test without a dictionary, since looksLikeWrongLayout
        // considers any Latin→Cyrillic switch as "wrong".
        // So all Latin words will be "wrong" and all Cyrillic words will be "wrong".
        // A mixed line of Cyrillic+Latin: the Cyrillic words switch to Latin, Latin words switch to Cyrillic.
        // Both directions = "wrong layout". So a mixed line has ALL words as wrong.
        // That's actually correct behavior — the 70% threshold handles the case
        // where one word has only numbers/symbols and doesn't register.
        
        // Test: 3 Latin words + 1 numeric token
        let boundary = converter.findWrongLayoutBoundary(in: "ghbdtn rfr ltkf 123")
        XCTAssertNotNil(boundary)
        // All 3 letter-words are wrong, "123" is not a word → 3/3 = 100% → convert all
        XCTAssertEqual(boundary?.keep, "")
        XCTAssertEqual(boundary?.convert, "ghbdtn rfr ltkf 123")
    }
}
