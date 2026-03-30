import SwiftUI

struct SoloVolumePaywallView: View {
    let book: Book
    let chapter: Chapter
    let volume: SoloVolumePlan
    let volumeStore: SoloVolumeStore
    let onContinue: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                artworkCard

                VStack(alignment: .leading, spacing: 10) {
                    Text("卷一已免费开放")
                        .font(.caption.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(SoloTheme.gold)

                    Text("接下来即将进入\(volume.title)")
                        .font(SoloTypography.posterTitle(size: 30))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(volume.teaser)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(6)
                }

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(title: "待解锁章节", value: "第 \(chapter.number) 章 · \(chapter.title)")
                    detailRow(title: "解锁价格", value: volumeStore.displayPrice(for: volume))
                    detailRow(title: "解锁方式", value: "单卷永久解锁，可恢复购买")
                }
                .padding(18)
                .soloPanel(.stage, prominence: 0.20)

                if let previewSnippet = chapter.openingPreviewSnippet {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("下一章试读")
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text("第 \(chapter.number) 章 · \(chapter.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoloTheme.ink)
                        Text(previewSnippet)
                            .font(SoloTypography.detail)
                            .foregroundStyle(SoloTheme.warmInk)
                            .lineSpacing(6)
                    }
                    .padding(18)
                    .soloPanel(.alert, prominence: 0.18)
                }

                if let statusMessage = volumeStore.statusMessage {
                    Text(statusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SoloTheme.warmInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(spacing: 12) {
                    Button(primaryActionTitle) {
                        Task {
                            if volumeStore.isUnlocked(volume) {
                                onContinue()
                                return
                            }

                            let unlocked = await volumeStore.purchase(volume)
                            if unlocked {
                                onContinue()
                            }
                        }
                    }
                    .buttonStyle(SoloPrimaryActionButtonStyle())
                    .disabled(isPrimaryActionDisabled)

                    Button("恢复已购卷") {
                        Task { _ = await volumeStore.restorePurchases() }
                    }
                    .buttonStyle(SoloGhostActionButtonStyle())
                    .foregroundStyle(SoloTheme.jade)

                    Button("稍后再说") {
                        onClose()
                    }
                    .buttonStyle(SoloGhostActionButtonStyle())
                    .foregroundStyle(SoloTheme.muted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(SoloBackdrop())
        .navigationTitle("解锁新卷")
        .navigationBarTitleDisplayMode(.inline)
        .task { await volumeStore.loadIfNeeded() }
        .onDisappear { volumeStore.clearStatusMessage() }
    }

    private var artworkCard: some View {
        let artwork = book.id == "天机录"
            ? TianjiluArtworkCatalog.volume(for: chapter.number).cover
            : TianjiluArtworkCatalog.welcomeCover

        return SoloArtworkCard(
            asset: artwork,
            height: 260,
            contentMode: .fill,
            tint: SoloTheme.gold,
            cornerRadius: 22
        )
    }

    private var primaryActionTitle: String {
        if volumeStore.isUnlocked(volume) {
            return "继续进入\(volume.shortTitle)"
        }

        return "解锁\(volume.shortTitle) · \(volumeStore.displayPrice(for: volume))"
    }

    private var isPrimaryActionDisabled: Bool {
        guard let productID = volume.productID else { return false }
        return volumeStore.activePurchaseProductID == productID
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
