import SwiftUI
import SwiftData

struct SoloReadingView: View {
    @State private var viewModel: ReadingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showSettlement = false
    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @AppStorage("solo.autoShowSettlement") private var autoShowSettlement = true
    @AppStorage("solo.largeReadingType") private var largeReadingType = false

    let book: Book
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let returnToHome: () -> Void

    init(
        book: Book,
        chapterId: String,
        openDossier: @escaping () -> Void,
        openRouteMap: @escaping () -> Void,
        returnToHome: @escaping () -> Void
    ) {
        self.book = book
        self.openDossier = openDossier
        self.openRouteMap = openRouteMap
        self.returnToHome = returnToHome
        _viewModel = State(initialValue: ReadingViewModel(book: book, chapterId: chapterId))
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            switch viewModel.state {
            case .loading:
                ProgressView("正在翻开章节")
                    .tint(SoloTheme.gold)
            case .error(let message):
                VStack(spacing: 16) {
                    Text("当前章节载入失败")
                        .font(.title3.weight(.semibold))
                    Text(message)
                        .foregroundStyle(SoloTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .soloCard()
                .padding(.horizontal, 24)
            case .reading, .choosing, .chapterEnd:
                content
            }

            if shouldShowChapterEndOverlay {
                chapterEndOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(2)
            }
        }
        .soloStoryChrome(title: navigationTitle, kicker: "阅读")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                SoloChromeIconButton(systemImage: "person.text.rectangle", tint: SoloTheme.jade, action: openDossier)
                SoloChromeIconButton(systemImage: "point.topleft.down.curvedto.point.bottomright.up", tint: SoloTheme.crimson, action: openRouteMap)
            }
        }
        .sheet(isPresented: $showSettlement) {
            if let chapter = viewModel.currentChapter {
                SoloSettlementView(
                    book: book,
                    chapter: chapter,
                    stats: viewModel.stats,
                    previousStats: viewModel.statsBeforeChapter,
                    relationships: viewModel.relationships,
                    previousRelationships: viewModel.relationshipsBeforeChapter,
                    choices: viewModel.chapterChoices
                )
            }
        }
        .onChange(of: shouldShowChapterEndOverlay) { _, shouldShow in
            if shouldShow {
                SoloFeedback.chapterEnd(isEnabled: !reduceMotion)
            }
            guard shouldShow, autoShowSettlement else { return }
            showSettlement = true
        }
        .task { await viewModel.onAppear(modelContext: modelContext) }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        if let chapter = viewModel.currentChapter {
                            // 章节标题 — 电影感大字
                            VStack(alignment: .leading, spacing: 10) {
                                Text("第 \(chapter.number) 章 · \(book.title)")
                                    .font(.caption2.weight(.bold))
                                    .tracking(3)
                                    .foregroundStyle(SoloTheme.gold)
                                Text(chapter.title)
                                    .font(SoloTypography.posterTitle(size: 36))
                                    .foregroundStyle(SoloTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        }

                        ForEach(Array(viewModel.displayedNodes.enumerated()), id: \.offset) { index, node in
                            SoloStoryNodeView(
                                node: node,
                                book: book,
                                prefersLargeType: largeReadingType,
                                isActiveChoice: activeChoiceNodeId == node.id,
                                onChoiceSelected: { choice, choiceNode in
                                    let previousCount = viewModel.displayedNodes.count
                                    SoloFeedback.choiceSelected(isEnabled: !reduceMotion)
                                    withAnimation(readingAnimation) {
                                        viewModel.selectChoice(choice, in: choiceNode)
                                    }
                                    scrollAfterUpdate(using: proxy, previousCount: previousCount)
                                }
                            )
                            .id(displayNodeIdentity(at: index))
                            .transition(
                                reduceMotion
                                    ? .identity
                                    : .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        guard canTapToAdvanceFromReadingArea else { return }
                        SoloFeedback.advance(isEnabled: !reduceMotion)
                        withAnimation(readingAnimation) {
                            viewModel.tapToAdvance()
                        }
                    }
                )
                .onChange(of: viewModel.displayedNodes.count) { oldValue, newValue in
                    guard newValue > oldValue else { return }
                    scrollAfterUpdate(using: proxy, previousCount: oldValue)
                }
            }

            if case .reading = viewModel.state, !shouldShowChapterEndOverlay {
                // 推进按钮 — 极简，不抢戏
                Button {
                    SoloFeedback.advance(isEnabled: !reduceMotion)
                    withAnimation(readingAnimation) {
                        viewModel.tapToAdvance()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                        Text("继续推进")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .foregroundStyle(SoloTheme.ink.opacity(0.80))
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1),
                        alignment: .top
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeChoiceNodeId: String? {
        if case .choosing(let choiceNode) = viewModel.state {
            return choiceNode.id
        }
        return nil
    }

    private var isChapterEndState: Bool {
        if case .chapterEnd = viewModel.state {
            return true
        }
        return false
    }

    private var shouldShowChapterEndOverlay: Bool {
        isChapterEndState || viewModel.isAwaitingChapterEndTransition
    }

    private var canTapToAdvanceFromReadingArea: Bool {
        guard case .reading = viewModel.state else { return false }
        return !shouldShowChapterEndOverlay
    }

    private var chapterEndOverlay: some View {
        ZStack(alignment: .bottom) {
            // Gradient veil — fades from clear at top to near-opaque at bottom
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.92),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.0),
                endPoint:   UnitPoint(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()

            // Panel — solid dark base so no content bleeds through
            VStack(alignment: .leading, spacing: 18) {
                // Eyebrow row
                HStack {
                    Text(chapterEndEyebrow)
                        .font(.caption2.weight(.bold))
                        .tracking(3.5)
                        .foregroundStyle(SoloTheme.gold)
                    Spacer()
                    Image(systemName: "moon.stars.fill")
                        .font(.subheadline)
                        .foregroundStyle(SoloTheme.warmInk.opacity(0.70))
                }

                // Chapter title
                if let chapter = viewModel.currentChapter {
                    Text(chapter.title)
                        .font(SoloTypography.posterTitle(size: 28))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Immersive body
                Text(chapterEndBody)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(6)

                // Next chapter hook
                if let hook = viewModel.currentChapter?.nextChapterHook {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(nextChapterEchoLabel)
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text(hook)
                            .font(.body)
                            .foregroundStyle(SoloTheme.warmInk)
                            .lineSpacing(6)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(SoloTheme.gold.opacity(0.18), lineWidth: 1)
                            )
                    )
                }

                // Actions
                VStack(spacing: 10) {
                    Button(chapterEndSettlementLabel) {
                        showSettlement = true
                    }
                    .buttonStyle(SoloGhostActionButtonStyle())
                    .foregroundStyle(SoloTheme.jade)

                    if viewModel.hasNextChapter {
                        Button(nextChapterLabel) {
                            Task { await viewModel.proceedToNextChapter() }
                        }
                        .buttonStyle(SoloPrimaryActionButtonStyle())
                    } else {
                        Button("回到主页") {
                            returnToHome()
                        }
                        .buttonStyle(SoloPrimaryActionButtonStyle())
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.02, blue: 0.06).opacity(0.97))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Chapter End Copy (genre-aware)

    private var chapterEndEyebrow: String {
        switch book.genre {
        case .apocalypsePower:   return "夜线封存"
        case .cultivation:       return "此局封存"
        case .suspenseSurvival:  return "事件归档"
        case .businessWar:       return "局势封存"
        case .urbanReversal:     return "阶段落定"
        }
    }

    private var chapterEndBody: String {
        switch book.genre {
        case .apocalypsePower:
            return "这一夜压过去了。留下来的不只是伤亡数字，还有你亲手把避难区的人心推向了哪里。"
        case .cultivation:
            return "这一局已经收场。真正留下来的，不只是胜负，还有你走出来的那条路会把天下推向哪里。"
        case .suspenseSurvival:
            return "这一段已经封存。留下来的不只是线索，还有你的判断把真相拨向了哪一面。"
        case .businessWar:
            return "这一轮落子。留下来的不只是账面，还有你把盘局推向了哪个方向。"
        case .urbanReversal:
            return "这一步已经走出去了。留下来的不只是结果，还有你亲手把局势翻向了哪里。"
        }
    }

    private var nextChapterEchoLabel: String {
        switch book.genre {
        case .apocalypsePower:  return "下一夜的回声"
        case .cultivation:      return "下一局的回响"
        default:                return "下一段的回响"
        }
    }

    private var nextChapterLabel: String {
        switch book.genre {
        case .apocalypsePower:  return "进入下一夜"
        case .cultivation:      return "进入下一局"
        case .suspenseSurvival: return "继续追查"
        case .businessWar:      return "进入下一轮"
        case .urbanReversal:    return "继续翻盘"
        }
    }

    private var chapterEndSettlementLabel: String {
        switch book.genre {
        case .apocalypsePower:  return "这一夜留下了什么"
        case .cultivation:      return "这一局留下了什么"
        default:                return "查看余波"
        }
    }

    private var readingAnimation: Animation {
        SoloMotion.reading(reduceMotion: reduceMotion)
    }

    private var navigationTitle: String {
        viewModel.currentChapter?.title ?? book.title
    }

    private func scrollAfterUpdate(using proxy: ScrollViewProxy, previousCount: Int) {
        guard viewModel.displayedNodes.count > previousCount else { return }
        let targetIndex = min(previousCount, viewModel.displayedNodes.count - 1)
        let targetId = displayNodeIdentity(at: targetIndex)
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.25)) {
                proxy.scrollTo(targetId, anchor: .top)
            }
        }
    }

    private func displayNodeIdentity(at index: Int) -> String {
        // Use display order as the stable identity to avoid collisions from duplicated content node ids.
        "display-node-\(index)"
    }
}
