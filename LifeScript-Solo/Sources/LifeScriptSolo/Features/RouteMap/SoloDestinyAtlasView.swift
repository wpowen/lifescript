import SwiftUI

struct SoloDestinyAtlasView: View {
    let book: Book
    let snapshot: SoloDestinyAtlasSnapshot
    let destinyStatus: SoloDestinyStatus

    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        ZStack {
            sceneBackground
            contentDimmer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    routeTimeline
                        .padding(.horizontal, 20)

                    omenPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .soloStoryChrome(title: book.id == "天机录" ? "命途" : "世界线", kicker: "推演")
    }

    @ViewBuilder
    private var sceneBackground: some View {
        if book.id == "天机录" {
            TianjiluHomeScene(illustration: TianjiluArtworkCatalog.routeBanner)
                .ignoresSafeArea()
        } else {
            SoloBackdrop()
        }
    }

    private var contentDimmer: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.50),
                Color.black.opacity(0.78),
                Color.black.opacity(0.92),
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.38)
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snapshot.currentStageTitle)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(snapshot.progressLine)
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)
            Text(destinyStatus.detail)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            HStack(spacing: 10) {
                badge(text: "天命值 \(destinyStatus.value)", tint: destinyTint)
                badge(text: destinyStatus.thresholdHint, tint: SoloTheme.gold)
            }
        }
        .padding(20)
        .soloPanel(.hero, prominence: 0.18)
    }

    // MARK: - Route Timeline

    private var routeTimeline: some View {
        let nodes = snapshot.stageNodes
        let trackX: CGFloat = 28
        let nodeRadius: CGFloat = 10
        let segmentHeight: CGFloat = 18

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                let isFirst = index == 0
                let isLast = index == nodes.count - 1
                let prevNode: SoloDestinyStageNode? = index > 0 ? nodes[index - 1] : nil

                HStack(alignment: .top, spacing: 0) {
                    trackColumn(
                        node: node,
                        prevNode: prevNode,
                        isFirst: isFirst,
                        isLast: isLast,
                        trackX: trackX,
                        nodeRadius: nodeRadius,
                        segmentHeight: segmentHeight
                    )
                    .frame(width: trackX * 2)

                    stageContent(node: node, index: index)
                        .padding(.leading, 6)
                        .padding(.bottom, isLast ? 0 : 20)
                }
            }
        }
    }

    @ViewBuilder
    private func trackColumn(
        node: SoloDestinyStageNode,
        prevNode: SoloDestinyStageNode?,
        isFirst: Bool,
        isLast: Bool,
        trackX: CGFloat,
        nodeRadius: CGFloat,
        segmentHeight: CGFloat
    ) -> some View {
        let tint = nodeTint(for: node)

        GeometryReader { geo in
            let midX = trackX
            let nodeY: CGFloat = segmentHeight + nodeRadius

            if !isFirst, let prevNode {
                trackSegment(
                    from: CGPoint(x: midX, y: 0),
                    to: CGPoint(x: midX, y: nodeY - nodeRadius),
                    sourceVisibility: prevNode.visibility,
                    targetVisibility: node.visibility
                )
            }

            if !isLast {
                trackSegment(
                    from: CGPoint(x: midX, y: nodeY + nodeRadius),
                    to: CGPoint(x: midX, y: geo.size.height),
                    sourceVisibility: node.visibility,
                    targetVisibility: .veiled
                )
            }

            nodeMarker(tint: tint, visibility: node.visibility)
                .position(x: midX, y: nodeY)
        }
    }

    private func trackSegment(
        from start: CGPoint,
        to end: CGPoint,
        sourceVisibility: SoloDestinyStageNode.Visibility,
        targetVisibility: SoloDestinyStageNode.Visibility
    ) -> some View {
        let isPassed = sourceVisibility == .passed
        let isSolid = isPassed || sourceVisibility == .current

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            isSolid
                ? AnyShapeStyle(LinearGradient(
                    colors: [
                        isPassed ? SoloTheme.jade.opacity(0.72) : SoloTheme.gold.opacity(0.82),
                        targetVisibility == .veiled ? SoloTheme.muted.opacity(0.24) : SoloTheme.gold.opacity(0.60),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                : AnyShapeStyle(SoloTheme.muted.opacity(0.20)),
            style: isSolid
                ? StrokeStyle(lineWidth: 2.4)
                : StrokeStyle(lineWidth: 1.4, dash: [5, 6])
        )
    }

    @ViewBuilder
    private func nodeMarker(tint: Color, visibility: SoloDestinyStageNode.Visibility) -> some View {
        ZStack {
            if visibility == .current && !reduceMotion {
                TimelineView(.animation(minimumInterval: 0.08)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = sin(t * 2.0) * 0.5 + 0.5
                    Circle()
                        .fill(tint.opacity(0.18 + pulse * 0.14))
                        .frame(width: 32, height: 32)
                }
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint, tint.opacity(0.60)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(visibility == .veiled ? 0.10 : 0.30), lineWidth: 1.5)
                )

            if visibility == .passed {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.white)
            }
        }
    }

    // MARK: - Stage Content

    private func stageContent(node: SoloDestinyStageNode, index: Int) -> some View {
        let tint = nodeTint(for: node)
        let isTianjilu = book.id == "天机录"
        let volumeVisual: TianjiluVolumeVisual? = isTianjilu
            ? TianjiluArtworkCatalog.volume(stageIndex: index, stageCount: snapshot.stageNodes.count)
            : nil

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(stageLabel(for: node))
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(tint)
                Spacer()
                badge(text: statusLabel(for: node), tint: tint)
            }

            Text(node.title)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink)

            if let visual = volumeVisual, node.visibility != .veiled {
                SoloBundledArtworkImage(resourceName: visual.cover.resourceName, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(tint.opacity(0.22), lineWidth: 1)
                    )
                    .opacity(node.visibility == .passed ? 0.80 : 1.0)
            }

            Text(node.summary)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            progressBar(node: node, tint: tint)
        }
        .padding(16)
        .soloPanel(
            node.visibility == .current ? .hero : (node.visibility == .passed ? .evidence : .quiet),
            prominence: node.visibility == .current ? 0.20 : 0.10
        )
    }

    private func progressBar(node: SoloDestinyStageNode, tint: Color) -> some View {
        let total = max(node.totalChapterCount, 1)
        let ratio = CGFloat(node.completedChapterCount) / CGFloat(total)

        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(tint.opacity(0.88))
                        .frame(width: geo.size.width * ratio, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(node.completedChapterCount) / \(total) 章已触达")
                .font(.caption2)
                .foregroundStyle(tint.opacity(0.82))
        }
    }

    // MARK: - Omen

    private var omenPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("将至征兆")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.crimson)
            Text(snapshot.omenLine)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(5)
            Text(snapshot.pressureLine)
                .font(.caption)
                .foregroundStyle(SoloTheme.muted)
        }
        .padding(20)
        .soloPanel(.alert, prominence: 0.14)
    }

    // MARK: - Helpers

    private func nodeTint(for node: SoloDestinyStageNode) -> Color {
        switch node.visibility {
        case .passed:  return SoloTheme.jade
        case .current: return SoloTheme.gold
        case .veiled:  return SoloTheme.muted
        }
    }

    private func stageLabel(for node: SoloDestinyStageNode) -> String {
        switch node.visibility {
        case .passed:  return "已行之路"
        case .current: return "眼前棋局"
        case .veiled:  return "将至征兆"
        }
    }

    private func statusLabel(for node: SoloDestinyStageNode) -> String {
        switch node.visibility {
        case .passed:  return "已走完"
        case .current: return "正在推进"
        case .veiled:  return "未显形"
        }
    }

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    private var destinyTint: Color {
        switch destinyStatus.level {
        case .abundant:         return SoloTheme.jade
        case .steady:           return SoloTheme.gold
        case .strained, .critical: return SoloTheme.crimson
        }
    }
}
