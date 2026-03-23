import SwiftUI

struct SoloEntryView: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let openReading: () -> Void
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let openSettings: () -> Void

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    SoloEntryHeroScene(
                        book: book,
                        snapshot: snapshot,
                        primaryActionTitle: primaryActionTitle,
                        secondaryActionTitle: snapshot.branding.landing.secondaryActionTitle,
                        openReading: openReading,
                        openWorld: openRouteMap
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

                        SoloEntryWorldProofStrip(book: book, snapshot: snapshot)

                        SoloEntryHookSection(
                            snapshot: snapshot,
                            primaryActionTitle: primaryActionTitle,
                            secondaryActionTitle: snapshot.branding.landing.secondaryActionTitle,
                            openReading: openReading,
                            openWorld: openRouteMap
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 56)
                }
            }
            // ← 关键：ScrollView 整体延伸进顶部安全区，消除硬切分割线
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var primaryActionTitle: String {
        snapshot.progress.completedChapterCount == 0
            ? snapshot.branding.landing.primaryActionTitle
            : "继续当前事件"
    }
}
