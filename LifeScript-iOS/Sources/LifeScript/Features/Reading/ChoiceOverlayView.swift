import SwiftUI

/// Full-screen overlay presented when a story choice node is reached.
/// Blocks tap-to-advance until the user makes a selection.
struct ChoiceOverlayView: View {
    let choiceNode: ChoiceNode
    let book: Book
    let currentStats: ProtagonistStats
    let onSelected: (Choice) -> Void

    @State private var selectedChoiceId: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dim overlay — absorbs taps so the reading scroll doesn't receive them
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {} // intentionally absorb

            choicePanel
        }
    }

    // MARK: - Choice Panel

    private var choicePanel: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.textTertiary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, .spacing12)
                .padding(.bottom, .spacing16)

            // Prompt
            Text(choiceNode.prompt)
                .font(.labelLarge)
                .foregroundStyle(Color.accentGold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacing20)
                .padding(.bottom, .spacing16)

            Divider()
                .background(Color.surfaceHighlight)

            // Choices
            ScrollView {
                VStack(spacing: .spacing8) {
                    ForEach(choiceNode.choices) { choice in
                        choiceButton(choice)
                    }
                }
                .padding(.horizontal, .spacing16)
                .padding(.vertical, .spacing16)
            }
            .frame(maxHeight: 480)

            Spacer(minLength: 0)
                .frame(height: 20)
        }
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusXLarge))
        .padding(.horizontal, .spacing8)
        .padding(.bottom, .spacing8)
        .shadow(color: .black.opacity(0.4), radius: 24, y: -8)
    }

    // MARK: - Individual Choice Button

    private func choiceButton(_ choice: Choice) -> some View {
        let isSelected = selectedChoiceId == choice.id
        let isDisabled = selectedChoiceId != nil && !isSelected

        return Button {
            guard selectedChoiceId == nil else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                selectedChoiceId = choice.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onSelected(choice)
            }
        } label: {
            VStack(alignment: .leading, spacing: .spacing8) {
                // Choice text + satisfaction badge
                HStack(alignment: .top, spacing: .spacing8) {
                    VStack(alignment: .leading, spacing: .spacing4) {
                        Text(choice.text)
                            .font(.choiceTitle)
                            .foregroundStyle(isDisabled ? Color.textTertiary : Color.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let desc = choice.description {
                            Text(desc)
                                .font(.captionLarge)
                                .foregroundStyle(isDisabled ? Color.textTertiary.opacity(0.6) : Color.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)

                    satisfactionBadge(choice.satisfactionType, dimmed: isDisabled)
                }

                // Stat effects preview
                if !choice.statEffects.isEmpty {
                    statEffectsRow(choice.statEffects, dimmed: isDisabled)
                }
            }
            .padding(.horizontal, .spacing12)
            .padding(.vertical, .spacing12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(choiceBackground(isSelected: isSelected, isDisabled: isDisabled))
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .stroke(
                        isSelected ? Color.accentGold : Color.surfaceHighlight,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .disabled(isDisabled)
    }

    private func choiceBackground(isSelected: Bool, isDisabled: Bool) -> Color {
        if isSelected { return Color.accentGold.opacity(0.12) }
        if isDisabled { return Color.surfacePrimary.opacity(0.4) }
        return Color.surfacePrimary
    }

    // MARK: - Satisfaction Badge

    private func satisfactionBadge(_ type: SatisfactionType, dimmed: Bool) -> some View {
        Text(type.displayName)
            .font(.captionSmall)
            .foregroundStyle(dimmed ? Color.textTertiary : satisfactionColor(type))
            .padding(.horizontal, .spacing6)
            .padding(.vertical, 3)
            .background((dimmed ? Color.textTertiary : satisfactionColor(type)).opacity(0.15))
            .clipShape(Capsule())
    }

    private func satisfactionColor(_ type: SatisfactionType) -> Color {
        switch type {
        case .immediatePower: return .accentCrimson
        case .delayedRevenge: return .accentSky
        case .cunningScheme: return .accentViolet
        case .dominantCrush: return .accentGold
        case .emotionalPlay: return .relationAffection
        case .undercover: return .accentEmerald
        }
    }

    // MARK: - Stat Effects Row

    private func statEffectsRow(_ effects: [StatEffect], dimmed: Bool) -> some View {
        HStack(spacing: .spacing6) {
            ForEach(effects.prefix(4), id: \.stat) { effect in
                statEffectChip(effect, dimmed: dimmed)
            }
            if effects.count > 4 {
                Text("+\(effects.count - 4)")
                    .font(.captionSmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    private func statEffectChip(_ effect: StatEffect, dimmed: Bool) -> some View {
        let positive = effect.delta > 0
        let color: Color = dimmed ? .textTertiary : (positive ? .accentEmerald : .accentCrimson)
        let sign = positive ? "+" : ""

        return Text("\(effect.stat.rawValue)\(sign)\(effect.delta)")
            .font(.captionSmall)
            .foregroundStyle(color)
            .padding(.horizontal, .spacing6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

