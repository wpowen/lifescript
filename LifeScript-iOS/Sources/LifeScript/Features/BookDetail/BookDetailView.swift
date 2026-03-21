import SwiftUI
import SwiftData

struct BookDetailView: View {
    @State private var viewModel: BookDetailViewModel
    @Query private var progressList: [ReadingProgress]

    @Environment(AppCoordinator.self) private var coordinator

    init(book: Book) {
        _viewModel = State(initialValue: BookDetailViewModel(book: book))
    }

    var body: some View {
        ZStack {
            SceneBackdrop(palette: viewModel.book.palette)

            ScrollView {
                VStack(alignment: .leading, spacing: .spacing24) {
                    immersiveHeroSection
                    commandDeckSection
                    routeAtlasSection
                    outcomeSection
                    charactersSection
                    chapterListSection
                }
                .padding(.horizontal, .spacing16)
                .padding(.top, .spacing20)
                .padding(.bottom, .spacing32)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .task { await viewModel.onAppear() }
    }

    private var immersiveHeroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            viewModel.book.palette.primary.opacity(0.40),
                            viewModel.book.palette.secondary.opacity(0.22),
                            Color.surfaceSecondary.opacity(0.96),
                            Color.backgroundSecondary.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 360)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(viewModel.book.palette.tertiary.opacity(0.20))
                        .frame(width: 180)
                        .blur(radius: 24)
                        .offset(x: 40, y: -30)
                }
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                        .strokeBorder(viewModel.book.palette.primary.opacity(0.18), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: .spacing16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: .spacing8) {
                        SceneAccentBadge(text: viewModel.book.sceneSummary, color: viewModel.book.palette.primary)
                        Text("互动式小说 · 沉浸周目")
                            .font(.captionLarge)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    if let currentProgress {
                        SceneAccentBadge(
                            text: "已推进 \(currentProgress.completedChapterIds.count)/\(viewModel.book.totalChapters) 章",
                            color: viewModel.book.palette.secondary
                        )
                    } else {
                        SceneAccentBadge(text: "首周目待开启", color: viewModel.book.palette.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: .spacing10) {
                    Text(viewModel.book.title)
                        .font(.displayLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("作者 · \(viewModel.book.author)")
                        .font(.captionLarge)
                        .foregroundStyle(viewModel.book.palette.primary)

                    Text(viewModel.book.synopsis)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(4)
                        .lineSpacing(5)
                }

                HStack(spacing: .spacing10) {
                    SceneMetricPill(
                        title: "章节",
                        value: "\(viewModel.book.totalChapters) 章",
                        systemImage: "text.book.closed.fill",
                        color: viewModel.book.palette.primary
                    )
                    SceneMetricPill(
                        title: "免费",
                        value: "\(viewModel.book.freeChapters) 章",
                        systemImage: "lock.open.fill",
                        color: viewModel.book.palette.secondary
                    )
                    SceneMetricPill(
                        title: "路线",
                        value: viewModel.publicRouteCount == 0 ? "待生成" : "\(viewModel.publicRouteCount) 条",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        color: viewModel.book.palette.tertiary
                    )
                }

                TagFlowView(tags: Array(viewModel.book.tags.prefix(4)), color: viewModel.book.palette.secondary)
            }
            .padding(.spacing24)
        }
        .overlay(alignment: .topTrailing) {
            Text(String(viewModel.book.title.prefix(1)))
                .font(.system(size: 150, weight: .bold, design: .serif))
                .foregroundStyle(viewModel.book.palette.primary.opacity(0.11))
                .offset(x: 10, y: -12)
                .allowsHitTesting(false)
        }
    }

