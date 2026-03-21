import Foundation

struct BookWalkthrough: Codable, Sendable {
    let bookId: String
    let title: String
    let stages: [WalkthroughStage]
    let chapterGuides: [WalkthroughChapterGuide]
}

struct WalkthroughStage: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let chapterIds: [String]
}

struct WalkthroughChapterGuide: Codable, Identifiable, Sendable {
    var id: String { chapterId }

    let chapterId: String
    let stageId: String
    let publicSummary: String
    let objective: String
    let estimatedMinutes: Int
    let interactionCount: Int
    let visibleRoutes: [WalkthroughRoute]
    let hiddenRouteHint: String?
}

struct WalkthroughRoute: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let style: String
    let unlockHint: String
    let payoff: String
    let processFocus: String
}
