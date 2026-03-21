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

    private var allNodes: [StoryNode] = []
    private var resultNodes: [String: [StoryNode]] = [:] // choiceId -> result nodes
    private let contentLoader: ContentProviding
    private var modelContext: ModelContext?

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
            let chapter = try await contentLoader.loadChapter(bookId: book.id, chapterId: id)
            currentChapter = chapter
            allNodes = chapter.nodes
            displayedNodes = []
            currentNodeIndex = 0
            chapterChoices = []
            statsBeforeChapter = stats
            relationshipsBeforeChapter = relationships
            state = .reading
            advanceToNextNode()
        } catch {
            state = .error(AppError.from(error).localizedDescription)
        }
    }

    // MARK: - Reading Progression

    func advanceToNextNode() {
        guard currentNodeIndex < allNodes.count else {
            state = .chapterEnd
            saveProgress()
            return
        }

        let node = allNodes[currentNodeIndex]
        currentNodeIndex += 1

        switch node {
        case .choice(let choiceNode):
            // Pause on choice — wait for user input
            displayedNodes.append(node)
            state = .choosing(choiceNode)
        case .notification:
            displayedNodes.append(node)
            // Auto-advance after notification
            advanceToNextNode()
        default:
            displayedNodes.append(node)
            state = .reading
        }
    }

    func tapToAdvance() {
        guard case .reading = state else { return }
        advanceToNextNode()
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
        chapterChoices.append(record)

        // Apply stat effects
        stats = stats.applying(effects: choice.statEffects)

        // Apply relationship effects
        relationships = relationships.map { rel in
            let effects = choice.relationshipEffects.filter { $0.characterId == rel.characterId }
            guard !effects.isEmpty else { return rel }
            return rel.applying(effects: effects)
        }

        // Show result feedback nodes
        // Insert result text after the choice node
        if !choice.resultNodeIds.isEmpty {
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
        advanceToNextNode()
    }

    // MARK: - Navigation

    func proceedToNextChapter() async {
        guard let current = currentChapter else { return }
        // Mark current chapter as completed
        let nextNumber = current.number + 1
        do {
            let allChapters = try await contentLoader.loadAllChapters(bookId: book.id)
            if let next = allChapters.first(where: { $0.number == nextNumber }) {
                await loadChapter(id: next.id)
            }
        } catch {
            state = .error("无法加载下一章")
        }
    }

    // MARK: - Persistence

    private func loadSavedProgress() async {
        guard let context = modelContext else { return }
        let bookId = book.id
        let descriptor = FetchDescriptor<ReadingProgress>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        if let progress = try? context.fetch(descriptor).first {
            if let savedStats = progress.stats {
                stats = savedStats
                statsBeforeChapter = savedStats
            }
            if let savedRelationships = progress.relationships {
                relationships = savedRelationships
                relationshipsBeforeChapter = savedRelationships
            }
            if let savedChoices = progress.choiceRecords {
                chapterChoices = savedChoices
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
        progress.choiceRecords = chapterChoices

        if case .chapterEnd = state {
            if !progress.completedChapterIds.contains(chapter.id) {
                progress.completedChapterIds.append(chapter.id)
            }
        }
        try? context.save()
    }
}