    private var commandDeckSection: some View {
        VStack(alignment: .leading, spacing: .spacing14) {
            SceneSectionHeader(
                title: "故事指挥台",
                subtitle: "像攻略游戏一样先看这一周目的推进状态、已拿到的路线和当前前线。",
                accent: viewModel.book.palette.primary
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacing12) {
                CommandDeckMetricCard(
                    title: "当前前线",
                    value: currentFrontlineLabel,
                    footnote: currentProgress == nil ? "从第一章开局" : "可直接回到上次落点",
                    icon: "location.north.line.fill",
                    color: viewModel.book.palette.primary
                )
                CommandDeckMetricCard(
                    title: "已征服章节",
                    value: "\(currentProgress?.completedChapterIds.count ?? 0) 章",
                    footnote: "完成后才显示具体攻略线路",
                    icon: "flag.pattern.checkered.2.crossed",
                    color: viewModel.book.palette.secondary
                )
                CommandDeckMetricCard(
                    title: "攻略可见路线",
                    value: "\(viewModel.publicRouteCount) 条",
                    footnote: viewModel.publicRouteCount == 0 ? "当前书籍还没有导入公开攻略图" : "公开路线来自内容工厂的攻略图物料",
                    icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                    color: viewModel.book.palette.tertiary
                )
                CommandDeckMetricCard(
                    title: "已解锁玩法",
                    value: unlockedStyles.isEmpty ? "0 种" : "\(unlockedStyles.count) 种",
                    footnote: unlockedStyles.isEmpty ? "进入故事后逐步解锁" : unlockedStyles.map(\.displayName).joined(separator: " / "),
                    icon: "sparkles.rectangle.stack.fill",
                    color: viewModel.book.palette.secondary
                )
            }

            if !unlockedStyles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing10) {
                        ForEach(unlockedStyles, id: \.rawValue) { style in
                            SceneAccentBadge(text: style.displayName, color: style.accentColor)
                        }
                    }
                    .padding(.vertical, .spacing2)
                }
            } else {
                TagFlowView(tags: viewModel.book.interactionTags, color: viewModel.book.palette.tertiary)
            }
        }
        .scenePanel(accent: viewModel.book.palette.primary, padding: .spacing20)
    }

    private var routeAtlasSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "攻略全景线路",
                subtitle: "只有已攻略章节会展示具体落子；未打通的部分保持悬念，但整条命运链路会一直在这里。",
                accent: viewModel.book.palette.secondary
            )

            if viewModel.isLoading {
                ProgressView()
                    .tint(viewModel.book.palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing20)
                    .scenePanel(accent: viewModel.book.palette.primary, padding: .spacing20)
            } else {
                VStack(spacing: .spacing16) {
                    ForEach(Array(chapterSnapshots.enumerated()), id: \.element.id) { index, snapshot in
                        RouteAtlasStop(
                            snapshot: snapshot,
                            palette: viewModel.book.palette,
                            isLast: index == chapterSnapshots.count - 1,
                            characterName: characterName(for:),
                            currentChapterTitle: currentChapterId == snapshot.chapter.id ? snapshot.chapter.title : nil
                        )
                    }
                }
                .scenePanel(accent: viewModel.book.palette.secondary, padding: .spacing20)
            }
        }
    }

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "已达成成果",
                subtitle: "把这条路线已经塑造出来的主角气质、关系局势和显性战果讲清楚。",
                accent: viewModel.book.palette.tertiary
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacing12) {
                OutcomeStatTile(
                    title: "主角当前气质",
                    value: dominantStat.label,
                    detail: "\(dominantStat.score) 点，当前最强属性",
                    color: dominantStat.color
                )
                OutcomeStatTile(
                    title: "命运位阶",
                    value: "\(activeStats.destiny)",
                    detail: currentProgress == nil ? "尚未形成周目结果" : "持续受你的关键选择影响",
                    color: viewModel.book.palette.secondary
                )
                OutcomeStatTile(
                    title: "最强牵引角色",
                    value: strongestRelationshipSummary.title,
                    detail: strongestRelationshipSummary.detail,
                    color: strongestRelationshipSummary.color
                )
                OutcomeStatTile(
                    title: "路线成果",
                    value: routeEntries.isEmpty ? "待形成" : "\(routeEntries.count) 条",
                    detail: routeEntries.isEmpty ? "完成章节后开始沉淀攻略记录" : "已可回看你此前的关键操作",
                    color: viewModel.book.palette.primary
                )
            }
        }
        .scenePanel(accent: viewModel.book.palette.tertiary, padding: .spacing20)
    }

    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "角色阵容",
                subtitle: "先看谁会被你攻略、谁会与你对立，像游戏阵容面板一样一眼判断局势。",
                accent: viewModel.book.palette.primary
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(viewModel.book.characters) { character in
                        CharacterCommandCard(
                            character: character,
                            palette: viewModel.book.palette,
                            relationship: activeRelationships.first(where: { $0.characterId == character.id })
                        )
                    }
                }
                .padding(.vertical, .spacing4)
            }
        }
    }

    private var chapterListSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "章节入口",
                subtitle: "明确告诉用户从哪里开始、当前打到哪、后面还有哪些舞台在等他推进。",
                accent: viewModel.book.palette.primary
            )

            if viewModel.isLoading {
                ProgressView()
                    .tint(viewModel.book.palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing20)
                    .scenePanel(accent: viewModel.book.palette.primary, padding: .spacing20)
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(chapterSnapshots) { snapshot in
                        ChapterEntranceCard(
                            snapshot: snapshot,
                            palette: viewModel.book.palette,
                            isCurrent: snapshot.chapter.id == currentChapterId
                        )
                    }
                }
                .scenePanel(accent: viewModel.book.palette.primary, padding: .spacing18)
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: .spacing12) {
            Button {
                if let chapterId = startChapterId {
                    coordinator.navigate(to: .reading(viewModel.book, chapterId))
                }
            } label: {
                SceneCTAButtonLabel(
                    title: currentProgress == nil ? "开启这一周目" : "回到当前前线",
                    subtitle: currentProgress == nil ? "直接进入第一章，开始形成你的攻略档案" : "继续把这条路线打穿，再回来回看战果",
                    systemImage: currentProgress == nil ? "play.fill" : "arrow.forward.circle.fill"
                )
            }
            .buttonStyle(.primary)
            .accessibilityLabel("开始阅读")
        }
        .padding(.horizontal, .spacing16)
        .padding(.top, .spacing12)
        .padding(.bottom, .spacing16)
        .background(
            LinearGradient(
                colors: [Color.backgroundPrimary.opacity(0), Color.backgroundPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var currentProgress: ReadingProgress? {
        progressList.first(where: { $0.bookId == viewModel.book.id })
    }

    private var currentChapterId: String? {
        currentProgress?.currentChapterId
    }

    private var startChapterId: String? {
        currentProgress?.currentChapterId ?? viewModel.firstChapterId
    }

    private var chapterSnapshots: [ChapterRouteSnapshot] {
        viewModel.chapterSnapshots(progress: currentProgress)
    }

    private var routeEntries: [RouteDecisionEntry] {
        viewModel.routeEntries(progress: currentProgress)
    }

    private var activeStats: ProtagonistStats {
        currentProgress?.stats ?? viewModel.book.initialStats
    }

    private var activeRelationships: [RelationshipState] {
        currentProgress?.relationships ?? []
    }

    private var unlockedStyles: [SatisfactionType] {
        routeEntries.reduce(into: [SatisfactionType]()) { result, entry in
            if !result.contains(entry.satisfactionType) {
                result.append(entry.satisfactionType)
            }
        }
    }

    private var currentFrontlineLabel: String {
        if let progress = currentProgress,
           let chapter = viewModel.chapters.first(where: { $0.id == progress.currentChapterId }) {
            return "第\(chapter.number)章"
        }
        return "第1章"
    }

    private var dominantStat: (label: String, score: Int, color: Color) {
        let values: [(String, Int, Color)] = [
            ("战力锋芒", activeStats.combat, .accentCrimson),
            ("名望抬升", activeStats.fame, .accentGold),
            ("谋略压制", activeStats.strategy, .accentSky),
            ("财富掌控", activeStats.wealth, .accentEmerald),
            ("魅力渗透", activeStats.charm, .accentViolet),
            ("黑化潜流", activeStats.darkness, .accentAmber),
            ("天命牵引", activeStats.destiny, viewModel.book.palette.primary)
        ]
        return values.max(by: { $0.1 < $1.1 }) ?? ("未定", 0, viewModel.book.palette.primary)
    }

    private var strongestRelationshipSummary: (title: String, detail: String, color: Color) {
        guard !activeRelationships.isEmpty else {
            return ("待建立", "进入故事后，角色关系会在这里沉淀", viewModel.book.palette.tertiary)
        }

        let leading = activeRelationships.max { lhs, rhs in
            relationshipPower(lhs) < relationshipPower(rhs)
        }

        guard
            let relation = leading,
            let character = viewModel.book.characters.first(where: { $0.id == relation.characterId })
        else {
            return ("待建立", "进入故事后，角色关系会在这里沉淀", viewModel.book.palette.tertiary)
        }

        let color: Color = relation.hostility >= max(relation.trust, relation.affection, relation.awe, relation.dependence)
            ? .accentCrimson
            : viewModel.book.palette.secondary
        return (character.name, "\(relation.attitudeLabel) · 当前局势最强牵引点", color)
    }

    private func relationshipPower(_ relation: RelationshipState) -> Int {
        max(relation.trust, relation.affection, relation.hostility, relation.awe, relation.dependence)
    }

    private func characterName(for id: String) -> String {
        viewModel.book.characters.first(where: { $0.id == id })?.name ?? "关键角色"
    }
}

private struct CommandDeckMetricCard: View {
    let title: String
    let value: String
    let footnote: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing10) {
            HStack {
                Image(systemName: icon)
                    .font(.bodyLarge)
                    .foregroundStyle(color)

                Spacer()

                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 10, height: 10)
            }

            Text(title)
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)

            Text(value)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)

            Text(footnote)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(.spacing16)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfaceSecondary.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                        .strokeBorder(color.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct RouteAtlasStop: View {
    let snapshot: ChapterRouteSnapshot
    let palette: StoryPalette
    let isLast: Bool
    let characterName: (String) -> String
    let currentChapterTitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: .spacing14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(markerColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .strokeBorder(markerColor.opacity(0.28), lineWidth: 6)
                    )

                if !isLast {
                    Rectangle()
                        .fill(markerColor.opacity(0.20))
                        .frame(width: 2, height: 128)
                        .padding(.top, .spacing4)
                }
            }
            .padding(.top, .spacing8)

            VStack(alignment: .leading, spacing: .spacing12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: .spacing6) {
                        Text("第\(snapshot.chapter.number)章")
                            .font(.chapterNumber)
                            .foregroundStyle(markerColor)

                        Text(displayTitle)
                            .font(.titleSmall)
                            .foregroundStyle(Color.textPrimary)
                    }

                    Spacer()

                    SceneAccentBadge(text: stateLabel, color: markerColor)
                }

                Text(stateDescription)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(4)

                if let stage = snapshot.stage {
                    SceneAccentBadge(text: stage.title, color: markerColor)
                }

                if let guide = snapshot.guide {
                    HStack(spacing: .spacing8) {
                        guideChip(text: "~\(guide.estimatedMinutes) 分钟")
                        guideChip(text: "\(guide.interactionCount) 次交互")
                        guideChip(text: "\(guide.visibleRoutes.count) 条路线")
                    }
                }

                if snapshot.state == .conquered {
                    VStack(spacing: .spacing10) {
                        ForEach(snapshot.decisions) { decision in
                            RouteDecisionCard(decision: decision, color: markerColor, characterName: characterName)
                        }
                    }
                    if snapshot.decisions.isEmpty, let guide = snapshot.guide {
                        VStack(spacing: .spacing10) {
                            ForEach(guide.visibleRoutes) { route in
                                PublicRoutePreviewCard(route: route, color: markerColor)
                            }
                        }
                    }
                } else if snapshot.state == .active {
                    VStack(alignment: .leading, spacing: .spacing10) {
                        SceneAccentBadge(
                            text: currentChapterTitle.map { "当前进行中 · \($0)" } ?? "当前进行中",
                            color: markerColor
                        )
                        if let guide = snapshot.guide {
                            VStack(spacing: .spacing10) {
                                ForEach(guide.visibleRoutes) { route in
                                    PublicRoutePreviewCard(route: route, color: markerColor)
                                }
                            }
                        }
                    }
                } else {
                    if let guide = snapshot.guide {
                        VStack(spacing: .spacing10) {
                            ForEach(guide.visibleRoutes) { route in
                                PublicRoutePreviewCard(route: route, color: markerColor)
                            }
                        }
                    } else {
                        HStack(spacing: .spacing10) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule(style: .continuous)
                                    .fill(Color.surfaceSecondary)
                                    .frame(width: 68, height: 10)
                                    .redacted(reason: .placeholder)
                            }
                        }
                    }
                }

                if let hiddenRouteHint = snapshot.guide?.hiddenRouteHint {
                    Text("暗线提示 · \(hiddenRouteHint)")
                        .font(.captionLarge)
                        .foregroundStyle(Color.textTertiary)
                        .italic()
                }
            }
            .padding(.spacing16)
            .background(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .fill(Color.surfaceSecondary.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                            .strokeBorder(markerColor.opacity(0.16), lineWidth: 1)
                    )
            )
        }
    }

    private var markerColor: Color {
        switch snapshot.state {
        case .conquered:
            palette.primary
        case .active:
            palette.secondary
        case .hidden:
            palette.tertiary
        }
    }

    private var displayTitle: String {
        snapshot.chapter.title
    }

    private var stateLabel: String {
        switch snapshot.state {
        case .conquered:
            "已攻略"
        case .active:
            "进行中"
        case .hidden:
            "未揭示"
        }
    }

    private var stateDescription: String {
        if let guide = snapshot.guide {
            switch snapshot.state {
            case .conquered:
                return snapshot.decisions.isEmpty
                    ? guide.publicSummary
                    : "本章已形成明确攻略线路，下面是你当时的关键落子。"
            case .active:
                return guide.publicSummary
            case .hidden:
                return guide.publicSummary
            }
        }

        switch snapshot.state {
        case .conquered:
            return snapshot.decisions.isEmpty
                ? "这一章已经打通，但尚未沉淀出明确的选择记录。"
                : "本章已形成明确攻略线路，下面是你当时的关键落子。"
        case .active:
            return "这一章还在推进中。具体路线要等你打完之后，才会作为正式攻略回显。"
        case .hidden:
            return "章节位置可见，但具体攻略线路与成果会在你通关后解锁。"
        }
    }

    private func guideChip(text: String) -> some View {
        Text(text)
            .font(.captionLarge)
            .foregroundStyle(markerColor)
            .padding(.horizontal, .spacing8)
            .padding(.vertical, .spacing6)
            .background(
                Capsule(style: .continuous)
                    .fill(markerColor.opacity(0.10))
            )
    }
}

