import Foundation

struct SoloAppProfile: Equatable, Sendable {
    let storyID: String
    let branding: SoloBranding

    static var current: SoloAppProfile {
        resolve(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    static func resolve(infoDictionary: [String: Any]) -> SoloAppProfile {
        let appDisplayName = stringValue("CFBundleDisplayName", in: infoDictionary) ?? "灰烬执政官"
        let palettePreset = SoloPalettePreset(rawValue: stringValue("SoloPalettePreset", in: infoDictionary) ?? "") ?? .ashCrimson
        let storyDisplayName = stringValue("SoloStoryDisplayName", in: infoDictionary) ?? appDisplayName
        let dossierTitle = stringValue("SoloDossierTitle", in: infoDictionary) ?? "生存档案"
        let routeMapTitle = stringValue("SoloRouteMapTitle", in: infoDictionary) ?? "灾变路线"
        let landing = resolveLandingConfig(
            infoDictionary: infoDictionary,
            palettePreset: palettePreset,
            storyDisplayName: storyDisplayName,
            dossierTitle: dossierTitle,
            routeMapTitle: routeMapTitle
        )

        let branding = SoloBranding(
            appDisplayName: appDisplayName,
            storyDisplayName: storyDisplayName,
            entryEyebrow: stringValue("SoloEntryEyebrow", in: infoDictionary) ?? "末日剧场 · 互动长篇",
            promise: stringValue("SoloPromise", in: infoDictionary) ?? "你不是在旁观末日。你是在决定谁能活到明天。",
            continueHint: stringValue("SoloContinueHint", in: infoDictionary) ?? "回到停电后的安全区，让上一夜留下的余波继续扩散。",
            currentRunTitle: stringValue("SoloCurrentRunTitle", in: infoDictionary) ?? "当前夜线",
            recapTitle: stringValue("SoloRecapTitle", in: infoDictionary) ?? "上一夜回响",
            currentStageTitle: stringValue("SoloStageTitle", in: infoDictionary) ?? "当前生存阶段",
            objectiveTitle: stringValue("SoloObjectiveTitle", in: infoDictionary) ?? "眼下保命目标",
            dossierTitle: dossierTitle,
            routeMapTitle: routeMapTitle,
            settlementTitle: stringValue("SoloSettlementTitle", in: infoDictionary) ?? "本章余波",
            chapterUnitName: stringValue("SoloChapterUnitName", in: infoDictionary) ?? "章",
            atmosphereLine: stringValue("SoloAtmosphereLine", in: infoDictionary) ?? "警报还没停，火光已经把人心照得太清楚。",
            ornamentSymbol: stringValue("SoloOrnamentSymbol", in: infoDictionary) ?? "bolt.horizontal.circle.fill",
            palettePreset: palettePreset,
            landing: landing
        )

        return SoloAppProfile(
            storyID: stringValue("SoloStoryID", in: infoDictionary) ?? "apocalypse_001",
            branding: branding
        )
    }

    private static func stringValue(_ key: String, in infoDictionary: [String: Any]) -> String? {
        infoDictionary[key] as? String
    }

    private static func resolveLandingConfig(
        infoDictionary: [String: Any],
        palettePreset: SoloPalettePreset,
        storyDisplayName: String,
        dossierTitle: String,
        routeMapTitle: String
    ) -> SoloEntryLandingConfig {
        let defaults = defaultLandingConfig(
            palettePreset: palettePreset,
            storyDisplayName: storyDisplayName,
            dossierTitle: dossierTitle,
            routeMapTitle: routeMapTitle
        )

        return SoloEntryLandingConfig(
            interactivePrompt: stringValue("SoloEntryInteractivePrompt", in: infoDictionary) ?? defaults.interactivePrompt,
            primaryActionTitle: stringValue("SoloEntryPrimaryActionTitle", in: infoDictionary) ?? defaults.primaryActionTitle,
            secondaryActionTitle: stringValue("SoloEntrySecondaryActionTitle", in: infoDictionary) ?? defaults.secondaryActionTitle,
            identityLabel: stringValue("SoloEntryIdentityLabel", in: infoDictionary) ?? defaults.identityLabel,
            dossierSubtitle: stringValue("SoloEntryDossierSubtitle", in: infoDictionary) ?? defaults.dossierSubtitle,
            routeMapSubtitle: stringValue("SoloEntryRouteMapSubtitle", in: infoDictionary) ?? defaults.routeMapSubtitle,
            hookTitle: stringValue("SoloEntryHookTitle", in: infoDictionary) ?? defaults.hookTitle,
            hookBody: stringValue("SoloEntryHookBody", in: infoDictionary) ?? defaults.hookBody,
            valueCards: parseValueCards(infoDictionary: infoDictionary, fallback: defaults.valueCards, defaultTint: palettePreset),
            flowSteps: parseFlowSteps(infoDictionary: infoDictionary, fallback: defaults.flowSteps, defaultTint: palettePreset),
            proofCards: parseProofCards(infoDictionary: infoDictionary, fallback: defaults.proofCards, defaultTint: palettePreset)
        )
    }

    private static func defaultLandingConfig(
        palettePreset: SoloPalettePreset,
        storyDisplayName: String,
        dossierTitle: String,
        routeMapTitle: String
    ) -> SoloEntryLandingConfig {
        switch palettePreset {
        case .ashCrimson:
            return SoloEntryLandingConfig(
                interactivePrompt: "你决定先救谁、怀疑谁、向谁隐瞒真相，都会让安全区里的关系和代价发生偏移。",
                primaryActionTitle: "进入避难夜",
                secondaryActionTitle: "先看灾变路线",
                identityLabel: "当前生存身份",
                dossierSubtitle: "先看谁还能信、谁已经松动，也看哪些关系正在被资源和恐惧拉扯。",
                routeMapSubtitle: "先看明面上的撤离线，再看那些只露出半句警报的暗线。",
                hookTitle: "\(storyDisplayName) 不会等你准备好",
                hookBody: "你现在打开的不是目录，而是一场已经开始倒数的灾变夜。只要按下去，就有人会因为你的决定活下来，也有人不会。",
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: "不是普通阅读", detail: "每一句安抚、试探或命令都会留下后果。你不是旁观者，而是安全区秩序的一部分。", tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: "不是单线求生", detail: "同一场警报，会因为你先保住谁、先牺牲谁，而长出截然不同的局势与人心。", tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: "不是一次性消费", detail: "重开不是重看，而是重新验证另一种生存策略会把世界推向哪里。", tint: .moonJade),
                    SoloEntryValueCard(id: "crafted-experience", title: "不是廉价灾变壳", detail: "警报、火光、余波与界面反馈一起服务于压迫感，而不是把末日题材随手贴在文字外面。", tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: "进入现场", detail: "不是读一段旁白，而是直接进入电力崩塌、物资失衡和人心松动的那一夜。", tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: "做出回应", detail: "你可以封锁、安抚、试探、强压，人物会沿着你的处理方式重新站队。", tint: .moonJade),
                    SoloEntryFlowStep(id: "change-destiny", title: "灾变偏转", detail: "资源、阵营、秘密与死亡名单都会变化，你走出来的夜线不会和别人一样。", tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: "对话预览", detail: "你在恐慌里说过的话，会被记住，也会在下一次断电前重新找上你。", tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: "分支预览", detail: "你以为只是换一种处置方式，实际可能是在把避难区推向另一条生存线。", tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: "看人物态度、资源紧张和当前局势，理解谁愿意跟你熬过这一关，谁在等你失手。", tint: .moonJade),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: "公开路线会亮出撤离承诺，而真正危险的暗线，通常只会先漏出一点信号。", tint: .sapphireMist),
                ]
            )
        case .moonJade:
            return SoloEntryLandingConfig(
                interactivePrompt: "你何时出手、如何回应、要不要继续追问那句被压住的真相，都会让这条路改道。",
                primaryActionTitle: "进入第一幕",
                secondaryActionTitle: "先看剑路图",
                identityLabel: "当前剑局",
                dossierSubtitle: "先看人物态度、势能消长，以及谁正在把筹码压到你身上。",
                routeMapSubtitle: "先看明面上的路，也看那些尚未真正亮出来的潜流。",
                hookTitle: "\(storyDisplayName) 不是旁观故事",
                hookBody: "你现在打开的不是目录，而是一场已经开始发酵的局。只要按下去，人物就会开始记住你的态度。",
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: "不是普通阅读", detail: "人物不是等你看完，而是在等你回应。态度不同，回声就会不同。", tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: "不是线性剑路", detail: "同一个起点，会因为你的判断不同，长出完全不一样的因果和代价。", tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: "不是一次性消费", detail: "重开不是重看，而是把此前错过的人心、暗线和伏笔重新照亮。", tint: .emberGold),
                    SoloEntryValueCard(id: "crafted-experience", title: "不是低成本拼装", detail: "文案、界面、节奏和反馈共同构成沉浸感，而不是把文字简单装进壳子里。", tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: "进入局中", detail: "不是站在外面读故事，而是直接被卷进那场会留下后果的事件。", tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: "做出回应", detail: "你可以试探、压制、追问、退让，每一种姿态都会让人物重新判断你。", tint: .emberGold),
                    SoloEntryFlowStep(id: "change-destiny", title: "局势偏转", detail: "分支、关系、暗线与结局都会变化，你走出来的路不会和别人一样。", tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: "对话预览", detail: "你说过的话，往往会在后面的对局里被重新提起。", tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: "分支预览", detail: "不是选项换皮，而是真正会推动关系和分路变化的决定。", tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: "看人物态度、当前局势和你自己的命格变化，理解谁站在你身边，谁在等你失手。", tint: .emberGold),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: "公开路线会给你承诺，真正高价值的暗线往往只露出半步。", tint: .sapphireMist),
                ]
            )
        default:
            return SoloEntryLandingConfig(
                interactivePrompt: "你说过的话、做出的判断和选择站位，都会让人物关系、分支和真相显露顺序发生偏移。",
                primaryActionTitle: "进入第一幕",
                secondaryActionTitle: "先看路线图",
                identityLabel: "当前状态",
                dossierSubtitle: "先看谁已经被你卷进局里，也看谁还没有真正亮出态度。",
                routeMapSubtitle: "先看公开路线，再看还有哪些暗线没有彻底浮出水面。",
                hookTitle: "\(storyDisplayName) 不是一本书",
                hookBody: "你现在打开的不是目录，而是一处已经开始运转的事件现场。只要按下去，角色就会开始记住你的态度。",
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: "不是普通阅读", detail: "沉浸式对话推进。你不是旁观者，而是会被回应的剧情参与者。", tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: "不是线性故事", detail: "同一个起点，不同判断，会带来不同关系、真相与结局倾斜。", tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: "不是一次性消费", detail: "可重玩、可回溯、可解锁隐藏线，每次重进都会看见另一层动机。", tint: .moonJade),
                    SoloEntryValueCard(id: "crafted-experience", title: "不是廉价拼贴", detail: "电影化叙事与精细交互设计一起服务于沉浸感，而不是堆砌设定。", tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: "进入剧情", detail: "以第一人称视角进入故事现场，而不是站在外面看一段文字。", tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: "做出回应", detail: "你可以选择态度、行动和追问方向，人物会记住你如何开口。", tint: .moonJade),
                    SoloEntryFlowStep(id: "change-destiny", title: "命运改变", detail: "分支、关系、线索和结局倾斜都会变化，你走出来的路不会和别人完全一样。", tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: "对话预览", detail: "你说的话，会被角色记住，也会被下一次相遇悄悄追上。", tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: "分支预览", detail: "你以为只是换一种回答方式，实际可能是在把命运推向另一条线。", tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: "看人物态度、关系势能与当前局势，理解谁站在你身边，谁在等你失手。", tint: .moonJade),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: "公开路线会提前亮出承诺，而真正危险的暗线，往往只露出一点回声。", tint: .sapphireMist),
                ]
            )
        }
    }

    private static func parseValueCards(
        infoDictionary: [String: Any],
        fallback: [SoloEntryValueCard],
        defaultTint: SoloPalettePreset
    ) -> [SoloEntryValueCard] {
        guard let rawCards = infoDictionary["SoloEntryValueCards"] as? [[String: Any]], !rawCards.isEmpty else {
            return fallback
        }

        let cards = rawCards.enumerated().compactMap { index, rawCard -> SoloEntryValueCard? in
            guard let title = rawCard["title"] as? String,
                  let detail = rawCard["detail"] as? String else {
                return nil
            }

            return SoloEntryValueCard(
                id: (rawCard["id"] as? String) ?? "value-card-\(index)",
                title: title,
                detail: detail,
                tint: paletteValue(rawCard["tint"], defaultTint: defaultTint)
            )
        }

        return cards.isEmpty ? fallback : cards
    }

    private static func parseFlowSteps(
        infoDictionary: [String: Any],
        fallback: [SoloEntryFlowStep],
        defaultTint: SoloPalettePreset
    ) -> [SoloEntryFlowStep] {
        guard let rawSteps = infoDictionary["SoloEntryFlowSteps"] as? [[String: Any]], !rawSteps.isEmpty else {
            return fallback
        }

        let steps = rawSteps.enumerated().compactMap { index, rawStep -> SoloEntryFlowStep? in
            guard let title = rawStep["title"] as? String,
                  let detail = rawStep["detail"] as? String else {
                return nil
            }

            return SoloEntryFlowStep(
                id: (rawStep["id"] as? String) ?? "flow-step-\(index)",
                title: title,
                detail: detail,
                tint: paletteValue(rawStep["tint"], defaultTint: defaultTint)
            )
        }

        return steps.isEmpty ? fallback : steps
    }

    private static func parseProofCards(
        infoDictionary: [String: Any],
        fallback: [SoloEntryProofCard],
        defaultTint: SoloPalettePreset
    ) -> [SoloEntryProofCard] {
        guard let rawCards = infoDictionary["SoloEntryProofCards"] as? [[String: Any]], !rawCards.isEmpty else {
            return fallback
        }

        let cards = rawCards.enumerated().compactMap { index, rawCard -> SoloEntryProofCard? in
            guard let title = rawCard["title"] as? String,
                  let detail = rawCard["detail"] as? String,
                  let kindRawValue = rawCard["kind"] as? String,
                  let kind = SoloEntryProofKind(rawValue: kindRawValue) else {
                return nil
            }

            return SoloEntryProofCard(
                id: (rawCard["id"] as? String) ?? "proof-card-\(index)",
                kind: kind,
                title: title,
                detail: detail,
                tint: paletteValue(rawCard["tint"], defaultTint: defaultTint)
            )
        }

        return cards.isEmpty ? fallback : cards
    }

    private static func paletteValue(_ rawValue: Any?, defaultTint: SoloPalettePreset) -> SoloPalettePreset {
        guard let rawValue = rawValue as? String,
              let palette = SoloPalettePreset(rawValue: rawValue) else {
            return defaultTint
        }
        return palette
    }
}
