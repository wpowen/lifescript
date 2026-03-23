import SwiftUI

struct SoloStoryNodeView: View {
    let node: StoryNode
    let book: Book
    let prefersLargeType: Bool
    let isActiveChoice: Bool
    let onChoiceSelected: (Choice, ChoiceNode) -> Void

    var body: some View {
        switch node {
        case .text(let textNode):
            textBody(textNode)
        case .dialogue(let dialogueNode):
            dialogueBody(dialogueNode)
        case .notification(let notificationNode):
            notificationBody(notificationNode)
        case .choice(let choiceNode):
            choiceBody(choiceNode)
        }
    }

    private func textBody(_ textNode: TextNode) -> some View {
        Group {
            if textNode.emphasis == .dramatic {
                // 戏剧性文字：居中 + 金线分隔 + 暖调
                VStack(spacing: 14) {
                    Rectangle()
                        .fill(SoloTheme.gold.opacity(0.40))
                        .frame(maxWidth: 36, maxHeight: 1)
                    Text(textNode.content)
                        .font(SoloTypography.reading(emphasis: .dramatic, prefersLargeType: prefersLargeType))
                        .foregroundStyle(SoloTheme.warmInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(prefersLargeType ? 14 : 10)
                        .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(SoloTheme.gold.opacity(0.40))
                        .frame(maxWidth: 36, maxHeight: 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 8)
            } else {
                // 普通/耳语文字：直接浮在黑底上，无卡片
                Text(textNode.content)
                    .font(SoloTypography.reading(emphasis: textNode.emphasis, prefersLargeType: prefersLargeType))
                    .foregroundStyle(textNode.emphasis == .whisper ? SoloTheme.muted : SoloTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(prefersLargeType ? 11 : 9)
                    .padding(.vertical, 4)
            }
        }
    }

    private func dialogueBody(_ dialogueNode: DialogueNode) -> some View {
        // 剧本格式：左侧金线 + 无卡片背景
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(SoloTheme.gold.opacity(0.45))
                .frame(width: 2)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(characterName(for: dialogueNode.characterId).uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(SoloTheme.gold)
                Text(dialogueNode.content)
                    .font(prefersLargeType ? .title3 : .body)
                    .foregroundStyle(SoloTheme.ink)
                    .lineSpacing(prefersLargeType ? 9 : 7)
                    .fixedSize(horizontal: false, vertical: true)
                if let emotion = dialogueNode.emotion {
                    Text(emotion)
                        .font(.caption.italic())
                        .foregroundStyle(SoloTheme.muted)
                }
            }
            .padding(.leading, 16)
            .padding(.vertical, 6)
        }
        .padding(.vertical, 6)
    }

    private func notificationBody(_ notificationNode: NotificationNode) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon(for: notificationNode.type))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoloTheme.jade)
            Text(notificationNode.message)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.jade.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SoloTheme.jade.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(SoloTheme.jade.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func choiceBody(_ choiceNode: ChoiceNode) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // 决策分割线
            HStack(spacing: 14) {
                Rectangle()
                    .fill(SoloTheme.gold.opacity(0.35))
                    .frame(height: 1)
                Text("决策")
                    .font(.caption2.weight(.bold))
                    .tracking(2.5)
                    .foregroundStyle(SoloTheme.gold.opacity(0.75))
                    .fixedSize()
                Rectangle()
                    .fill(SoloTheme.gold.opacity(0.35))
                    .frame(height: 1)
            }

            // Prompt
            Text(choiceNode.prompt)
                .font(SoloTypography.sceneHeadline(size: prefersLargeType ? 22 : 19))
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // Choice buttons
            VStack(spacing: 8) {
                ForEach(choiceNode.choices) { choice in
                    Button {
                        onChoiceSelected(choice, choiceNode)
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            Text(choice.text)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isActiveChoice ? SoloTheme.ink : SoloTheme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                            if let description = choice.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(SoloTheme.muted)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            let hasTags = choice.visibleCost != nil || choice.visibleReward != nil || choice.processLabel != nil
                            if hasTags {
                                HStack(spacing: 6) {
                                    if let visibleCost = choice.visibleCost {
                                        chip(text: "代价: \(visibleCost)", tint: SoloTheme.crimson)
                                    }
                                    if let visibleReward = choice.visibleReward {
                                        chip(text: "收益: \(visibleReward)", tint: SoloTheme.gold)
                                    }
                                    if let processLabel = choice.processLabel {
                                        chip(text: processLabel, tint: SoloTheme.jade)
                                    }
                                }
                            }
                            if let riskHint = choice.riskHint {
                                Text("⚠ \(riskHint)")
                                    .font(.caption2)
                                    .foregroundStyle(SoloTheme.crimson.opacity(0.75))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isActiveChoice ? Color.white.opacity(0.07) : Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            isActiveChoice
                                                ? LinearGradient(
                                                    colors: [SoloTheme.gold.opacity(0.45), Color.white.opacity(0.10)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [Color.white.opacity(0.07), Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isActiveChoice)
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func characterName(for id: String) -> String {
        book.characters.first(where: { $0.id == id })?.name ?? "未知角色"
    }

    private func icon(for type: NotificationNode.NotificationType) -> String {
        switch type {
        case .statChange:
            return "chart.line.uptrend.xyaxis"
        case .relationshipChange:
            return "person.2.fill"
        case .itemGained:
            return "shippingbox.fill"
        case .storyHint:
            return "sparkles"
        }
    }

    private func chip(text: String, tint: Color) -> some View {
        Text(text)
            .font(SoloTypography.meta)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }
}
