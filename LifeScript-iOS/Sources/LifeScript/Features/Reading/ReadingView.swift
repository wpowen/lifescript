import SwiftUI
import SwiftData

struct ReadingView: View {
    @State private var viewModel: ReadingViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) private var coordinator

    init(book: Book, chapterId: String) {
        _viewModel = State(initialValue: ReadingViewModel(book: book, chapterId: chapterId))
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(Color.accentGold)

            case .reading, .choosing:
                readingContent

            case .chapterEnd:
                chapterEndOverlay

            case .error(let message):
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "加载失败",
                    subtitle: message,
                    action: { Task { await viewModel.loadChapter(id: viewModel.currentChapter?.id ?? "") } },
                    actionTitle: "重试"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { readingToolbar }
        .task { await viewModel.onAppear(modelContext: modelContext) }
    }

    // MARK: - Reading Content

    private var readingContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing16) {
                    // Chapter header
                    if let chapter = viewModel.currentChapter {
                        chapterHeader(chapter)
                    }

                    // Story nodes
                    ForEach(viewModel.displayedNodes) { node in
                        StoryNodeView(
                            node: node,
                            book: viewModel.book,
                            onChoiceSelected: { choice, choiceNode in
                                viewModel.selectChoice(choice, in: choiceNode)
                            }
                        )
                        .id(node.id)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Tap to continue indicator
                    if case .reading = viewModel.state {
                        tapToContinueHint
                            .id("tap_hint")
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, .spacing16)
                .padding(.top, .spacing16)
            }
            .onTapGesture {
                let previousCount = viewModel.displayedNodes.count
                withAnimation(.easeOut(duration: 0.35)) {
                    viewModel.tapToAdvance()
                }
                // Scroll to the first NEW node in the batch so user reads from the top
                if viewModel.displayedNodes.count > previousCount {
                    let firstNewId = viewModel.displayedNodes[previousCount].id
                    withAnimation(.easeOut(duration: 0.4)) {
                        proxy.scrollTo(firstNewId, anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: - Chapter Header

    private func chapterHeader(_ chapter: Chapter) -> some View {
        VStack(spacing: .spacing8) {
            Text("第\(chapter.number)章")
                .font(.chapterNumber)
                .foregroundStyle(Color.accentGold)
            Text(chapter.title)
                .font(.displayMedium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing32)
    }

    // MARK: - Tap Hint

    private var tapToContinueHint: some View {
        HStack(spacing: .spacing8) {
            Circle()
                .fill(Color.accentGold.opacity(0.4))
                .frame(width: 6, height: 6)
                .phaseAnimator([false, true]) { content, phase in
                    content.opacity(phase ? 0.3 : 1.0)
                } animation: { _ in .easeInOut(duration: 1.2).repeatForever() }
            Text("点击继续")
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)
            Circle()
                .fill(Color.accentGold.opacity(0.4))
                .frame(width: 6, height: 6)
                .phaseAnimator([false, true]) { content, phase in
                    content.opacity(phase ? 0.3 : 1.0)
                } animation: { _ in .easeInOut(duration: 1.2).repeatForever() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacing24)
    }

    // MARK: - Chapter End Overlay

    private var chapterEndOverlay: some View {
        VStack(spacing: .spacing24) {
            Spacer()

            // Chapter complete indicator
            VStack(spacing: .spacing12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentGold)
                if let chapter = viewModel.currentChapter {
                    Text("第\(chapter.number)章 完")
                        .font(.chapterNumber)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if let hook = viewModel.currentChapter?.nextChapterHook {
                Text(hook)
                    .font(.readingBody)
                    .foregroundStyle(Color.accentGold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacing24)
                    .italic()
                    .padding(.vertical, .spacing12)
                    .background(Color.accentGold.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                    .padding(.horizontal, .spacing16)
            }

            VStack(spacing: .spacing12) {
                if let chapter = viewModel.currentChapter {
                    Button("查看本章结算") {
                        coordinator.presentSheet(.chapterSettlement(
                            book: viewModel.book,
                            chapter: chapter,
                            stats: viewModel.stats,
                            previousStats: viewModel.statsBeforeChapter,
                            relationships: viewModel.relationships,
                            previousRelationships: viewModel.relationshipsBeforeChapter,
                            choices: viewModel.chapterChoices
                        ))
                    }
                    .buttonStyle(.primary)
                }

                Button("继续下一章") {
                    Task { await viewModel.proceedToNextChapter() }
                }
                .buttonStyle(.secondary)
            }
            .padding(.horizontal, .spacing16)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var readingToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.currentChapter?.title ?? "")
                .font(.labelSmall)
                .foregroundStyle(Color.textSecondary)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    coordinator.presentSheet(.stats(
                        stats: viewModel.stats,
                        previousStats: viewModel.statsBeforeChapter
                    ))
                } label: {
                    Label("主角属性", systemImage: "chart.bar")
                }
                Button {
                    coordinator.presentSheet(.relationships(
                        book: viewModel.book,
                        relationships: viewModel.relationships
                    ))
                } label: {
                    Label("角色关系", systemImage: "person.2")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - Story Node View

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

    // MARK: - Text

    private func textView(_ node: TextNode) -> some View {
        Group {
            switch node.emphasis {
            case .dramatic:
                Text(node.content)
                    .font(.readingBodyLarge)
                    .foregroundStyle(Color.accentGold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, .spacing8)
            case .whisper:
                Text(node.content)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
                    .italic()
            case .system:
                Text(node.content)
                    .font(.bodySmall)
                    .foregroundStyle(Color.accentSky)
                    .padding(.spacing12)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentSky.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSmall))
            default:
                Text(node.content)
                    .font(.readingBody)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(8)
            }
        }
    }

    // MARK: - Dialogue

    private func dialogueView(_ node: DialogueNode) -> some View {
        let character = book.characters.first { $0.id == node.characterId }
        return HStack(alignment: .top, spacing: .spacing12) {
            Circle()
                .fill(Color.surfaceHighlight)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(character?.name.prefix(1) ?? "?"))
                        .font(.labelSmall)
                        .foregroundStyle(Color.accentGold)
                )

            VStack(alignment: .leading, spacing: .spacing4) {
                HStack(spacing: .spacing6) {
                    Text(character?.name ?? "???")
                        .font(.labelSmall)
                        .foregroundStyle(Color.accentGold)
                    if let emotion = node.emotion {
                        Text("(\(emotion))")
                            .font(.captionSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                Text("\u{201C}\(node.content)\u{201D}")
                    .font(.readingBody)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(6)
            }
        }
        .padding(.vertical, .spacing4)
    }

    // MARK: - Choice

    private func choiceView(_ node: ChoiceNode) -> some View {
        VStack(spacing: .spacing12) {
            Text(node.prompt)
                .font(.labelLarge)
                .foregroundStyle(Color.accentGold)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.vertical, .spacing8)

            ForEach(node.choices) { choice in
                Button {
                    onChoiceSelected?(choice, node)
                } label: {
                    VStack(alignment: .leading, spacing: .spacing4) {
                        Text(choice.text)
                            .font(.choiceTitle)
                        if let desc = choice.description {
                            Text(desc)
                                .font(.captionLarge)
                                .foregroundStyle(Color.textTertiary)
                        }
                        HStack(spacing: .spacing6) {
                            Image(systemName: choice.satisfactionType.iconName)
                                .font(.captionSmall)
                            Text(choice.satisfactionType.displayName)
                                .font(.captionSmall)
                        }
                        .foregroundStyle(Color.textTertiary)
                    }
                }
                .buttonStyle(ChoiceButtonStyle())
            }
        }
        .padding(.vertical, .spacing8)
    }

    // MARK: - Notification

    private func notificationView(_ node: NotificationNode) -> some View {
        HStack(spacing: .spacing8) {
            Image(systemName: notificationIcon(node.type))
                .font(.captionLarge)
                .foregroundStyle(notificationColor(node.type))
            Text(node.message)
                .font(.labelSmall)
                .foregroundStyle(notificationColor(node.type))
        }
        .padding(.horizontal, .spacing12)
        .padding(.vertical, .spacing8)
        .frame(maxWidth: .infinity)
        .background(notificationColor(node.type).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: .radiusSmall))
    }

    private func notificationIcon(_ type: NotificationNode.NotificationType) -> String {
        switch type {
        case .statChange: return "arrow.up.circle"
        case .relationshipChange: return "person.2.circle"
        case .itemGained: return "gift"
        case .storyHint: return "lightbulb"
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
