import SwiftUI

struct SceneBackdrop: View {
    var palette: StoryPalette = StoryPalette(primary: .accentGold, secondary: .accentCrimson, tertiary: .accentSky)

    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.backgroundPrimary,
                        Color.backgroundSecondary,
                        Color.backgroundPrimary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(palette.primary.opacity(0.20))
                    .frame(width: proxy.size.width * 0.95)
                    .blur(radius: 90)
                    .offset(
                        x: animate ? proxy.size.width * 0.20 : -proxy.size.width * 0.18,
                        y: animate ? -120 : -30
                    )

                Circle()
                    .fill(palette.secondary.opacity(0.16))
                    .frame(width: proxy.size.width * 0.72)
                    .blur(radius: 80)
                    .offset(
                        x: animate ? -proxy.size.width * 0.12 : proxy.size.width * 0.24,
                        y: animate ? proxy.size.height * 0.32 : proxy.size.height * 0.22
                    )

                RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                    .fill(palette.tertiary.opacity(0.10))
                    .frame(width: proxy.size.width * 0.84, height: proxy.size.height * 0.20)
                    .rotationEffect(.degrees(animate ? 8 : -10))
                    .blur(radius: 90)
                    .offset(
                        x: animate ? proxy.size.width * 0.08 : -proxy.size.width * 0.10,
                        y: proxy.size.height * 0.38
                    )
            }
            .ignoresSafeArea()
            .task {
                guard !animate else { return }
                withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
    }
}

struct ScenePageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var accent: Color = .accentGold

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack(spacing: .spacing8) {
                Capsule()
                    .fill(accent)
                    .frame(width: 20, height: 6)

                Text(eyebrow)
                    .font(.captionLarge)
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
            }

            Text(title)
                .font(.displayLarge)
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SceneSectionHeader: View {
    let title: String
    let subtitle: String
    var accent: Color = .accentGold

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            Text(title)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(width: 3)
                .offset(x: -12)
        }
    }
}

struct SceneMetricPill: View {
    let title: String
    let value: String
    let systemImage: String
    var color: Color = .accentGold

    var body: some View {
        HStack(spacing: .spacing8) {
            Image(systemName: systemImage)
                .font(.captionLarge)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: .spacing2) {
                Text(title)
                    .font(.captionSmall)
                    .foregroundStyle(Color.textTertiary)
                Text(value)
                    .font(.labelMedium)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(.horizontal, .spacing12)
        .padding(.vertical, .spacing10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.surfaceSecondary.opacity(0.90))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(color.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct SceneAccentBadge: View {
    let text: String
    var color: Color = .accentGold

    var body: some View {
        Text(text)
            .font(.captionLarge)
            .foregroundStyle(color)
            .padding(.horizontal, .spacing10)
            .padding(.vertical, .spacing6)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }
}

struct SceneCTAButtonLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var subtitleColor: Color = .white.opacity(0.78)

    var body: some View {
        HStack(spacing: .spacing12) {
            Image(systemName: systemImage)
                .font(.bodyLarge)

            VStack(alignment: .leading, spacing: .spacing2) {
                Text(title)
                    .font(.labelLarge)

                Text(subtitle)
                    .font(.captionLarge)
                    .foregroundStyle(subtitleColor)
            }

            Spacer()
        }
    }
}

private struct ScenePanelModifier: ViewModifier {
    let accent: Color
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .fill(Color.surfacePrimary.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                            .strokeBorder(accent.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: 14)
            )
    }
}

extension View {
    func scenePanel(accent: Color = .accentGold, padding: CGFloat = .spacing16) -> some View {
        modifier(ScenePanelModifier(accent: accent, padding: padding))
    }
}
