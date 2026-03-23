import SwiftUI

struct SoloEntryHeroScene: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let openReading: () -> Void
    let openWorld: () -> Void

    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 主题艺术背景画 — 全出血，自带底部渐变消融
            SoloHeroArtwork(preset: snapshot.branding.palettePreset)

            // 内容叠层
            contentStack
        }
        .frame(maxWidth: .infinity, minHeight: 620)
    }

    // MARK: - Content anchored to bottom (Netflix style)
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 140)

            // Eyebrow label
            Text(snapshot.branding.entryEyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(3.5)
                .foregroundStyle(SoloTheme.gold)
                .padding(.bottom, 14)

            // Title — oversized, cinematic
            Text(book.title)
                .font(SoloTypography.posterTitle(size: 56))
                .foregroundStyle(SoloTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)

            // Promise tagline
            Text(snapshot.branding.promise)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink.opacity(0.78))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)

            // Meta chips row
            HStack(spacing: 8) {
                cinemaChip(book.genre.displayName, SoloTheme.gold)
                cinemaChip("\(book.totalChapters) \(snapshot.branding.chapterUnitName)", SoloTheme.crimson)
                cinemaChip("买断制", SoloTheme.jade)
            }
            .padding(.bottom, 6)

            Text(snapshot.branding.landing.identityLabel + " · " + snapshot.currentIdentityValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted)
                .padding(.bottom, 22)

            // Primary action — portal threshold button
            primaryPortalButton
                .padding(.bottom, 10)

            // Secondary action — ghost
            Button(action: openWorld) {
                HStack(spacing: 10) {
                    Image(systemName: "map")
                        .font(.caption.weight(.semibold))
                    Text(secondaryActionTitle)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .opacity(0.45)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .foregroundStyle(SoloTheme.ink.opacity(0.72))
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)

            // Hook teaser
            Text(snapshot.branding.atmosphereLine)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.warmInk.opacity(0.75))
                .lineSpacing(4)
                .lineLimit(2)
                .padding(.bottom, 36)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Portal Entry Button

    private var primaryPortalButton: some View {
        Group {
            if reduceMotion {
                portalButtonLayer(pulse: 0.5)
            } else {
                TimelineView(.animation(minimumInterval: 0.05)) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let pulse = (sin(t * 1.15) + 1) / 2
                    portalButtonLayer(pulse: pulse)
                }
            }
        }
    }

    private func portalButtonLayer(pulse: Double) -> some View {
        Button(action: openReading) {
            VStack(alignment: .leading, spacing: 0) {
                // Eyebrow — ceremony / threshold language
                Text("点击踏入")
                    .font(.caption2.weight(.bold))
                    .tracking(5)
                    .foregroundStyle(Color.white.opacity(0.32 + pulse * 0.18))
                    .padding(.bottom, 12)

                // Main CTA row
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SoloTheme.gold.opacity(0.18 + pulse * 0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SoloTheme.gold)
                    }
                    Text(primaryActionTitle)
                        .font(SoloTypography.posterTitle(size: 26))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.bottom, 12)

                // Thin gold divider — animated width
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [SoloTheme.gold.opacity(0.55 + pulse * 0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.bottom, 10)

                // Destiny status line
                Text(snapshot.destinyStatusLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SoloTheme.warmInk.opacity(0.55))
                    .lineLimit(1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color.black.opacity(0.55)
                    RadialGradient(
                        colors: [
                            SoloTheme.crimson.opacity(0.12 + pulse * 0.16),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 220
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                SoloTheme.gold.opacity(0.20 + pulse * 0.55),
                                SoloTheme.crimson.opacity(0.14 + pulse * 0.20),
                                Color.white.opacity(0.04 + pulse * 0.07),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: SoloTheme.crimson.opacity(0.18 + pulse * 0.26),
                radius: CGFloat(10 + pulse * 14),
                x: 0, y: 5
            )
        }
        .buttonStyle(.plain)
    }

    private func cinemaChip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.14))
            )
    }
}
