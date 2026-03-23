import SwiftUI

enum SoloPanelStyle {
    case hero
    case stage
    case evidence
    case quiet
    case alert
}

private struct SoloPanelModifier: ViewModifier {
    let style: SoloPanelStyle
    let prominence: Double

    func body(content: Content) -> some View {
        content
            .background(backgroundShape)
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeGradient, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }

    private var fillGradient: LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stage:
            return LinearGradient(
                colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .evidence:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.04 + (prominence * 0.03)),
                    Color.white.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .quiet:
            return LinearGradient(
                colors: [Color.white.opacity(0.03), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .alert:
            return LinearGradient(
                colors: [SoloTheme.crimson.opacity(0.10), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var strokeGradient: LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [
                    SoloTheme.gold.opacity(0.20 + (prominence * 0.08)),
                    Color.white.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .alert:
            return LinearGradient(
                colors: [SoloTheme.crimson.opacity(0.30), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.08 + (prominence * 0.04)),
                    Color.white.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColor: Color {
        switch style {
        case .hero:
            return SoloTheme.gold.opacity(0.08)
        case .alert:
            return SoloTheme.crimson.opacity(0.08)
        default:
            return Color.black.opacity(0.18)
        }
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .hero:
            return 16
        default:
            return 12
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero:
            return 16
        default:
            return 10
        }
    }

    private var shadowYOffset: CGFloat {
        switch style {
        case .hero:
            return 8
        default:
            return 6
        }
    }
}

struct SoloSignalChip: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(SoloTypography.meta)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }
}

struct SoloSectionHeading: View {
    let eyebrow: String?
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(SoloTypography.eyebrow)
                    .tracking(2.2)
                    .foregroundStyle(SoloTheme.gold.opacity(0.92))
            }

            Text(title)
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            if let detail {
                Text(detail)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(5)
            }
        }
    }
}

struct SoloPrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .foregroundStyle(Color.black)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(SoloMotion.tap(isPressed: configuration.isPressed), value: configuration.isPressed)
    }
}

struct SoloGhostActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(SoloMotion.tap(isPressed: configuration.isPressed), value: configuration.isPressed)
    }
}

extension View {
    func soloPanel(_ style: SoloPanelStyle = .quiet, prominence: Double = 0) -> some View {
        modifier(SoloPanelModifier(style: style, prominence: prominence))
    }
}
