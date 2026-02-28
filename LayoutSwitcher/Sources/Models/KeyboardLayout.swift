import Foundation
import Carbon

// MARK: - Keyboard Layout Model

struct KeyboardLayout: Identifiable, Hashable, Codable {
    let id: String           // e.g. "com.apple.keylayout.US"
    let localizedName: String // e.g. "U.S." or "Russian"
    let languageCode: String  // e.g. "en", "ru"
    
    var displayName: String {
        "\(localizedName) (\(languageCode.uppercased()))"
    }
}

// MARK: - Layout Pair

struct LayoutPair: Identifiable, Hashable, Codable {
    var id: String { "\(source.id)->\(target.id)" }
    let source: KeyboardLayout
    let target: KeyboardLayout
}

// MARK: - Layout Character Maps
// Standard QWERTY <-> various layout mappings for physical key positions

enum LayoutCharacterMap {
    
    // Standard US QWERTY keyboard
    static let qwertyUS: [Character: Character] = {
        let chars = "`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?"
        var map: [Character: Character] = [:]
        for (i, c) in chars.enumerated() {
            map[c] = c
        }
        return map
    }()
    
    // Russian (standard) keyboard — mapped to same physical keys as US QWERTY
    static let russian: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let russian = Array("ё1234567890-=йцукенгшщзхъ\\фывапролджэячсмитьбю.Ё!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, russian.count) {
            map[qwerty[i]] = russian[i]
        }
        return map
    }()
    
    // German QWERTZ
    static let german: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let german = Array("^1234567890ß´qwertzuiopü+#asdfghjklöäyxcvbnm,.-°!\"§$%&/()=?`QWERTZUIOPÜ*'ASDFGHJKLÖÄYXCVBNM;:_")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, german.count) {
            map[qwerty[i]] = german[i]
        }
        return map
    }()
    
    // French AZERTY
    static let french: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let french = Array("²&é\"'(-è_çà)=azertyuiop^$*qsdfghjklmùwxcvbn,;:!³1234567890°+AZERTYUIOP¨£µQSDFGHJKLM%WXCVBN?./§")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, french.count) {
            map[qwerty[i]] = french[i]
        }
        return map
    }()
    
    // Ukrainian
    static let ukrainian: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let ukr    = Array("'1234567890-=йцукенгшщзхї\\фівапролджєячсмитьбю.₴!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЇ/ФІВАПРОЛДЖЄЯЧСМИТЬБЮ,")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, ukr.count) {
            map[qwerty[i]] = ukr[i]
        }
        return map
    }()
    
    // Spanish
    static let spanish: [Character: Character] = {
        let qwerty  = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let spanish = Array("º1234567890'¡qwertyuiop`+çasdfghjklñ´zxcvbnm,.-ª!\"·$%&/()=?¿QWERTYUIOP^*ÇASDFGHJKLÑ¨ZXCVBNM;:_")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, spanish.count) {
            map[qwerty[i]] = spanish[i]
        }
        return map
    }()
    
    // Map of layout identifier patterns to their character maps
    static let allMaps: [(pattern: String, map: [Character: Character])] = [
        ("us", qwertyUS),
        ("abc", qwertyUS),        // ABC keyboard is same as US
        ("british", qwertyUS),    // Close enough for conversion
        ("russian", russian),
        ("german", german),
        ("french", french),
        ("ukrainian", ukrainian),
        ("spanish", spanish),
    ]
    
    /// Get character map for a given layout identifier
    static func characterMap(for layoutID: String) -> [Character: Character]? {
        let lowered = layoutID.lowercased()
        for (pattern, map) in allMaps {
            if lowered.contains(pattern) {
                return map
            }
        }
        return nil
    }
}
