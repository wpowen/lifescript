import Foundation

enum SoloAppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case zhHans = "zh-Hans"
    case en
    case ja
    case ko

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return SoloLocalization.localized("跟随系统")
        case .zhHans:
            return SoloLocalization.localized("简体中文")
        case .en:
            return "English"
        case .ja:
            return "日本語"
        case .ko:
            return "한국어"
        }
    }

    var localeIdentifier: String {
        switch resolved {
        case .system:
            return Locale.preferredLanguages.first ?? "zh-Hans"
        case .zhHans:
            return "zh-Hans"
        case .en:
            return "en"
        case .ja:
            return "ja"
        case .ko:
            return "ko"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var bundleLocalizationCode: String? {
        switch resolved {
        case .system, .zhHans:
            return nil
        case .en:
            return "en"
        case .ja:
            return "ja"
        case .ko:
            return "ko"
        }
    }

    var translationFolderName: String? {
        bundleLocalizationCode
    }

    var resolved: SoloAppLanguage {
        guard self == .system else { return self }

        let preferred = Locale.preferredLanguages
        for language in preferred {
            let normalized = language.lowercased()
            if normalized.hasPrefix("zh") {
                return .zhHans
            }
            if normalized.hasPrefix("en") {
                return .en
            }
            if normalized.hasPrefix("ja") {
                return .ja
            }
            if normalized.hasPrefix("ko") {
                return .ko
            }
        }

        return .zhHans
    }
}

enum SoloLocalization {
    static let storageKey = "solo.appLanguage"

    static func selectedLanguage(userDefaults: UserDefaults = .standard) -> SoloAppLanguage {
        let rawValue = userDefaults.string(forKey: storageKey)
        return rawValue.flatMap(SoloAppLanguage.init(rawValue:)) ?? .system
    }

    static func currentLocale(userDefaults: UserDefaults = .standard) -> Locale {
        selectedLanguage(userDefaults: userDefaults).locale
    }

    static func localized(
        _ key: String,
        language: SoloAppLanguage? = nil,
        bundle: Bundle = .main
    ) -> String {
        let activeLanguage = (language ?? selectedLanguage()).resolved
        guard let localizationCode = activeLanguage.bundleLocalizationCode,
              let bundlePath = bundle.path(forResource: localizationCode, ofType: "lproj"),
              let localizedBundle = Bundle(path: bundlePath) else {
            return key
        }

        return NSLocalizedString(key, bundle: localizedBundle, value: key, comment: "")
    }

    static func format(
        _ key: String,
        _ arguments: CVarArg...,
        language: SoloAppLanguage? = nil,
        bundle: Bundle = .main
    ) -> String {
        let activeLanguage = language ?? selectedLanguage()
        let format = localized(key, language: activeLanguage, bundle: bundle)
        return String(format: format, locale: activeLanguage.locale, arguments: arguments)
    }

    static func stripWrappedQuotes(in value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return value }

        let pairs: [(Swift.Character, Swift.Character)] = [
            (Swift.Character("\""), Swift.Character("\"")),
            (Swift.Character("“"), Swift.Character("”")),
            (Swift.Character("‘"), Swift.Character("’")),
        ]

        for (opening, closing) in pairs {
            if trimmed.first == opening, trimmed.last == closing {
                let inner = trimmed.dropFirst().dropLast()
                return String(inner)
            }
        }

        return value
    }
}

struct SoloTranslationAvailability: Identifiable, Equatable, Sendable {
    let language: SoloAppLanguage
    let translatedChapterCount: Int
    let totalChapterCount: Int

    var id: SoloAppLanguage { language }

    var coverageRatio: Double {
        guard totalChapterCount > 0 else { return 0 }
        return Double(translatedChapterCount) / Double(totalChapterCount)
    }
}

enum SoloTranslationCatalog {
    static func chapterAvailability(
        for bookId: String,
        totalChapterCount: Int,
        bundle: Bundle = .main
    ) -> [SoloTranslationAvailability] {
        let supportedLanguages = SoloAppLanguage.allCases.filter { $0 != .system }

        return supportedLanguages.map { language in
            if language == .zhHans {
                return SoloTranslationAvailability(
                    language: language,
                    translatedChapterCount: totalChapterCount,
                    totalChapterCount: totalChapterCount
                )
            }

            let chapterCount = translatedChapterURLs(language: language, bundle: bundle).count
            return SoloTranslationAvailability(
                language: language,
                translatedChapterCount: chapterCount,
                totalChapterCount: totalChapterCount
            )
        }
    }

    static func translatedChapterURLs(
        language: SoloAppLanguage,
        bundle: Bundle = .main
    ) -> [String: URL] {
        guard let resourceRoot = bundle.resourceURL else {
            return [:]
        }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: resourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }

        var result: [String: URL] = [:]
        let compiledPrefix = "translation_\(language.rawValue)_"
        let legacyLanguageFolder = language.translationFolderName

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "json" else { continue }

            let filename = fileURL.lastPathComponent

            if filename.hasPrefix(compiledPrefix) {
                let chapterFilename = String(filename.dropFirst(compiledPrefix.count))
                result[chapterFilename] = fileURL
                continue
            }

            if let legacyLanguageFolder {
                let components = fileURL.pathComponents
                if components.contains("translations"),
                   components.contains(legacyLanguageFolder),
                   components.contains("chapters") {
                    result[filename] = fileURL
                }
            }
        }

        return result
    }
}
