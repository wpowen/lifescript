import SwiftUI

enum SoloCharacterCodex {
    static func accent(for character: Character, relation: RelationshipState?) -> Color {
        if let dominant = relation?.prominentDimensions.first?.0 {
            return tint(for: dominant)
        }

        switch character.role {
        case .protagonist:
            return SoloTheme.gold
        case .ally, .loveInterest, .mentor:
            return SoloTheme.jade
        case .rival, .antagonist:
            return SoloTheme.crimson
        case .family, .neutral:
            return SoloTheme.warmInk
        }
    }

    static func tint(for dimension: RelationshipEffect.RelationshipDimension) -> Color {
        switch dimension {
        case .trust, .affection, .dependence:
            return SoloTheme.jade
        case .awe, .curiosity:
            return SoloTheme.gold
        case .hostility, .vigilance, .contempt, .anger:
            return SoloTheme.crimson
        default:
            return SoloTheme.warmInk
        }
    }

    static func roleSymbol(for role: Character.CharacterRole) -> String {
        switch role {
        case .protagonist:
            return "sparkles"
        case .ally:
            return "shield.lefthalf.filled"
        case .rival:
            return "flame.fill"
        case .loveInterest:
            return "heart.fill"
        case .mentor:
            return "scroll.fill"
        case .family:
            return "house.fill"
        case .neutral:
            return "eye.fill"
        case .antagonist:
            return "bolt.horizontal.fill"
        }
    }

    static func roleLabel(for role: Character.CharacterRole) -> String {
        role.rawValue
    }

    static func dimensions(for relation: RelationshipState?) -> [(RelationshipEffect.RelationshipDimension, Int)] {
        relation?.prominentDimensions ?? []
    }

    static func resonanceScore(for relation: RelationshipState?) -> Int {
        let values = dimensions(for: relation).prefix(3).map(\.1)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / values.count
    }

    static func influenceScore(for character: Character, relation: RelationshipState?) -> Int {
        let roleBonus: Int
        switch character.role {
        case .protagonist:
            roleBonus = 32
        case .mentor, .antagonist:
            roleBonus = 24
        case .rival, .loveInterest:
            roleBonus = 20
        case .ally, .family:
            roleBonus = 18
        case .neutral:
            roleBonus = 12
        }

        return min(100, roleBonus + resonanceScore(for: relation))
    }

    static func stanceSummary(for character: Character, relation: RelationshipState?) -> String {
        guard let relation else {
            return "这个人还没有真正入局，你只看得见轮廓，看不见立场。"
        }

        let attitude = relation.attitudeLabel
        let dimensions = relation.topDimensions(limit: 2)
        if dimensions.isEmpty {
            return "\(character.name)已经出现在棋局里，但还没有露出足够稳定的态度。"
        }

        let leading = dimensions[0]
        let trailing = dimensions.count > 1 ? dimensions[1] : nil
        if let trailing {
            return "\(character.name)当前最明显的是「\(leading.0.rawValue)」与「\(trailing.0.rawValue)」，整体态度落在「\(attitude)」。"
        }
        return "\(character.name)当前最明显的是「\(leading.0.rawValue)」，整体态度落在「\(attitude)」。"
    }

    static func thresholdHint(for character: Character, relation: RelationshipState?) -> String {
        guard let relation else {
            return "继续推进章节、接住第一次正面互动后，这个人的真正立场才会显形。"
        }

        let trustGap = max(0, 60 - relation.trust)
        let curiosityGap = max(0, 55 - relation.value(for: .curiosity))
        let vigilanceGap = max(0, relation.value(for: .vigilance) - 35)

        if trustGap == 0 && curiosityGap == 0 {
            return "这条线已经可以被主动牵引，适合拿来试探暗线或交换真相。"
        }
        if vigilanceGap > 0 {
            return "先压低「警惕」再继续靠近，否则 \(character.name) 会把你的后手看成威胁。"
        }
        if trustGap < curiosityGap {
            return "再补 \(trustGap) 点「信任」，这条线就更容易被稳稳拉住。"
        }
        return "再补 \(curiosityGap) 点「好奇」，更适合把 \(character.name) 引进你的局。"
    }
}

struct SoloCharacterPortraitView: View {
    let character: Character
    let relation: RelationshipState?
    var height: CGFloat = 176

    private var portraitAsset: SoloArtworkAsset? {
        TianjiluArtworkCatalog.portrait(for: character)
    }