private struct PublicRoutePreviewCard: View {
    let route: WalkthroughRoute
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing6) {
            HStack(spacing: .spacing8) {
                SceneAccentBadge(text: route.style, color: color)
                SceneAccentBadge(text: route.processFocus, color: .accentSky)
            }

            Text(route.title)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)

            Text("\(route.payoff) · 解锁提示：\(route.unlockHint)")
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing12)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfacePrimary.opacity(0.88))
        )
    }
}

private struct RouteDecisionCard: View {
    let decision: RouteDecisionEntry
    let color: Color
    let characterName: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            HStack(spacing: .spacing8) {
                SceneAccentBadge(text: decision.choiceType.displayName, color: color)
                SceneAccentBadge(text: decision.satisfactionType.displayName, color: decision.satisfactionType.accentColor)
            }

            Text(decision.choiceText)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)

            Text(decision.choiceSummary ?? decision.prompt)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)

            Text(impactSummary)
                .font(.captionLarge)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing14)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfacePrimary.opacity(0.92))
        )
    }

    private var impactSummary: String {
        if let strongestStat = decision.statEffects.max(by: { abs($0.delta) < abs($1.delta) }) {
            let sign = strongestStat.delta > 0 ? "+" : ""
            return "核心收益 · \(strongestStat.stat.rawValue) \(sign)\(strongestStat.delta)"
        }

        if let strongestRelation = decision.relationshipEffects.max(by: { abs($0.delta) < abs($1.delta) }) {
            let sign = strongestRelation.delta > 0 ? "+" : ""
            return "关系波动 · \(characterName(strongestRelation.characterId)) \(strongestRelation.dimension.rawValue) \(sign)\(strongestRelation.delta)"
        }

        return "路线已收录到攻略档案"
    }
}

