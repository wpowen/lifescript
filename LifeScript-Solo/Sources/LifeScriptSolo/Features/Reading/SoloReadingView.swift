import SwiftUI
import SwiftData

struct SoloReadingView: View {
    private struct ChoiceToast: Identifiable, Equatable {
        enum Kind {
            case stat
            case relationship
            case system
        }

        let id = UUID()
        let kind: Kind
        let icon: String
        let message: String
    }

    @State private var viewModel: ReadingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showSettlement = false
    @State private var showRewindSheet = false
    @State private var activeToasts: [ChoiceToast] = []
    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @AppStorage("solo.largeReadingType") private var largeReadingType = false

    let book: Book
    let chapterAccessState: (String) -> SoloChapterAccessState
    let openLockedChapter: (String) -> Void
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let returnToHome: () -> Void

    init(
        book: Book,
        chapterId: String,
        preloadedChapters: [Chapter] = [],
        preloadedWalkthrough: BookWalkthrough? = nil,
        chapterAccessState: @escaping (String) -> SoloChapterAccessState,
        openLockedChapter: @escaping (String) -> Void,
        openDossier: @escaping () -> Void,
        openRouteMap: @escaping () -> Void,
        returnToHome: @escaping () -> Void
    ) {
        self.book = book
        self.chapterAccessState = chapterAccessState
        self.openLockedChapter = openLockedChapter
        self.openDossier = openDossier
        self.openRouteMap = openRouteMap
        self.returnToHome = returnToHome
        _viewModel = State(initialValue: ReadingViewModel(
            book: book,
            chapterId: chapterId,
            preloadedChapters: preloadedChapters,
            preloadedWalkthrough: preloadedWalkthrough
        ))
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

            if !activeToasts.isEmpty {
                toastRail
                    .padding(.top, 86)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
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
        .sheet(isPresented: $showRewindSheet) {
            rewindSheet
        }
        .onChange(of: isChapterEndPresented) { _, isPresented in
            if isPresented {
                SoloFeedback.chapterEnd(isEnabled: !reduceMotion)
            }
        }
        .task { await viewModel.onAppear(modelContext: modelContext) }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 26) {
                        // 当前目标栏 — 仅当 walkthrough 有 objective 时显示
                        if let objective = viewModel.chapterGuide?.objective {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(SoloTheme.gold)
                                    .padding(.top, 3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("当前目标")
                                        .font(.caption2.weight(.bold))
                                        .tracking(2)
                                        .foregroundStyle(SoloTheme.gold.opacity(0.80))
                                    Text(objective)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(SoloTheme.warmInk)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(SoloTheme.gold.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(SoloTheme.gold.opacity(0.18), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                        }

                        if shouldShowDestinyFieldNote {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "eye.trianglebadge.exclamationmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(destinyFieldTint)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(destinyFieldHeadline)
                                        .font(.caption.weight(.bold))
                                        .tracking(1.4)
                                        .foregroundStyle(destinyFieldTint)
                                    Text("天命值 \(viewModel.stats.destiny) · 心魇 \(viewModel.stats.darkness)。\(destinyFieldDetail)")
                                        .font(.caption)
                                        .foregroundStyle(SoloTheme.warmInk)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(destinyFieldTint.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(destinyFieldTint.opacity(0.20), lineWidth: 1)
                                    )
                            )
                        }

                        if let chapter = viewModel.currentChapter {
                            // 章节标题 — 电影感大字
                            VStack(alignment: .leading, spacing: 10) {
                                Text("第 \(chapter.number) 章 · \(book.title)")
                                    .font(.caption2.weight(.bold))
                                    .tracking(3)
                                    .foregroundStyle(SoloTheme.gold)
                                Text(chapter.title)
                                    .font(SoloTypography.posterTitle(size: 28))
                                    .foregroundStyle(SoloTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                            if let artwork = chapterArtwork(for: chapter.number) {
                                SoloArtworkCard(
                                    asset: artwork,
                                    height: 196,
                                    contentMode: .fill,
                                    tint: SoloTheme.gold,
                                    cornerRadius: 18
                                )
                            }
                        }

                        ForEach(Array(viewModel.displayedNodes.enumerated()), id: \.offset) { index, node in
                            SoloStoryNodeView(
                                node: node,
                                book: book,
                                prefersLargeType: largeReadingType,
                                isActiveChoice: activeChoiceNodeId == node.id,
                                selectedChoiceId: viewModel.selectedChoiceIds[node.id],
                                onChoiceSelected: { choice, choiceNode in
                                    let previousCount = viewModel.displayedNodes.count
                                    enqueueChoiceToasts(for: choice)
                                    SoloFeedback.choiceSelected(isEnabled: !reduceMotion)
                                    withAnimation(readingAnimation) {
                                        viewModel.selectChoice(choice, in: choiceNode)
                                    }
                                    scrollAfterUpdate(using: proxy, previousCount: previousCount)
                                }
                            )
                            .id(displayNodeIdentity(at: index))
                            .transition(reduceMotion ? .identity : .opacity)
                        }

                        if isChapterEndPresented {
                            chapterEndPanel
                                .id("chapter-end-panel")
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .soloReadingAdvanceGesture(enabled: canTapToAdvanceFromReadingArea) {
                    SoloFeedback.advance(isEnabled: !reduceMotion)
                    withAnimation(readingAnimation) {
                        viewModel.tapToAdvance()
                    }
                }
                .onChange(of: viewModel.displayedNodes.count) { oldValue, newValue in
                    if newValue > oldValue {
                        scrollAfterUpdate(using: proxy, previousCount: oldValue)
                    } else if newValue < oldValue, newValue > 0 {
                        // 回溯后滚动到当前最后一个节点（决策节点）
                        DispatchQueue.main.async {
                            withAnimation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.3)) {
                                proxy.scrollTo(displayNodeIdentity(at: newValue - 1), anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.currentChapter?.id) { _, _ in
                    DispatchQueue.main.async {
                        proxy.scrollTo(displayNodeIdentity(at: 0), anchor: .top)
                    }
                }
            }

            if case .reading = viewModel.state, !isChapterEndPresented {
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

    private var isChapterEndPresented: Bool {
        isChapterEndState || viewModel.isAwaitingChapterEndTransition
    }

    private var canTapToAdvanceFromReadingArea: Bool {
        guard case .reading = viewModel.state else { return false }
        return !isChapterEndPresented
    }

    private var chapterEndPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(chapterEndEyebrow)
                        .font(.caption2.weight(.bold))
                        .tracking(3.5)
                        .foregroundStyle(SoloTheme.gold)
                    if let chapter = viewModel.currentChapter {
                        Text(chapter.title)
                            .font(SoloTypography.posterTitle(size: 26))
                            .foregroundStyle(SoloTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.subheadline)
                    .foregroundStyle(SoloTheme.warmInk.opacity(0.72))
                    .padding(.top, 2)
            }

            Text(chapterEndBody)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(6)

            Text("当前章节已经完整收束。你可以先回看上面的结果，再决定查看此局总结、回溯关键节点，或直接进入下一章。")
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(5)

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

            if let previewSnippet = viewModel.nextChapterPreviewSnippet {
                VStack(alignment: .leading, spacing: 8) {
                    Text("下一章试读")
                        .font(SoloTypography.meta)
                        .foregroundStyle(SoloTheme.gold)
                    if let previewHeadline = nextChapterPreviewHeadline {
                        Text(previewHeadline)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoloTheme.ink)
                    }
                    Text(previewSnippet)
                        .font(SoloTypography.detail)
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

            VStack(spacing: 10) {
                Button(chapterEndSettlementLabel) {
                    showSettlement = true
                }
                .buttonStyle(SoloGhostActionButtonStyle())
                .foregroundStyle(SoloTheme.jade)

                if !viewModel.completedChoiceNodes.isEmpty {
                    Button {
                        showRewindSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.caption.weight(.semibold))
                            Text(viewModel.canRewind ? "回溯命运节点" : "回溯命运节点（天命不足）")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .buttonStyle(SoloGhostActionButtonStyle())
                    .foregroundStyle(
                        viewModel.canRewind
                            ? SoloTheme.warmInk.opacity(0.70)
                            : SoloTheme.muted.opacity(0.35)
                    )
                    .disabled(!viewModel.canRewind)
                }

                if let lockedState = nextLockedChapterState {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("新卷门槛")
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text(lockedState.supportingLine ?? "卷一完整免费，后续按卷单独解锁。")
                            .font(SoloTypography.detail)
                            .foregroundStyle(SoloTheme.warmInk)
                            .lineSpacing(5)
                    }
                    .padding(16)
                    .soloPanel(.alert, prominence: 0.18)
                }

                if viewModel.hasNextChapter {
                    Button(nextChapterButtonTitle) {
                        if let nextChapterId = viewModel.nextChapterId,
                           chapterAccessState(nextChapterId).isLocked {
                            openLockedChapter(nextChapterId)
                        } else {
                            Task { await viewModel.proceedToNextChapter() }
                        }
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
        .soloPanel(.stage, prominence: 0.22)
    }

    private var toastRail: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(activeToasts) { toast in
                HStack(spacing: 10) {
                    Image(systemName: toast.icon)
                        .font(.caption.weight(.bold))
                    Text(toast.message)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(toastForeground(for: toast.kind))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: 280, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.80))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(toastBorder(for: toast.kind), lineWidth: 1)
                        )
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 8)
            }
        }
    }

    // MARK: - Chapter End Copy (genre-aware)

    private var chapterEndEyebrow: String {
        switch book.genre {
        case .apocalypsePower:   return SoloLocalization.localized("夜线封存")
        case .cultivation:       return SoloLocalization.localized("此局封存")
        case .suspenseSurvival:  return SoloLocalization.localized("事件归档")
        case .businessWar:       return SoloLocalization.localized("局势封存")
        case .urbanReversal:     return SoloLocalization.localized("阶段落定")
        }
    }

    private var chapterEndBody: String {
        switch book.genre {
        case .apocalypsePower:
            return SoloLocalization.localized("这一夜压过去了。留下来的不只是伤亡数字，还有你亲手把避难区的人心推向了哪里。")
        case .cultivation:
            return SoloLocalization.localized("这一局已经收场。真正留下来的，不只是胜负，还有你走出来的那条路会把天下推向哪里。")
        case .suspenseSurvival:
            return SoloLocalization.localized("这一段已经封存。留下来的不只是线索，还有你的判断把真相拨向了哪一面。")
        case .businessWar:
            return SoloLocalization.localized("这一轮落子。留下来的不只是账面，还有你把盘局推向了哪个方向。")
        case .urbanReversal:
            return SoloLocalization.localized("这一步已经走出去了。留下来的不只是结果，还有你亲手把局势翻向了哪里。")
        }
    }

    private var nextChapterEchoLabel: String {
        switch book.genre {
        case .apocalypsePower:  return SoloLocalization.localized("下一夜的回声")
        case .cultivation:      return SoloLocalization.localized("下一局的回响")
        default:                return SoloLocalization.localized("下一段的回响")
        }
    }

    private var nextChapterLabel: String {
        switch book.genre {
        case .apocalypsePower:  return SoloLocalization.localized("进入下一夜")
        case .cultivation:      return SoloLocalization.localized("进入下一局")
        case .suspenseSurvival: return SoloLocalization.localized("继续追查")
        case .businessWar:      return SoloLocalization.localized("进入下一轮")
        case .urbanReversal:    return SoloLocalization.localized("继续翻盘")
        }
    }

    private var nextChapterButtonTitle: String {
        guard let nextChapterId = viewModel.nextChapterId else {
            return nextChapterLabel
        }

        let accessState = chapterAccessState(nextChapterId)
        return accessState.isLocked ? accessState.primaryActionTitle : nextChapterLabel
    }

    private var nextChapterPreviewHeadline: String? {
        guard let number = viewModel.nextChapterNumber,
              let title = viewModel.nextChapterTitle else {
            return nil
        }

        return "第 \(number) 章 · \(title)"
    }

    private var nextLockedChapterState: SoloChapterAccessState? {
        guard let nextChapterId = viewModel.nextChapterId else { return nil }

        let accessState = chapterAccessState(nextChapterId)
        return accessState.isLocked ? accessState : nil
    }

    private var chapterEndSettlementLabel: String {
        switch book.genre {
        case .apocalypsePower:  return SoloLocalization.localized("这一夜留下了什么")
        case .cultivation:      return SoloLocalization.localized("这一局留下了什么")
        default:                return SoloLocalization.localized("查看余波")
        }
    }

    private func chapterArtwork(for chapterNumber: Int) -> SoloArtworkAsset? {
        guard book.id == "天机录" else { return nil }
        return TianjiluArtworkCatalog.volume(for: max(chapterNumber, 1)).keyframe
    }

    // MARK: - Rewind Sheet

    private var rewindSheet: some View {
        NavigationStack {
            ZStack {
                SoloBackdrop()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // 消耗提示
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SoloTheme.gold)
                            Text("每次回溯消耗天命值 10 点")
                                .font(.caption)
                                .foregroundStyle(SoloTheme.muted)
                            Spacer()
                            Text("天命值：\(viewModel.stats.destiny)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SoloTheme.gold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))

                        Divider().background(Color.white.opacity(0.08))

                        VStack(spacing: 12) {
                            ForEach(viewModel.completedChoiceNodes, id: \.index) { item in
                                rewindRow(item: item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("命运回溯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { showRewindSheet = false }
                        .foregroundStyle(SoloTheme.muted)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }

    private func rewindRow(item: (index: Int, node: ChoiceNode, chosenText: String)) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.node.prompt)
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(SoloTheme.gold.opacity(0.70))
                    .lineLimit(2)
                Text(item.chosenText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloTheme.ink)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                showRewindSheet = false
                SoloFeedback.choiceSelected(isEnabled: !reduceMotion)
                withAnimation(readingAnimation) {
                    viewModel.rewindToChoice(nodeIndex: item.index)
                }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SoloTheme.crimson)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
    }

    private func enqueueChoiceToasts(for choice: Choice) {
        let toasts = buildChoiceToasts(for: choice).prefix(4)

        for (offset, toast) in toasts.enumerated() {
            Task {
                let appearDelay = UInt64(offset) * 180_000_000
                try? await Task.sleep(nanoseconds: appearDelay)

                await MainActor.run {
                    withAnimation(reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.32, dampingFraction: 0.88)) {
                        activeToasts.append(toast)
                    }
                }

                try? await Task.sleep(nanoseconds: 2_200_000_000)

                await MainActor.run {
                    withAnimation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.22)) {
                        activeToasts.removeAll { $0.id == toast.id }
                    }
                }
            }
        }
    }

    private func buildChoiceToasts(for choice: Choice) -> [ChoiceToast] {
        var toasts: [ChoiceToast] = []

        for effect in choice.statEffects where effect.delta != 0 {
            let sign = effect.delta > 0 ? "+" : ""
            toasts.append(
                ChoiceToast(
                    kind: .stat,
                    icon: effect.delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    message: "\(effect.stat.displayName) \(sign)\(effect.delta)"
                )
            )
        }

        for effect in choice.relationshipEffects where effect.delta != 0 {
            let characterName = book.characters.first(where: { $0.id == effect.characterId })?.name ?? SoloLocalization.localized("某人")
            let sign = effect.delta > 0 ? "+" : ""
            toasts.append(
                ChoiceToast(
                    kind: .relationship,
                    icon: effect.delta >= 0 ? "heart.circle.fill" : "person.crop.circle.badge.xmark",
                    message: "\(characterName) · \(effect.dimension.displayName) \(sign)\(effect.delta)"
                )
            )
        }

        if toasts.isEmpty, let reward = choice.visibleReward {
            toasts.append(
                ChoiceToast(
                    kind: .system,
                    icon: "sparkles",
                    message: reward
                )
            )
        }

        return toasts
    }

    private func toastForeground(for kind: ChoiceToast.Kind) -> Color {
        switch kind {
        case .stat:
            return SoloTheme.gold
        case .relationship:
            return SoloTheme.jade
        case .system:
            return SoloTheme.warmInk
        }
    }

    private func toastBorder(for kind: ChoiceToast.Kind) -> Color {
        switch kind {
        case .stat:
            return SoloTheme.gold.opacity(0.32)
        case .relationship:
            return SoloTheme.jade.opacity(0.28)
        case .system:
            return Color.white.opacity(0.10)
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

    private var shouldShowDestinyFieldNote: Bool {
        book.genre == .cultivation || viewModel.stats.destiny <= 45 || viewModel.stats.darkness >= 30
    }

    private var destinyFieldHeadline: String {
        if viewModel.stats.destiny <= 15 || (viewModel.stats.destiny <= 28 && viewModel.stats.darkness >= 45) {
            return SoloLocalization.localized("命火将熄")
        }
        if viewModel.stats.destiny <= 35 || viewModel.stats.darkness >= 60 {
            return SoloLocalization.localized("反噬逼近")
        }
        if viewModel.stats.destiny <= 65 {
            return SoloLocalization.localized("命局平衡")
        }
        return SoloLocalization.localized("天命充盈")
    }

    private var destinyFieldDetail: String {
        switch destinyFieldHeadline {
        case SoloLocalization.localized("命火将熄"):
            return SoloLocalization.localized("再动一次天机录，就可能把后手直接烧穿。")
        case SoloLocalization.localized("反噬逼近"):
            return SoloLocalization.localized("还能继续落子，但高风险选择最好先确认收益。")
        case SoloLocalization.localized("命局平衡"):
            return SoloLocalization.localized("局势仍在可控区，适合试探，不适合连烧后手。")
        default:
            return SoloLocalization.localized("当前还握得住主动，但越顺手越要记得藏锋。")
        }
    }

    private var destinyFieldTint: Color {
        switch destinyFieldHeadline {
        case SoloLocalization.localized("天命充盈"):
            return SoloTheme.jade
        case SoloLocalization.localized("命局平衡"):
            return SoloTheme.gold
        default:
            return SoloTheme.crimson
        }
    }
}

private struct SoloReadingAdvanceGestureModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded(action)
                )
        } else {
            content
        }
    }
}

private extension View {
    func soloReadingAdvanceGesture(enabled: Bool, action: @escaping () -> Void) -> some View {
        modifier(SoloReadingAdvanceGestureModifier(enabled: enabled, action: action))
    }
}
