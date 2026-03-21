import SwiftUI

// MARK: - Primary CTA Button

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, .spacing20)
            .padding(.vertical, .spacing6)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.accentGold, Color.accentCrimson],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(isEnabled ? 1 : 0.4)

                    LinearGradient(
                        colors: [Color.white.opacity(0.18), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.accentCrimson.opacity(0.18), radius: 18, x: 0, y: 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Choice Button (for interactive choices)

struct ChoiceButtonStyle: ButtonStyle {
    let accentColor: Color

    init(accentColor: Color = .accentGold) {
        self.accentColor = accentColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.choiceTitle)
            .foregroundStyle(configuration.isPressed ? .white : Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .spacing16)
            .padding(.vertical, .spacing16)
            .background(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .fill(configuration.isPressed ? accentColor.opacity(0.30) : Color.surfaceSecondary.opacity(0.90))
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .strokeBorder(
                        accentColor.opacity(configuration.isPressed ? 0.8 : 0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: accentColor.opacity(configuration.isPressed ? 0.16 : 0.06), radius: 12, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelMedium)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, .spacing18)
            .padding(.vertical, .spacing14)
            .background(
                RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                    .fill(Color.surfaceSecondary.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                            .strokeBorder(Color.accentGold.opacity(0.18), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { .init() }
}
