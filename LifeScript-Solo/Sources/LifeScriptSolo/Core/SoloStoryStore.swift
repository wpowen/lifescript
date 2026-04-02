import Foundation
import Observation
import SwiftData

struct SoloWelcomeStage: Equatable {
    let id: String
    let title: String
    let detail: String
    let progressThreshold: Double
}

struct SoloWelcomeSnapshot: Equatable {
    let title: String
    let author: String
    let eyebrow: String
    let headline: String
    let detail: String
    let progress: Double
    let generatedChapterCount: Int
    let plannedChapterCount: Int
    let stages: [SoloWelcomeStage]
}

struct SoloProgressSummary: Equatable {
    let currentChapterTitle: String
    let currentChapterNumber: Int
    let completedChapterCount: Int
    let totalChapterCount: Int

    var completionRatio: Double {
        guard totalChapterCount > 0 else { return 0 }
        return Double(completedChapterCount) / Double(totalChapterCount)
    }

    var actionTitle: String {
        completedChapterCount == 0
            ? SoloLocalization.localized("开始这一局")
            : SoloLocalization.localized("继续推进")
    }
}

@MainActor
@Observable
final class SoloStoryStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case error(String)
    }

    enum LoadingPhase: Equatable {
        case idle
        case openingCodex
        case unfoldingChapters
        case chartingRoutes
        case ready

        var progress: Double {
            switch self {
            case .idle:
                return 0.10
            case .openingCodex:
                return 0.28
            case .unfoldingChapters:
                return 0.68
            case .chartingRoutes:
                return 0.88
            case .ready:
                return 1.0
            }
        }
    }

    let storyId: String

    private let contentLoader: ContentProviding

    private(set) var state: LoadState = .idle
    private(set) var loadingPhase: LoadingPhase = .idle
    private(set) var book: Book?
    private(set) var chapters: [Chapter] = []
    private(set) var walkthrough: BookWalkthrough?

    init(
        storyId: String = SoloStoryConfig.storyId,
        contentLoader: ContentProviding = BundledContentLoader()
    ) {
        self.storyId = storyId
        self.contentLoader = contentLoader
        // 提前启动加载，与首帧渲染并行，避免视图出现后才触发 IO
        Task { await loadIfNeeded() }
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        state = .loading

        do {
            loadingPhase = .openingCodex
            let loadedBook = try await contentLoader.loadBook(id: storyId)
            book = loadedBook

            loadingPhase = .unfoldingChapters
            let loadedChapters = try await contentLoader.loadAllChapters(bookId: storyId)
                .sorted { lhs, rhs in
                    if lhs.number == rhs.number {
                        return lhs.id < rhs.id
                    }
                    return lhs.number < rhs.number
                }

            chapters = loadedChapters

            loadingPhase = .chartingRoutes
            walkthrough = try await contentLoader.loadWalkthrough(bookId: storyId)
            loadingPhase = .ready
            state = .ready
        } catch {
            NSLog("‼️ SoloStoryStore load error: %@", String(describing: error))
            state = .error(String(describing: error))
        }
    }

    func reconcilePersistedProgress(in context: ModelContext) async {
        await StoryContentVersioning.reconcilePersistedProgress(
            bookId: storyId,
            contentLoader: contentLoader,
            modelContext: context
        )
    }

    var welcomeSnapshot: SoloWelcomeSnapshot {
        let branding = SoloStoryConfig.branding
        let generatedChapterCount = chapters.count
        let plannedChapterCount = latestChapterTotal

        let headline: String
        let detail: String

        switch loadingPhase {
        case .idle:
            headline = SoloLocalization.localized("命局将启")
            detail = SoloLocalization.localized("正在唤醒天机录的底稿与人物命盘。")
        case .openingCodex:
            headline = SoloLocalization.localized("正在校准命书")
            detail = SoloLocalization.localized("先把书卷、人物与世界法则接入当前这局，让欢迎页先稳稳亮起来。")
        case .unfoldingChapters:
            headline = SoloLocalization.localized("正在展开章节")
            detail = generatedChapterCount > 0
                ? SoloLocalization.format("已接入 %d 章当前版本内容，首开不再重复扫整包章节。", generatedChapterCount)
                : SoloLocalization.localized("正在把当前版本章节接入这一局。")
        case .chartingRoutes:
            headline = SoloLocalization.localized("正在描摹命途")
            detail = SoloLocalization.localized("把阶段、暗线和人物牵引整理成可读的命途图，不让路线信息再压住正文。")
        case .ready:
            headline = SoloLocalization.localized("命局已就绪")
            detail = SoloLocalization.localized("天机台已经稳定，可以正式入局。")
        }

        return SoloWelcomeSnapshot(
            title: book.map { SoloLocalization.localized($0.title) } ?? branding.storyDisplayName,
            author: book.map { SoloLocalization.localized($0.author) } ?? SoloLocalization.localized("命书工作室"),
            eyebrow: branding.entryEyebrow,
            headline: headline,
            detail: detail,
            progress: loadingPhase.progress,
            generatedChapterCount: generatedChapterCount,
            plannedChapterCount: plannedChapterCount,
            stages: [
                SoloWelcomeStage(
                    id: "codex",
                    title: SoloLocalization.localized("命书唤醒"),
                    detail: SoloLocalization.localized("先接入书卷与人物法则。"),
                    progressThreshold: 0.22
                ),
                SoloWelcomeStage(
                    id: "chapters",
                    title: SoloLocalization.localized("章节展开"),
                    detail: SoloLocalization.localized("把当前已生成章节接入本局。"),
                    progressThreshold: 0.60
                ),
                SoloWelcomeStage(
                    id: "routes",
                    title: SoloLocalization.localized("命途校准"),
                    detail: SoloLocalization.localized("整理阶段、人心与暗线。"),
                    progressThreshold: 0.90
                ),
            ]
        )
    }

    func resumeChapterId(progress: ReadingProgress?) -> String? {
        if let progress, chapters.contains(where: { $0.id == progress.currentChapterId }) {
            return progress.currentChapterId
        }
        return chapters.first?.id
    }

    func progressSummary(progress: ReadingProgress?) -> SoloProgressSummary {
        let currentChapter = currentChapter(progress: progress)
        let completedChapterIDs = completedChapterIDs(progress: progress)

        return SoloProgressSummary(
            currentChapterTitle: currentChapter?.title ?? SoloLocalization.localized("序章未定"),
            currentChapterNumber: currentChapter?.number ?? 1,
            completedChapterCount: completedChapterIDs.count,
            totalChapterCount: latestChapterTotal
        )
    }

    func entrySnapshot(progress: ReadingProgress?) -> SoloEntrySnapshot {
        let branding = SoloStoryConfig.branding
        let progressSummary = progressSummary(progress: progress)
        let currentChapter = currentChapter(progress: progress)
        let currentGuide = guide(forChapterID: currentChapter?.id) ?? walkthrough?.chapterGuides.first
        let currentStage = stage(for: currentGuide) ?? walkthrough?.stages.first
        let recapGuide = recapGuide(progress: progress)
        let stats = currentStats(progress: progress)
        let generatedChapterCount = chapters.count
        let plannedChapterCount = plannedChapterTotal
        let experienceStats = entryExperienceStats(
            book: book,
            walkthrough: walkthrough,
            branding: branding
        )

        return SoloEntrySnapshot(
            branding: branding,
            progress: progressSummary,
            generatedChapterCount: generatedChapterCount,
            plannedChapterCount: plannedChapterCount,
            currentStageTitle: currentStage?.title ?? SoloLocalization.localized("故事已开场"),
            currentStageSummary: currentStage?.summary ?? branding.atmosphereLine,
            currentObjective: currentGuide?.objective ?? SoloLocalization.localized("继续推进主线，别让上一章留下的因果冷掉。"),
            currentObjectiveSummary: currentGuide?.publicSummary ?? branding.continueHint,
            recapSummary: recapGuide?.publicSummary,
            hiddenRouteHint: currentGuide?.hiddenRouteHint,
            visibleRouteTitles: currentGuide?.visibleRoutes.map(\.title) ?? [],
            currentIdentityValue: identityValue(for: progressSummary, stageTitle: currentStage?.title),
            destinyStatusLine: currentGuide?.objective ?? currentStage?.summary ?? branding.continueHint,
            serialReleaseLine: serialReleaseLine(
                generatedChapterCount: generatedChapterCount,
                currentStageTitle: currentStage?.title
            ),
            destinyStatus: makeDestinyStatus(for: stats),
            hookLine: currentChapter?.nextChapterHook ?? currentGuide?.hiddenRouteHint ?? branding.landing.hookBody,
            experienceStats: experienceStats,
            worldStatDeltas: worldStatDeltas(progress: progress),
            worldCharacters: worldCharacterStatuses(progress: progress)
        )
    }

    func routeMapSnapshot(progress: ReadingProgress?) -> SoloRouteMapSnapshot {
        let currentChapter = currentChapter(progress: progress)
        let currentGuide = guide(forChapterID: currentChapter?.id)
        let stats = currentStats(progress: progress)

        return SoloRouteMapSnapshot(
            currentChapterID: currentChapter?.id,
            currentStageID: currentGuide?.stageId,
            currentStageTitle: stage(for: currentGuide).map { SoloLocalization.localized($0.title) },
            currentObjective: currentGuide?.objective,
            generatedChapterCount: chapters.count,
            plannedChapterCount: plannedChapterTotal,
            destinyStatus: makeDestinyStatus(for: stats),
            completedChapterIDs: completedChapterIDs(progress: progress)
        )
    }

    func routeMapHubSnapshot(progress: ReadingProgress?) -> SoloRouteMapHubSnapshot {
        let routeSnapshot = routeMapSnapshot(progress: progress)
        let relationships = currentRelationships(progress: progress)
        let darklineSnapshot = darklineBoardSnapshot(progress: progress)
        let heartSnapshot = humanHeartsSnapshot(progress: progress)
        let stageTitle = routeSnapshot.currentStageTitle ?? SoloLocalization.localized("迷雾初开")
        let objective = routeSnapshot.currentObjective ?? SoloLocalization.localized("继续推进眼前章节，新的征兆会在行动后显形。")
        let stageLine = SoloLocalization.format("当前命局停在「%@」，你已经走完 %d 章。", stageTitle, routeSnapshot.completedChapterIDs.count)
        let pressureLine = darklineSnapshot.discoveredSignals.isEmpty
            ? SoloLocalization.localized("暗线仍在潜伏，先稳住当前局面。")
            : SoloLocalization.format("已有 %d 条异动露头，别让节奏被暗线牵走。", darklineSnapshot.discoveredSignals.count)
        let destinySummary = SoloLocalization.format("天命值 %d · %@", routeSnapshot.destinyStatus.value, routeSnapshot.destinyStatus.thresholdHint)
        let stageProgress = SoloLocalization.format("%d / %d %@", routeSnapshot.generatedChapterCount, routeSnapshot.plannedChapterCount, SoloStoryConfig.branding.chapterUnitName)

        return SoloRouteMapHubSnapshot(
            currentObjective: objective,
            stageLine: stageLine,
            pressureLine: pressureLine,
            destinySummary: destinySummary,
            destinyStatus: routeSnapshot.destinyStatus,
            destinyCard: SoloRouteMapHubCard(
                id: "destiny",
                title: SoloLocalization.localized("命途"),
                subtitle: SoloLocalization.localized("看已行之路、眼前棋局与将至征兆"),
                statusLine: SoloLocalization.format("当前阶段：%@ · 显形进度 %@", stageTitle, stageProgress),
                badge: routeSnapshot.currentStageTitle == nil ? SoloLocalization.localized("待显形") : SoloLocalization.localized("在局中"),
                callToAction: SoloLocalization.localized("进入命途推演")
            ),
            heartsCard: SoloRouteMapHubCard(
                id: "hearts",
                title: SoloLocalization.localized("人心"),
                subtitle: SoloLocalization.localized("看谁已入局、谁可试探、谁需警惕"),
                statusLine: heartSnapshot.spotlightLine,
                badge: SoloLocalization.format("%d 人在局", relationships.count),
                callToAction: SoloLocalization.localized("进入人心盘")
            ),
            darklineCard: SoloRouteMapHubCard(
                id: "darkline",
                title: SoloLocalization.localized("暗线"),
                subtitle: SoloLocalization.localized("看异动、疑云与未显形缺口"),
                statusLine: darklineSnapshot.boardLine,
                badge: SoloLocalization.format("%d 已识别", darklineSnapshot.discoveredSignals.count),
                callToAction: SoloLocalization.localized("进入暗线观测")
            )
        )
    }

    func destinyAtlasSnapshot(progress: ReadingProgress?) -> SoloDestinyAtlasSnapshot {
        let routeSnapshot = routeMapSnapshot(progress: progress)
        let completedIDs = routeSnapshot.completedChapterIDs
        let currentStageID = routeSnapshot.currentStageID
        let stageNodes = (walkthrough?.stages ?? []).map { stage in
            let completedCount = stage.chapterIds.filter { completedIDs.contains($0) }.count
            let isCurrent = stage.id == currentStageID
            let isPassed = completedCount == stage.chapterIds.count && !stage.chapterIds.isEmpty
            let isUnlocked = isCurrent || completedCount > 0
            let visibility: SoloDestinyStageNode.Visibility
            if isPassed {
                visibility = .passed
            } else if isCurrent {
                visibility = .current
            } else if isUnlocked {
                visibility = .current
            } else {
                visibility = .veiled
            }

            return SoloDestinyStageNode(
                id: stage.id,
                title: isUnlocked ? SoloLocalization.localized(stage.title) : SoloLocalization.localized("未显形阶段"),
                summary: isUnlocked ? SoloLocalization.localized(stage.summary) : SoloLocalization.localized("你只能感知这段命途存在，仍看不清它的真相。"),
                visibility: visibility,
                completedChapterCount: completedCount,
                totalChapterCount: stage.chapterIds.count
            )
        }

        let currentStageTitle = routeSnapshot.currentStageTitle ?? SoloLocalization.localized("迷雾初开")
        let currentGuide = guide(forChapterID: routeSnapshot.currentChapterID)
        let omenLine = currentGuide?.hiddenRouteHint ?? SoloLocalization.localized("继续推进当前章节，新的征兆会浮出水面。")
        let progressLine = SoloLocalization.format("已显形 %d / %d %@", routeSnapshot.generatedChapterCount, routeSnapshot.plannedChapterCount, SoloStoryConfig.branding.chapterUnitName)

        return SoloDestinyAtlasSnapshot(
            stageNodes: stageNodes,
            currentStageTitle: currentStageTitle,
            omenLine: omenLine,
            pressureLine: routeSnapshot.destinyStatus.detail,
            progressLine: progressLine
        )
    }

    func humanHeartsSnapshot(progress: ReadingProgress?) -> SoloHumanHeartsSnapshot {
        guard let book else {
            return SoloHumanHeartsSnapshot(
                spotlightLine: SoloLocalization.localized("局中人物尚未载入。"),
                pressureLine: SoloLocalization.localized("暂无可分析人心信号。"),
                rings: []
            )
        }

        let relationships = currentRelationships(progress: progress)
        let relationshipByID = Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })

        var inPlay: [String] = []
        var testable: [String] = []
        var dangerous: [String] = []
        var veiled: [String] = []

        for character in book.characters {
            guard let relation = relationshipByID[character.id] else {
                veiled.append(character.id)
                continue
            }
            let vigilance = relation.value(for: .vigilance)
            let curiosity = relation.value(for: .curiosity)
            let hasMoved = relation.lastChangeReason != nil

            if relation.hostility >= 50 || vigilance >= 45 {
                dangerous.append(character.id)
            } else if relation.trust >= 55 || hasMoved {
                inPlay.append(character.id)
            } else if curiosity >= 42 || relation.awe >= 40 {
                testable.append(character.id)
            } else {
                veiled.append(character.id)
            }
        }

        let rings: [SoloHeartRing] = [
            SoloHeartRing(
                id: "in-play",
                title: SoloLocalization.localized("已入局"),
                subtitle: SoloLocalization.localized("这些人会直接反馈你的落子。"),
                characterIDs: inPlay
            ),
            SoloHeartRing(
                id: "testable",
                title: SoloLocalization.localized("可试探"),
                subtitle: SoloLocalization.localized("可以先用低成本动作探边界。"),
                characterIDs: testable
            ),
            SoloHeartRing(
                id: "dangerous",
                title: SoloLocalization.localized("需警惕"),
                subtitle: SoloLocalization.localized("这批关系已带有明显对抗或防备。"),
                characterIDs: dangerous
            ),
            SoloHeartRing(
                id: "veiled",
                title: SoloLocalization.localized("尚未看透"),
                subtitle: SoloLocalization.localized("轮廓已在，但真实立场还未显形。"),
                characterIDs: veiled
            )
        ]

        let spotlight = relationships.max(by: { spotlightScore(lhs: $0) < spotlightScore(lhs: $1) })
        let spotlightLine: String
        if let spotlight,
           let character = book.characters.first(where: { $0.id == spotlight.characterId }) {
            spotlightLine = SoloLocalization.format("%@目前最容易牵动局势，态度落在「%@」。", character.name, spotlight.attitudeLabel)
        } else {
            spotlightLine = SoloLocalization.localized("人心线索仍浅，继续推进互动后再回看。")
        }

        let pressureLine = dangerous.isEmpty
            ? SoloLocalization.localized("目前没有明显失控的人心风险。")
            : SoloLocalization.format("至少 %d 条关系处在高警惕区，优先止损。", dangerous.count)

        return SoloHumanHeartsSnapshot(
            spotlightLine: spotlightLine,
            pressureLine: pressureLine,
            rings: rings
        )
    }

    func darklineBoardSnapshot(progress: ReadingProgress?) -> SoloDarklineBoardSnapshot {
        let routeSnapshot = routeMapSnapshot(progress: progress)
        let guides = walkthrough?.chapterGuides ?? []
        let stageByID = Dictionary(uniqueKeysWithValues: (walkthrough?.stages ?? []).map { ($0.id, $0) })
        let chapterByID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        let completedIDs = completedChapterIDs(progress: progress)
        let currentStageID = routeSnapshot.currentStageID
        let currentChapterID = routeSnapshot.currentChapterID

        var discovered: [SoloDarklineSignal] = []
        var approaching: [SoloDarklineSignal] = []
        var hiddenSignalCount = 0

        for guide in guides {
            guard let hint = guide.hiddenRouteHint else { continue }
            hiddenSignalCount += 1

            let stageTitle = stageByID[guide.stageId].map { SoloLocalization.localized($0.title) } ?? SoloLocalization.localized("未知阶段")
            let chapterTitle = chapterByID[guide.chapterId].map { SoloLocalization.localized($0.title) } ?? SoloLocalization.localized("未知章节")

            if completedIDs.contains(guide.chapterId) {
                discovered.append(
                    SoloDarklineSignal(
                        id: guide.chapterId,
                        title: SoloLocalization.localized("已识别异动"),
                        hint: hint,
                        sourceStageTitle: stageTitle,
                        sourceChapterTitle: chapterTitle,
                        state: .discovered
                    )
                )
                continue
            }

            if guide.chapterId == currentChapterID || guide.stageId == currentStageID {
                approaching.append(
                    SoloDarklineSignal(
                        id: guide.chapterId,
                        title: SoloLocalization.localized("正在逼近"),
                        hint: approachingDarklineHint(stageTitle: stageTitle, chapterTitle: chapterTitle),
                        sourceStageTitle: stageTitle,
                        sourceChapterTitle: chapterTitle,
                        state: .approaching
                    )
                )
            }
        }

        let sealedCount = max(0, hiddenSignalCount - discovered.count - approaching.count)
        let boardLine: String
        if discovered.isEmpty && approaching.isEmpty {
            boardLine = SoloLocalization.localized("暗线仍在水下，你还没有抓住它的尾迹。")
        } else if discovered.isEmpty {
            boardLine = SoloLocalization.format("你已经感觉到 %d 股异动逼近，但还不能直接看穿它。", approaching.count)
        } else {
            boardLine = SoloLocalization.format("你已识别 %d 条暗线尾迹，眼前还有 %d 股异动正在逼近。", discovered.count, approaching.count)
        }

        return SoloDarklineBoardSnapshot(
            discoveredSignals: discovered,
            approachingSignals: approaching,
            sealedCount: sealedCount,
            totalSignalCount: hiddenSignalCount,
            boardLine: boardLine,
            destinyStatus: routeSnapshot.destinyStatus
        )
    }

    func dossierSnapshot(
        book: Book,
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> SoloDossierSnapshot {
        let moduleCards = dossierModules(for: book, stats: stats, relationships: relationships)
        let spotlight = relationshipSpotlight(book: book, relationships: relationships)

        return SoloDossierSnapshot(
            statCards: dossierStatCards(for: book, stats: stats),
            moduleCards: moduleCards,
            destinyStatus: makeDestinyStatus(for: stats),
            relationshipSpotlight: spotlight
        )
    }

    func currentStats(progress: ReadingProgress?) -> ProtagonistStats {
        progress?.stats ?? book?.initialStats ?? .initial
    }

    func currentRelationships(progress: ReadingProgress?) -> [RelationshipState] {
        if let relationships = progress?.relationships {
            return relationships
        }
        guard let book else { return [] }
        return Self.defaultRelationships(for: book)
    }

    static func defaultRelationships(for book: Book) -> [RelationshipState] {
        book.characters.map { character in
            RelationshipState(
                characterId: character.id,
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

    private func currentChapter(progress: ReadingProgress?) -> Chapter? {
        let currentChapterID = resumeChapterId(progress: progress)
        return chapters.first(where: { $0.id == currentChapterID }) ?? chapters.first
    }

    private func guide(forChapterID chapterID: String?) -> WalkthroughChapterGuide? {
        guard let chapterID else { return nil }
        return walkthrough?.chapterGuides.first(where: { $0.chapterId == chapterID })
    }

    private func stage(for guide: WalkthroughChapterGuide?) -> WalkthroughStage? {
        guard let stageID = guide?.stageId else { return nil }
        return walkthrough?.stages.first(where: { $0.id == stageID })
    }

    private func recapGuide(progress: ReadingProgress?) -> WalkthroughChapterGuide? {
        guard let progress else { return nil }

        let completedIDs = completedChapterIDs(progress: progress)

        if let lastCompletedChapterID = mostRecentCompletedChapterID(from: completedIDs),
           lastCompletedChapterID != progress.currentChapterId,
           let completedGuide = guide(forChapterID: lastCompletedChapterID) {
            return completedGuide
        }

        guard let currentChapter = currentChapter(progress: progress) else { return nil }
        guard currentChapter.number > 1 else { return nil }
        let previousChapter = chapters.first(where: { $0.number == currentChapter.number - 1 })
        return guide(forChapterID: previousChapter?.id)
    }

    private func completedChapterIDs(progress: ReadingProgress?) -> Set<String> {
        guard let progress else { return [] }

        var completedIDs = Set(progress.completedChapterIds)

        if let currentChapter = chapters.first(where: { $0.id == progress.currentChapterId }),
           progress.currentNodeIndex >= currentChapter.nodes.count {
            completedIDs.insert(currentChapter.id)
        }

        return completedIDs
    }

    private func identityValue(for progressSummary: SoloProgressSummary, stageTitle: String?) -> String {
        if let stageTitle {
            return SoloLocalization.format("第 %d %@ · %@", progressSummary.currentChapterNumber, SoloStoryConfig.branding.chapterUnitName, stageTitle)
        }
        return SoloLocalization.format("第 %d %@", progressSummary.currentChapterNumber, SoloStoryConfig.branding.chapterUnitName)
    }

    private func entryExperienceStats(
        book: Book?,
        walkthrough: BookWalkthrough?,
        branding: SoloBranding
    ) -> [SoloEntryExperienceStat] {
        let totalChapters = latestChapterTotal
        let totalRoutes = walkthrough?.chapterGuides.reduce(0) { partialResult, guide in
            partialResult + guide.visibleRoutes.count
        } ?? 0
        let totalCharacters = book?.characters.count ?? 0
        let totalInteractions = walkthrough?.chapterGuides.reduce(0) { partialResult, guide in
            partialResult + guide.interactionCount
        } ?? 0

        return [
            SoloEntryExperienceStat(id: "chapter-scale", title: SoloLocalization.localized("章节规模"), valueText: "\(totalChapters) \(branding.chapterUnitName)"),
            SoloEntryExperienceStat(id: "route-scale", title: SoloLocalization.localized("公开分路"), valueText: SoloLocalization.format("%d 条", totalRoutes)),
            SoloEntryExperienceStat(id: "character-scale", title: SoloLocalization.localized("关键人物"), valueText: SoloLocalization.format("%d 人", totalCharacters)),
            SoloEntryExperienceStat(id: "interaction-scale", title: SoloLocalization.localized("交互密度"), valueText: SoloLocalization.format("%d 次", totalInteractions)),
        ]
    }

    private func worldStatDeltas(progress: ReadingProgress?) -> [SoloWorldStatDelta] {
        guard let book, progress != nil else { return [] }
        let current = currentStats(progress: progress)
        let initial = book.initialStats
        let diff = current.diff(from: initial)
        return diff
            .sorted { abs($0.value) > abs($1.value) }
            .prefix(3)
            .map { statType, delta in
                SoloWorldStatDelta(
                    name: statType.rawValue,
                    value: current.value(for: statType),
                    delta: delta
                )
            }
    }

    private func worldCharacterStatuses(progress: ReadingProgress?) -> [SoloWorldCharacterStatus] {
        guard let book else { return [] }
        let relationships = currentRelationships(progress: progress)
        return relationships
            .sorted { spotlightScore(lhs: $0) > spotlightScore(lhs: $1) }
            .prefix(2)
            .compactMap { relation -> SoloWorldCharacterStatus? in
                guard let character = book.characters.first(where: { $0.id == relation.characterId }) else { return nil }
                return SoloWorldCharacterStatus(
                    characterId: character.id,
                    name: character.name,
                    attitudeLabel: relation.attitudeLabel
                )
            }
    }

    private func mostRecentCompletedChapterID(from completedIDs: Set<String>) -> String? {
        chapters
            .filter { completedIDs.contains($0.id) }
            .max(by: { $0.number < $1.number })?
            .id
    }

    private func relationshipSpotlight(
        book: Book,
        relationships: [RelationshipState]
    ) -> SoloRelationshipSpotlight? {
        guard let relation = relationships.max(by: { spotlightScore(lhs: $0) < spotlightScore(lhs: $1) }) else {
            return nil
        }
        guard let character = book.characters.first(where: { $0.id == relation.characterId }) else {
            return nil
        }

        return SoloRelationshipSpotlight(
            characterName: character.name,
            characterTitle: character.title,
            attitudeLabel: relation.attitudeLabel,
            reason: relation.lastChangeReason
        )
    }

    private func spotlightScore(lhs relation: RelationshipState) -> Int {
        relation.prominentDimensions
            .prefix(3)
            .reduce(0) { partialResult, element in
                partialResult + abs(element.1)
            }
    }

    private func approachingDarklineHint(stageTitle: String, chapterTitle: String) -> String {
        SoloLocalization.format(
            "你只能确认这股异动与「%@ / %@」有关，真相仍藏在水面之下。继续推进后，它才会把真正的轮廓露出来。",
            stageTitle,
            chapterTitle
        )
    }

    private var plannedChapterTotal: Int {
        latestChapterTotal
    }

    private var latestChapterTotal: Int {
        max(book?.totalChapters ?? 0, chapters.count)
    }

    private func serialReleaseLine(
        generatedChapterCount: Int,
        currentStageTitle: String?
    ) -> String {
        if generatedChapterCount <= 0 {
            return SoloLocalization.localized("当前版本内容接入中，马上就能完整进入这一局。")
        }

        if let currentStageTitle {
            return SoloLocalization.format(
                "当前版本内容已就绪，共 %d 章，当前命途从「%@」继续展开。",
                generatedChapterCount,
                currentStageTitle
            )
        }

        return SoloLocalization.format(
            "当前版本内容已就绪，共 %d 章，你可以直接进入并完整推进这一局。",
            generatedChapterCount
        )
    }

    private func makeDestinyStatus(for stats: ProtagonistStats) -> SoloDestinyStatus {
        if stats.destiny <= 15 || (stats.destiny <= 28 && stats.darkness >= 45) {
            return SoloDestinyStatus(
                level: .critical,
                headline: SoloLocalization.localized("命火将熄"),
                detail: SoloLocalization.localized("天命值已经压到危险区，再硬推一次，反噬几乎会直接贴脸。"),
                value: stats.destiny,
                thresholdHint: SoloLocalization.localized("低于 20 时优先止损，谨慎动用天机录")
            )
        }

        if stats.destiny <= 35 || stats.darkness >= 60 {
            return SoloDestinyStatus(
                level: .strained,
                headline: SoloLocalization.localized("反噬逼近"),
                detail: SoloLocalization.localized("还能继续布局，但每次窥天都在加速消耗后手，最好先回收天命再做大动作。"),
                value: stats.destiny,
                thresholdHint: SoloLocalization.localized("保持 35 以上更稳，避免连续高风险选择")
            )
        }

        if stats.destiny <= 65 {
            return SoloDestinyStatus(
                level: .steady,
                headline: SoloLocalization.localized("命局平衡"),
                detail: SoloLocalization.localized("局面仍在可控区，适合试探、借势和有限回溯，但还不到可以随意烧牌的时候。"),
                value: stats.destiny,
                thresholdHint: SoloLocalization.localized("40-65 适合谨慎落子，优先确认收益")
            )
        }

        return SoloDestinyStatus(
            level: .abundant,
            headline: SoloLocalization.localized("天命充盈"),
            detail: SoloLocalization.localized("你手里的天机还够用，既能提前落子，也能承受几次关键试探。"),
            value: stats.destiny,
            thresholdHint: SoloLocalization.localized("70 以上适合主动试探，但仍要藏锋")
        )
    }

    private func dossierModules(
        for book: Book,
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        if book.id == "天机录" {
            return tianjiluModules(stats: stats, relationships: relationships)
        }

        switch book.genre {
        case .cultivation:
            return cultivationModules(stats: stats, relationships: relationships)
        case .businessWar:
            return businessWarModules(stats: stats, relationships: relationships)
        case .suspenseSurvival:
            return suspenseModules(stats: stats, relationships: relationships)
        case .apocalypsePower:
            return apocalypseModules(stats: stats, relationships: relationships)
        case .urbanReversal:
            return urbanReversalModules(stats: stats, relationships: relationships)
        }
    }

    private func dossierStatCards(for book: Book, stats: ProtagonistStats) -> [SoloDossierStatCard] {
        if book.id == "天机录" {
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("落子"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("牌面"), value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("机锋"), value: stats.strategy, tint: .oracleJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("残页"), value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("人心"), value: stats.charm, tint: .oracleJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("心魇"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("天命"), value: stats.destiny, tint: .emberGold),
            ]
        }

        switch book.genre {
        case .cultivation:
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("剑势"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("声名"), value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("机锋"), value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("灵资"), value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("气度"), value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("心魇"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("天命"), value: stats.destiny, tint: .emberGold),
            ]
        case .businessWar:
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("压制力"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("声望"), value: stats.fame, tint: .sapphireMist),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("筹谋"), value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("资本"), value: stats.wealth, tint: .emberGold),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("游说"), value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("代价"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("风向"), value: stats.destiny, tint: .sapphireMist),
            ]
        case .suspenseSurvival:
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("求生"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("暴露"), value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("判断"), value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("物资"), value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("说服"), value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("污染"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("直觉"), value: stats.destiny, tint: .emberGold),
            ]
        case .apocalypsePower:
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("战备"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("声噪"), value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("决断"), value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("补给"), value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("凝聚"), value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("异化"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("火种"), value: stats.destiny, tint: .emberGold),
            ]
        case .urbanReversal:
            return [
                SoloDossierStatCard(id: "combat", title: SoloLocalization.localized("锋芒"), value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: SoloLocalization.localized("牌面"), value: stats.fame, tint: .sapphireMist),
                SoloDossierStatCard(id: "strategy", title: SoloLocalization.localized("手段"), value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: SoloLocalization.localized("底气"), value: stats.wealth, tint: .emberGold),
                SoloDossierStatCard(id: "charm", title: SoloLocalization.localized("拿捏"), value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: SoloLocalization.localized("反噬"), value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: SoloLocalization.localized("势头"), value: stats.destiny, tint: .sapphireMist),
            ]
        }
    }

    private func tianjiluModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let stableThreads = relationships.filter {
            $0.trust >= 58 || $0.value(for: .curiosity) >= 55
        }.count
        let hostilityPressure =
            relationships.map(\.hostility).reduce(0, +) +
            relationships.map { $0.value(for: .vigilance) }.reduce(0, +)
        let hiddenPull = stats.strategy + stats.destiny + stats.wealth

        return [
            SoloDossierModuleCard(
                id: "tianji-buffer",
                title: SoloLocalization.localized("天机余裕"),
                valueText: "\(stats.destiny + stats.strategy)",
                detailText: SoloLocalization.localized("天命越高，你越能提前窥一步；机锋越足，你越能把这一步伪装成顺势而为。"),
                tint: .emberGold
            ),
            SoloDossierModuleCard(
                id: "tianji-threads",
                title: SoloLocalization.localized("关系阈值"),
                valueText: SoloLocalization.format("%d 条可牵引线", stableThreads),
                detailText: SoloLocalization.localized("真正关键的不是绝对好感，而是谁既愿意信你、又还没完全看穿你。"),
                tint: .oracleJade
            ),
            SoloDossierModuleCard(
                id: "tianji-pressure",
                title: SoloLocalization.localized("暗线牵引"),
                valueText: "\(hiddenPull + hostilityPressure)",
                detailText: SoloLocalization.localized("残页、机锋与人心正在一起拖动暗线。你手里的筹码越多，盯着你的人也越多。"),
                tint: .royalPlum
            )
        ]
    }

    private func cultivationModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let trustedCount = relationships.filter { $0.trust >= 60 || $0.affection >= 60 }.count
        return [
            SoloDossierModuleCard(
                id: "realmMomentum",
                title: SoloLocalization.localized("境界势能"),
                valueText: "\(stats.combat + stats.destiny)",
                detailText: SoloLocalization.localized("战力与天命正在共同抬升你的破境势能，黑化值越高，后续代价越重。"),
                tint: .emberGold
            ),
            SoloDossierModuleCard(
                id: "karmaNetwork",
                title: SoloLocalization.localized("人脉因果"),
                valueText: SoloLocalization.format("%d 条稳固线", trustedCount),
                detailText: SoloLocalization.localized("真正能替你挡劫的不是嘴上的盟友，而是高信任与高敬畏叠起来的关系。"),
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "fameStake",
                title: SoloLocalization.localized("名望与筹码"),
                valueText: "\(stats.fame + stats.wealth + stats.strategy)",
                detailText: SoloLocalization.localized("名望决定你是否被看见，财富和谋略决定你被看见之后有没有资格继续压局。"),
                tint: .royalPlum
            )
        ]
    }

    private func businessWarModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let leverage = stats.strategy + stats.wealth + stats.fame
        return [
            SoloDossierModuleCard(
                id: "leverage",
                title: SoloLocalization.localized("杠杆总量"),
                valueText: "\(leverage)",
                detailText: SoloLocalization.localized("真正有用的不是你手里有什么，而是你能逼对方以为你还有什么。"),
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "boardTrust",
                title: SoloLocalization.localized("牌桌信号"),
                valueText: SoloLocalization.format("%d 人偏向你", relationships.filter { $0.trust >= 55 }.count),
                detailText: SoloLocalization.localized("高信任并不一定可靠，但低信任一定会在关键回合动摇。"),
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "risk",
                title: SoloLocalization.localized("反噬风险"),
                valueText: "\(stats.darkness + relationships.map(\.hostility).reduce(0, +))",
                detailText: SoloLocalization.localized("你压住的敌意越多，后面需要付出的切割成本就越大。"),
                tint: .royalPlum
            )
        ]
    }

    private func suspenseModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let threatScore = stats.darkness + relationships.map(\.hostility).reduce(0, +)
        return [
            SoloDossierModuleCard(
                id: "threat",
                title: SoloLocalization.localized("威胁浓度"),
                valueText: "\(threatScore)",
                detailText: SoloLocalization.localized("敌意与黑化并行升高时，说明危险不只在外面，也开始向你体内渗透。"),
                tint: .royalPlum
            ),
            SoloDossierModuleCard(
                id: "clarity",
                title: SoloLocalization.localized("线索清晰度"),
                valueText: "\(stats.strategy + stats.destiny)",
                detailText: SoloLocalization.localized("谋略与直觉越高，越能在碎片信息里看见真正的因果链。"),
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "anchors",
                title: SoloLocalization.localized("安全锚点"),
                valueText: SoloLocalization.format("%d 个", relationships.filter { $0.trust >= 60 }.count),
                detailText: SoloLocalization.localized("在高压故事里，能否找到真正的安全锚点，比一时赢一局更重要。"),
                tint: .moonJade
            )
        ]
    }

    private func apocalypseModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let pressureScore = stats.darkness + stats.fame + relationships.map(\.hostility).reduce(0, +)
        let trustCount = relationships.filter { $0.trust >= 60 || $0.dependence >= 25 }.count
        let leverage = stats.strategy + stats.wealth + stats.destiny

        return [
            SoloDossierModuleCard(
                id: "zonePressure",
                title: SoloLocalization.localized("避难区承压"),
                valueText: "\(pressureScore)",
                detailText: SoloLocalization.localized("越多人知道你手里握着钥匙，越多人会把恐惧和怨气一起压到你身上。"),
                tint: .royalPlum
            ),
            SoloDossierModuleCard(
                id: "teamSignal",
                title: SoloLocalization.localized("队伍信号"),
                valueText: SoloLocalization.format("%d 条稳定线", trustCount),
                detailText: SoloLocalization.localized("真正能陪你熬过断电夜的，不是嘴上说愿意，而是在高压下仍愿意跟着你的人。"),
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "survivalLeverage",
                title: SoloLocalization.localized("生存筹码"),
                valueText: "\(leverage)",
                detailText: SoloLocalization.localized("补给、判断和那点还没熄掉的火种，决定你接下来是守住秩序，还是被局势反咬。"),
                tint: .emberGold
            )
        ]
    }

    private func urbanReversalModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let socialCapital = stats.fame + stats.charm + stats.wealth
        return [
            SoloDossierModuleCard(
                id: "momentum",
                title: SoloLocalization.localized("翻盘势能"),
                valueText: "\(stats.combat + stats.strategy)",
                detailText: SoloLocalization.localized("翻盘从来不是一拳打回去，而是你在对方以为稳了的时候突然反过来控局。"),
                tint: .emberGold
            ),
            SoloDossierModuleCard(
                id: "socialCapital",
                title: SoloLocalization.localized("场面筹码"),
                valueText: "\(socialCapital)",
                detailText: SoloLocalization.localized("名望、魅力和财富共同决定你在公开场面上的压制力。"),
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "supporters",
                title: SoloLocalization.localized("站队倾向"),
                valueText: SoloLocalization.format("%d 人", relationships.filter { $0.trust + $0.affection > $0.hostility + 20 }.count),
                detailText: SoloLocalization.localized("站队不是口头支持，而是对方在关键节点是否愿意替你付代价。"),
                tint: .moonJade
            )
        ]
    }
}
