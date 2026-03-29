import SwiftUI

struct SoloWelcomeView: View {
    let snapshot: SoloWelcomeSnapshot
    let countdownSeconds: Int
    let onSkip: () -> Void

    private let branding = SoloStoryConfig.branding

    @State private var appear = false
    @State private var pulse = false
    @State private var orbit = false

    var body: some View {
        ZStack {
            SoloBackdrop()

            RadialGradient(
                colors: [
                    SoloTheme.gold.opacity(0.18),
                    SoloTheme.crimson.opacity(0.08),
                    Color.clear,
                ],
                center: .top,
                startRadius: 10,
                endRadius: 340
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    skipButton
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    welcomeHero
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                }

                loadingFooter
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {
            appear = true
            pulse = true
            orbit = true
        }
    }

    private var skipButton: some View {
        Button(action: onSkip) {
            HStack(spacing: 6) {
                Text(countdownSeconds > 0 ? "\(countdownSeconds)s" : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(SoloTheme.gold)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.3), value: countdownSeconds)

                Text("跳过")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SoloTheme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(SoloTheme.gold.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
    }

    private var welcomeHero: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(snapshot.eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(3.6)
                        .foregroundStyle(SoloTheme.gold.opacity(0.88))

                    Text(snapshot.title)
                        .font(SoloTypography.posterTitle(size: 52, weight: .bold))
                        .foregroundStyle(SoloTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(snapshot.author)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SoloTheme.muted)
                }

                Spacer(minLength: 16)

                if isTianjiluVisualEnabled {
                    welcomeVisualColumn
                } else {
                    sigilView
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(snapshot.headline)
                    .font(SoloTypography.sceneHeadline(size: 24))
                    .foregroundStyle(SoloTheme.ink)

                Text(snapshot.detail)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(6)
            }

            HStack(spacing: 10) {
                signalChip(text: chapterStatusLine, tint: SoloTheme.crimson)
                signalChip(text: "修仙互动长篇", tint: SoloTheme.jade)
                signalChip(text: "离线阅读体验", tint: SoloTheme.gold)
            }

            if isTianjiluVisualEnabled {
                SoloArtworkCard(
                    asset: TianjiluArtworkCatalog.welcomeArtifact,
                    height: 164,
                    contentMode: .fill,
                    tint: SoloTheme.gold,
                    cornerRadius: 18
                )
            }

            progressDeck

            VStack(alignment: .leading, spacing: 10) {
                Text("入局阶段")
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)

                VStack(spacing: 12) {
                    ForEach(Array(snapshot.stages.enumerated()), id: \.element.id) { index, stage in
                        stageRow(stage, index: index)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: SoloTheme.crimson.opacity(0.14), radius: 28, x: 0, y: 16)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 18)
        .animation(.easeOut(duration: 0.65), value: appear)
    }

    private var welcomeVisualColumn: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                SoloBundledArtworkImage(
                    resourceName: TianjiluArtworkCatalog.welcomeCover.resourceName,
                    contentMode: .fill
                )
                .frame(width: 126, height: 188)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.75),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("当前卷面")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(SoloTheme.gold)
                    Text(TianjiluArtworkCatalog.welcomeCover.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
            }

            HStack(spacing: 8) {
                sigilView
                    .scaleEffect(0.78)
                VStack(alignment: .leading, spacing: 2) {
                    Text("天机录残页")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SoloTheme.gold)
                    Text("欢迎页先亮起命书与卷面，再退入正文。")
                        .font(.caption2)
                        .foregroundStyle(SoloTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 126, alignment: .leading)
        }
    }

