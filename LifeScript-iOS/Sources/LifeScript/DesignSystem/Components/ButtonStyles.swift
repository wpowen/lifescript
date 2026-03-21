import SwiftUI

// MARK: - Primary CTA Button

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.accentGold, Color.accentAmber],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isEnabled ? 1 : 0.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .fill(configuration.isPressed ? accentColor.opacity(0.3) : Color.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .strokeBorder(
                        accentColor.opacity(configuration.isPressed ? 0.8 : 0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelMedium)
            .foregroundStyle(Color.accentGold)
            .padding(.horizontal, .spacing16)
            .padding(.vertical, .spacing12)
            .background(
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .fill(Color.accentGold.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { .init() }
}
