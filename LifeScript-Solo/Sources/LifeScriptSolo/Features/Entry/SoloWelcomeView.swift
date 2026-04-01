import SwiftUI

struct SoloWelcomeView: View {
    let snapshot: SoloWelcomeSnapshot
    let countdownSeconds: Int
    let onSkip: () -> Void

    private let branding = SoloStoryConfig.branding

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var appear = false
    @State private var pulse = false
    @State private var orbit = false

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

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
                        .padding(.trailing, isRegularWidth ? 40 : 20)
                        .padding(.top, isCompactHeight ? 6 : 12)
                }

                Spacer()

                welcomeCard
                    .padding(.horizontal, isRegularWidth ? 60 : 24)
                    .frame(maxWidth: isRegularWidth ? 520 : .infinity)

                Spacer()

                loadingFooter
                    .padding(.horizontal, isRegularWidth ? 60 : 20)
                    .padding(.bottom, isCompactHeight ? 16 : 36)
            }
        }
        .onAppear {
            appear = true
            pulse = true
            orbit = true
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button(action: onSkip) {
            HStack(spacing: 6) {
                Text(countdownSeconds > 0 ? "\(countdownSeconds)s" : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(SoloTheme.gold)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.3), value: countdownSeconds)

                Text(SoloLocalization.localized("跳过"))
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

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        VStack(spacing: isCompactHeight ? 20 : 28) {
            if isCompactHeight {
                // 横屏：水平排列封面与文字
                HStack(spacing: 20) {
                    coverOrSigil
                    titleBlock
                }
            } else {
                // 竖屏：垂直排列，封面居中
                coverOrSigil
                titleBlock
            }

            chapterChip
        }
        .padding(isCompactHeight ? 20 : 28)
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

    @ViewBuilder
    private var coverOrSigil: some View {
        if isTianjiluVisualEnabled {
            coverImage
        } else {
            sigilView
        }
    }

    private var coverImage: some View {
        let coverWidth: CGFloat = isCompactHeight ? 88 : 120
        let coverHeight: CGFloat = isCompactHeight ? 130 : 178

        return SoloBundledArtworkImage(
            resourceName: TianjiluArtworkCatalog.welcomeCover.resourceName,
            contentMode: .fill
        )
        .frame(width: coverWidth, height: coverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: SoloTheme.gold.opacity(0.20), radius: 16, x: 0, y: 8)
    }

    private var titleBlock: some View {
        VStack(spacing: isCompactHeight ? 6 : 10) {
            Text(snapshot.eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(3.6)
                .foregroundStyle(SoloTheme.gold.opacity(0.88))

            Text(snapshot.title)
                .font(SoloTypography.posterTitle(
                    size: isCompactHeight ? 36 : (isRegularWidth ? 56 : 46),
                    weight: .bold
                ))
                .foregroundStyle(SoloTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(snapshot.headline)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
                .lineLimit(2)

            Text(snapshot.author)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted.opacity(0.7))
        }
        .multilineTextAlignment(isCompactHeight ? .leading : .center)
        .frame(maxWidth: .infinity, alignment: isCompactHeight ? .leading : .center)
    }

    private var chapterChip: some View {
        Text(chapterStatusLine)
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .foregroundStyle(SoloTheme.crimson)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(SoloTheme.crimson.opacity(0.12))
            )
    }

    // MARK: - Sigil

    private var sigilView: some View {
        let outerSize: CGFloat = isCompactHeight ? 72 : 100
        let innerSize: CGFloat = isCompactHeight ? 60 : 84

        return ZStack {
            Circle()
                .strokeBorder(SoloTheme.gold.opacity(0.16), lineWidth: 1)
                .frame(width: outerSize, height: outerSize)
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
                .frame(width: innerSize, height: innerSize)
                .rotationEffect(.degrees(orbit ? 360 : 0))
                .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: orbit)

            Image(systemName: branding.ornamentSymbol)
                .font(isCompactHeight ? .callout.weight(.light) : .title3.weight(.light))
                .foregroundStyle(SoloTheme.gold.opacity(0.86))
        }
    }

    // MARK: - Loading Footer

    private var loadingFooter: some View {
        VStack(spacing: 12) {
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
                 ? SoloLocalization.format("命局正在接入，%d 秒后自动进入正文。", countdownSeconds)
                 : SoloLocalization.localized("命局已就绪，即将进入正文。"))
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

    // MARK: - Helpers

    private var chapterStatusLine: String {
        guard snapshot.generatedChapterCount > 0 else { return SoloLocalization.localized("章节接入中") }
        return SoloLocalization.format("%d 章内容已接入", snapshot.generatedChapterCount)
    }

    private var isTianjiluVisualEnabled: Bool {
        SoloStoryConfig.storyId == "天机录"
    }
}
