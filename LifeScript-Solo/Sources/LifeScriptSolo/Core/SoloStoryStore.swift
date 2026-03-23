import Foundation
import Observation

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
        completedChapterCount == 0 ? "开始这一局" : "继续推进"
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

    let storyId: String

    private let contentLoader: ContentProviding

    private(set) var state: LoadState = .idle
    private(set) var book: Book?
    private(set) var chapters: [Chapter] = []
    private(set) var walkthrough: BookWalkthrough?

    init(
        storyId: String = SoloStoryConfig.storyId,
        contentLoader: ContentProviding = BundledContentLoader()
    ) {
        self.storyId = storyId
        self.contentLoader = contentLoader
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        state = .loading

        do {
            let loadedBook = try await contentLoader.loadBook(id: storyId)
            let loadedChapters = try await contentLoader.loadAllChapters(bookId: storyId)
                .sorted { lhs, rhs in
                    if lhs.number == rhs.number {
                        return lhs.id < rhs.id
                    }
                    return lhs.number < rhs.number
                }

            book = loadedBook
            chapters = loadedChapters
            walkthrough = try await contentLoader.loadWalkthrough(bookId: storyId)
            state = .ready
        } catch {
            NSLog("‼️ SoloStoryStore load error: %@", String(describing: error))
            state = .error(String(describing: error))
        }
    }

    func resumeChapterId(progress: ReadingProgress?) -> String? {
        if let progress {
            return progress.currentChapterId
        }
        return chapters.first?.id
    }

    func progressSummary(progress: ReadingProgress?) -> SoloProgressSummary {
        let currentChapter = currentChapter(progress: progress)
        let completedChapterIDs = completedChapterIDs(progress: progress)

        return SoloProgressSummary(
            currentChapterTitle: currentChapter?.title ?? "序章未定",
            currentChapterNumber: currentChapter?.number ?? 1,
            completedChapterCount: completedChapterIDs.count,
            totalChapterCount: chapters.count
        )
    }

    func entrySnapshot(progress: ReadingProgress?) -> SoloEntrySnapshot {
        let branding = SoloStoryConfig.branding
        let progressSummary = progressSummary(progress: progress)
        let currentChapter = currentChapter(progress: progress)
        let currentGuide = guide(forChapterID: currentChapter?.id) ?? walkthrough?.chapterGuides.first
        let currentStage = stage(for: currentGuide) ?? walkthrough?.stages.first
        let recapGuide = recapGuide(progress: progress)
        let experienceStats = entryExperienceStats(
            book: book,
            walkthrough: walkthrough,
            branding: branding
        )

        return SoloEntrySnapshot(
            branding: branding,
            progress: progressSummary,
            currentStageTitle: currentStage?.title ?? "故事已开场",
            currentStageSummary: currentStage?.summary ?? branding.atmosphereLine,
            currentObjective: currentGuide?.objective ?? "继续推进主线，别让上一章留下的因果冷掉。",
            currentObjectiveSummary: currentGuide?.publicSummary ?? branding.continueHint,
            recapSummary: recapGuide?.publicSummary,
            hiddenRouteHint: currentGuide?.hiddenRouteHint,
            visibleRouteTitles: currentGuide?.visibleRoutes.map(\.title) ?? [],
            currentIdentityValue: identityValue(for: progressSummary, stageTitle: currentStage?.title),
            destinyStatusLine: currentGuide?.objective ?? currentStage?.summary ?? branding.continueHint,
            hookLine: currentChapter?.nextChapterHook ?? currentGuide?.hiddenRouteHint ?? branding.landing.hookBody,
            experienceStats: experienceStats
        )
    }

    func routeMapSnapshot(progress: ReadingProgress?) -> SoloRouteMapSnapshot {
        let currentChapter = currentChapter(progress: progress)
        let currentGuide = guide(forChapterID: currentChapter?.id)

        return SoloRouteMapSnapshot(
            currentChapterID: currentChapter?.id,
            currentStageID: currentGuide?.stageId,
            completedChapterIDs: completedChapterIDs(progress: progress)
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
        let currentChapterID = progress?.currentChapterId ?? chapters.first?.id
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
            return "第 \(progressSummary.currentChapterNumber) \(SoloStoryConfig.branding.chapterUnitName) · \(stageTitle)"
        }
        return "第 \(progressSummary.currentChapterNumber) \(SoloStoryConfig.branding.chapterUnitName)"
    }

    private func entryExperienceStats(
        book: Book?,
        walkthrough: BookWalkthrough?,
        branding: SoloBranding
    ) -> [SoloEntryExperienceStat] {
        let totalChapters = book?.totalChapters ?? chapters.count
        let totalRoutes = walkthrough?.chapterGuides.reduce(0) { partialResult, guide in
            partialResult + guide.visibleRoutes.count
        } ?? 0
        let totalCharacters = book?.characters.count ?? 0
        let totalInteractions = walkthrough?.chapterGuides.reduce(0) { partialResult, guide in
            partialResult + guide.interactionCount
        } ?? 0

        return [
            SoloEntryExperienceStat(id: "chapter-scale", title: "章节规模", valueText: "\(totalChapters) \(branding.chapterUnitName)"),
            SoloEntryExperienceStat(id: "route-scale", title: "公开分路", valueText: "\(totalRoutes) 条"),
            SoloEntryExperienceStat(id: "character-scale", title: "关键人物", valueText: "\(totalCharacters) 人"),
            SoloEntryExperienceStat(id: "interaction-scale", title: "交互密度", valueText: "\(totalInteractions) 次"),
        ]
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
        relation.trust + relation.affection + relation.awe - relation.hostility + relation.dependence
    }

    private func dossierModules(
        for book: Book,
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
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
        switch book.genre {
        case .cultivation:
            return [
                SoloDossierStatCard(id: "combat", title: "剑势", value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: "声名", value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: "机锋", value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: "灵资", value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: "气度", value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: "心魇", value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: "天命", value: stats.destiny, tint: .emberGold),
            ]
        case .businessWar:
            return [
                SoloDossierStatCard(id: "combat", title: "压制力", value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: "声望", value: stats.fame, tint: .sapphireMist),
                SoloDossierStatCard(id: "strategy", title: "筹谋", value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: "资本", value: stats.wealth, tint: .emberGold),
                SoloDossierStatCard(id: "charm", title: "游说", value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: "代价", value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: "风向", value: stats.destiny, tint: .sapphireMist),
            ]
        case .suspenseSurvival:
            return [
                SoloDossierStatCard(id: "combat", title: "求生", value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: "暴露", value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: "判断", value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: "物资", value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: "说服", value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: "污染", value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: "直觉", value: stats.destiny, tint: .emberGold),
            ]
        case .apocalypsePower:
            return [
                SoloDossierStatCard(id: "combat", title: "战备", value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: "声噪", value: stats.fame, tint: .royalPlum),
                SoloDossierStatCard(id: "strategy", title: "决断", value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: "补给", value: stats.wealth, tint: .sapphireMist),
                SoloDossierStatCard(id: "charm", title: "凝聚", value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: "异化", value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: "火种", value: stats.destiny, tint: .emberGold),
            ]
        case .urbanReversal:
            return [
                SoloDossierStatCard(id: "combat", title: "锋芒", value: stats.combat, tint: .emberGold),
                SoloDossierStatCard(id: "fame", title: "牌面", value: stats.fame, tint: .sapphireMist),
                SoloDossierStatCard(id: "strategy", title: "手段", value: stats.strategy, tint: .moonJade),
                SoloDossierStatCard(id: "wealth", title: "底气", value: stats.wealth, tint: .emberGold),
                SoloDossierStatCard(id: "charm", title: "拿捏", value: stats.charm, tint: .moonJade),
                SoloDossierStatCard(id: "darkness", title: "反噬", value: stats.darkness, tint: .royalPlum),
                SoloDossierStatCard(id: "destiny", title: "势头", value: stats.destiny, tint: .sapphireMist),
            ]
        }
    }

    private func cultivationModules(
        stats: ProtagonistStats,
        relationships: [RelationshipState]
    ) -> [SoloDossierModuleCard] {
        let trustedCount = relationships.filter { $0.trust >= 60 || $0.affection >= 60 }.count
        return [
            SoloDossierModuleCard(
                id: "realmMomentum",
                title: "境界势能",
                valueText: "\(stats.combat + stats.destiny)",
                detailText: "战力与天命正在共同抬升你的破境势能，黑化值越高，后续代价越重。",
                tint: .emberGold
            ),
            SoloDossierModuleCard(
                id: "karmaNetwork",
                title: "人脉因果",
                valueText: "\(trustedCount) 条稳固线",
                detailText: "真正能替你挡劫的不是嘴上的盟友，而是高信任与高敬畏叠起来的关系。",
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "fameStake",
                title: "名望与筹码",
                valueText: "\(stats.fame + stats.wealth + stats.strategy)",
                detailText: "名望决定你是否被看见，财富和谋略决定你被看见之后有没有资格继续压局。",
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
                title: "杠杆总量",
                valueText: "\(leverage)",
                detailText: "真正有用的不是你手里有什么，而是你能逼对方以为你还有什么。",
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "boardTrust",
                title: "牌桌信号",
                valueText: "\(relationships.filter { $0.trust >= 55 }.count) 人偏向你",
                detailText: "高信任并不一定可靠，但低信任一定会在关键回合动摇。",
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "risk",
                title: "反噬风险",
                valueText: "\(stats.darkness + relationships.map(\.hostility).reduce(0, +))",
                detailText: "你压住的敌意越多，后面需要付出的切割成本就越大。",
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
                title: "威胁浓度",
                valueText: "\(threatScore)",
                detailText: "敌意与黑化并行升高时，说明危险不只在外面，也开始向你体内渗透。",
                tint: .royalPlum
            ),
            SoloDossierModuleCard(
                id: "clarity",
                title: "线索清晰度",
                valueText: "\(stats.strategy + stats.destiny)",
                detailText: "谋略与直觉越高，越能在碎片信息里看见真正的因果链。",
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "anchors",
                title: "安全锚点",
                valueText: "\(relationships.filter { $0.trust >= 60 }.count) 个",
                detailText: "在高压故事里，能否找到真正的安全锚点，比一时赢一局更重要。",
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
                title: "避难区承压",
                valueText: "\(pressureScore)",
                detailText: "越多人知道你手里握着钥匙，越多人会把恐惧和怨气一起压到你身上。",
                tint: .royalPlum
            ),
            SoloDossierModuleCard(
                id: "teamSignal",
                title: "队伍信号",
                valueText: "\(trustCount) 条稳定线",
                detailText: "真正能陪你熬过断电夜的，不是嘴上说愿意，而是在高压下仍愿意跟着你的人。",
                tint: .moonJade
            ),
            SoloDossierModuleCard(
                id: "survivalLeverage",
                title: "生存筹码",
                valueText: "\(leverage)",
                detailText: "补给、判断和那点还没熄掉的火种，决定你接下来是守住秩序，还是被局势反咬。",
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
                title: "翻盘势能",
                valueText: "\(stats.combat + stats.strategy)",
                detailText: "翻盘从来不是一拳打回去，而是你在对方以为稳了的时候突然反过来控局。",
                tint: .emberGold
            ),
            SoloDossierModuleCard(
                id: "socialCapital",
                title: "场面筹码",
                valueText: "\(socialCapital)",
                detailText: "名望、魅力和财富共同决定你在公开场面上的压制力。",
                tint: .sapphireMist
            ),
            SoloDossierModuleCard(
                id: "supporters",
                title: "站队倾向",
                valueText: "\(relationships.filter { $0.trust + $0.affection > $0.hostility + 20 }.count) 人",
                detailText: "站队不是口头支持，而是对方在关键节点是否愿意替你付代价。",
                tint: .moonJade
            )
        ]
    }
}
