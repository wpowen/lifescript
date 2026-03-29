import SwiftUI

struct SoloStoryNodeView: View {
    let node: StoryNode
    let book: Book
    let prefersLargeType: Bool
    let isActiveChoice: Bool
    let selectedChoiceId: String?
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
                    .font(.system(size: prefersLargeType ? 19 : 16))
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
        VStack(spacing: 0) {
            // ── 叙事中断线：居中标题 + 双侧渐隐金线 ──
            HStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.clear, SoloTheme.gold.opacity(0.45)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
                HStack(spacing: 7) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 7, weight: .bold))
                    Text("抉择时刻")
                        .font(.caption.weight(.bold))
                        .tracking(4)
                }
                .foregroundStyle(SoloTheme.gold)
                .padding(.horizontal, 16)
                .fixedSize()
                Rectangle()
                    .fill(LinearGradient(
                        colors: [SoloTheme.gold.opacity(0.45), Color.clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
            .padding(.top, 28)
            .padding(.bottom, 18)
            .padding(.horizontal, 24)

            // ── 决策卡片 ──
            VStack(alignment: .leading, spacing: 0) {
                // 顶部重音条（加粗 + 满宽）
                Rectangle()
                    .fill(SoloTheme.heroGradient)
                    .frame(height: 4)

                VStack(alignment: .leading, spacing: 22) {
                    // 提示语 — 大字，视觉重量最强
                    Text(choiceNode.prompt)
                        .font(SoloTypography.sceneHeadline(size: prefersLargeType ? 24 : 21))
                        .foregroundStyle(SoloTheme.ink)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    // 选项计数点阵（选前显示）
                    if selectedChoiceId == nil {
                        HStack(spacing: 6) {
                            ForEach(0..<min(choiceNode.choices.count, 4), id: \.self) { _ in
                                Circle()
                                    .fill(SoloTheme.gold.opacity(0.40))
                                    .frame(width: 5, height: 5)
                            }
                            Spacer()
                        }
                    }

                    // 选项列表
                    VStack(spacing: 10) {
                        ForEach(Array(choiceNode.choices.enumerated()), id: \.element.id) { index, choice in
                            choiceRow(choice: choice, choiceNode: choiceNode, index: index)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 22)
            }
            .background(
                ZStack {
                    // 深邃底色 — 明显区别于叙事背景
                    Color(red: 0.07, green: 0.03, blue: 0.09)
                    // 左上角金色大气晕染
                    RadialGradient(
                        colors: [SoloTheme.gold.opacity(0.08), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 220
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [SoloTheme.gold.opacity(0.55), SoloTheme.gold.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: SoloTheme.gold.opacity(0.22), radius: 40, x: 0, y: 0)
            .shadow(color: .black.opacity(0.70), radius: 20, x: 0, y: 14)
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)
        }
        // 突破父容器的水平内边距，实现满宽氛围背景
        .padding(.horizontal, -24)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.18), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .padding(.top, 8)
    }

    @ViewBuilder
    private func choiceRow(choice: Choice, choiceNode: ChoiceNode, index: Int) -> some View {
        let isChosen = selectedChoiceId == choice.id
        let isDimmed = selectedChoiceId != nil && !isChosen
        let numerals = ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ"]
        let numeral = index < numerals.count ? numerals[index] : "\(index + 1)"

        Button {
            onChoiceSelected(choice, choiceNode)
        } label: {
            HStack(spacing: 14) {
                // 数字徽章 — 方圆角矩形
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            isChosen
                                ? SoloTheme.gold
                                : isDimmed
                                    ? Color.white.opacity(0.05)
                                    : Color.white.opacity(0.10)
                        )
                        .frame(width: 30, height: 30)
                    if isChosen {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black)
                    } else {
                        Text(numeral)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .foregroundStyle(isDimmed ? SoloTheme.gold.opacity(0.20) : SoloTheme.gold)
                    }
                }

                // 选项文本
                VStack(alignment: .leading, spacing: 4) {
                    Text(choice.text)
                        .font(.system(size: prefersLargeType ? 17 : 15, weight: .medium))
                        .foregroundStyle(
                            isDimmed ? SoloTheme.ink.opacity(0.25) : SoloTheme.ink
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let description = choice.description, !isDimmed {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(SoloTheme.muted.opacity(isChosen ? 0.70 : 0.50))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 决策元信息：代价 / 收益 / 风险（选前）；结算标注（选后）
                    if !isDimmed {
                        choiceMetaRow(choice: choice, isChosen: isChosen)
                    }
                }

                // 箭头提示（等待选择时）
                if !isDimmed && !isChosen {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.gold.opacity(0.40))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                isChosen
                    ? SoloTheme.gold.opacity(0.10)
                    : isDimmed
                        ? Color.white.opacity(0.02)
                        : Color.white.opacity(0.07)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isChosen
                            ? SoloTheme.gold.opacity(0.50)
                            : isDimmed
                                ? Color.white.opacity(0.04)
                                : Color.white.opacity(0.14),
                        lineWidth: isChosen ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isActiveChoice)
        .opacity(isDimmed ? 0.30 : 1.0)
    }

    @ViewBuilder
    private func choiceMetaRow(choice: Choice, isChosen: Bool) -> some View {
        let hasMeta = choice.processLabel != nil || choice.visibleCost != nil
            || choice.visibleReward != nil || choice.riskHint != nil
        if hasMeta {
            VStack(alignment: .leading, spacing: 5) {
                // 行动类型标签行
                HStack(spacing: 6) {
                    if let label = choice.processLabel {
                        Text(label)
                            .font(.caption2.weight(.bold))
                            .tracking(0.5)
                            .foregroundStyle(isChosen ? Color.black.opacity(0.70) : Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isChosen ? SoloTheme.gold.opacity(0.55) : SoloTheme.gold)
                            .clipShape(Capsule())
                    }
                    if !isChosen {
                        HStack(spacing: 3) {
                            Image(systemName: choice.satisfactionType.iconName)
                                .font(.system(size: 9))
                            Text(choice.satisfactionType.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(SoloTheme.muted.opacity(0.55))
                    }
                }

                // 代价 / 收益行
                if isChosen {
                    // 选后：灰化结算提示
                    HStack(spacing: 10) {
                        if let cost = choice.visibleCost {
                            Text("消耗: \(cost)")
                                .font(.caption2)
                                .foregroundStyle(SoloTheme.muted.opacity(0.40))
                        }
                        if let reward = choice.visibleReward {
                            Text("得到: \(reward)")
                                .font(.caption2)
                                .foregroundStyle(SoloTheme.muted.opacity(0.40))
                        }
                    }
                } else {
                    // 选前：彩色标签
                    HStack(spacing: 8) {
                        if let cost = choice.visibleCost {
                            Label(cost, systemImage: "minus.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(SoloTheme.crimson.opacity(0.85))
                        }
                        if let reward = choice.visibleReward {
                            Label(reward, systemImage: "plus.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(SoloTheme.jade.opacity(0.85))
                        }
                    }
                    // 风险提示
                    if let risk = choice.riskHint {
                        Label(risk, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(SoloTheme.gold.opacity(0.65))
                    }
                }
            }
            .padding(.top, 5)
        }
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

}
