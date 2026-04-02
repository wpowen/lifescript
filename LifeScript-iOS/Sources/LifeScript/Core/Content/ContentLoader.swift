import Foundation

/// Loads book and chapter content from bundled JSON files.
/// Designed for easy migration to REST API in future versions.
protocol ContentProviding: Sendable {
    func listBooks() async throws -> [Book]
    func loadBook(id: String) async throws -> Book
    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter
    func loadAllChapters(bookId: String) async throws -> [Chapter]
    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough?
    func loadContentVersion(bookId: String) async throws -> String?
}

extension ContentProviding {
    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough? {
        nil
    }

    func loadContentVersion(bookId: String) async throws -> String? {
        nil
    }
}

actor BundledContentLoader: ContentProviding {
    private struct CompiledStoryManifest: Decodable {
        let bookId: String
        let chapterCount: Int
        let contentVersion: String
        let storyPackageSha256: String?
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private var packagedStoryEntriesCache: [PackagedStoryEntry]?
    private var packagedStoryEntryByBookID: [String: PackagedStoryEntry] = [:]
    private var loadedBookCache: [String: Book] = [:]
    private var loadedChapterCache: [String: [Chapter]] = [:]
    private var loadedWalkthroughCache: [String: BookWalkthrough] = [:]
    private var missingWalkthroughBookIDs: Set<String> = []
    private var packagedChapterURLCache: [String: [URL]] = [:]
    private var translatedChapterURLCache: [String: [String: URL]] = [:]
    private var loadedContentVersionCache: [String: String] = [:]

    func listBooks() async throws -> [Book] {
        let manifestBooks = (try? loadJSON(filename: "books", type: [Book].self)) ?? []
        let generatedBooks = try loadGeneratedBooks()
        let packagedBooks = try loadPackagedStoryEntries().map(\.package.book)
        let mergedBooks = mergeBookCatalogs(
            manifest: manifestBooks,
            generated: generatedBooks + packagedBooks
        )
        return mergedBooks.map(localizeBook(_:))
    }

    func loadBook(id: String) async throws -> Book {
        let cacheKey = localizedCacheKey(for: id)
        if let cached = loadedBookCache[cacheKey] {
            return cached
        }
        if let generated = try loadJSONIfPresent(filename: "book_\(id)", type: Book.self) {
            let localizedBook = localizeBook(generated)
            loadedBookCache[cacheKey] = localizedBook
            return localizedBook
        }
        if let packaged = try loadPackagedStoryEntry(bookId: id) {
            let localizedBook = localizeBook(packaged.package.book)
            loadedBookCache[cacheKey] = localizedBook
            return localizedBook
        }
        let books = try await listBooks()
        guard let book = books.first(where: { $0.id == id }) else {
            throw ContentError.bookNotFound(id)
        }
        loadedBookCache[cacheKey] = book
        return book
    }

    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter {
        let chapters = try await loadAllChapters(bookId: bookId)
        guard let chapter = chapters.first(where: { $0.id == chapterId }) else {
            throw ContentError.chapterNotFound(chapterId)
        }
        return chapter
    }

    func loadAllChapters(bookId: String) async throws -> [Chapter] {
        let cacheKey = localizedCacheKey(for: bookId)
        if let cached = loadedChapterCache[cacheKey] {
            return cached
        }
        if let bundled = try loadCompiledChaptersIfPresent(bookId: bookId) {
            let localizedChapters = try localizeChapters(bundled, bookId: bookId)
            loadedChapterCache[cacheKey] = localizedChapters
            return localizedChapters
        }
        if let packaged = try loadPackagedStoryEntry(bookId: bookId) {
            let chapters = try loadPackagedChapters(bookId: bookId, from: packaged.packageURL)
            let localizedChapters = try localizeChapters(chapters, bookId: bookId)
            loadedChapterCache[cacheKey] = localizedChapters
            return localizedChapters
        }
        throw ContentError.fileNotFound("chapters_\(bookId)")
    }

    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough? {
        let cacheKey = localizedCacheKey(for: bookId)
        if let cached = loadedWalkthroughCache[cacheKey] {
            return cached
        }
        if missingWalkthroughBookIDs.contains(cacheKey) {
            return nil
        }
        let activeLanguage = SoloLocalization.selectedLanguage().resolved

        if activeLanguage == .zhHans,
           let bundled = try loadJSONIfPresent(filename: "walkthrough_\(bookId)", type: BookWalkthrough.self) {
            let localizedWalkthrough = localizeWalkthrough(bundled)
            loadedWalkthroughCache[cacheKey] = localizedWalkthrough
            return localizedWalkthrough
        }
        guard let packaged = try loadPackagedStoryEntry(bookId: bookId) else {
            missingWalkthroughBookIDs.insert(cacheKey)
            return nil
        }
        let chapters = try await loadAllChapters(bookId: bookId)
        let walkthrough = buildFallbackWalkthrough(package: packaged.package, chapters: chapters)
        if let walkthrough {
            loadedWalkthroughCache[cacheKey] = localizeWalkthrough(walkthrough)
        } else {
            missingWalkthroughBookIDs.insert(cacheKey)
        }
        return loadedWalkthroughCache[cacheKey]
    }

    func loadContentVersion(bookId: String) async throws -> String? {
        if let cached = loadedContentVersionCache[bookId] {
            return cached
        }

        if let manifest = try loadJSONIfPresent(
            filename: "manifest_\(bookId)",
            type: CompiledStoryManifest.self
        ) {
            loadedContentVersionCache[bookId] = manifest.contentVersion
            return manifest.contentVersion
        }

        return nil
    }

    // MARK: - Private

    private func loadJSON<T: Decodable>(filename: String, type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentError.fileNotFound(filename)
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return try decoder.decode(T.self, from: data)
    }

    private func loadJSONIfPresent<T: Decodable>(filename: String, type: T.Type) throws -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return try decoder.decode(T.self, from: data)
    }

    private func localizedCacheKey(for bookId: String) -> String {
        let language = SoloLocalization.selectedLanguage().resolved
        let suffix = language.bundleLocalizationCode ?? "zh-Hans"
        return "\(bookId)::\(suffix)"
    }

    private func localizeBook(_ book: Book) -> Book {
        Book(
            id: book.id,
            title: SoloLocalization.localized(book.title),
            author: SoloLocalization.localized(book.author),
            coverImageName: book.coverImageName,
            synopsis: SoloLocalization.localized(book.synopsis),
            genre: book.genre,
            tags: book.tags.map { SoloLocalization.localized($0) },
            interactionTags: book.interactionTags.map { SoloLocalization.localized($0) },
            totalChapters: book.totalChapters,
            freeChapters: book.freeChapters,
            characters: book.characters.map(localizeCharacter(_:)),
            initialStats: book.initialStats
        )
    }

    private func localizeCharacter(_ character: Character) -> Character {
        Character(
            id: character.id,
            name: SoloLocalization.localized(character.name),
            title: SoloLocalization.localized(character.title),
            avatarImageName: character.avatarImageName,
            description: SoloLocalization.localized(character.description),
            role: character.role
        )
    }

    private func localizeWalkthrough(_ walkthrough: BookWalkthrough) -> BookWalkthrough {
        BookWalkthrough(
            bookId: walkthrough.bookId,
            title: SoloLocalization.localized(walkthrough.title),
            stages: walkthrough.stages.map { stage in
                WalkthroughStage(
                    id: stage.id,
                    title: SoloLocalization.localized(stage.title),
                    summary: SoloLocalization.localized(stage.summary),
                    chapterIds: stage.chapterIds
                )
            },
            chapterGuides: walkthrough.chapterGuides.map { guide in
                WalkthroughChapterGuide(
                    chapterId: guide.chapterId,
                    stageId: guide.stageId,
                    publicSummary: SoloLocalization.localized(guide.publicSummary),
                    objective: SoloLocalization.localized(guide.objective),
                    estimatedMinutes: guide.estimatedMinutes,
                    interactionCount: guide.interactionCount,
                    visibleRoutes: guide.visibleRoutes.map { route in
                        WalkthroughRoute(
                            id: route.id,
                            title: SoloLocalization.localized(route.title),
                            style: SoloLocalization.localized(route.style),
                            unlockHint: SoloLocalization.localized(route.unlockHint),
                            payoff: SoloLocalization.localized(route.payoff),
                            processFocus: SoloLocalization.localized(route.processFocus)
                        )
                    },
                    hiddenRouteHint: guide.hiddenRouteHint.map { SoloLocalization.localized($0) }
                )
            }
        )
    }

    private func localizeChapters(_ chapters: [Chapter], bookId: String) throws -> [Chapter] {
        let selectedLanguage = SoloLocalization.selectedLanguage().resolved
        guard let language = selectedLanguage.translationFolderName else {
            return chapters
        }

        let translatedChapterURLs = try translatedChapterURLs(
            for: language,
            bookId: bookId
        )
        guard !translatedChapterURLs.isEmpty else {
            return chapters
        }

        return try chapters.map { chapter in
            let filename = String(format: "ch%04d.json", chapter.number)
            guard let translationURL = translatedChapterURLs[filename] else {
                return chapter
            }
            return try decodeTranslatedChapter(
                at: translationURL,
                fallback: chapter,
                bookId: bookId,
                language: selectedLanguage
            )
        }
    }

    private func loadCompiledChaptersIfPresent(bookId: String) throws -> [Chapter]? {
        guard let url = Bundle.main.url(forResource: "chapters_\(bookId)", withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        do {
            return try decoder.decode([Chapter].self, from: data)
        } catch {
            return try normalizeCompiledChapterArray(data)
        }
    }

    private func loadGeneratedBooks() throws -> [Book] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }

        return try urls
            .filter { $0.deletingPathExtension().lastPathComponent.hasPrefix("book_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                return try decoder.decode(Book.self, from: data)
            }
    }

    private func loadPackagedStoryEntries() throws -> [PackagedStoryEntry] {
        if let cached = packagedStoryEntriesCache {
            return cached
        }
        guard let resourceRoot = Bundle.main.resourceURL else {
            return []
        }

        let enumerator = FileManager.default.enumerator(
            at: resourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var entries: [PackagedStoryEntry] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.lastPathComponent == "story_package.json" else { continue }
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let package = try decoder.decode(PackagedStory.self, from: data)
            entries.append(PackagedStoryEntry(packageURL: fileURL, package: package))
        }

        let sortedEntries = entries.sorted { $0.package.book.id < $1.package.book.id }
        packagedStoryEntriesCache = sortedEntries
        packagedStoryEntryByBookID = Dictionary(
            uniqueKeysWithValues: sortedEntries.map { ($0.package.book.id, $0) }
        )
        return sortedEntries
    }

    private func loadPackagedStoryEntry(bookId: String) throws -> PackagedStoryEntry? {
        if let cached = packagedStoryEntryByBookID[bookId] {
            return cached
        }
        _ = try loadPackagedStoryEntries()
        return packagedStoryEntryByBookID[bookId]
    }

    private func loadPackagedChapters(bookId: String, from packageURL: URL) throws -> [Chapter] {
        let chapterURLs = try packagedChapterFileURLs(bookId: bookId, from: packageURL)
        return try decodePackagedChapters(at: chapterURLs)
    }

    private func translatedChapterURLs(
        for languageFolder: String,
        bookId: String
    ) throws -> [String: URL] {
        let cacheKey = "\(bookId)::\(languageFolder)"
        if let cached = translatedChapterURLCache[cacheKey] {
            return cached
        }

        let urls = SoloTranslationCatalog.translatedChapterURLs(
            language: SoloAppLanguage(rawValue: languageFolder) ?? .zhHans,
            bookId: bookId
        )
        translatedChapterURLCache[cacheKey] = urls
        return urls
    }

    private func packagedChapterFileURLs(bookId: String, from packageURL: URL) throws -> [URL] {
        if let cached = packagedChapterURLCache[bookId] {
            return cached
        }
        let fileManager = FileManager.default
        let packageDirectoryURL = packageURL.deletingLastPathComponent()
        let chapterDirectoryURL = packageDirectoryURL.appendingPathComponent("chapters", isDirectory: true)

        if fileManager.fileExists(atPath: chapterDirectoryURL.path) {
            let urls = try fileManager.contentsOfDirectory(
                at: chapterDirectoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            packagedChapterURLCache[bookId] = urls
            return urls
        }

        // Xcode may flatten directory resources into the bundle root. Fall back to
        // sibling `chXXXX.json` files so packaged stories still load on device/simulator.
        let urls = try fileManager.contentsOfDirectory(
            at: packageDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        .filter { url in
            guard url.pathExtension == "json" else { return false }
            let name = url.deletingPathExtension().lastPathComponent
            guard name.hasPrefix("ch") else { return false }
            return name.dropFirst(2).allSatisfy(\.isNumber)
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
        packagedChapterURLCache[bookId] = urls
        return urls
    }

    private func decodePackagedChapters(at chapterURLs: [URL]) throws -> [Chapter] {
        try chapterURLs.map { url in
            let data = try Data(contentsOf: url, options: .mappedIfSafe)

            do {
                return try decoder.decode(Chapter.self, from: data)
            } catch {
                let normalizedData = try normalizePackagedChapterData(data)
                do {
                    return try decoder.decode(Chapter.self, from: normalizedData)
                } catch {
                    throw ContentError.decodingFailed(error)
                }
            }
        }
    }

    private func decodeTranslatedChapter(
        at url: URL,
        fallback: Chapter,
        bookId: String,
        language: SoloAppLanguage
    ) throws -> Chapter {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let normalizedData = try normalizeTranslatedChapterData(data)

        do {
            let chapter = try decoder.decode(Chapter.self, from: normalizedData)
            guard translatedChapterMatchesFallback(chapter, fallback: fallback),
                  chapter.bookId == bookId else {
                #if DEBUG
                NSLog("‼️ translation mismatch for %@ -> fallback", url.lastPathComponent)
                #endif
                return fallback
            }

            if translationContainsSuspiciousArtifacts(chapter, language: language) {
                #if DEBUG
                NSLog("‼️ suspicious translation artifacts in %@ -> fallback", url.lastPathComponent)
                #endif
                return fallback
            }
            return chapter
        } catch {
            #if DEBUG
            NSLog("‼️ translation decode error for %@: %@", url.lastPathComponent, String(describing: error))
            #endif
            return fallback
        }
    }

    private func normalizeCompiledChapterArray(_ data: Data) throws -> [Chapter] {
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw ContentError.decodingFailed(
                NSError(domain: "BundledContentLoader", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "compiled chapter payload is not an array"
                ])
            )
        }

        return try payload.map { rawChapter in
            let chapterData = try JSONSerialization.data(withJSONObject: rawChapter)

            do {
                return try decoder.decode(Chapter.self, from: chapterData)
            } catch {
                let normalizedData = try normalizePackagedChapterData(chapterData)
                do {
                    return try decoder.decode(Chapter.self, from: normalizedData)
                } catch {
                    throw ContentError.decodingFailed(error)
                }
            }
        }
    }

    private func buildFallbackWalkthrough(
        package: PackagedStory,
        chapters: [Chapter]
    ) -> BookWalkthrough? {
        guard !chapters.isEmpty else { return nil }

        let stages = fallbackStages(package: package, chapters: chapters)
        let stageByChapterId = Dictionary(
            uniqueKeysWithValues: stages.flatMap { stage in
                stage.chapterIds.map { ($0, stage.id) }
            }
        )
        let hiddenRouteHint = package.walkthrough?.unlockHint ?? package.routeGraph?.hiddenRoutes.first

        let chapterGuides = chapters.map { chapter in
            let stageID = stageByChapterId[chapter.id] ?? stages.first?.id ?? "stage_live"
            let summary = fallbackSummary(for: chapter)
            let objective = fallbackObjective(for: chapter)
            return WalkthroughChapterGuide(
                chapterId: chapter.id,
                stageId: stageID,
                publicSummary: summary,
                objective: objective,
                estimatedMinutes: max(3, min(12, max(1, chapter.nodes.count / 4))),
                interactionCount: chapter.nodes.reduce(0) { partial, node in
                    if case .choice = node { return partial + 1 }
                    return partial
                },
                visibleRoutes: [],
                hiddenRouteHint: hiddenRouteHint
            )
        }

        return BookWalkthrough(
            bookId: package.book.id,
            title: "\(package.book.title)命运图谱",
            stages: stages,
            chapterGuides: chapterGuides
        )
    }

    private func fallbackStages(package: PackagedStory, chapters: [Chapter]) -> [WalkthroughStage] {
        let sortedChapters = chapters.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.id < rhs.id
            }
            return lhs.number < rhs.number
        }

        let milestoneStages = (package.routeGraph?.milestones ?? []).compactMap { milestone -> WalkthroughStage? in
            guard let range = parseChapterRange(milestone.chapterRange) else { return nil }
            let chapterIds = sortedChapters
                .filter { range.contains($0.number) }
                .map(\.id)

            guard !chapterIds.isEmpty else { return nil }

            return WalkthroughStage(
                id: milestone.id,
                title: milestone.title,
                summary: "第\(range.lowerBound)-\(range.upperBound)章阶段，围绕「\(milestone.title)」推进。",
                chapterIds: chapterIds
            )
        }

        if !milestoneStages.isEmpty {
            return milestoneStages
        }

        return [
            WalkthroughStage(
                id: "stage_live",
                title: "天机连载",
                summary: "当前已生成章节的主线推进与关键抉择。",
                chapterIds: sortedChapters.map(\.id)
            )
        ]
    }

    private func fallbackSummary(for chapter: Chapter) -> String {
        if let snippet = firstNarrativeSnippet(in: chapter), !snippet.isEmpty {
            return snippet
        }
        return chapter.nextChapterHook ?? "这一章的局势仍在继续发酵。"
    }

    private func fallbackObjective(for chapter: Chapter) -> String {
        for node in chapter.nodes {
            if case .choice(let choiceNode) = node {
                return choiceNode.prompt
            }
        }
        return "推进「\(chapter.title)」并接住下一次因果变化。"
    }

    private func firstNarrativeSnippet(in chapter: Chapter) -> String? {
        for node in chapter.nodes {
            switch node {
            case .text(let textNode):
                let trimmed = normalizeNarrativeSnippet(textNode.content)
                if !trimmed.isEmpty { return trimmed }
            case .dialogue(let dialogueNode):
                let trimmed = normalizeNarrativeSnippet(dialogueNode.content)
                if !trimmed.isEmpty { return trimmed }
            case .choice, .notification:
                continue
            }
        }
        return nil
    }

    private func normalizeNarrativeSnippet(_ content: String) -> String {
        content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(52)
            .description
    }

    private func parseChapterRange(_ rawValue: String) -> ClosedRange<Int>? {
        let numbers = rawValue
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        guard let first = numbers.first, let last = numbers.last else {
            return nil
        }

        return first...last
    }
}

