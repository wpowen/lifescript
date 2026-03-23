import SwiftUI

struct SoloRouteMapView: View {
    let book: Book
    let walkthrough: BookWalkthrough?
    let progressSummary: SoloProgressSummary
    let routeSnapshot: SoloRouteMapSnapshot
    let relationships: [RelationshipState]
    private let branding = SoloStoryConfig.branding

    @State private var selectedTab = RouteMapTab.worldline

    enum RouteMapTab: CaseIterable {
        case worldline, characters, darklines
        var label: String {
            switch self {
            case .worldline:  return "世界线"
            case .characters: return "人物"
            case .darklines:  return "暗线"
            }
        }
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            VStack(spacing: 0) {
                progressStrip
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                tabBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 2)

                ScrollView(showsIndicators: false) {
                    Group {
                        switch selectedTab {
                        case .worldline:  worldlineTab
                        case .characters: charactersTab
                        case .darklines:  darklinesTab
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .soloStoryChrome(title: "命运图谱", kicker: "探索")
    }

    // MARK: - Progress Strip

    private var progressStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("探索进度")
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)
                Spacer()
                Text("\(progressSummary.completedChapterCount) / \(progressSummary.totalChapterCount) \(branding.chapterUnitName)")
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.muted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                    let ratio = CGFloat(progressSummary.completedChapterCount) /
                                CGFloat(max(progressSummary.totalChapterCount, 1))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(LinearGradient(
                            colors: [SoloTheme.crimson, SoloTheme.gold],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * ratio, height: 3)
                }
            }
            .frame(height: 3)

