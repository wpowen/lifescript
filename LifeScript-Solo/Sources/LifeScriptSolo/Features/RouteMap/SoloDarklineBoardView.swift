import SwiftUI

struct SoloDarklineBoardView: View {
    let book: Book
    let snapshot: SoloDarklineBoardSnapshot

    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        ZStack {
            sceneBackground
            contentDimmer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    revealGauge
                    discoveredSection
                    approachingSection
                    abyssSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: book.id == "天机录" ? SoloLocalization.localized("暗线") : SoloLocalization.localized("暗流"), kicker: SoloLocalization.localized("观测"))
    }

    // MARK: - Reveal Gauge

    private var revealGauge: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(SoloLocalization.localized("暗线揭露"))
                        .font(SoloTypography.posterTitle(size: 28))
                        .foregroundStyle(SoloTheme.ink)
                    Text(snapshot.boardLine)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineSpacing(5)
                }
                Spacer()
                revealRing
            }

            revealBar

            HStack(spacing: 12) {
                gaugeStat(
                    icon: "waveform.path.ecg",
                    value: "\(snapshot.discoveredSignals.count)",
                    label: SoloLocalization.localized("已浮出"),
                    tint: SoloTheme.crimson
                )
                gaugeStat(
                    icon: "sensor.tag.radiowaves.forward",
                    value: "\(snapshot.approachingSignals.count)",
                    label: SoloLocalization.localized("正逼近"),
                    tint: SoloTheme.gold
                )
                gaugeStat(
                    icon: "lock.shield",
                    value: "\(snapshot.sealedCount)",
                    label: SoloLocalization.localized("深水中"),
                    tint: SoloTheme.muted
                )
            }

            Text(SoloLocalization.format("天命压力：%@", snapshot.destinyStatus.thresholdHint))
                .font(.caption)
                .foregroundStyle(SoloTheme.muted)
        }
        .padding(20)
        .soloPanel(.hero, prominence: 0.20)
    }

    private var revealRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 5)
                .frame(width: 68, height: 68)

            Circle()
                .trim(from: 0, to: CGFloat(snapshot.revealRatio))
                .stroke(
                    AngularGradient(
                        colors: [SoloTheme.crimson, SoloTheme.gold, SoloTheme.crimson],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(snapshot.revealLabel)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(SoloTheme.crimson)
                Text(SoloLocalization.localized("揭露"))
                    .font(.system(size: 9))
                    .foregroundStyle(SoloTheme.muted)
            }
        }
    }

    private var revealBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let total = max(snapshot.totalSignalCount, 1)
            let discoveredW = w * CGFloat(snapshot.discoveredSignals.count) / CGFloat(total)
            let approachingW = w * CGFloat(snapshot.approachingSignals.count) / CGFloat(total)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(SoloTheme.crimson.opacity(0.88))
                        .frame(width: max(discoveredW, 0), height: 6)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(SoloTheme.gold.opacity(0.56))
                        .frame(width: max(approachingW, 0), height: 6)
                }
            }
        }
        .frame(height: 6)
    }

    private func gaugeStat(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.06))
        )
    }

    // MARK: - Discovered

    private var discoveredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(SoloLocalization.localized("已浮出水面"), systemImage: "waveform.path.ecg")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.ink)
                Spacer()
                badge(text: SoloLocalization.format("%d 条", snapshot.discoveredSignals.count), tint: SoloTheme.crimson)
            }

            if snapshot.discoveredSignals.isEmpty {
                emptySlot(text: SoloLocalization.localized("你还没有触发任何暗线。继续推进章节、做出关键选择后，暗线尾迹才会浮出水面。"))
            } else {
                ForEach(Array(snapshot.discoveredSignals.enumerated()), id: \.element.id) { index, signal in
                    evidenceCard(signal: signal, index: index + 1)
                }
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.14)
    }

    private func evidenceCard(signal: SoloDarklineSignal, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SoloTheme.crimson)
                        .frame(width: 8, height: 8)
                    Text(SoloLocalization.format("暗线 #%d", index))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(SoloTheme.crimson)
                }
                Spacer()
                Text(signal.sourceStageTitle)
                    .font(.caption2)
                    .foregroundStyle(SoloTheme.muted)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [SoloTheme.crimson.opacity(0.40), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text(signal.hint)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.warmInk)
                    .lineSpacing(6)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(SoloTheme.gold.opacity(0.72))
                    Text(SoloLocalization.format("发现于「%@」", signal.sourceChapterTitle))
                        .font(.caption2)
                        .foregroundStyle(SoloTheme.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [SoloTheme.crimson.opacity(0.30), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Approaching

    private var approachingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(SoloLocalization.localized("水下回声"), systemImage: "sensor.tag.radiowaves.forward")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.ink)
                Spacer()
                badge(text: SoloLocalization.format("%d 股", snapshot.approachingSignals.count), tint: SoloTheme.gold)
            }

            Text(SoloLocalization.localized("你已经感觉到这些异动的存在，但还不能直接看穿它。继续推进对应阶段后，它会把真正的面目露出来。"))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            if snapshot.approachingSignals.isEmpty {
                emptySlot(text: SoloLocalization.localized("眼前还没有明确逼近的暗流。当你走到某条暗线的触发区域附近时，这里会出现干扰波纹。"))
            } else if reduceMotion {
                ForEach(snapshot.approachingSignals) { signal in
                    interferenceCard(signal: signal, pulse: 0)
                }
            } else {
                TimelineView(.animation(minimumInterval: 0.12)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = sin(t * 2.4) * 0.5 + 0.5
                    ForEach(snapshot.approachingSignals) { signal in
                        interferenceCard(signal: signal, pulse: pulse)
                    }
                }
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.12)
    }

    private func interferenceCard(signal: SoloDarklineSignal, pulse: Double) -> some View {
        HStack(spacing: 14) {
            interferenceIcon(pulse: pulse)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(signal.sourceStageTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloTheme.gold)
                    Spacer()
                    badge(text: signal.sourceChapterTitle, tint: SoloTheme.gold)
                }
                Text(signal.hint)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(5)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SoloTheme.gold.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    SoloTheme.gold.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                )
        )
    }

    private func interferenceIcon(pulse: Double) -> some View {
        ZStack {
            Circle()
                .fill(SoloTheme.gold.opacity(0.08 + pulse * 0.10))
                .frame(width: 40, height: 40)
            Circle()
                .strokeBorder(SoloTheme.gold.opacity(0.30 + pulse * 0.20), lineWidth: 1.5)
                .frame(width: 40, height: 40)
            Image(systemName: "wave.3.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SoloTheme.gold.opacity(0.70 + pulse * 0.30))
        }
    }

    // MARK: - Abyss

    private var abyssSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(SoloLocalization.localized("深渊"), systemImage: "lock.shield")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.muted)
                Spacer()
                badge(text: SoloLocalization.format("%d 处", snapshot.sealedCount), tint: SoloTheme.muted)
            }

            Text(SoloLocalization.format("仍有 %d 条暗线沉在水底，你既不知道它们是什么，也不知道什么时候会被触发。唯一确定的是——它们存在。", snapshot.sealedCount))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            if snapshot.sealedCount > 0 {
                abyssGrid
            }
        }
        .padding(20)
        .soloPanel(.quiet)
    }

    private var abyssGrid: some View {
        let displayCount = min(snapshot.sealedCount, 6)
        let hasMore = snapshot.sealedCount > 6

        return VStack(spacing: 10) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(0..<displayCount, id: \.self) { index in
                    abyssSlot(index: index)
                }
            }

            if hasMore {
                Text(SoloLocalization.format("还有 %d 处暗线仍在更深的水下……", snapshot.sealedCount - 6))
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted.opacity(0.60))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func abyssSlot(index: Int) -> some View {
        let symbols = ["questionmark", "eye.slash", "water.waves", "tornado", "moon.stars", "sparkles"]
        let symbol = symbols[index % symbols.count]

        return VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(SoloTheme.muted.opacity(0.36))
            Text("???")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SoloTheme.muted.opacity(0.30))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    SoloTheme.muted.opacity(0.16),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 6])
                )
        )
    }

    // MARK: - Shared

    private func emptySlot(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.title3.weight(.light))
                .foregroundStyle(SoloTheme.muted.opacity(0.40))
            Text(text)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    @ViewBuilder
    private var sceneBackground: some View {
        if book.id == "天机录" {
            TianjiluHomeScene(illustration: TianjiluArtworkCatalog.darklineArtifact)
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
}
