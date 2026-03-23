import SwiftUI
import SwiftData

private struct BottomSentinelKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

struct ReadingView: View {
    @State private var viewModel: ReadingViewModel
    @State private var advancedForNodeCount: Int = -1
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) private var coordinator

    init(book: Book, chapterId: String) {
        _viewModel = State(initialValue: ReadingViewModel(book: book, chapterId: chapterId))
    }

    var body: some View {
        ZStack {
            SceneBackdrop(palette: viewModel.book.palette)

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(viewModel.book.palette.primary)

            case .error(let message):
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "当前场景载入失败",
                    subtitle: message,
                    action: {
                        Task {
                            await viewModel.loadChapter(id: viewModel.currentChapter?.id ?? "")
                        }
                    },
                    actionTitle: "重新进入场景"
                )

            case .reading, .choosing, .chapterEnd:
                readingContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await viewModel.onAppear(modelContext: modelContext) }
    }

    private var readingContent: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing16) {
                        if let chapter = viewModel.currentChapter {
                            chapterMarker(chapter)
                        }

                        if let guide = viewModel.chapterGuide {
                            chapterGuidePanel(guide: guide, stage: viewModel.chapterStage)
                        }

                        ForEach(viewModel.displayedNodes) { node in
                            StoryNodeView(
                                node: node,
                                book: viewModel.book,
                                onChoiceSelected: { choice, choiceNode in
                                    let previousCount = viewModel.displayedNodes.count
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                                        viewModel.selectChoice(choice, in: choiceNode)
                                    }
                                    scrollAfterUpdate(using: proxy, previousCount: previousCount)
                                }
                            )
                            .id(node.id)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Scroll-to-advance sentinel: fires when the bottom of content enters viewport
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: BottomSentinelKey.self,
                                value: geo.frame(in: .global).minY
                            )
                        }
                        .frame(height: 0)

                        Spacer(minLength: 160)
                    }
                    .padding(.horizontal, .spacing20)
                    .padding(.top, .spacing24)
                    .padding(.bottom, .spacing32)
                    .onPreferenceChange(BottomSentinelKey.self) { sentinelY in
                        autoAdvanceIfNeeded(sentinelY: sentinelY)
                    }
                }
                .accessibilityIdentifier("immersiveReadingView")
                .onChange(of: viewModel.displayedNodes.count) { oldValue, newValue in
                    guard newValue > oldValue else { return }
                    scrollAfterUpdate(using: proxy, previousCount: oldValue)
                }

                if case .chapterEnd = viewModel.state {
                    chapterEndBar
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            immersiveNavigationBar
        }
    }

    private func autoAdvanceIfNeeded(sentinelY: CGFloat) {
        let screenHeight = UIScreen.main.bounds.height
        let nodeCount = viewModel.displayedNodes.count
        guard sentinelY <= screenHeight,
              case .reading = viewModel.state,
              nodeCount != advancedForNodeCount else { return }
        advancedForNodeCount = nodeCount
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            viewModel.tapToAdvance()
        }
    }

    private var immersiveNavigationBar: some View {
        HStack(spacing: .spacing10) {
            if coordinator.canGoBack {
                immersiveChromeButton(
                    title: "上一页",
                    systemImage: "chevron.left",
                    accessibilityIdentifier: "readingBackButton"
                ) {
                    coordinator.goBack()
                }
            }

            immersiveChromeButton(
                title: "首页",
                systemImage: "house.fill",
                accessibilityIdentifier: "readingHomeButton"
            ) {
                coordinator.returnToHome()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .spacing16)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing12)
        .background(
            LinearGradient(
                colors: [
                    Color.backgroundPrimary.opacity(0.92),
                    Color.backgroundPrimary.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func chapterMarker(_ chapter: Chapter) -> some View {
        VStack(spacing: .spacing8) {
            Text("第\(chapter.number)章")
                .font(.chapterNumber)
                .foregroundStyle(viewModel.book.palette.primary)

            Text(chapter.title)
                .font(.displayMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, .spacing8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("readingChapterMarker")
    }

    private func chapterGuidePanel(guide: WalkthroughChapterGuide, stage: WalkthroughStage?) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack {
                if let stage {
                    SceneAccentBadge(text: stage.title, color: viewModel.book.palette.secondary)
                }
                SceneAccentBadge(text: "\(guide.visibleRoutes.count) 条公开路线", color: viewModel.book.palette.tertiary)
                Spacer()
            }

            Text(guide.objective)
                .font(.titleSmall)
                .foregroundStyle(Color.textPrimary)

            Text(guide.publicSummary)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)

            HStack(spacing: .spacing8) {
                guideMetricChip(text: "~\(guide.estimatedMinutes) 分钟", color: viewModel.book.palette.primary)
                guideMetricChip(text: "\(guide.interactionCount) 次交互", color: viewModel.book.palette.secondary)
                if let hiddenRouteHint = guide.hiddenRouteHint {
                    guideMetricChip(text: hiddenRouteHint, color: viewModel.book.palette.tertiary)
                }
            }
        }
        .scenePanel(accent: viewModel.book.palette.secondary, padding: .spacing16)
    }

    private func guideMetricChip(text: String, color: Color) -> some View {
        Text(text)
            .font(.captionLarge)
            .foregroundStyle(color)
            .padding(.horizontal, .spacing10)
            .padding(.vertical, .spacing8)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.10))
            )
    }

    private var chapterEndBar: some View {
        VStack(spacing: .spacing12) {
            if viewModel.hasNextChapter {
                Button {
                    Task { await viewModel.proceedToNextChapter() }
                } label: {
                    SceneCTAButtonLabel(
                        title: "进入下一章",
                        subtitle: "继续把这条路线推进下去",
                        systemImage: "arrow.right.circle.fill"
                    )
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("readingNextChapterButton")
            } else {
                Button {
                    coordinator.returnToHome()
                } label: {
                    SceneCTAButtonLabel(
                        title: "返回首页",
                        subtitle: "这一卷已经读完，回到故事大厅",
                        systemImage: "house.fill"
                    )
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("readingReturnHomeButton")
            }

            if let chapter = viewModel.currentChapter {
                Button {
                    coordinator.presentSheet(.chapterSettlement(
                        book: viewModel.book,
                        chapter: chapter,
                        stats: viewModel.stats,
                        previousStats: viewModel.statsBeforeChapter,
                        relationships: viewModel.relationships,
                        previousRelationships: viewModel.relationshipsBeforeChapter,
                        choices: viewModel.chapterChoices
                    ))
                } label: {
                    Text("查看本章影响")
                        .font(.captionLarge)
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .spacing16)
        .padding(.vertical, .spacing20)
        .background(
            LinearGradient(
                colors: [Color.backgroundPrimary.opacity(0), Color.backgroundPrimary.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func scrollAfterUpdate(using proxy: ScrollViewProxy, previousCount: Int) {
        guard viewModel.displayedNodes.count > previousCount else { return }
        let firstNewIndex = min(previousCount, viewModel.displayedNodes.count - 1)
        let targetId = viewModel.displayedNodes[firstNewIndex].id
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.35)) {
                proxy.scrollTo(targetId, anchor: .top)
            }
        }
    }

    private func immersiveChromeButton(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.captionLarge.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, .spacing12)
                .padding(.vertical, .spacing10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.surfacePrimary.opacity(0.88))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct StoryNodeView: View {
    let node: StoryNode
    let book: Book
    var onChoiceSelected: ((Choice, ChoiceNode) -> Void)?

    var body: some View {
        switch node {
        case .text(let textNode):
            textView(textNode)
        case .dialogue(let dialogueNode):
            dialogueView(dialogueNode)
        case .choice(let choiceNode):
            choiceView(choiceNode)
        case .notification(let notificationNode):
            notificationView(notificationNode)
        }
    }

    private func textView(_ node: TextNode) -> some View {
        Group {
            switch node.emphasis ?? .normal {
            case .dramatic:
                Text(node.content)
                    .font(.readingBodyLarge)
                    .foregroundStyle(book.palette.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                    .padding(.vertical, .spacing10)

            case .whisper:
                Text(node.content)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .italic()
                    .padding(.leading, .spacing12)
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(book.palette.tertiary.opacity(0.55))
                            .frame(width: 3)
                    }

            case .system:
                HStack(alignment: .top, spacing: .spacing8) {
                    Image(systemName: "sparkles")
                        .font(.captionLarge)
                        .foregroundStyle(book.palette.tertiary)
                    Text(node.content)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(5)
                }
                .padding(.vertical, .spacing4)

            case .normal:
                Text(node.content)
                    .font(.readingBody)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dialogueView(_ node: DialogueNode) -> some View {
        let character = book.characters.first { $0.id == node.characterId }

        return VStack(alignment: .leading, spacing: .spacing6) {
            HStack(spacing: .spacing8) {
                Text(character?.name ?? "未知角色")
                    .font(.labelMedium)
                    .foregroundStyle(book.palette.primary)

                if let emotion = node.emotion {
                    Text(emotion)
                        .font(.captionLarge)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Text("“\(node.content)”")
                .font(.readingBody)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
        }
        .padding(.leading, .spacing14)
        .overlay(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(book.palette.secondary.opacity(0.65))
                .frame(width: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choiceView(_ node: ChoiceNode) -> some View {
        VStack(alignment: .leading, spacing: .spacing14) {
            SceneAccentBadge(text: node.choiceType.displayName, color: book.palette.primary)

            Text(node.prompt)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(5)

            VStack(spacing: .spacing12) {
                ForEach(node.choices) { choice in
                    Button {
                        onChoiceSelected?(choice, node)
                    } label: {
                        VStack(alignment: .leading, spacing: .spacing8) {
                            Text(choice.text)
                                .font(.choiceTitle)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let desc = choice.description {
                                Text(desc)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .buttonStyle(ChoiceButtonStyle(accentColor: choice.satisfactionType.accentColor))
                }
            }
        }
        .padding(.vertical, .spacing8)
    }

    private func notificationView(_ node: NotificationNode) -> some View {
        HStack(spacing: .spacing8) {
            Image(systemName: notificationIcon(node.type))
                .font(.captionLarge)
                .foregroundStyle(notificationColor(node.type))

            Text(node.message)
                .font(.labelSmall)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, .spacing12)
        .padding(.vertical, .spacing10)
        .background(
            Capsule(style: .continuous)
                .fill(notificationColor(node.type).opacity(0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(notificationColor(node.type).opacity(0.18), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notificationIcon(_ type: NotificationNode.NotificationType) -> String {
        switch type {
        case .statChange: return "chart.bar.fill"
        case .relationshipChange: return "person.2.fill"
        case .itemGained: return "gift.fill"
        case .storyHint: return "lightbulb.fill"
        }
    }

    private func notificationColor(_ type: NotificationNode.NotificationType) -> Color {
        switch type {
        case .statChange: return .accentGold
        case .relationshipChange: return .accentViolet
        case .itemGained: return .accentEmerald
        case .storyHint: return .accentSky
        }
    }

}