func normalizePackagedChapterData(_ data: Data) throws -> Data {
    guard var chapterJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return data
    }

    if let rawNodes = chapterJSON["nodes"] as? [Any] {
        chapterJSON["nodes"] = normalizeStoryNodeArray(rawNodes, path: "chapter_nodes")
    }

    return try JSONSerialization.data(withJSONObject: chapterJSON)
}

func normalizeTranslatedChapterData(_ data: Data) throws -> Data {
    let payload = try JSONSerialization.jsonObject(with: data)
    let sanitizedPayload = sanitizeTranslationPayload(payload)
    let sanitizedData = try JSONSerialization.data(withJSONObject: sanitizedPayload)
    return try normalizePackagedChapterData(sanitizedData)
}

private func sanitizeTranslationPayload(_ payload: Any) -> Any {
    switch payload {
    case let dictionary as [String: Any]:
        return dictionary.mapValues(sanitizeTranslationPayload(_:))
    case let array as [Any]:
        return array.map(sanitizeTranslationPayload(_:))
    case let value as String:
        return SoloLocalization.stripWrappedQuotes(in: value)
    default:
        return payload
    }
}

private func normalizeStoryNodeArray(_ rawNodes: [Any], path: String) -> [[String: Any]] {
    rawNodes.enumerated().flatMap { index, rawNode in
        let nodePath = "\(path)_\(index)"
        if let nodeDictionary = rawNode as? [String: Any] {
            return normalizeStoryNodeDictionary(nodeDictionary, path: nodePath)
        }
        if let rawText = rawNode as? String {
            return [[
                "text": [
                    "id": "\(nodePath)_text",
                    "content": rawText,
                ]
            ]]
        }
        return []
    }
}

