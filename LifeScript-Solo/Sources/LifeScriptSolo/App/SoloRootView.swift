import SwiftUI
import SwiftData

struct SoloRootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SoloLocalization.storageKey) private var appLanguageRawValue = SoloAppLanguage.system.rawValue
    @State private var coordinator = SoloCoordinator()
    @State private var storyStore = SoloStoryStore()
    @State private var volumeStore = SoloVolumeStore()
    @State private var welcomeComplete = false
    @State private var countdownSeconds: Int = SoloRootView.welcomeDuration
    @Query(sort: \ReadingProgress.lastReadDate, order: .reverse)
    private var progressList: [ReadingProgress]

    private static let welcomeDuration = 3

    private var progress: ReadingProgress? {
        progressList.first(where: { $0.bookId == storyStore.storyId })
    }

    private var isReady: Bool {
        if case .ready = storyStore.state { return true }
        return false
    }

    private var errorMessage: String? {
        if case .error(let msg) = storyStore.state { return msg }
        return nil
    }

    private var appLanguage: SoloAppLanguage {
        SoloAppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            ZStack {
                SoloBackdrop()

                if let message = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(SoloTheme.crimson)
                        Text(SoloLocalization.localized("故事装载失败"))
                            .font(.title2.weight(.semibold))
                        Text(message)
                            .foregroundStyle(SoloTheme.muted)
                            .multilineTextAlignment(.center)
                        Button(SoloLocalization.localized("重新装载")) {
                            Task { await storyStore.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SoloTheme.gold)
                    }
                    .padding(24)
                    .soloCard()
                    .padding(.horizontal, 24)
                } else if isReady && welcomeComplete, let book = storyStore.book {
                    SoloEntryView(
                        book: book,
                        snapshot: storyStore.entrySnapshot(progress: progress),
                        readingRoute: currentReadingRoute,
                        openDossier: { coordinator.open(.dossier) },
                        openRouteMap: { coordinator.open(.routeMap) },
                        openSettings: { coordinator.open(.settings) },
                        openChapterBrowser: { coordinator.open(.chapterBrowser) }
                    )
                    .transition(.opacity)
                } else {
                    SoloWelcomeView(
                        snapshot: storyStore.welcomeSnapshot,
                        countdownSeconds: countdownSeconds,
                        onSkip: { finishWelcome() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: isReady && welcomeComplete)
            .navigationDestination(for: SoloRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environment(coordinator)
        .environment(\.locale, appLanguage.locale)
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await storyStore.loadIfNeeded() }
                group.addTask { await volumeStore.loadIfNeeded() }
                group.addTask { @MainActor in
                    await runCountdown()
                }
                await group.waitForAll()
            }
            await storyStore.reconcilePersistedProgress(in: modelContext)
            finishWelcome()
        }
        .onChange(of: appLanguageRawValue) { _, _ in
            coordinator.popToRoot()
            Task {
                await storyStore.reload()
            }
        }
    }

    /// 每秒递减倒计时，到 0 后自然结束
    @MainActor
    private func runCountdown() async {
        for tick in (0..<SoloRootView.welcomeDuration).reversed() {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            countdownSeconds = tick
        }
    }

    private func finishWelcome() {
        guard !welcomeComplete else { return }
        welcomeComplete = true
    }

    @ViewBuilder
    private func destinationView(for route: SoloRoute) -> some View {
        if let book = storyStore.book {
            switch route {
            case .reading(let chapterId):
                readingView(for: book, chapterId: chapterId)

            case .volumeGate(let chapterId):
                if let chapter = storyStore.chapters.first(where: { $0.id == chapterId }),
                   let lockedVolume = chapterAccessState(for: chapterId).volume,
                   chapterAccessState(for: chapterId).isLocked {
                    SoloVolumePaywallView(
                        book: book,
                        chapter: chapter,
                        volume: lockedVolume,
                        volumeStore: volumeStore,
                        onContinue: {
                            coordinator.pop()
                            coordinator.open(.reading(chapterId))
                        },
                        onClose: { coordinator.pop() }
                    )
                } else {
                    readingView(for: book, chapterId: chapterId)
                }

            case .chapterBrowser:
                SoloChapterBrowserView(
                    chapters: storyStore.chapters,
                    volumeStore: volumeStore,
                    currentChapterId: storyStore.resumeChapterId(progress: progress)
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
                SoloRouteMapView(
                    book: book,
                    progressSummary: storyStore.progressSummary(progress: progress),
                    routeSnapshot: storyStore.routeMapSnapshot(progress: progress),
                    hubSnapshot: storyStore.routeMapHubSnapshot(progress: progress),
                    openDestinyAtlas: { coordinator.open(.destinyAtlas) },
                    openHumanHearts: { coordinator.open(.humanHearts) },
                    openDarklineBoard: { coordinator.open(.darklineBoard) }
                )

            case .destinyAtlas:
                SoloDestinyAtlasView(
                    book: book,
                    snapshot: storyStore.destinyAtlasSnapshot(progress: progress),
                    destinyStatus: storyStore.routeMapSnapshot(progress: progress).destinyStatus
                )

            case .humanHearts:
                let heartRelationships = storyStore.currentRelationships(progress: progress)
                SoloHumanHeartsView(
                    book: book,
                    relationships: heartRelationships,
                    snapshot: storyStore.humanHeartsSnapshot(progress: progress),
                    destinyStatus: storyStore.routeMapSnapshot(progress: progress).destinyStatus
                )

            case .darklineBoard:
                SoloDarklineBoardView(
                    book: book,
                    snapshot: storyStore.darklineBoardSnapshot(progress: progress)
                )

            case .settings:
                SoloSettingsView(book: book, volumeStore: volumeStore)
            }
        } else {
            EmptyView()
        }
    }

    private var currentReadingRoute: SoloRoute? {
        guard let resumeChapterId = storyStore.resumeChapterId(progress: progress) else {
            return nil
        }

        if let lockedChapterId = pendingLockedChapterId(after: resumeChapterId) {
            return .volumeGate(lockedChapterId)
        }

        return routeForChapter(resumeChapterId)
    }

    @ViewBuilder
    private func readingView(for book: Book, chapterId: String) -> some View {
        SoloReadingView(
            book: book,
            chapterId: chapterId,
            preloadedChapters: storyStore.chapters,
            preloadedWalkthrough: storyStore.walkthrough,
            chapterAccessState: chapterAccessState(for:),
            openLockedChapter: { lockedChapterId in
                coordinator.open(.volumeGate(lockedChapterId))
            },
            openDossier: { coordinator.open(.dossier) },
            openRouteMap: { coordinator.open(.routeMap) },
            returnToHome: { coordinator.popToRoot() }
        )
    }

    private func routeForChapter(_ chapterId: String) -> SoloRoute {
        let accessState = chapterAccessState(for: chapterId)
        return accessState.isLocked ? .volumeGate(chapterId) : .reading(chapterId)
    }

    private func chapterAccessState(for chapterId: String) -> SoloChapterAccessState {
        guard let chapter = storyStore.chapters.first(where: { $0.id == chapterId }) else {
            return SoloChapterAccessState(
                chapterId: chapterId,
                isLocked: false,
                volume: nil,
                primaryActionTitle: "",
                supportingLine: nil
            )
        }

        return volumeStore.chapterAccessState(
            chapterId: chapter.id,
            chapterNumber: chapter.number
        )
    }

    private func pendingLockedChapterId(after chapterId: String) -> String? {
        guard let progress,
              let currentChapter = storyStore.chapters.first(where: { $0.id == chapterId }),
              progress.currentChapterId == currentChapter.id,
              progress.currentNodeIndex >= currentChapter.nodes.count,
              let nextChapter = nextChapter(after: currentChapter.id)
        else {
            return nil
        }

        return chapterAccessState(for: nextChapter.id).isLocked ? nextChapter.id : nil
    }

    private func nextChapter(after chapterId: String) -> Chapter? {
        guard let currentIndex = storyStore.chapters.firstIndex(where: { $0.id == chapterId }) else {
            return nil
        }

        let nextIndex = storyStore.chapters.index(after: currentIndex)
        guard nextIndex < storyStore.chapters.endIndex else { return nil }
        return storyStore.chapters[nextIndex]
    }
}
