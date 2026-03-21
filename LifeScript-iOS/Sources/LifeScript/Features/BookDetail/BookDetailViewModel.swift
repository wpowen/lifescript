import Foundation
import Observation
import SwiftData

struct RouteDecisionEntry: Identifiable {
    let id: String
    let chapterId: String
    let chapterNumber: Int
    let chapterTitle: String
    let prompt: String
    let choiceText: String
    let choiceSummary: String?
    let choiceType: ChoiceNode.ChoiceType
    let satisfactionType: SatisfactionType
    let statEffects: [StatEffect]
    let relationshipEffects: [RelationshipEffect]
}

struct ChapterRouteSnapshot: Identifiable {
    enum State {
        case conquered
        case active
        case hidden
    }

    let id: String
    let chapter: Chapter
    let state: State
    let decisions: [RouteDecisionEntry]
    let stage: WalkthroughStage?
    let guide: WalkthroughChapterGuide?
}

@Observable
@MainActor
final class BookDetailViewModel {

    let book: Book
    private(set) var chapters: [Chapter] = []
    private(set) var walkthrough: BookWalkthrough?
    private(set) var isLoading = false
    private(set) var hasProgress = false

    private let contentLoader: ContentProviding

    init(book: Book, contentLoader: ContentProviding = BundledContentLoader()) {
        self.book = book
        self.contentLoader = contentLoader
    }

    func onAppear() async {
        isLoading = true
        defer { isLoading = false }
        do {
            chapters = try await contentLoader.loadAllChapters(bookId: book.id)
        } catch {
            // Fail silently for chapter list — book details are still visible
            chapters = []
        }

        walkthrough = try? await contentLoader.loadWalkthrough(bookId: book.id)
    }

    var firstChapterId: String? {
        chapters.first?.id
    }

    func routeEntries(progress: ReadingProgress?) -> [RouteDecisionEntry] {
        guard let records = progress?.choiceRecords, !chapters.isEmpty else { return [] }

        return records
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap(resolveChoiceRecord)
    }

    func chapterSnapshots(progress: ReadingProgress?) -> [ChapterRouteSnapshot] {
        let completedChapterIds = Set(progress?.completedChapterIds ?? [])
        let routeEntriesByChapter = Dictionary(grouping: routeEntries(progress: progress), by: \.chapterId)
        let activeChapterId = progress?.currentChapterId ?? chapters.first?.id
        let guidesByChapterId = Dictionary(uniqueKeysWithValues: (walkthrough?.chapterGuides ?? []).map { ($0.chapterId, $0) })
        let stagesById = Dictionary(uniqueKeysWithValues: (walkthrough?.stages ?? []).map { ($0.id, $0) })

        return chapters.map { chapter in
            let state: ChapterRouteSnapshot.State
            if completedChapterIds.contains(chapter.id) {
                state = .conquered
            } else if chapter.id == activeChapterId {
                state = .active
            } else {
                state = .hidden
            }

            let guide = guidesByChapterId[chapter.id]
            let stage = guide.flatMap { stagesById[$0.stageId] }

            return ChapterRouteSnapshot(
                id: chapter.id,
                chapter: chapter,
                state: state,
                decisions: routeEntriesByChapter[chapter.id] ?? [],
                stage: stage,
                guide: guide
            )
        }
    }

    var publicRouteCount: Int {
        walkthrough?.chapterGuides.reduce(0) { $0 + $1.visibleRoutes.count } ?? 0
    }

    private func resolveChoiceRecord(_ record: UserChoiceRecord) -> RouteDecisionEntry? {
        guard let chapter = chapters.first(where: { $0.id == record.chapterId }) else { return nil }

        for node in chapter.nodes {
            guard case .choice(let choiceNode) = node, choiceNode.id == record.choiceNodeId else { continue }
            guard let choice = choiceNode.choices.first(where: { $0.id == record.selectedChoiceId }) else { continue }

            return RouteDecisionEntry(
                id: record.id,
                chapterId: chapter.id,
                chapterNumber: chapter.number,
                chapterTitle: chapter.title,
                prompt: choiceNode.prompt,
                choiceText: choice.text,
                choiceSummary: choice.description,
                choiceType: choiceNode.choiceType,
                satisfactionType: choice.satisfactionType,
                statEffects: choice.statEffects,
                relationshipEffects: choice.relationshipEffects
            )
        }

        return nil
    }
}