private func normalizeStoryNodeDictionary(_ rawNode: [String: Any], path: String) -> [[String: Any]] {
    guard let rawChoice = rawNode["choice"] as? [String: Any] else {
        return extractSingleStoryNodes(from: rawNode, path: path)
    }

    let (normalizedChoice, promotedNodes) = normalizeChoiceNode(rawChoice, path: path)
    return [["choice": normalizedChoice]] + promotedNodes
}

private func normalizeChoiceNode(_ rawChoice: [String: Any], path: String) -> ([String: Any], [[String: Any]]) {
    var choice = rawChoice
    let rawChoices = rawChoice["choices"] as? [Any] ?? []
    var normalizedChoices: [[String: Any]] = []
    var promotedNodes: [[String: Any]] = []

    for (index, rawItem) in rawChoices.enumerated() {
        guard let choiceCandidate = rawItem as? [String: Any] else { continue }
        let optionPath = "\(path)_choice_\(index)"

        if isValidChoiceOption(choiceCandidate) {
            var normalizedChoice = choiceCandidate
            if let rawResultNodes = choiceCandidate["result_nodes"] as? [Any] {
                normalizedChoice["result_nodes"] = normalizeStoryNodeArray(
                    rawResultNodes,
                    path: "\(optionPath)_result"
                )
            }
            normalizedChoices.append(normalizedChoice)
        } else {
            promotedNodes.append(contentsOf: extractSingleStoryNodes(from: choiceCandidate, path: "\(optionPath)_promoted"))
        }
    }

    choice["choices"] = normalizedChoices
    return (choice, promotedNodes)
}

