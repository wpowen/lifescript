import SwiftUI

struct SoloEntryView: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let readingRoute: SoloRoute?
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let openSettings: () -> Void
    let openChapterBrowser: () -> Void

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
                            openSettings: openSettings,
                            openChapterBrowser: openChapterBrowser
                        )

                        if book.id == "天机录" {
                            SoloEntryOracleShellModule(snapshot: snapshot)
                        }
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

    private var primaryActionTitle: String {
        if case .volumeGate = readingRoute {
            return SoloLocalization.localized("解锁下一卷")
        }

        return snapshot.progress.completedChapterCount == 0
            ? snapshot.branding.landing.primaryActionTitle
            : SoloLocalization.localized("继续当前事件")
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