            HStack(spacing: 20) {
                progressPill(value: "\(progressSummary.completedChapterCount)", label: "章已走完", tint: SoloTheme.jade)
                progressPill(value: "\(relationships.count)", label: "人已认识", tint: SoloTheme.gold)
                progressPill(value: "\(discoveredHints.count)", label: "暗线已知", tint: SoloTheme.crimson)
            }
        }
        .padding(16)
        .soloPanel(.hero, prominence: 0.14)
    }

    private func progressPill(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
        }
    }

    // MARK: - Custom Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(RouteMapTab.allCases, id: \.label) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 7) {
                        Text(tab.label)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? SoloTheme.gold : SoloTheme.muted)
                        Rectangle()
                            .fill(selectedTab == tab ? SoloTheme.gold : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - World Line Tab

    private var worldlineTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let walkthrough {
                let stages = walkthrough.stages
                ForEach(Array(stages.enumerated()), id: \.element.id) { idx, stage in
                    stageBlock(
                        stage: stage,
                        isUnlocked: isStageUnlocked(stage),
                        isCurrent: routeSnapshot.currentStageID == stage.id,
                        isCompleted: stage.chapterIds.allSatisfy { routeSnapshot.completedChapterIDs.contains($0) },
                        isLast: idx == stages.count - 1
                    )
                }
            } else {
                Text("当前故事还没有公开路线图。")
                    .foregroundStyle(SoloTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            }
        }
    }

    private func stageBlock(
        stage: WalkthroughStage,
        isUnlocked: Bool,
        isCurrent: Bool,
        isCompleted: Bool,
        isLast: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Stage header card
            HStack(alignment: .center, spacing: 12) {
                stageMarker(isUnlocked: isUnlocked, isCurrent: isCurrent, isCompleted: isCompleted)

                VStack(alignment: .leading, spacing: 3) {
                    if isUnlocked {
                        Text(stage.title)
                            .font(SoloTypography.sceneHeadline(size: 17))
                            .foregroundStyle(isCompleted ? SoloTheme.warmInk : SoloTheme.ink)
                        Text(stage.summary)
                            .font(.caption)
                            .foregroundStyle(SoloTheme.muted)
                            .lineLimit(1)
                    } else {
                        Text("??? · 封锁区段")
                            .font(SoloTypography.sceneHeadline(size: 17))
                            .foregroundStyle(SoloTheme.muted.opacity(0.38))
                        Text("推进到此阶段后才会显形")
                            .font(.caption)
                            .foregroundStyle(SoloTheme.muted.opacity(0.28))
                    }
                }

                Spacer()

                stageBadge(isUnlocked: isUnlocked, isCurrent: isCurrent, isCompleted: isCompleted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isCurrent ? Color.white.opacity(0.07) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isCurrent ? SoloTheme.crimson.opacity(0.28) : Color.white.opacity(0.05),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.bottom, 6)

            // Chapter nodes within the stage
            if isUnlocked {
                let guideList = guides(in: stage)
                ForEach(Array(guideList.enumerated()), id: \.element.id) { nodeIdx, guide in
                    HStack(alignment: .top, spacing: 0) {
                        // Vertical rail + dot
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                            chapterDot(guide)
                            if nodeIdx < guideList.count - 1 || !isLast {
                                Rectangle()
                                    .fill(Color.white.opacity(0.07))
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 28)
                        .padding(.leading, 14)

                        chapterCard(guide)
                            .padding(.leading, 10)
                            .padding(.bottom, 6)
                    }
                }
            }

            // Inter-stage connector
            if !isLast {
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 1, height: 18)
                        .padding(.leading, 25)
                    Spacer()
                }
                .padding(.bottom, 6)
            }
        }
    }

    @ViewBuilder
    private func stageMarker(isUnlocked: Bool, isCurrent: Bool, isCompleted: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    isCompleted ? SoloTheme.jade.opacity(0.22) :
                    isCurrent   ? SoloTheme.crimson.opacity(0.22) :
                    isUnlocked  ? Color.white.opacity(0.08) :
                                  Color.white.opacity(0.03)
                )
                .frame(width: 30, height: 30)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SoloTheme.jade)
            } else if isCurrent {
                Circle()
                    .fill(SoloTheme.crimson)
                    .frame(width: 9, height: 9)
            } else if isUnlocked {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 6, height: 6)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(SoloTheme.muted.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private func stageBadge(isUnlocked: Bool, isCurrent: Bool, isCompleted: Bool) -> some View {
        if isCompleted {
            Text("已走完")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SoloTheme.jade)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(SoloTheme.jade.opacity(0.12)))
        } else if isCurrent {
            Text("当前")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SoloTheme.crimson)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(SoloTheme.crimson.opacity(0.14)))
        }
    }

    private func chapterDot(_ guide: WalkthroughChapterGuide) -> some View {
        Circle()
            .fill(
                guide.chapterId == routeSnapshot.currentChapterID ? SoloTheme.crimson :
                routeSnapshot.completedChapterIDs.contains(guide.chapterId) ? SoloTheme.jade :
                Color.white.opacity(0.18)
            )
            .frame(width: 7, height: 7)
    }

    private func chapterCard(_ guide: WalkthroughChapterGuide) -> some View {
        let isCompleted = routeSnapshot.completedChapterIDs.contains(guide.chapterId)
        let isCurrent   = guide.chapterId == routeSnapshot.currentChapterID
        let isLocked    = !isCompleted && !isCurrent

        return VStack(alignment: .leading, spacing: 8) {
            // Objective row
            HStack(alignment: .firstTextBaseline) {
                Text(isLocked ? "??? · 未触达" : guide.objective)
                    .font(SoloTypography.label)
                    .foregroundStyle(isLocked ? SoloTheme.muted.opacity(0.40) : SoloTheme.gold)
                    .lineLimit(2)
                Spacer(minLength: 8)
                if isCurrent {
                    Text("正在推进")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SoloTheme.crimson)
                } else if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(SoloTheme.jade.opacity(0.75))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(SoloTheme.muted.opacity(0.30))
                }
            }

            if isLocked {
                // Redacted content
                Text("██████████████ ████████████ ███")
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted.opacity(0.16))
                    .lineLimit(2)
                    .padding(.bottom, 2)
                labelChip(text: "解锁后显形", tint: SoloTheme.muted.opacity(0.35))
            } else {
                Text(guide.publicSummary)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    labelChip(text: "~\(guide.estimatedMinutes)分钟", tint: SoloTheme.gold)
                    labelChip(text: "\(guide.interactionCount)个选择", tint: SoloTheme.jade)
                    if let hint = guide.hiddenRouteHint, isCompleted {
                        labelChip(text: hint, tint: SoloTheme.crimson)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCurrent ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isCurrent ? SoloTheme.crimson.opacity(0.20) : Color.white.opacity(0.04),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Characters Tab

    private var charactersTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("人物档案")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.ink)
                Spacer()
                Text("\(relationships.count) / \(book.characters.count) 已认识")
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.muted)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(book.characters) { character in
                    let relation = relationships.first(where: { $0.characterId == character.id })
                    characterCard(character, relation: relation)
                }
            }
        }
    }

    private func characterCard(_ character: Character, relation: RelationshipState?) -> some View {
        let isUnlocked = relation != nil

        return VStack(alignment: .leading, spacing: 10) {
            // Avatar area
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isUnlocked ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    .frame(height: 68)

                if isUnlocked {
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(SoloTheme.gold.opacity(0.65))
                } else {
                    // Silhouette
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.white.opacity(0.06))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SoloTheme.muted.opacity(0.45))
                        .offset(x: 14, y: 16)
                }
            }

            // Identity
            if isUnlocked {
                Text(character.name)
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)
                Text(character.title)
                    .font(.caption2)
                    .foregroundStyle(SoloTheme.gold.opacity(0.8))
                    .lineLimit(1)
                if let relation {
                    Text(relation.attitudeLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.jade)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(SoloTheme.jade.opacity(0.12)))
                }
            } else {
                Text("???")
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.muted.opacity(0.35))
                Text("尚未相遇")
                    .font(.caption2)
                    .foregroundStyle(SoloTheme.muted.opacity(0.28))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .soloPanel(isUnlocked ? .evidence : .quiet, prominence: isUnlocked ? 0.12 : 0)
    }

    // MARK: - Dark Lines Tab

    private var darklinesTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section intro
            VStack(alignment: .leading, spacing: 8) {
                Text("异常记录")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.ink)
                Text("明线之外的暗流。有些信号已经浮出水面，有些还需要你亲手触达。")
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
            }
            .padding(18)
            .soloPanel(.stage)

            // Hint cards
            if let walkthrough {
                let hintPairs: [(String, Bool)] = walkthrough.chapterGuides.compactMap { guide in
                    guard let hint = guide.hiddenRouteHint else { return nil }
                    let discovered = routeSnapshot.completedChapterIDs.contains(guide.chapterId)
                    return (hint, discovered)
                }

                if hintPairs.isEmpty {
                    noHintsPlaceholder
                } else {
                    ForEach(Array(hintPairs.enumerated()), id: \.offset) { idx, pair in
                        darklineCard(hint: pair.0, isDiscovered: pair.1, index: idx)
                    }
                }
            } else {
                noHintsPlaceholder
            }
        }
    }

    private func darklineCard(hint: String, isDiscovered: Bool, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDiscovered
                          ? SoloTheme.crimson.opacity(0.18)
                          : Color.white.opacity(0.04))
                    .frame(width: 36, height: 36)
                Image(systemName: isDiscovered ? "waveform.path.ecg" : "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isDiscovered
                                     ? SoloTheme.crimson
                                     : SoloTheme.muted.opacity(0.35))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(isDiscovered ? "异常信号 #\(index + 1)" : "??? 信号 #\(index + 1)")
                    .font(SoloTypography.meta)
                    .foregroundStyle(isDiscovered
                                     ? SoloTheme.crimson
                                     : SoloTheme.muted.opacity(0.35))

                if isDiscovered {
                    Text(hint)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineSpacing(5)
                } else {
                    Text("███████ ████ ████████████ ████")
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.muted.opacity(0.16))
                    Text("████ ████████")
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.muted.opacity(0.10))
                    Text("继续推进后解锁")
                        .font(.caption2.italic())
                        .foregroundStyle(SoloTheme.muted.opacity(0.32))
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .soloPanel(isDiscovered ? .alert : .quiet, prominence: isDiscovered ? 0.16 : 0)
    }

    private var noHintsPlaceholder: some View {
        Text("推进故事后，暗线信号会陆续浮现。")
            .foregroundStyle(SoloTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(24)
    }

    // MARK: - Helpers

    private var discoveredHints: [String] {
        walkthrough?.chapterGuides.compactMap { guide -> String? in
            guard let hint = guide.hiddenRouteHint,
                  routeSnapshot.completedChapterIDs.contains(guide.chapterId) else { return nil }
            return hint
        } ?? []
    }

    private func isStageUnlocked(_ stage: WalkthroughStage) -> Bool {
        if routeSnapshot.currentStageID == stage.id { return true }
        return stage.chapterIds.contains(where: {
            routeSnapshot.completedChapterIDs.contains($0) || $0 == routeSnapshot.currentChapterID
        })
    }

    private func guides(in stage: WalkthroughStage) -> [WalkthroughChapterGuide] {
        walkthrough?.chapterGuides.filter { $0.stageId == stage.id } ?? []
    }

    private func labelChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}
