import SwiftUI

@MainActor
struct SoloChapterBrowserView: View {
    let chapters: [Chapter]
    let volumeStore: SoloVolumeStore
    let currentChapterId: String?

    @Environment(SoloCoordinator.self) private var coordinator
    @State private var expandedVolumeIDs: Set<String> = []
    @State private var purchasingVolume: SoloVolumePlan?
    @State private var progressAnimated = false

    init(
        chapters: [Chapter],
        volumeStore: SoloVolumeStore,
        currentChapterId: String? = nil
    ) {
        self.chapters = chapters
        self.volumeStore = volumeStore
        self.currentChapterId = currentChapterId
    }

    // MARK: - Computed State

    private var currentChapterNumber: Int? {
        guard let id = currentChapterId else { return nil }
        return chapters.first(where: { $0.id == id })?.number
    }

    private var currentChapterTitle: String? {
        guard let id = currentChapterId else { return nil }
        return chapters.first(where: { $0.id == id }).map { SoloLocalization.localized($0.title) }
    }

    private var overallProgressFraction: Double {
        guard let n = currentChapterNumber, !chapters.isEmpty else { return 0 }
        return Double(n) / Double(chapters.count)
    }

    private func isCompleted(_ chapter: Chapter) -> Bool {
        guard let n = currentChapterNumber else { return false }
        return chapter.number < n
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    readingProgressCard
                        .padding(.top, 4)

                    if !volumeStore.plans.isEmpty {
                        ForEach(volumeStore.plans) { volume in
                            volumeAccordion(volume)
                        }
                    } else {
                        flatChapterSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(SoloLocalization.localized("章节目录"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if let message = volumeStore.statusMessage {
                statusBanner(message)
            }
        }
        .onAppear {
            setupInitialExpansion()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                progressAnimated = true
            }
        }
    }

    private func setupInitialExpansion() {
        if let firstPlan = volumeStore.plans.first {
            expandedVolumeIDs.insert(firstPlan.id)
        }
        if let chapterId = currentChapterId,
           let chapter = chapters.first(where: { $0.id == chapterId }),
           let plan = volumeStore.plans.first(where: { $0.chapterRange.contains(chapter.number) }) {
            expandedVolumeIDs.insert(plan.id)
        }
    }

    // MARK: - Reading Progress Card

    private var readingProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                Text(SoloLocalization.localized("阅读进度"))
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)
                Spacer()
                if overallProgressFraction > 0 {
                    Text("\(Int(overallProgressFraction * 100))%")
                        .font(SoloTypography.chromeTitle(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SoloTheme.gold, SoloTheme.crimson],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }

            // Current chapter display
            if let title = currentChapterTitle, let num = currentChapterNumber {
                VStack(alignment: .leading, spacing: 3) {
                    Text(SoloLocalization.format("第%d章", num))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloTheme.gold.opacity(0.72))
                    Text(title)
                        .font(SoloTypography.sceneHeadline(size: 20))
                        .foregroundStyle(SoloTheme.ink)
                        .lineLimit(1)
                }
            } else {
                Text(SoloLocalization.localized("尚未开始阅读"))
                    .font(SoloTypography.sceneHeadline(size: 20))
                    .foregroundStyle(SoloTheme.muted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)

                    // Fill
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.gold, SoloTheme.crimson],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (progressAnimated ? overallProgressFraction : 0),
                            height: 5
                        )
                        .animation(
                            .easeOut(duration: 1.2).delay(0.3),
                            value: progressAnimated
                        )
                }
            }
            .frame(height: 5)

            // Footer stat
            HStack {
                if let n = currentChapterNumber {
                    Text(SoloLocalization.format("已读 %d 章", n))
                        .font(SoloTypography.caption)
                        .foregroundStyle(SoloTheme.muted)
                }
                Spacer()
                Text(SoloLocalization.format("共 %d 章", chapters.count))
                    .font(SoloTypography.caption)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .soloPanel(.stage, prominence: 0.28)
    }

    // MARK: - Volume Accordion

    @ViewBuilder
    private func volumeAccordion(_ volume: SoloVolumePlan) -> some View {
        let isExpanded = expandedVolumeIDs.contains(volume.id)
        let isUnlocked = volumeStore.isUnlocked(volume)
        let volumeChapters = chapters.filter { volume.chapterRange.contains($0.number) }
        let accent = volumeAccentColor(isFree: volume.isFree, isUnlocked: isUnlocked)

        VStack(spacing: 0) {
            volumeHeaderRow(
                volume: volume,
                isExpanded: isExpanded,
                isUnlocked: isUnlocked,
                chapterCount: volumeChapters.count,
                accent: accent
            )

            if isExpanded {
                // Separator
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.30), Color.white.opacity(0.04), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.leading, 56)
                    .transition(.opacity)

                if !isUnlocked {
                    unlockButtonRow(volume: volume)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                }

                VStack(spacing: 0) {
                    ForEach(Array(volumeChapters.enumerated()), id: \.element.id) { index, chapter in
                        chapterRow(
                            chapter: chapter,
                            isLocked: !isUnlocked,
                            showDivider: index < volumeChapters.count - 1,
                            isCurrent: chapter.id == currentChapterId,
                            isCompleted: isCompleted(chapter)
                        )
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .soloPanel(.stage, prominence: 0.18)
    }

    // MARK: - Volume Header Row

    private func volumeHeaderRow(
        volume: SoloVolumePlan,
        isExpanded: Bool,
        isUnlocked: Bool,
        chapterCount: Int,
        accent: Color
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.40, dampingFraction: 0.80)) {
                if expandedVolumeIDs.contains(volume.id) {
                    expandedVolumeIDs.remove(volume.id)
                } else {
                    expandedVolumeIDs.insert(volume.id)
                }
            }
        } label: {
            ZStack(alignment: .trailing) {
                // Roman numeral watermark
                Text(romanNumeral(for: volume.index))
                    .font(.system(size: 72, weight: .black, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.03))
                    .offset(x: -8)
                    .allowsHitTesting(false)

                HStack(alignment: .center, spacing: 0) {
                    // Left accent bar
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(accent.opacity(isExpanded ? 1.0 : 0.5))
                        .frame(width: 3)
                        .padding(.vertical, 12)

                    // Volume badge
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.14))
                        Circle()
                            .strokeBorder(accent.opacity(0.28), lineWidth: 1)
                        Text("\(volume.index)")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(accent)
                    }
                    .frame(width: 38, height: 38)
                    .padding(.leading, 14)

                    // Content
                    VStack(alignment: .leading, spacing: 5) {
                        Text(volume.localizedTitle)
                            .font(SoloTypography.chromeTitle(size: 17, weight: .semibold))
                            .foregroundStyle(SoloTheme.ink)
                            .lineLimit(1)

                        Text(SoloLocalization.format("第%d–%d章 · 共%d节", volume.chapterRange.lowerBound, volume.chapterRange.upperBound, chapterCount))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(SoloTheme.muted)

                        // Teaser — only visible when collapsed
                        if !isExpanded && !volume.teaser.isEmpty {
                            Text(volume.localizedTeaser)
                                .font(SoloTypography.detail)
                                .foregroundStyle(SoloTheme.muted.opacity(0.75))
                                .lineLimit(2)
                                .lineSpacing(3)
                                .padding(.top, 2)
                                .transition(.opacity)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.vertical, 14)

                    Spacer()

                    // Status badge
                    volumeStatusBadge(volume: volume, isUnlocked: isUnlocked)
                        .padding(.trailing, 10)

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SoloTheme.muted.opacity(0.40))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.trailing, 16)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func volumeStatusBadge(volume: SoloVolumePlan, isUnlocked: Bool) -> some View {
        if volume.isFree {
            Text(SoloLocalization.localized("免费"))
                .font(.caption2.weight(.bold))
                .foregroundStyle(SoloTheme.jade)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(SoloTheme.jade.opacity(0.14))
                .clipShape(Capsule())
        } else if isUnlocked {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                Text(SoloLocalization.localized("已解锁"))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(SoloTheme.gold)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(SoloTheme.gold.opacity(0.10))
            .overlay(
                Capsule()
                    .strokeBorder(SoloTheme.gold.opacity(0.22), lineWidth: 1)
            )
            .clipShape(Capsule())
        } else {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text(SoloLocalization.format("未解锁 · %@", volumeStore.displayPrice(for: volume)))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(SoloTheme.gold.opacity(0.92))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(SoloTheme.gold.opacity(0.10))
            .overlay(
                Capsule()
                    .strokeBorder(SoloTheme.gold.opacity(0.18), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Unlock Button Row

    private func unlockButtonRow(volume: SoloVolumePlan) -> some View {
        let isPurchasing = purchasingVolume?.id == volume.id
        let price = volumeStore.displayPrice(for: volume)

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(SoloLocalization.localized("本卷需解锁后阅读"))
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(SoloTheme.gold)
                    Spacer()
                    Text(price)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloTheme.gold)
                }

                Text(volume.localizedTitle)
                    .font(SoloTypography.sceneHeadline(size: 22))
                    .foregroundStyle(SoloTheme.ink)

                HStack(spacing: 10) {
                    unlockMetaChip(
                        icon: "text.book.closed.fill",
                        text: SoloLocalization.format(
                            "第%d-%d章",
                            volume.chapterRange.lowerBound,
                            volume.chapterRange.upperBound
                        )
                    )
                    unlockMetaChip(
                        icon: "tray.and.arrow.down.fill",
                        text: SoloLocalization.localized("单卷永久解锁")
                    )
                    unlockMetaChip(
                        icon: "arrow.clockwise",
                        text: SoloLocalization.localized("支持恢复购买")
                    )
                }

                Text(volume.localizedTeaser)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.warmInk.opacity(0.86))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Button {
                Task {
                    purchasingVolume = volume
                    _ = await volumeStore.purchase(volume)
                    purchasingVolume = nil
                }
            } label: {
                HStack(spacing: 12) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(SoloTheme.ink)
                            .scaleEffect(0.82)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.subheadline.weight(.bold))
                    }

                    Text(
                        isPurchasing
                            ? SoloLocalization.localized("正在处理购买…")
                            : SoloLocalization.format("解锁%@并继续阅读", volume.shortTitle)
                    )
                    .font(.headline.weight(.semibold))

                    Spacer()

                    Text(price)
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(SoloTheme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(SoloTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing || volumeStore.isOperationInProgress)
            .opacity(isPurchasing ? 0.70 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [SoloTheme.gold.opacity(0.16), SoloTheme.gold.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [SoloTheme.gold.opacity(0.45), SoloTheme.gold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .opacity(isPurchasing ? 0.76 : 1.0)
    }

    private func unlockMetaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(SoloTheme.warmInk)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    // MARK: - Chapter Row

    private func chapterRow(
        chapter: Chapter,
        isLocked: Bool,
        showDivider: Bool,
        isCurrent: Bool,
        isCompleted: Bool
    ) -> some View {
        Button {
            if isLocked {
                coordinator.open(.volumeGate(chapter.id))
            } else {
                coordinator.open(.reading(chapter.id))
            }
        } label: {
            HStack(spacing: 0) {
                // Left accent glow for current chapter
                Rectangle()
                    .fill(isCurrent ? SoloTheme.gold.opacity(0.75) : Color.clear)
                    .frame(width: 2)
                    .padding(.vertical, isCurrent ? 6 : 0)

                HStack(spacing: 12) {
                    // Status dot
                    ZStack {
                        if isCurrent {
                            Circle()
                                .fill(SoloTheme.gold)
                                .frame(width: 6, height: 6)
                                .shadow(color: SoloTheme.gold.opacity(0.80), radius: 4)
                        } else if isCompleted {
                            Circle()
                                .fill(SoloTheme.jade.opacity(0.70))
                                .frame(width: 5, height: 5)
                        } else if !isLocked {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 5, height: 5)
                        } else {
                            Color.clear
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(width: 14, alignment: .center)

                    // Chapter number
                    Text(SoloLocalization.format("第%d章", chapter.number))
                        .font(.system(size: 11, weight: isCurrent ? .bold : .semibold, design: .serif))
                        .foregroundStyle(
                            isCurrent
                                ? SoloTheme.gold
                                : (isCompleted ? SoloTheme.muted : SoloTheme.gold.opacity(0.45))
                        )
                        .frame(width: 56, alignment: .leading)

                    // Chapter title
                    Text(SoloLocalization.localized(chapter.title))
                        .font(
                            isCurrent
                                ? .subheadline.weight(.semibold)
                                : SoloTypography.detail
                        )
                        .foregroundStyle(
                            isLocked
                                ? SoloTheme.muted
                                : (isCurrent
                                    ? SoloTheme.ink
                                    : (isCompleted
                                        ? SoloTheme.warmInk.opacity(0.68)
                                        : SoloTheme.warmInk))
                        )
                        .lineLimit(1)

                    Spacer()

                    // Right indicator
                    if isCurrent {
                        Text(SoloLocalization.localized("阅读中"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SoloTheme.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SoloTheme.gold.opacity(0.14))
                            .clipShape(Capsule())
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(SoloTheme.muted.opacity(0.38))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SoloTheme.muted.opacity(0.25))
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.vertical, 11)
            }
            .background(
                isCurrent
                    ? LinearGradient(
                        colors: [SoloTheme.gold.opacity(0.09), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
            )
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if showDivider {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                        .padding(.leading, 90)
                }
            }
            .opacity(isLocked ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flat Chapter Section

    private var flatChapterSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                chapterRow(
                    chapter: chapter,
                    isLocked: false,
                    showDivider: index < chapters.count - 1,
                    isCurrent: chapter.id == currentChapterId,
                    isCompleted: isCompleted(chapter)
                )
            }
        }
        .soloPanel(.stage, prominence: 0.18)
    }

    // MARK: - Status Banner

    private func statusBanner(_ message: String) -> some View {
        let isError = message.contains("失败") || message.contains("错误")
        let accentColor = isError ? SoloTheme.crimson : SoloTheme.jade

        return HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)

            Text(message)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.ink)
                .lineLimit(2)

            Spacer()

            Button {
                volumeStore.clearStatusMessage()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SoloTheme.muted)
                    .padding(7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .soloPanel(.stage, prominence: 0.30)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func volumeAccentColor(isFree: Bool, isUnlocked: Bool) -> Color {
        if isFree { return SoloTheme.jade }
        if isUnlocked { return SoloTheme.gold }
        return Color.white.opacity(0.40)
    }

    private func romanNumeral(for index: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        guard index >= 1 && index <= numerals.count else { return "\(index)" }
        return numerals[index - 1]
    }
}
