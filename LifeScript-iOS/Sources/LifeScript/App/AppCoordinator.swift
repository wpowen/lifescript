import SwiftUI

// MARK: - Navigation Routes

enum AppRoute: Hashable {
    case bookDetail(Book)
    case reading(Book, String)  // Book + chapterId

    func hash(into hasher: inout Hasher) {
        switch self {
        case .bookDetail(let book):
            hasher.combine("bookDetail")
            hasher.combine(book.id)
        case .reading(let book, let chapterId):
            hasher.combine("reading")
            hasher.combine(book.id)
            hasher.combine(chapterId)
        }
    }

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.bookDetail(let a), .bookDetail(let b)):
            return a.id == b.id
        case (.reading(let a1, let a2), .reading(let b1, let b2)):
            return a1.id == b1.id && a2 == b2
        default:
            return false
        }
    }
}

// MARK: - Sheet Routes

enum AppSheet: Identifiable {
    case stats(stats: ProtagonistStats, previousStats: ProtagonistStats)
    case relationships(book: Book, relationships: [RelationshipState])
    case chapterSettlement(
        book: Book,
        chapter: Chapter,
        stats: ProtagonistStats,
        previousStats: ProtagonistStats,
        relationships: [RelationshipState],
        previousRelationships: [RelationshipState],
        choices: [UserChoiceRecord]
    )

    var id: String {
        switch self {
        case .stats: return "stats"
        case .relationships: return "relationships"
        case .chapterSettlement: return "chapterSettlement"
        }
    }
}

// MARK: - Tab

enum AppTab: Int, CaseIterable {
    case home = 0
    case bookshelf = 1
    case profile = 2

    var title: String {
        switch self {
        case .home: return "发现"
        case .bookshelf: return "书架"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: return "compass"
        case .bookshelf: return "books.vertical"
        case .profile: return "person"
        }
    }
}

// MARK: - Coordinator

@Observable
final class AppCoordinator {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var bookshelfPath = NavigationPath()
    var presentedSheet: AppSheet?

    func navigate(to route: AppRoute) {
        switch selectedTab {
        case .home:
            homePath.append(route)
        case .bookshelf:
            bookshelfPath.append(route)
        case .profile:
            homePath.append(route) // Profile can navigate via home path
        }
    }

    func presentSheet(_ sheet: AppSheet) {
        presentedSheet = sheet
    }

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func popToRoot() {
        switch selectedTab {
        case .home:
            homePath = NavigationPath()
        case .bookshelf:
            bookshelfPath = NavigationPath()
        case .profile:
            break
        }
    }
}
