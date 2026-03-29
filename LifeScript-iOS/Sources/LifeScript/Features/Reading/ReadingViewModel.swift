import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ReadingViewModel {

    // MARK: - State

    enum ViewState {
        case loading
        case reading
        case choosing(ChoiceNode)
        case chapterEnd
        case error(String)
    }

    private(set) var state: ViewState = .loading
    private(set) var book: Book
    private(set) var currentChapter: Chapter?
    private(set) var displayedNodes: [StoryNode] = []
    private(set) var currentNodeIndex: Int = 0
    private(set) var stats: ProtagonistStats
    private(set) var relationships: [RelationshipState]
    private(set) var chapterChoices: [UserChoiceRecord] = []
    private(set) var selectedChoiceIds: [String: String] = [:]
    private(set) var statsBeforeChapter: ProtagonistStats
    private(set) var relationshipsBeforeChapter: [RelationshipState]
    private(set) var chapterGuide: WalkthroughChapterGuide?
    private(set) var chapterStage: WalkthroughStage?

    private var allChoiceRecords: [UserChoiceRecord] = []
    private var allNodes: [StoryNode] = []
    private var chapterSequence: [Chapter] = []
    private var walkthrough: BookWalkthrough?
    private var preloadedChapters: [Chapter]
    private let contentLoader: ContentProviding
    private var modelContext: ModelContext?
    private var savedProgress: ReadingProgress?

    // MARK: - Init

    init(
        book: Book,
        chapterId: String,
        preloadedChapters: [Chapter] = [],
        preloadedWalkthrough: BookWalkthrough? = nil,
        contentLoader: ContentProviding = BundledContentLoader()
    ) {
        self.book = book
        self.stats = book.initialStats
        self.statsBeforeChapter = book.initialStats
        let initialRelationships = Self.initialRelationships(for: book)
        self.relationships = initialRelationships
        self.relationshipsBeforeChapter = initialRelationships
        self.preloadedChapters = preloadedChapters
        self.contentLoader = contentLoader
        self._pendingChapterId = chapterId
        // 直接注入预加载的 walkthrough，跳过后续 IO
        if let w = preloadedWalkthrough { self.walkthrough = w }
    }

    private var _pendingChapterId: String

    // MARK: - Lifecycle

    func onAppear(modelContext: ModelContext) async {
        self.modelContext = modelContext
        await StoryContentVersioning.reconcilePersistedProgress(
            bookId: book.id,
            contentLoader: contentLoader,
            modelContext: modelContext
        )
        await loadSavedProgress()
        await loadChapter(id: _pendingChapterId)
    }

    // MARK: - Load Chapter

    func loadChapter(id: String) async {
        state = .loading
        do {
            // 优先使用内存中已解码的章节数据，避免重复解析 JSON
            let allChapters: [Chapter]
            if !preloadedChapters.isEmpty {
                allChapters = preloadedChapters
            } else {
                await loadWalkthroughIfNeeded()
                allChapters = (try? await contentLoader.loadAllChapters(bookId: book.id)) ?? []
            }

            guard !allChapters.isEmpty else {
                throw AppError.contentNotFound(id)
            }

            let chapter = allChapters.first(where: { $0.id == id }) ?? allChapters.first!
            let loadedChapters = allChapters

            chapterSequence = loadedChapters.sorted { lhs, rhs in
                if lhs.number == rhs.number {
                    return lhs.id < rhs.id
                }
                return lhs.number < rhs.number
            }
            currentChapter = chapter
            _pendingChapterId = chapter.id
            syncGuide(for: chapter)
            allNodes = chapter.nodes
            displayedNodes = []
            chapterChoices = allChoiceRecords
                .filter { $0.chapterId == chapter.id }
                .sorted { $0.timestamp < $1.timestamp }
            selectedChoiceIds = Dictionary(
                uniqueKeysWithValues: chapterChoices.map { ($0.choiceNodeId, $0.selectedChoiceId) }
            )
            let restoredChapterState = restoredChapterStateIfAvailable(for: chapter)
            if let restoredChapterState {
                currentNodeIndex = restoredChapterState.savedNodeIndex
                statsBeforeChapter = restoredChapterState.startStats
                relationshipsBeforeChapter = restoredChapterState.startRelationships
                displayedNodes = restoredChapterState.displayedNodes
                if currentNodeIndex >= allNodes.count {
                    state = .chapterEnd
                } else if let pendingChoice = pendingChoiceNode(in: displayedNodes) {
                    state = .choosing(pendingChoice)
                } else {
                    state = .reading
                }
            } else {
                currentNodeIndex = 0
                statsBeforeChapter = stats
                relationshipsBeforeChapter = relationships
                state = .reading
                advanceToNextSegment()
            }
        } catch {
            state = .error(AppError.from(error).localizedDescription)
        }
    }

    private func loadWalkthroughIfNeeded() async {
        guard walkthrough == nil else { return }
        walkthrough = try? await contentLoader.loadWalkthrough(bookId: book.id)
    }

    private func syncGuide(for chapter: Chapter) {
        guard let walkthrough else {
            chapterGuide = nil
            chapterStage = nil
            return
        }

        chapterGuide = walkthrough.chapterGuides.first(where: { $0.chapterId == chapter.id })
        if let stageId = chapterGuide?.stageId {
            chapterStage = walkthrough.stages.first(where: { $0.id == stageId })
        } else {
            chapterStage = nil
        }
    }

    // MARK: - Reading Progression

    /// Advances through all narrative content until the next choice node or chapter end.
    /// Only pauses when user input is required (choice) or the chapter is complete.
    func advanceToNextSegment() {
        guard currentNodeIndex < allNodes.count else {
            state = .chapterEnd
            saveProgress()
            return
        }

        while currentNodeIndex < allNodes.count {
            let node = allNodes[currentNodeIndex]

            switch node {
            case .choice(let choiceNode):
                displayedNodes.append(node)
                currentNodeIndex += 1
                state = .choosing(choiceNode)
                saveProgress()
                return

            case .text, .dialogue, .notification:
                displayedNodes.append(node)
                currentNodeIndex += 1
            }
        }

        if currentNodeIndex >= allNodes.count {
            saveProgress()
        }
        state = .reading
    }

    func tapToAdvance() {
        guard case .reading = state else { return }
        advanceToNextSegment()
    }

    // MARK: - Choice Selection

    func selectChoice(_ choice: Choice, in choiceNode: ChoiceNode) {
        selectedChoiceIds[choiceNode.id] = choice.id

        // Record the choice
        let record = UserChoiceRecord(
            chapterId: currentChapter?.id ?? "",
            choiceNodeId: choiceNode.id,
            selectedChoiceId: choice.id,
            timestamp: Date()
        )
        chapterChoices.removeAll { $0.chapterId == record.chapterId && $0.choiceNodeId == record.choiceNodeId }
        chapterChoices.append(record)
        chapterChoices.sort { $0.timestamp < $1.timestamp }

        allChoiceRecords.removeAll { $0.chapterId == record.chapterId && $0.choiceNodeId == record.choiceNodeId }
        allChoiceRecords.append(record)
        allChoiceRecords.sort { $0.timestamp < $1.timestamp }

        // Apply stat effects
        stats = stats.applying(effects: choice.statEffects)

        // Apply relationship effects
        relationships = relationships.map { rel in
            let effects = choice.relationshipEffects.filter { $0.characterId == rel.characterId }
            guard !effects.isEmpty else { return rel }
            return rel.applying(effects: effects)
        }

        // Show result feedback nodes.
        // Prefer inline scene nodes so choices can play out with actual process.
        if let resultNodes = choice.resultNodes, !resultNodes.isEmpty {
            displayedNodes.append(contentsOf: resultNodes)
        } else if !choice.resultNodeIds.isEmpty {
            let resultTextNode = StoryNode.text(TextNode(
                id: "result_\(choice.id)",
                content: choice.description ?? "",
                emphasis: .dramatic
            ))
            displayedNodes.append(resultTextNode)
        }

        // Show stat change notifications
        for effect in choice.statEffects {
            let sign = effect.delta > 0 ? "+" : ""
            let notification = StoryNode.notification(NotificationNode(
                id: "stat_\(choice.id)_\(effect.stat.rawValue)",
                message: "\(effect.stat.displayName) \(sign)\(effect.delta)",
                type: .statChange
            ))
            displayedNodes.append(notification)
        }

        // Show relationship change notifications
        for effect in choice.relationshipEffects {
            if let char = book.characters.first(where: { $0.id == effect.characterId }) {
                let sign = effect.delta > 0 ? "+" : ""
                let notification = StoryNode.notification(NotificationNode(
                    id: "rel_\(choice.id)_\(effect.characterId)",
                    message: SoloLocalization.format(
                        "%@的%@ %@%d",
                        char.name,
                        effect.dimension.displayName,
                        sign,
                        effect.delta
                    ),
                    type: .relationshipChange
                ))
                displayedNodes.append(notification)
            }
        }

        state = .reading
        saveProgress()

        // Continue advancing
        advanceToNextSegment()
    }

    // MARK: - Branch Rewind

    /// 当前章节内已选过的决策节点（供回溯 UI 列举）
    var completedChoiceNodes: [(index: Int, node: ChoiceNode, chosenText: String)] {
        allNodes.prefix(currentNodeIndex).enumerated().compactMap { index, node in
            guard case .choice(let choiceNode) = node else { return nil }
            guard let chosenId = selectedChoiceIds[choiceNode.id] else { return nil }
            let chosenText = choiceNode.choices.first(where: { $0.id == chosenId })?.text ?? ""
            return (index: index, node: choiceNode, chosenText: chosenText)
        }
    }

    /// 天命值充足（>= 10）才可回溯
    var canRewind: Bool { stats.destiny >= 10 }

    /// 回溯到指定决策节点（消耗 10 点天命值，清除该节点及之后的所有选择）
    func rewindToChoice(nodeIndex: Int) {
        guard let chapter = currentChapter else { return }
        guard nodeIndex < allNodes.count, case .choice(let targetNode) = allNodes[nodeIndex] else { return }

        // 收集从 nodeIndex 起所有已选择节点对应的 Choice 对象
        let laterChoicePairs: [(nodeId: String, choice: Choice)] = allNodes[nodeIndex...].compactMap { node in
            guard case .choice(let cn) = node else { return nil }
            guard let chosenId = selectedChoiceIds[cn.id] else { return nil }
            guard let choice = cn.choices.first(where: { $0.id == chosenId }) else { return nil }
            return (cn.id, choice)
        }
        let laterChoices = laterChoicePairs.map(\.choice)
        let laterNodeIds = laterChoicePairs.map(\.nodeId)

        // 逆向还原 stats 和 relationships
        stats = revertedStats(from: stats, choices: laterChoices)
        relationships = revertedRelationships(from: relationships, choices: laterChoices)

        // 消耗天命值（回溯代价）
        stats = stats.applying(effects: [StatEffect(stat: .destiny, delta: -10)])

        // 清除已选记录
        for id in laterNodeIds { selectedChoiceIds.removeValue(forKey: id) }
        chapterChoices.removeAll { laterNodeIds.contains($0.choiceNodeId) }
        allChoiceRecords.removeAll { record in
            record.chapterId == chapter.id && laterNodeIds.contains(record.choiceNodeId)
        }

        // 重建 displayedNodes（到 nodeIndex 之前的节点 + 回溯目标决策节点本身）
        let remaining = Dictionary(
            uniqueKeysWithValues: selectedChoices(in: chapter).map { ($0.nodeID, $0.choice) }
        )
        displayedNodes = rebuiltDisplayedNodes(until: nodeIndex, selectedChoicesByNodeID: remaining)
        displayedNodes.append(allNodes[nodeIndex])

        currentNodeIndex = nodeIndex + 1
        state = .choosing(targetNode)
        saveProgress()
    }

    // MARK: - Navigation

    func proceedToNextChapter() async {
        guard let next = nextChapter else { return }
        await loadChapter(id: next.id)
    }

    // MARK: - Persistence

    private func loadSavedProgress() async {
        guard let context = modelContext else { return }
        resetRuntimeStateToBookDefaults()
        let bookId = book.id
        let descriptor = FetchDescriptor<ReadingProgress>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        if let progress = try? context.fetch(descriptor).first {
            savedProgress = progress
            _pendingChapterId = progress.currentChapterId
            if let savedStats = progress.stats {
                stats = savedStats
                statsBeforeChapter = savedStats
            }
            if let savedRelationships = progress.relationships {
                relationships = savedRelationships
                relationshipsBeforeChapter = savedRelationships
            }
            if let savedChoices = progress.choiceRecords {
                allChoiceRecords = savedChoices.sorted { $0.timestamp < $1.timestamp }
            }
        }
    }

    private func saveProgress() {
        guard let context = modelContext, let chapter = currentChapter else { return }
        let bookId = book.id
        let descriptor = FetchDescriptor<ReadingProgress>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        let progress: ReadingProgress
        if let existing = try? context.fetch(descriptor).first {
            progress = existing
        } else {
            progress = ReadingProgress(bookId: book.id, currentChapterId: chapter.id)
            context.insert(progress)
        }
        progress.currentChapterId = chapter.id
        progress.currentNodeIndex = currentNodeIndex
        progress.lastReadDate = Date()
        progress.stats = stats
        progress.relationships = relationships
        progress.choiceRecords = allChoiceRecords

        if currentNodeIndex >= allNodes.count {
            if !progress.completedChapterIds.contains(chapter.id) {
                progress.completedChapterIds.append(chapter.id)
            }
        }
        try? context.save()
    }

    private func resetRuntimeStateToBookDefaults() {
        savedProgress = nil
        allChoiceRecords = []
        stats = book.initialStats
        statsBeforeChapter = book.initialStats
        let initialRelationships = Self.initialRelationships(for: book)
        relationships = initialRelationships
        relationshipsBeforeChapter = initialRelationships
    }

    var isAwaitingChapterEndTransition: Bool {
        guard case .reading = state else { return false }
        return currentNodeIndex >= allNodes.count && currentChapter != nil
    }

    var hasNextChapter: Bool {
        nextChapter != nil
    }

    private var nextChapter: Chapter? {
        guard let currentChapter else { return nil }
        guard let currentIndex = chapterSequence.firstIndex(where: { $0.id == currentChapter.id }) else {
            return nil
        }

        let nextIndex = chapterSequence.index(after: currentIndex)
        guard nextIndex < chapterSequence.endIndex else { return nil }
        return chapterSequence[nextIndex]
    }

    private func restoredChapterStateIfAvailable(for chapter: Chapter) -> RestoredChapterState? {
        guard let savedProgress else { return nil }
        guard savedProgress.currentChapterId == chapter.id else { return nil }
        guard savedProgress.currentNodeIndex > 0 else { return nil }

        let savedNodeIndex = min(savedProgress.currentNodeIndex, allNodes.count)
        let selectedChoices = selectedChoices(in: chapter)

        return RestoredChapterState(
            savedNodeIndex: savedNodeIndex,
            displayedNodes: rebuiltDisplayedNodes(
                until: savedNodeIndex,
                selectedChoicesByNodeID: Dictionary(uniqueKeysWithValues: selectedChoices.map { ($0.nodeID, $0.choice) })
            ),
            startStats: revertedStats(
                from: stats,
                choices: selectedChoices.map(\.choice)
            ),
            startRelationships: revertedRelationships(
                from: relationships,
                choices: selectedChoices.map(\.choice)
            )
        )
    }

    private func selectedChoices(in chapter: Chapter) -> [(nodeID: String, choice: Choice)] {
        let choiceRecordMap = Dictionary(uniqueKeysWithValues: chapterChoices.map { ($0.choiceNodeId, $0) })

        return chapter.nodes.compactMap { node in
            guard case .choice(let choiceNode) = node else { return nil }
            guard let record = choiceRecordMap[choiceNode.id] else { return nil }
            guard let choice = choiceNode.choices.first(where: { $0.id == record.selectedChoiceId }) else { return nil }
            return (choiceNode.id, choice)
        }
    }

    private func pendingChoiceNode(in nodes: [StoryNode]) -> ChoiceNode? {
        for node in nodes.reversed() {
            guard case .choice(let choiceNode) = node else { continue }
            if selectedChoiceIds[choiceNode.id] == nil {
                return choiceNode
            }
        }
        return nil
    }

    private func rebuiltDisplayedNodes(
        until savedNodeIndex: Int,
        selectedChoicesByNodeID: [String: Choice]
    ) -> [StoryNode] {
        var rebuilt: [StoryNode] = []

        for node in allNodes.prefix(savedNodeIndex) {
            rebuilt.append(node)

            guard case .choice(let choiceNode) = node else { continue }
            guard let choice = selectedChoicesByNodeID[choiceNode.id] else { continue }
            rebuilt.append(contentsOf: feedbackNodes(for: choice))
        }

        return rebuilt
    }

    private func revertedStats(from current: ProtagonistStats, choices: [Choice]) -> ProtagonistStats {
        choices.reversed().reduce(current) { partial, choice in
            partial.applying(effects: choice.statEffects.map {
                StatEffect(stat: $0.stat, delta: -$0.delta)
            })
        }
    }

    private func revertedRelationships(from current: [RelationshipState], choices: [Choice]) -> [RelationshipState] {
        choices.reversed().reduce(current) { partial, choice in
            partial.map { relation in
                let reverseEffects = choice.relationshipEffects
                    .filter { $0.characterId == relation.characterId }
                    .map {
                        RelationshipEffect(
                            characterId: $0.characterId,
                            dimension: $0.dimension,
                            delta: -$0.delta
                        )
                    }
                guard !reverseEffects.isEmpty else { return relation }
                return relation.applying(effects: reverseEffects)
            }
        }
    }

    private func feedbackNodes(for choice: Choice) -> [StoryNode] {
        var nodes: [StoryNode] = []

        if let resultNodes = choice.resultNodes, !resultNodes.isEmpty {
            nodes.append(contentsOf: resultNodes)
        } else if !choice.resultNodeIds.isEmpty {
            nodes.append(
                .text(TextNode(
                    id: "result_\(choice.id)",
                    content: choice.description ?? "",
                    emphasis: .dramatic
                ))
            )
        }

        for effect in choice.statEffects {
            let sign = effect.delta > 0 ? "+" : ""
            nodes.append(
                .notification(NotificationNode(
                    id: "stat_\(choice.id)_\(effect.stat.rawValue)",
                    message: "\(effect.stat.rawValue) \(sign)\(effect.delta)",
                    type: .statChange
                ))
            )
        }

        for effect in choice.relationshipEffects {
            guard let char = book.characters.first(where: { $0.id == effect.characterId }) else { continue }
            let sign = effect.delta > 0 ? "+" : ""
            nodes.append(
                .notification(NotificationNode(
                    id: "rel_\(choice.id)_\(effect.characterId)",
                    message: "\(char.name)的\(effect.dimension.rawValue) \(sign)\(effect.delta)",
                    type: .relationshipChange
                ))
            )
        }

        return nodes
    }

    private static func initialRelationships(for book: Book) -> [RelationshipState] {
        book.characters.map { char in
            RelationshipState(
                characterId: char.id,
                trust: 30,
                affection: 20,
                hostility: 10,
                awe: 10,
                dependence: 0,
                lastChangeReason: nil,
                unlockedEvents: []
            )
        }
    }
}

private struct RestoredChapterState {
    let savedNodeIndex: Int
    let displayedNodes: [StoryNode]
    let startStats: ProtagonistStats
    let startRelationships: [RelationshipState]
}