private func isValidChoiceOption(_ candidate: [String: Any]) -> Bool {
    guard let id = candidate["id"] as? String, !id.isEmpty else {
        return false
    }
    guard let text = candidate["text"] as? String, !text.isEmpty else {
        return false
    }
    return true
}

private func extractSingleStoryNodes(from rawDictionary: [String: Any], path: String) -> [[String: Any]] {
    var extracted: [(kind: String, id: String, payload: [String: Any])] = []
    var promotedFromNestedChoice: [[String: Any]] = []

    for kind in ["text", "dialogue", "notification"] {
        guard let payload = rawDictionary[kind] as? [String: Any] else { continue }
        let normalizedNodes = normalizeLeafNode(kind: kind, payload: payload, path: "\(path)_\(kind)")
        extracted.append(contentsOf: normalizedNodes.map { node in
            let nodeKind = node.keys.first ?? kind
            let nodePayload = node[nodeKind] as? [String: Any] ?? [:]
            return (nodeKind, nodePayload["id"] as? String ?? "", nodePayload)
        })
    }

    if let rawChoice = rawDictionary["choice"] as? [String: Any] {
        let (normalizedChoice, promotedNodes) = normalizeChoiceNode(rawChoice, path: "\(path)_choice")
        extracted.append(("choice", normalizedChoice["id"] as? String ?? "", normalizedChoice))
        promotedFromNestedChoice = promotedNodes
    }

    guard !extracted.isEmpty else {
        return []
    }

    let narrative = extracted
        .filter { $0.kind != "choice" }
        .sorted { lhs, rhs in lhs.id < rhs.id }
        .map { [$0.kind: $0.payload] }

    let choices = extracted
        .filter { $0.kind == "choice" }
        .map { [$0.kind: $0.payload] }

    return narrative + choices + promotedFromNestedChoice
}