    private var sigilView: some View {
        ZStack {
            Circle()
                .strokeBorder(SoloTheme.gold.opacity(0.16), lineWidth: 1)
                .frame(width: 88, height: 88)
                .scaleEffect(pulse ? 1.05 : 0.94)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

            Circle()
                .trim(from: 0.10, to: 0.68)
                .stroke(
                    AngularGradient(
                        colors: [SoloTheme.gold.opacity(0.05), SoloTheme.gold, SoloTheme.crimson],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 76, height: 76)
                .rotationEffect(.degrees(orbit ? 360 : 0))
                .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: orbit)

            Image(systemName: branding.ornamentSymbol)
                .font(.title3.weight(.light))
                .foregroundStyle(SoloTheme.gold.opacity(0.86))
        }
    }

    private var progressDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("命局进度")
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)
                Spacer()
                Text("\(Int(snapshot.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SoloTheme.warmInk)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.crimson, SoloTheme.gold, SoloTheme.jade],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geo.size.width * snapshot.progress))
                }
            }
            .frame(height: 6)

            Text(activeStageText)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(5)
        }
        .padding(18)
        .soloPanel(.hero, prominence: 0.14)
    }

    private func stageRow(_ stage: SoloWelcomeStage, index: Int) -> some View {
        let isComplete = snapshot.progress >= stage.progressThreshold
        let isActive = activeStageIndex == index
        let tint = isComplete ? SoloTheme.jade : (isActive ? SoloTheme.gold : SoloTheme.muted)

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(isComplete ? 0.18 : 0.10))
                    .frame(width: 32, height: 32)
                Image(systemName: isComplete ? "checkmark" : (isActive ? "sparkles" : "circle"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isComplete || isActive ? SoloTheme.ink : SoloTheme.muted)
                    Spacer()
                    Text(stageStatusLabel(isComplete: isComplete, isActive: isActive))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tint)
                }

                Text(stage.detail)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.07 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isActive ? SoloTheme.gold.opacity(0.20) : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
    }

    private var loadingFooter: some View {
        VStack(spacing: 12) {
            countdownBar

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(SoloTheme.gold.opacity(pulse ? 0.58 : 0.16))
                        .frame(width: 5, height: 5)
                        .animation(
                            .easeInOut(duration: 0.75)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.18),
                            value: pulse
                        )
                }
            }

            Text(countdownSeconds > 0
                 ? "命局正在接入，\(countdownSeconds) 秒后自动进入正文。"
                 : "命局已就绪，即将进入正文。")
                .font(.caption)
                .foregroundStyle(SoloTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .contentTransition(.numericText(countsDown: true))
                .animation(.easeInOut(duration: 0.3), value: countdownSeconds)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.55).delay(0.2), value: appear)
    }

    /// 底部倒计时进度条
    private var countdownBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SoloTheme.gold, SoloTheme.crimson],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, geo.size.width * countdownProgress))
                    .animation(.linear(duration: 1.0), value: countdownSeconds)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 40)
    }

    private var countdownProgress: CGFloat {
        let total = 5.0
        let elapsed = total - Double(countdownSeconds)
        return CGFloat(min(1.0, max(0.0, elapsed / total)))
    }

    private func signalChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }

    private var chapterStatusLine: String {
        guard snapshot.generatedChapterCount > 0 else { return "章节接入中" }
        return "\(snapshot.generatedChapterCount) 章内容已接入"
    }

    private var activeStageIndex: Int {
        snapshot.stages.firstIndex(where: { snapshot.progress < $0.progressThreshold }) ?? max(snapshot.stages.count - 1, 0)
    }

    private var activeStageText: String {
        if snapshot.progress >= 1 {
            return "命局已经就绪，可以直接踏入当前这一局。"
        }
        guard snapshot.stages.indices.contains(activeStageIndex) else {
            return "命局已经就绪，可以开始体验。"
        }
        return "当前阶段：\(snapshot.stages[activeStageIndex].title)"
    }

    private func stageStatusLabel(isComplete: Bool, isActive: Bool) -> String {
        if isComplete { return "完成" }
        if isActive { return "进行中" }
        return "待接入"
    }

    private var isTianjiluVisualEnabled: Bool {
        SoloStoryConfig.storyId == "天机录"
    }
}