private struct OutcomeStatTile: View {
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing10) {
            Text(title)
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)

            Text(value)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)

            Text(detail)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .padding(.spacing16)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfaceSecondary.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                        .strokeBorder(color.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct CharacterCommandCard: View {
    let character: Character
    let palette: StoryPalette
    let relationship: RelationshipState?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Circle()
                .fill(Color.surfaceSecondary)
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String(character.name.prefix(1)))
                        .font(.titleMedium)
                        .foregroundStyle(palette.primary)
                )

            VStack(alignment: .leading, spacing: .spacing4) {
                Text(character.name)
                    .font(.labelLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(character.title)
                    .font(.captionLarge)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }

            SceneAccentBadge(
                text: relationship?.attitudeLabel ?? character.role.rawValue,
                color: relationship == nil ? palette.secondary : attitudeColor
            )

            Text(relationshipDescription)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)
        }
        .frame(width: 156, alignment: .leading)
        .scenePanel(accent: palette.primary, padding: .spacing16)
    }

    private var relationshipDescription: String {
        guard let relationship else { return character.description }
        return "信任 \(relationship.trust) · 好感 \(relationship.affection) · 敌意 \(relationship.hostility)"
    }

    private var attitudeColor: Color {
        guard let relationship else { return palette.secondary }
        if relationship.hostility >= max(relationship.trust, relationship.affection, relationship.awe, relationship.dependence) {
            return .accentCrimson
        }
        if relationship.affection >= max(relationship.trust, relationship.hostility, relationship.awe, relationship.dependence) {
            return .accentViolet
        }
        if relationship.awe >= max(relationship.trust, relationship.affection, relationship.hostility, relationship.dependence) {
            return .accentGold
        }
        return palette.secondary
    }
}

