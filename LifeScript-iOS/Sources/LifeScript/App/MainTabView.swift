import SwiftUI

struct MainTabView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            // Home Tab
            NavigationStack(path: $coordinator.homePath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(AppTab.home)
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }

            // Bookshelf Tab
            NavigationStack(path: $coordinator.bookshelfPath) {
                BookshelfView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(AppTab.bookshelf)
            .tabItem {
                Label(AppTab.bookshelf.title, systemImage: AppTab.bookshelf.icon)
            }

            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tag(AppTab.profile)
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
            }
        }
        .tint(Color.accentGold)
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Destination Builder

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .bookDetail(let book):
            BookDetailView(book: book)
        case .reading(let book, let chapterId):
            ReadingView(book: book, chapterId: chapterId)
        }
    }

    // MARK: - Sheet Builder

    @ViewBuilder
    private func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case .stats(let stats, let previousStats):
            StatsView(stats: stats, previousStats: previousStats)
                .presentationDetents([.large])

        case .relationships(let book, let relationships):
            RelationshipsView(book: book, relationships: relationships)
                .presentationDetents([.large])

        case .chapterSettlement(let book, let chapter, let stats, let previousStats, let relationships, let previousRelationships, let choices):
            ChapterSettlementView(
                book: book,
                chapter: chapter,
                stats: stats,
                previousStats: previousStats,
                relationships: relationships,
                previousRelationships: previousRelationships,
                choices: choices
            )
            .presentationDetents([.large])
        }
    }
}