    var body: some View {
        let accent = SoloCharacterCodex.accent(for: character, relation: relation)

        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.28),
                            SoloTheme.surfaceRaised.opacity(0.92),
                            Color.black.opacity(0.96),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let portraitAsset {
                SoloBundledArtworkImage(resourceName: portraitAsset.resourceName, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.clear,
                                Color.black.opacity(0.66),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                RadialGradient(
                    colors: [
                        accent.opacity(0.12),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.74, y: 0.18),
                    startRadius: 12,
                    endRadius: height * 0.70
                )
            } else {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: height * 0.72, height: height * 0.72)
                    .blur(radius: 10)

                Circle()
                    .strokeBorder(accent.opacity(0.22), lineWidth: 1)
                    .frame(width: height * 0.68, height: height * 0.68)

                Circle()
                    .strokeBorder(SoloTheme.gold.opacity(0.14), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
                    .frame(width: height * 0.82, height: height * 0.82)

                Text(String(character.name.prefix(1)))
                    .font(SoloTypography.posterTitle(size: height * 0.34))
                    .foregroundStyle(Color.white.opacity(0.08))
                    .offset(x: height * 0.08, y: -height * 0.10)

                VStack(spacing: 10) {
                    Image(systemName: SoloCharacterCodex.roleSymbol(for: character.role))
                        .font(.system(size: height * 0.16, weight: .semibold))
                        .foregroundStyle(accent)

                    Capsule(style: .continuous)
                        .fill(SoloTheme.gold.opacity(0.18))
                        .frame(width: height * 0.18, height: 4)
                }
            }

            VStack {
                HStack {
                    Text(SoloCharacterCodex.roleLabel(for: character.role))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.26)))
                    Spacer()
                    if let relation {
                        Text(relation.attitudeLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SoloTheme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(accent.opacity(0.22)))
                    }
                }
                Spacer()

                if let portraitAsset {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(portraitAsset.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SoloTheme.ink)
                            Text(portraitAsset.subtitle)
                                .font(.caption2)
                                .foregroundStyle(SoloTheme.warmInk)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                }
            }
            .padding(14)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

struct SoloCharacterRosterCard: View {
    let character: Character
    let relation: RelationshipState?

    var body: some View {
        let accent = SoloCharacterCodex.accent(for: character, relation: relation)
        let resonance = SoloCharacterCodex.resonanceScore(for: relation)
        let influence = SoloCharacterCodex.influenceScore(for: character, relation: relation)

        VStack(alignment: .leading, spacing: 14) {
            SoloCharacterPortraitView(character: character, relation: relation, height: 152)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(character.name)
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.ink)
                    Spacer()
                    if relation == nil {
                        labelChip(text: "未入局", tint: SoloTheme.muted)
                    }
                }

