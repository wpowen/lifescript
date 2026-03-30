import SwiftUI

struct SoloEntryView: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let readingRoute: SoloRoute?
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let openSettings: () -> Void

    @State private var isScrollActive = false
    @State private var lastObservedScrollOffset: CGFloat?
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollIdleTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    SoloEntryScrollProbe()

                    SoloEntryHeroScene(
                        book: book,
                        snapshot: snapshot,
                        primaryActionTitle: primaryActionTitle,
                        secondaryActionTitle: snapshot.branding.landing.secondaryActionTitle,
                        readingRoute: readingRoute,
                        openWorld: openRouteMap,
                        animationsEnabled: heroAnimationsEnabled
                    )

                    // 以下各区块保持正常 padding
                    VStack(alignment: .leading, spacing: 32) {
                        SoloEntryContinueRail(
                            book: book,
                            snapshot: snapshot,
                            openDossier: openDossier,
                            openRouteMap: openRouteMap,
                            openSettings: openSettings
                        )

                        if book.id == "天机录" {
                            SoloEntryOracleShellModule(snapshot: snapshot)
                        }

                        if snapshot.generatedChapterCount < snapshot.plannedChapterCount {
                            serialPulsePanel
                        }

                        if snapshot.progress.completedChapterCount > 0 {
                            worldStatePanel
                        }

                        SoloEntryWorldProofStrip(book: book, snapshot: snapshot)

                        SoloEntryHookSection(
                            snapshot: snapshot,
                            primaryActionTitle: primaryActionTitle,
                            secondaryActionTitle: snapshot.branding.landing.secondaryActionTitle,
                            readingRoute: readingRoute,
                            openWorld: openRouteMap
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 56)
                }
            }
            // ← 关键：ScrollView 整体延伸进顶部安全区，消除硬切分割线
            .coordinateSpace(name: "soloEntryScroll")
            .ignoresSafeArea(edges: .top)
            .onPreferenceChange(SoloEntryScrollOffsetPreferenceKey.self, perform: handleScrollOffsetChange)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            scrollIdleTask?.cancel()
        }
    }

    // MARK: - World State Panel

    private var serialPulsePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("内容进度")
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(snapshot.generatedChapterCount) / \(snapshot.plannedChapterCount)")
                        .font(SoloTypography.posterTitle(size: 26, weight: .bold))
                        .foregroundStyle(SoloTheme.ink)
                    Text("当前版本收录章节")
                        .font(.caption)
                        .foregroundStyle(SoloTheme.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(serialCoverage * 100))%")
                        .font(SoloTypography.sceneHeadline(size: 20))
                        .foregroundStyle(SoloTheme.crimson)
                    Text("内容已接入")
                        .font(.caption2)
                        .foregroundStyle(SoloTheme.muted)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.gold, SoloTheme.crimson],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * serialCoverage)
                }
            }
            .frame(height: 6)

            Text(snapshot.serialReleaseLine)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
        }
        .padding(18)
        .soloPanel(.alert, prominence: 0.16)
    }

    private var worldStatePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("世界状态")
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)

            VStack(spacing: 0) {
                // Stats
                if !snapshot.worldStatDeltas.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(snapshot.worldStatDeltas, id: \.name) { stat in
                            worldStatRow(stat)
                        }
                    }
                    .padding(.bottom, 14)

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                        .padding(.bottom, 14)
                }

                // Characters
                if !snapshot.worldCharacters.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(snapshot.worldCharacters, id: \.name) { char in
                            worldCharRow(char)
                        }
                    }
                }
            }
            .padding(18)
            .soloPanel(.stage, prominence: 0.2)
        }
    }

    private func worldStatRow(_ stat: SoloWorldStatDelta) -> some View {
        HStack(spacing: 12) {
            Text(stat.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted)
                .frame(width: 44, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.gold.opacity(0.70), SoloTheme.jade.opacity(0.50)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(stat.value, 100)) / 100)
                }
            }
            .frame(height: 4)

            Text("\(stat.value)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SoloTheme.ink)
                .frame(width: 28, alignment: .trailing)

            if stat.delta != 0 {
                Text(stat.delta > 0 ? "+\(stat.delta)" : "\(stat.delta)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(stat.delta > 0 ? SoloTheme.jade : SoloTheme.crimson)
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }

    private func worldCharRow(_ char: SoloWorldCharacterStatus) -> some View {
        HStack(spacing: 10) {
            if book.id == "天机录",
               let portrait = TianjiluArtworkCatalog.portrait(for: char.characterId) {
                SoloBundledArtworkImage(resourceName: portrait.resourceName, contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(SoloTheme.gold.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SoloTheme.gold.opacity(0.60))
                    )
            }

            Text(char.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoloTheme.ink)

            Spacer()

            Text(char.attitudeLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(SoloTheme.warmInk)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.07))
                .clipShape(Capsule())
        }
    }

    private var primaryActionTitle: String {
        if case .volumeGate = readingRoute {
            return "解锁下一卷"
        }

        return snapshot.progress.completedChapterCount == 0
            ? snapshot.branding.landing.primaryActionTitle
            : "继续当前事件"
    }

    private var serialCoverage: CGFloat {
        CGFloat(snapshot.generatedChapterCount) / CGFloat(max(snapshot.plannedChapterCount, 1))
    }

    private var heroAnimationsEnabled: Bool {
        !isScrollActive && scrollOffset > -460
    }

    private func handleScrollOffsetChange(_ offset: CGFloat) {
        let previousOffset = lastObservedScrollOffset
        lastObservedScrollOffset = offset
        scrollOffset = offset

        guard let previousOffset, abs(previousOffset - offset) > 0.5 else { return }

        isScrollActive = true
        scrollIdleTask?.cancel()
        scrollIdleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !Task.isCancelled else { return }
            isScrollActive = false
        }
    }
}

private struct SoloEntryScrollProbe: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: SoloEntryScrollOffsetPreferenceKey.self,
                value: geo.frame(in: .named("soloEntryScroll")).minY
            )
        }
        .frame(height: 0)
    }
}

private struct SoloEntryScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
