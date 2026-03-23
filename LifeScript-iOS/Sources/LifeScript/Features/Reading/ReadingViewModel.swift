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
    private(set) var statsBeforeChapter: ProtagonistStats
    private(set) var relationshipsBeforeChapter: [RelationshipState]
    private(set) var chapterGuide: WalkthroughChapterGuide?
    private(set) var chapterStage: WalkthroughStage?

    private var allChoiceRecords: [UserChoiceRecord] = []
    private var allNodes: [StoryNode] = []
    private var chapterSequence: [Chapter] = []
    private var walkthrough: BookWalkthrough?
    private let contentLoader: ContentProviding
    private var modelContext: ModelContext?
    private var savedProgress: ReadingProgress?

    // MARK: - Init

    init(
        book: Book,
        chapterId: String,
        contentLoader: ContentProviding = BundledContentLoader()
    ) {
        self.book = book
        self.stats = book.initialStats
        self.statsBeforeChapter = book.initialStats
        let initialRelationships = book.characters.map { char in
            RelationshipState(
                characterId: char.id,
                trust: 30, affection: 20, hostility: 10,
                awe: 10, dependence: 0,
                lastChangeReason: nil,
                unlockedEvents: []
            )
        }
        self.relationships = initialRelationships
        self.relationshipsBeforeChapter = initialRelationships
        self.contentLoader = contentLoader
        self._pendingChapterId = chapterId
    }

    private var _pendingChapterId: String

    // MARK: - Lifecycle

    func onAppear(modelContext: ModelContext) async {
        self.modelContext = modelContext
        await loadSavedProgress()
        await loadChapter(id: _pendingChapterId)
    }

    // MARK: - Load Chapter

    func loadChapter(id: String) async {
        state = .loading
        do {
            await loadWalkthroughIfNeeded()
            let chapter = try await contentLoader.loadChapter(bookId: book.id, chapterId: id)
            let loadedChapters = (try? await contentLoader.loadAllChapters(bookId: book.id)) ?? [chapter]

            chapterSequence = loadedChapters.sorted { lhs, rhs in
                if lhs.number == rhs.number {
                    return lhs.id < rhs.id
                }
                return lhs.number < rhs.number
            }
            currentChapter = chapter
            _pendingChapterId = id
            syncGuide(for: chapter)
            allNodes = chapter.nodes
            displayedNodes = []
            chapterChoices = allChoiceRecords
                .filter { $0.chapterId == chapter.id }
                .sorted { $0.timestamp < $1.timestamp }
            let restoredChapterState = restoredChapterStateIfAvailable(for: chapter)
            if let restoredChapterState {
                currentNodeIndex = restoredChapterState.savedNodeIndex
                statsBeforeChapter = restoredChapterState.startStats
                relationshipsBeforeChapter = restoredChapterState.startRelationships
                displayedNodes = restoredChapterState.displayedNodes
                state = currentNodeIndex >= allNodes.count ? .chapterEnd : .reading
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

    /// Advances to the next logical "segment" of content.
    /// A segment is a group of consecutive nodes displayed together,
    /// stopping at natural pause points for better reading flow.
    func advanceToNextSegment() {
        guard currentNodeIndex < allNodes.count else {
            state = .chapterEnd
            saveProgress()
            return
        }

        var addedCount = 0

        while currentNodeIndex < allNodes.count {
            let node = allNodes[currentNodeIndex]

            switch node {
            case .choice(let choiceNode):
                // Always pause before a choice — user must decide
                if addedCount == 0 {
                    // If this is the first node, show the choice
                    displayedNodes.append(node)
                    currentNodeIndex += 1
                    state = .choosing(choiceNode)
                } else {
                    // Content was already shown; stop here so choice appears on next tap
                    state = .reading
                }
                return

            case .notification:
                // Notifications are always added (they're small inline badges)
                displayedNodes.append(node)
                currentNodeIndex += 1
                addedCount += 1
                // Don't count notifications toward pause logic, keep going

            case .text(let textNode):
                displayedNodes.append(node)
                currentNodeIndex += 1
                addedCount += 1

                // Pause AFTER dramatic or system emphasis text (scene breaks)
                if textNode.emphasis == .dramatic || textNode.emphasis == .system {
                    // But only pause if we've already shown some content
                    // If this is the opening dramatic line, continue to build the scene
                    if addedCount >= 2 {
                        state = .reading
                        return
                    }
                }

            case .dialogue:
                displayedNodes.append(node)
                currentNodeIndex += 1
                addedCount += 1

                // After adding a dialogue, peek ahead:
                // If the next node is NOT dialogue (conversation ended), consider pausing
                if addedCount >= 3, !isNextNodeDialogue {
                    state = .reading
                    return
                }
            }

            // Soft cap: after 5 content nodes (not counting notifications),
            // pause if the next node starts a new "beat"
            let contentCount = addedCount
            if contentCount >= 5 {
                state = .reading
                return
            }
        }

        // If the last readable beat was just appended, let the user read it first.
        // Chapter-end presentation should happen on the next deliberate tap.
        if currentNodeIndex >= allNodes.count {
            saveProgress()
        }
        state = .reading
    }

    /// Peek at the next node without consuming it
    private var isNextNodeDialogue: Bool {
        guard currentNodeIndex < allNodes.count else { return false }
        if case .dialogue = allNodes[currentNodeIndex] { return true }
        return false
    }

    func tapToAdvance() {
        guard case .reading = state else { return }
        advanceToNextSegment()
    }

    // MARK: - Choice Selection

    func selectChoice(_ choice: Choice, in choiceNode: ChoiceNode) {
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
                message: "\(effect.stat.rawValue) \(sign)\(effect.delta)",
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
                    message: "\(char.name)的\(effect.dimension.rawValue) \(sign)\(effect.delta)",
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

    // MARK: - Navigation

    func proceedToNextChapter() async {
        guard let next = nextChapter else { return }
        await loadChapter(id: next.id)
    }

    // MARK: - Persistence

    private func loadSavedProgress() async {
        guard let context = modelContext else { return }
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
}

private struct RestoredChapterState {
    let savedNodeIndex: Int
    let displayedNodes: [StoryNode]
    let startStats: ProtagonistStats
    let startRelationships: [RelationshipState]
}