private struct ChapterEntranceCard: View {
    let snapshot: ChapterRouteSnapshot
    let palette: StoryPalette
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: .spacing14) {
            RoundedRectangle(cornerRadius: .radiusMedium, style: .continuous)
                .fill(tileGradient)
                .frame(width: 84, height: 108)
                .overlay(
                    VStack(spacing: .spacing6) {
                        Text("第\(snapshot.chapter.number)章")
                            .font(.captionLarge)
                            .foregroundStyle(Color.textPrimary.opacity(0.82))
                        Text(String(snapshot.chapter.title.prefix(1)))
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(accentColor)
                    }
                )

            VStack(alignment: .leading, spacing: .spacing8) {
                HStack(spacing: .spacing8) {
                    Text(snapshot.chapter.title)
                        .font(.titleSmall)
                        .foregroundStyle(Color.textPrimary)

                    if isCurrent {
                        SceneAccentBadge(text: "当前落点", color: palette.secondary)
                    } else if snapshot.state == .conquered {
                        SceneAccentBadge(text: "已攻略", color: palette.primary)
                    } else if snapshot.chapter.isPaid {
                        SceneAccentBadge(text: "待解锁", color: .accentAmber)
                    } else {
                        SceneAccentBadge(text: "待推进", color: palette.tertiary)
                    }
                }

                Text(summaryLine)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)

                if let guide = snapshot.guide {
                    HStack(spacing: .spacing8) {
                        entryChip(text: "~\(guide.estimatedMinutes) 分钟")
                        entryChip(text: "\(guide.interactionCount) 次交互")
                        entryChip(text: "\(guide.visibleRoutes.count) 条路线")
                    }
                }

                if let hook = snapshot.chapter.nextChapterHook, isCurrent || snapshot.state == .conquered {
                    Text(hook)
                        .font(.captionLarge)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.vertical, .spacing8)
    }

    private var accentColor: Color {
        switch snapshot.state {
        case .conquered:
            palette.primary
        case .active:
            palette.secondary
        case .hidden:
            palette.tertiary
        }
    }

    private var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(0.30),
                palette.secondary.opacity(0.15),
                Color.surfaceSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var summaryLine: String {
        if let guide = snapshot.guide {
            return guide.publicSummary
        }

        switch snapshot.state {
        case .conquered:
            return snapshot.decisions.isEmpty ? "本章已完成，等待更多攻略细节沉淀。" : "本章已有 \(snapshot.decisions.count) 条路线记录可回看。"
        case .active:
            return "你当前就在这一章的战场上，继续推进后会解锁完整路线回显。"
        case .hidden:
            return snapshot.chapter.isPaid ? "后续章节已在等待中，解锁后即可继续推进。" : "舞台已经排好，但具体打法还要靠你亲手打出来。"
        }
    }

    private func entryChip(text: String) -> some View {
        Text(text)
            .font(.captionLarge)
            .foregroundStyle(accentColor)
            .padding(.horizontal, .spacing8)
            .padding(.vertical, .spacing6)
            .background(
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(0.10))
            )
    }
}
