import SwiftUI
import SwiftData

struct SoloRootView: View {
    @State private var coordinator = SoloCoordinator()
    @State private var storyStore = SoloStoryStore()
    @Query(sort: \ReadingProgress.lastReadDate, order: .reverse)
    private var progressList: [ReadingProgress]

    private var progress: ReadingProgress? {
        progressList.first(where: { $0.bookId == storyStore.storyId })
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            ZStack {
                SoloBackdrop()

                switch storyStore.state {
                case .idle, .loading:
                    ProgressView("正在装载当前作品")
                        .tint(SoloTheme.gold)
                        .foregroundStyle(SoloTheme.ink)
                case .error(let message):
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(SoloTheme.crimson)
                        Text("故事装载失败")
                            .font(.title2.weight(.semibold))
                        Text(message)
                            .foregroundStyle(SoloTheme.muted)
                            .multilineTextAlignment(.center)
                        Button("重新装载") {
                            Task { await storyStore.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SoloTheme.gold)
                    }
                    .padding(24)
                    .soloCard()
                    .padding(.horizontal, 24)
                case .ready:
                    if let book = storyStore.book {
                        SoloEntryView(
                            book: book,
                            snapshot: storyStore.entrySnapshot(progress: progress),
                            openReading: openReading,
                            openDossier: { coordinator.open(.dossier) },
                            openRouteMap: { coordinator.open(.routeMap) },
                            openSettings: { coordinator.open(.settings) }
                        )
                    }
                }
            }
            .navigationDestination(for: SoloRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environment(coordinator)
        .task { await storyStore.loadIfNeeded() }
    }

    @ViewBuilder
    private func destinationView(for route: SoloRoute) -> some View {
        if let book = storyStore.book {
            switch route {
            case .reading(let chapterId):
                SoloReadingView(
                    book: book,
                    chapterId: chapterId,
                    openDossier: { coordinator.open(.dossier) },
                    openRouteMap: { coordinator.open(.routeMap) },
                    returnToHome: { coordinator.popToRoot() }
                )

            case .dossier:
                let currentStats = storyStore.currentStats(progress: progress)
                let currentRelationships = storyStore.currentRelationships(progress: progress)
                SoloDossierView(
                    book: book,
                    relationships: currentRelationships,
                    snapshot: storyStore.dossierSnapshot(
                        book: book,
                        stats: currentStats,
                        relationships: currentRelationships
                    )
                )

            case .routeMap:
                let routeRelationships = storyStore.currentRelationships(progress: progress)
                SoloRouteMapView(
                    book: book,
                    walkthrough: storyStore.walkthrough,
                    progressSummary: storyStore.progressSummary(progress: progress),
                    routeSnapshot: storyStore.routeMapSnapshot(progress: progress),
                    relationships: routeRelationships
                )

            case .settings:
                SoloSettingsView()
            }
        } else {
            EmptyView()
        }
    }

    private func openReading() {
        guard let chapterId = storyStore.resumeChapterId(progress: progress) else { return }
        coordinator.open(.reading(chapterId))
    }
}