                Text(character.title)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.gold.opacity(0.82))

                Text(SoloCharacterCodex.stanceSummary(for: character, relation: relation))
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
                    .lineLimit(3)
            }

            if relation != nil {
                HStack(spacing: 10) {
                    infoBadge(title: "牵引", value: "\(resonance)", tint: accent)
                    infoBadge(title: "局重", value: "\(influence)", tint: SoloTheme.gold)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SoloCharacterCodex.dimensions(for: relation).prefix(2), id: \.0.rawValue) { dimension, value in
                        SoloCharacterMeterRow(
                            title: dimension.rawValue,
                            value: value,
                            tint: SoloCharacterCodex.tint(for: dimension)
                        )
                    }
                }
            }
        }
        .padding(16)
        .soloPanel(.evidence, prominence: relation == nil ? 0.04 : 0.14)
    }

    private func infoBadge(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func labelChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

struct SoloCharacterDetailView: View {
    let character: Character
    let relation: RelationshipState?
    let destinyStatus: SoloDestinyStatus?

    private var portraitAsset: SoloArtworkAsset? {
        TianjiluArtworkCatalog.portrait(for: character)
    }

    private var accent: Color {
        SoloCharacterCodex.accent(for: character, relation: relation)
    }

    private var resonance: Int {
        SoloCharacterCodex.resonanceScore(for: relation)
    }

    private var influence: Int {
        SoloCharacterCodex.influenceScore(for: character, relation: relation)
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroPanel
                    currentStancePanel
                    dimensionPanel
                    lorePanel
                    thresholdPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: character.name, kicker: relation == nil ? "未入局" : "角色档案")
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SoloCharacterPortraitView(character: character, relation: relation, height: 228)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(SoloTypography.posterTitle(size: 30))
                            .foregroundStyle(SoloTheme.ink)
                        Text(character.title)
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        chip(text: SoloCharacterCodex.roleLabel(for: character.role), tint: accent)
                        chip(text: relation?.attitudeLabel ?? "未入局", tint: relation == nil ? SoloTheme.muted : accent)
                    }
                }

                Text(character.description)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(5)

                if let caption = portraitAsset?.caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineSpacing(4)
                }
            }
        }
        .padding(22)
        .soloPanel(.hero, prominence: 0.18)
    }

    private var currentStancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("当前盘面")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 10) {
                statCard(title: "当前态度", value: relation?.attitudeLabel ?? "未入局", detail: SoloCharacterCodex.stanceSummary(for: character, relation: relation), tint: accent)
                statCard(title: "牵引指数", value: "\(resonance)", detail: "越高说明这条关系越适合被主动推动，用来借势、套话或交换后手。", tint: SoloTheme.gold)
                statCard(title: "命局权重", value: "\(influence)", detail: "越高说明这个人越可能影响你的主线走向、暗线条件或后续风险。", tint: SoloTheme.crimson)
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    @ViewBuilder
    private var dimensionPanel: some View {
        if let relation {
            VStack(alignment: .leading, spacing: 14) {
                Text("具体属性")
                    .font(SoloTypography.sectionTitle())
                    .foregroundStyle(SoloTheme.ink)

                ForEach(SoloCharacterCodex.dimensions(for: relation), id: \.0.rawValue) { dimension, value in
                    SoloCharacterMeterRow(
                        title: dimension.rawValue,
                        value: value,
                        tint: SoloCharacterCodex.tint(for: dimension),
                        detail: dimensionNarration(for: dimension, value: value)
                    )
                }
            }
            .padding(22)
            .soloPanel(.stage)
        }
    }

    private var lorePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("局中情报")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(alignment: .leading, spacing: 10) {
                loreRow(title: "人物定位", detail: "\(character.name)在当前书内被识别为「\(SoloCharacterCodex.roleLabel(for: character.role))」单位。")
                loreRow(title: "当前判断", detail: SoloCharacterCodex.stanceSummary(for: character, relation: relation))
                if let reason = relation?.lastChangeReason {
                    loreRow(title: "最近波动", detail: reason)
                }
            }
        }
        .padding(22)
        .soloPanel(.evidence, prominence: 0.14)
    }

    private var thresholdPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下一步建议")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(accent)

            Text(SoloCharacterCodex.thresholdHint(for: character, relation: relation))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(5)

            if let destinyStatus {
                Text("当前命局：\(destinyStatus.headline)。\(destinyStatus.thresholdHint)")
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .padding(22)
        .soloPanel(.alert, prominence: 0.12)
    }

    private func statCard(title: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(value)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink)
            Text(detail)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
        .soloPanel(.evidence, prominence: 0.14)
    }

    private func chip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    private func loreRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)
            Text(detail)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
        }
    }

    private func dimensionNarration(
        for dimension: RelationshipEffect.RelationshipDimension,
        value: Int
    ) -> String {
        switch dimension {
        case .trust:
            return value >= 60 ? "已经可以把关键消息先递给你。" : "还在观察你到底值不值得托底。"
        case .affection:
            return value >= 60 ? "情绪会明显偏向你。" : "还没到会为你改立场的时候。"
        case .hostility:
            return value >= 60 ? "这条线已经有直接翻脸风险。" : "对抗性仍在积累。"
        case .awe:
            return value >= 60 ? "对你的判断带着明显敬畏。" : "更多是谨慎旁观。"
        case .dependence:
            return value >= 60 ? "一旦你抽手，对方会失衡。" : "还没形成真正绑定。"
        case .curiosity:
            return value >= 55 ? "最适合拿来引入暗线与秘密。" : "还停留在试探阶段。"
        case .vigilance:
            return value >= 45 ? "你的一举一动都会被放大解读。" : "警报还没彻底拉满。"
        case .contempt:
            return value >= 45 ? "对你存在轻敌窗口，可利用。" : "轻视感正在缓慢形成。"
        case .anger:
            return value >= 45 ? "情绪已经容易失控，适合引爆。" : "怒意还没彻底点燃。"
        default:
            return "这是当前关系里已经浮出水面的额外维度。"
        }
    }
}

struct SoloCharacterMeterRow: View {
    let title: String
    let value: Int
    let tint: Color
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SoloTheme.warmInk)
                Spacer()
                Text("\(value)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.88))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 8)

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
            }
        }
    }
}
