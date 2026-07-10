//
//  SpellingLanguage.swift
//  KeyType
//
//  Shared detected-language → installed-dictionary resolution for every `NSSpellChecker`
//  consumer (typo guard, dead-end guard, output filter, correction lane). See ADR-116.
//

import Foundation

/// Maps a detected-language tag onto an installed spelling dictionary.
///
/// `LanguageDetector` emits *base* tags only (`"en"`, never `"en-GB"`), and macOS's generic `"en"`
/// dictionary is US-flavoured — it flags `colour`/`realise` as misspellings. So a bare base tag is
/// first refined with the user's preferred regional variant of that language
/// (`Locale.preferredLanguages`, the same OS-derived signal ADR-089 uses for prompt style) before
/// falling back to the generic dictionary. A region-qualified request keeps exact-match priority;
/// unknown languages fall back to their base and then to `nil` (checker auto-detect), so we never
/// force the checker into a language it can't handle.
enum SpellingLanguage {
    static func resolve(
        _ requested: String?,
        availableLanguages: [String],
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String? {
        guard let requested, !requested.isEmpty else { return nil }
        let normalized = requested.replacingOccurrences(of: "-", with: "_")
        let base = String(normalized.prefix { $0 != "_" })
        // Bare base tag → prefer the user's own regional variant of that language (e.g. detected
        // "en" on an en-GB system resolves to "en_GB", not the US-flavoured "en").
        if normalized == base {
            for preferred in preferredLanguages {
                let variant = preferred.replacingOccurrences(of: "-", with: "_")
                if variant.hasPrefix("\(base)_"), availableLanguages.contains(variant) {
                    return variant
                }
            }
        }
        if availableLanguages.contains(normalized) { return normalized }
        if availableLanguages.contains(base) { return base }
        return nil
    }
}
