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
                    Text(SoloLocalization.localized("卷一已免费开放"))
                        .font(.caption.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(SoloTheme.gold)

                    Text(SoloLocalization.format("接下来即将进入%@", volume.localizedTitle))
                        .font(SoloTypography.posterTitle(size: 30))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(volume.localizedTeaser)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(6)
                }

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(
                        title: SoloLocalization.localized("待解锁章节"),
                        value: SoloLocalization.format("第 %d 章 · %@", chapter.number, SoloLocalization.localized(chapter.title))
                    )
                    detailRow(
                        title: SoloLocalization.localized("解锁价格"),
                        value: priceDisplay
                    )
                    detailRow(
                        title: SoloLocalization.localized("解锁方式"),
                        value: SoloLocalization.localized("单卷永久解锁，可恢复购买")
                    )
                }
                .padding(18)
                .soloPanel(.stage, prominence: 0.20)

                if let previewSnippet = chapter.openingPreviewSnippet {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(SoloLocalization.localized("下一章试读"))
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text(SoloLocalization.format("第 %d 章 · %@", chapter.number, SoloLocalization.localized(chapter.title)))
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

                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .overlay { loadingOverlay }
        .background(SoloBackdrop())
        .navigationTitle(SoloLocalization.localized("解锁新卷"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await volumeStore.loadIfNeeded() }
        .onDisappear { volumeStore.clearStatusMessage() }
    }

    // MARK: - Subviews

    private var actionButtons: some View {
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
            .disabled(volumeStore.isOperationInProgress)

            Button(SoloLocalization.localized("恢复已购卷")) {
                Task { _ = await volumeStore.restorePurchases() }
            }
            .buttonStyle(SoloGhostActionButtonStyle())
            .foregroundStyle(SoloTheme.jade)
            .disabled(volumeStore.isOperationInProgress)

            Button(SoloLocalization.localized("稍后再说")) {
                onClose()
            }
            .buttonStyle(SoloGhostActionButtonStyle())
            .foregroundStyle(SoloTheme.muted)
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if volumeStore.loadState == .loading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(SoloTheme.gold)
                    .scaleEffect(1.2)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: volumeStore.loadState)
        }
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

    // MARK: - Computed

    private var priceDisplay: String {
        if volumeStore.loadState == .loading {
            return SoloLocalization.localized("正在获取…")
        }
        return volumeStore.displayPrice(for: volume)
    }

    private var primaryActionTitle: String {
        if volumeStore.isUnlocked(volume) {
            return SoloLocalization.format("继续进入%@", volume.shortTitle)
        }

        return SoloLocalization.format("解锁%@ · %@", volume.shortTitle, volumeStore.displayPrice(for: volume))
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