private func normalizeLeafNode(kind: String, payload: [String: Any], path: String) -> [[String: Any]] {
    let stableID = (payload["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? path

    switch kind {
    case "text":
        guard let content = payload["content"] as? String, !content.isEmpty else {
            return []
        }
        var normalizedPayload = payload
        normalizedPayload["id"] = stableID
        if let emphasis = normalizedPayload["emphasis"] as? String,
           !["normal", "dramatic", "whisper", "system"].contains(emphasis) {
            normalizedPayload.removeValue(forKey: "emphasis")
        }
        return [["text": normalizedPayload]]

    case "dialogue":
        guard let content = payload["content"] as? String, !content.isEmpty else {
            return []
        }

        if let characterID = payload["character_id"] as? String, !characterID.isEmpty {
            var normalizedPayload = payload
            normalizedPayload["id"] = stableID
            normalizedPayload["character_id"] = characterID
            return [["dialogue": normalizedPayload]]
        }

        var normalizedPayload: [String: Any] = [
            "id": stableID,
            "content": content,
        ]
        if let emphasis = payload["emotion"] as? String, !emphasis.isEmpty {
            normalizedPayload["emphasis"] = "dramatic"
        }
        return [["text": normalizedPayload]]

    case "notification":
        guard let message = payload["message"] as? String, !message.isEmpty else {
            return []
        }
        var normalizedPayload = payload
        normalizedPayload["id"] = stableID
        normalizedPayload["message"] = message
        return [["notification": normalizedPayload]]

    default:
        return []
    }
}

func translatedChapterMatchesFallback(_ translated: Chapter, fallback: Chapter) -> Bool {
    guard translated.id == fallback.id,
          translated.bookId == fallback.bookId,
          translated.number == fallback.number,
          translated.nodes.count == fallback.nodes.count else {
        return false
    }

    guard translated.nodes.elementsEqual(fallback.nodes, by: translatedStoryNodeMatchesFallback(_:fallback:)) else {
        return false
    }

    return true
}

func translationContainsSuspiciousArtifacts(
    _ chapter: Chapter,
    language: SoloAppLanguage
) -> Bool {
    let suspiciousMarkers = [
        "[the original text appears",
        "let me provide a natural translation",
        "[based on context:",
        "encoding issues",
    ]

    for string in collectChapterStrings(chapter) {
        let normalized = string.lowercased()
        if suspiciousMarkers.contains(where: normalized.contains) {
            return true
        }
    }

    // English and Korean builds should not ship chapters that still contain
    // large blocks of untranslated Han text. If they do, prefer the source
    // Chinese chapter over a visibly broken mixed-language chapter.
    switch language {
    case .en, .ko:
        let contentStrings = collectChapterNarrativeStrings(chapter)
        let totalScalarCount = contentStrings.reduce(0) { $0 + $1.unicodeScalars.count }
        guard totalScalarCount > 0 else { return false }

        let hanScalarCount = contentStrings.reduce(0) { partial, value in
            partial + value.unicodeScalars.filter {
                (0x4E00...0x9FFF).contains($0.value)
            }.count
        }

        return Double(hanScalarCount) / Double(totalScalarCount) > 0.12
    default:
        return false
    }
}

private func translatedStoryNodeMatchesFallback(_ translated: StoryNode, fallback: StoryNode) -> Bool {
    switch (translated, fallback) {
    case (.text(let lhs), .text(let rhs)):
        return lhs.id == rhs.id
    case (.dialogue(let lhs), .dialogue(let rhs)):
        return lhs.id == rhs.id && lhs.characterId == rhs.characterId
    case (.notification(let lhs), .notification(let rhs)):
        return lhs.id == rhs.id
    case (.choice(let lhs), .choice(let rhs)):
        return translatedChoiceMatchesFallback(lhs, fallback: rhs)
    default:
        return false
    }
}

private func translatedChoiceMatchesFallback(_ translated: ChoiceNode, fallback: ChoiceNode) -> Bool {
    guard translated.id == fallback.id,
          translated.choices.count == fallback.choices.count else {
        return false
    }

    return translated.choices.elementsEqual(fallback.choices, by: translatedChoiceOptionMatchesFallback(_:fallback:))
}

private func translatedChoiceOptionMatchesFallback(_ translated: Choice, fallback: Choice) -> Bool {
    guard translated.id == fallback.id else { return false }

    let translatedResultNodes = translated.resultNodes ?? []
    let fallbackResultNodes = fallback.resultNodes ?? []
    guard translatedResultNodes.count == fallbackResultNodes.count else { return false }

    return translatedResultNodes.elementsEqual(
        fallbackResultNodes,
        by: translatedStoryNodeMatchesFallback(_:fallback:)
    )
}

private func collectChapterStrings(_ chapter: Chapter) -> [String] {
    var result = [chapter.title]

    if let nextChapterHook = chapter.nextChapterHook {
        result.append(nextChapterHook)
    }

    for node in chapter.nodes {
        switch node {
        case .text(let text):
            result.append(text.content)
        case .dialogue(let dialogue):
            result.append(dialogue.content)
        case .notification(let notification):
            result.append(notification.message)
        case .choice(let choice):
            result.append(choice.prompt)
            for option in choice.choices {
                result.append(option.text)
                if let description = option.description {
                    result.append(description)
                }
                if let visibleCost = option.visibleCost {
                    result.append(visibleCost)
                }
                if let visibleReward = option.visibleReward {
                    result.append(visibleReward)
                }
                if let riskHint = option.riskHint {
                    result.append(riskHint)
                }
                if let processLabel = option.processLabel {
                    result.append(processLabel)
                }
                if let resultNodes = option.resultNodes {
                    result.append(contentsOf: collectChapterStrings(
                        Chapter(
                            id: chapter.id,
                            bookId: chapter.bookId,
                            number: chapter.number,
                            title: chapter.title,
                            nodes: resultNodes,
                            isPaid: chapter.isPaid,
                            nextChapterHook: nil
                        )
                    ))
                }
            }
        }
    }

    return result
}

private func collectChapterNarrativeStrings(_ chapter: Chapter) -> [String] {
    var result = [chapter.title]

    if let nextChapterHook = chapter.nextChapterHook {
        result.append(nextChapterHook)
    }

    for node in chapter.nodes {
        switch node {
        case .text(let text):
            result.append(text.content)
        case .dialogue(let dialogue):
            result.append(dialogue.content)
        case .notification(let notification):
            result.append(notification.message)
        case .choice(let choice):
            result.append(choice.prompt)
            for option in choice.choices {
                result.append(option.text)
                if let description = option.description {
                    result.append(description)
                }
                if let resultNodes = option.resultNodes {
                    result.append(contentsOf: collectChapterNarrativeStrings(
                        Chapter(
                            id: chapter.id,
                            bookId: chapter.bookId,
                            number: chapter.number,
                            title: chapter.title,
                            nodes: resultNodes,
                            isPaid: chapter.isPaid,
                            nextChapterHook: nil
                        )
                    ))
                }
            }
        }
    }

    return result
}

private struct PackagedStoryEntry {
    let packageURL: URL
    let package: PackagedStory
}

private struct PackagedStory: Decodable {
    let book: Book
    let walkthrough: PackagedWalkthroughSeed?
    let routeGraph: PackagedRouteGraph?
}

private struct PackagedWalkthroughSeed: Decodable {
    let unlockHint: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unlockHint = try container.decodeIfPresent(String.self, forKey: .unlockHint)
    }

    private enum CodingKeys: String, CodingKey {
        case unlockHint
    }
}

private struct PackagedRouteGraph: Decodable {
    let hiddenRoutes: [String]
    let milestones: [PackagedMilestone]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hiddenRoutes = try container.decodeIfPresent([String].self, forKey: .hiddenRoutes) ?? []
        milestones = try container.decodeIfPresent([PackagedMilestone].self, forKey: .milestones) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case hiddenRoutes, milestones
    }
}

private struct PackagedMilestone: Decodable {
    let id: String
    let title: String
    let chapterRange: String
}

enum ContentError: LocalizedError {
    case fileNotFound(String)
    case bookNotFound(String)
    case chapterNotFound(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "内容文件未找到: \(name)"
        case .bookNotFound(let id):
            return "书籍不存在: \(id)"
        case .chapterNotFound(let id):
            return "章节不存在: \(id)"
        case .decodingFailed(let error):
            return "内容解析失败: \(error.localizedDescription)"
        }
    }
}
