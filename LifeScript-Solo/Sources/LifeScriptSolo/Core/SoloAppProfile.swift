import Foundation

struct SoloAppProfile: Equatable, Sendable {
    let storyID: String
    let branding: SoloBranding

    static var current: SoloAppProfile {
        resolve(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    static func resolve(infoDictionary: [String: Any]) -> SoloAppProfile {
        let appDisplayName = localizedValue("CFBundleDisplayName", in: infoDictionary) ?? SoloLocalization.localized("灰烬执政官")
        let palettePreset = SoloPalettePreset(rawValue: stringValue("SoloPalettePreset", in: infoDictionary) ?? "") ?? .ashCrimson
        let storyDisplayName = localizedValue("SoloStoryDisplayName", in: infoDictionary) ?? appDisplayName
        let dossierTitle = localizedValue("SoloDossierTitle", in: infoDictionary) ?? SoloLocalization.localized("生存档案")
        let routeMapTitle = localizedValue("SoloRouteMapTitle", in: infoDictionary) ?? SoloLocalization.localized("灾变路线")
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
            entryEyebrow: localizedValue("SoloEntryEyebrow", in: infoDictionary) ?? SoloLocalization.localized("末日剧场 · 互动长篇"),
            promise: localizedValue("SoloPromise", in: infoDictionary) ?? SoloLocalization.localized("你不是在旁观末日。你是在决定谁能活到明天。"),
            continueHint: localizedValue("SoloContinueHint", in: infoDictionary) ?? SoloLocalization.localized("回到停电后的安全区，让上一夜留下的余波继续扩散。"),
            currentRunTitle: localizedValue("SoloCurrentRunTitle", in: infoDictionary) ?? SoloLocalization.localized("当前夜线"),
            recapTitle: localizedValue("SoloRecapTitle", in: infoDictionary) ?? SoloLocalization.localized("上一夜回响"),
            currentStageTitle: localizedValue("SoloStageTitle", in: infoDictionary) ?? SoloLocalization.localized("当前生存阶段"),
            objectiveTitle: localizedValue("SoloObjectiveTitle", in: infoDictionary) ?? SoloLocalization.localized("眼下保命目标"),
            dossierTitle: dossierTitle,
            routeMapTitle: routeMapTitle,
            settlementTitle: localizedValue("SoloSettlementTitle", in: infoDictionary) ?? SoloLocalization.localized("本章余波"),
            chapterUnitName: localizedValue("SoloChapterUnitName", in: infoDictionary) ?? SoloLocalization.localized("章"),
            atmosphereLine: localizedValue("SoloAtmosphereLine", in: infoDictionary) ?? SoloLocalization.localized("警报还没停，火光已经把人心照得太清楚。"),
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

    private static func localizedValue(_ key: String, in infoDictionary: [String: Any]) -> String? {
        guard let value = stringValue(key, in: infoDictionary) else { return nil }
        return SoloLocalization.localized(value)
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
            interactivePrompt: localizedValue("SoloEntryInteractivePrompt", in: infoDictionary) ?? defaults.interactivePrompt,
            primaryActionTitle: localizedValue("SoloEntryPrimaryActionTitle", in: infoDictionary) ?? defaults.primaryActionTitle,
            secondaryActionTitle: localizedValue("SoloEntrySecondaryActionTitle", in: infoDictionary) ?? defaults.secondaryActionTitle,
            identityLabel: localizedValue("SoloEntryIdentityLabel", in: infoDictionary) ?? defaults.identityLabel,
            dossierSubtitle: localizedValue("SoloEntryDossierSubtitle", in: infoDictionary) ?? defaults.dossierSubtitle,
            routeMapSubtitle: localizedValue("SoloEntryRouteMapSubtitle", in: infoDictionary) ?? defaults.routeMapSubtitle,
            hookTitle: localizedValue("SoloEntryHookTitle", in: infoDictionary) ?? defaults.hookTitle,
            hookBody: localizedValue("SoloEntryHookBody", in: infoDictionary) ?? defaults.hookBody,
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
                interactivePrompt: SoloLocalization.localized("你决定先救谁、怀疑谁、向谁隐瞒真相，都会让安全区里的关系和代价发生偏移。"),
                primaryActionTitle: SoloLocalization.localized("进入避难夜"),
                secondaryActionTitle: SoloLocalization.localized("先看灾变路线"),
                identityLabel: SoloLocalization.localized("当前生存身份"),
                dossierSubtitle: SoloLocalization.localized("看谁还能信、谁已经松动，也看哪些关系正在被资源和恐惧拉扯。"),
                routeMapSubtitle: SoloLocalization.localized("看明面上的撤离线，也看那些只露出半句警报的暗线。"),
                hookTitle: SoloLocalization.localized("今夜的第一声警报"),
                hookBody: SoloLocalization.localized("这不是目录，而是一场已经开始倒数的灾变夜。你越快进去，越能感到每一步决定到底在牺牲什么。"),
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: SoloLocalization.localized("不是普通阅读"), detail: SoloLocalization.localized("每一次安抚、试探和命令，都会在断电夜里留下回声。"), tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: SoloLocalization.localized("不是单线求生"), detail: SoloLocalization.localized("同一场警报，会因为你先保住谁、先牺牲谁，而长出完全不同的夜线。"), tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: SoloLocalization.localized("不是一次性消费"), detail: SoloLocalization.localized("重开不是重看，而是重新验证另一种生存策略会把世界推向哪里。"), tint: .moonJade),
                    SoloEntryValueCard(id: "crafted-experience", title: SoloLocalization.localized("不是廉价灾变壳"), detail: SoloLocalization.localized("警报、火光、余波与界面反馈一起服务于压迫感，而不是把末日题材随手贴在文字外面。"), tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: SoloLocalization.localized("进入现场"), detail: SoloLocalization.localized("不是读旁白，而是直接进入电力崩塌、物资失衡和人心松动的那一夜。"), tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: SoloLocalization.localized("做出回应"), detail: SoloLocalization.localized("你可以封锁、安抚、试探、强压，人物会沿着你的处理方式重新站队。"), tint: .moonJade),
                    SoloEntryFlowStep(id: "change-destiny", title: SoloLocalization.localized("灾变偏转"), detail: SoloLocalization.localized("资源、阵营、秘密与死亡名单都会变化，你走出来的夜线不会和别人一样。"), tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: SoloLocalization.localized("对话预览"), detail: SoloLocalization.localized("你在恐慌里说过的话，会在下一次断电前重新找上你。"), tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: SoloLocalization.localized("分支预览"), detail: SoloLocalization.localized("不是选项换皮，而是真正会推动关系、资源和撤离线变化的决定。"), tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: SoloLocalization.localized("人物态度、补给压力和当前站位，都会在这里留下痕迹。"), tint: .moonJade),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: SoloLocalization.localized("公开路线会给你撤离承诺，真正危险的变化往往藏在暗线后面。"), tint: .sapphireMist),
                ]
            )
        case .moonJade:
            return SoloEntryLandingConfig(
                interactivePrompt: SoloLocalization.localized("你选择何时出剑、如何回应、要不要继续追问那句被压住的真相，都会改变剑局。"),
                primaryActionTitle: SoloLocalization.localized("进入第一幕"),
                secondaryActionTitle: SoloLocalization.localized("先看剑路图"),
                identityLabel: SoloLocalization.localized("当前剑局"),
                dossierSubtitle: SoloLocalization.localized("看人物态度、剑势消长与谁正在把筹码压到你身上。"),
                routeMapSubtitle: SoloLocalization.localized("看明面上的剑路，也看那些尚未真正亮出来的潜流。"),
                hookTitle: SoloLocalization.localized("今夜的第一道剑鸣"),
                hookBody: SoloLocalization.localized("这不是一次普通的开场，而是一场会持续发酵的试剑局。你越早进去，越能感觉到每一步后果。"),
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: SoloLocalization.localized("不是普通阅读"), detail: SoloLocalization.localized("人物不是等你看完，而是在等你回应。态度不同，回声就会不同。"), tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: SoloLocalization.localized("不是线性剑路"), detail: SoloLocalization.localized("同一柄残剑，可以走出不同的因果、不同的人心与不同的证道路。"), tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: SoloLocalization.localized("不是一次性消费"), detail: SoloLocalization.localized("重开后你会看到先前忽略的暗示、错过的人物动机，以及另一套局势走向。"), tint: .emberGold),
                    SoloEntryValueCard(id: "crafted-experience", title: SoloLocalization.localized("不是低成本拼装"), detail: SoloLocalization.localized("文案、界面、节奏和反馈共同构成沉浸感，而不是把文字简单装进壳子里。"), tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: SoloLocalization.localized("进入剧情"), detail: SoloLocalization.localized("以第一人称走进试剑局，而不是站在外面旁观一卷故事。"), tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: SoloLocalization.localized("做出回应"), detail: SoloLocalization.localized("你可以试探、压制、追问、退让，每一种姿态都会让人物重新判断你。"), tint: .emberGold),
                    SoloEntryFlowStep(id: "change-destiny", title: SoloLocalization.localized("剑局偏转"), detail: SoloLocalization.localized("剧情分支、角色好感、隐藏线索和最终结局会随你的判断发生偏移。"), tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: SoloLocalization.localized("对话预览"), detail: SoloLocalization.localized("一段对话不仅推进剧情，也会把关系推向不同的温度。"), tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: SoloLocalization.localized("分支预览"), detail: SoloLocalization.localized("一次回答方式的变化，可能就是另一条剑路的入口。"), tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: SoloLocalization.localized("角色态度、当前局势和你自己的命格变化都会被沉淀下来。"), tint: .emberGold),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: SoloLocalization.localized("公开路线展示方向，真正高价值的暗线则要靠你自己逼出来。"), tint: .sapphireMist),
                ]
            )
        default:
            return SoloEntryLandingConfig(
                interactivePrompt: SoloLocalization.localized("你选择何时动用天机录、先稳哪条关系、要不要提前摊牌，都会让因果链条发生偏转。"),
                primaryActionTitle: SoloLocalization.localized("进入第一幕"),
                secondaryActionTitle: SoloLocalization.localized("先看命途图"),
                identityLabel: SoloLocalization.localized("当前棋局"),
                dossierSubtitle: SoloLocalization.localized("看谁开始信你、谁在提防你，也看天命值与因果压力如何堆高。"),
                routeMapSubtitle: SoloLocalization.localized("看主线阶段，也看那些要靠关系阈值与天命代价才能逼出来的暗线。"),
                hookTitle: SoloLocalization.localized("命数第一次回响"),
                hookBody: SoloLocalization.localized("这不是普通书架，而是一场会越走越深的谋局修仙。你越早进去，越能感到每一次提前落子都在改命。"),
                valueCards: [
                    SoloEntryValueCard(id: "immersive-dialogue", title: SoloLocalization.localized("不是普通阅读"), detail: SoloLocalization.localized("人物不是等你看完，而是在等你回应。态度不同，回声就会不同。"), tint: palettePreset),
                    SoloEntryValueCard(id: "branching-destiny", title: SoloLocalization.localized("不是线性剑路"), detail: SoloLocalization.localized("同一柄残剑，可以走出不同的因果、不同的人心与不同的证道路。"), tint: .royalPlum),
                    SoloEntryValueCard(id: "replay-value", title: SoloLocalization.localized("不是一次性消费"), detail: SoloLocalization.localized("重开后你会看到先前忽略的暗示、错过的人物动机，以及另一套局势走向。"), tint: .moonJade),
                    SoloEntryValueCard(id: "crafted-experience", title: SoloLocalization.localized("不是低成本拼装"), detail: SoloLocalization.localized("文案、界面、节奏和反馈共同构成沉浸感，而不是把文字简单装进壳子里。"), tint: .sapphireMist),
                ],
                flowSteps: [
                    SoloEntryFlowStep(id: "enter-story", title: SoloLocalization.localized("进入剧情"), detail: SoloLocalization.localized("以第一人称走进试剑局，而不是站在外面旁观一卷故事。"), tint: palettePreset),
                    SoloEntryFlowStep(id: "make-response", title: SoloLocalization.localized("做出回应"), detail: SoloLocalization.localized("你可以试探、压制、追问、退让，每一种姿态都会让人物重新判断你。"), tint: .moonJade),
                    SoloEntryFlowStep(id: "change-destiny", title: SoloLocalization.localized("改命偏转"), detail: SoloLocalization.localized("人物态度、命数压力和隐藏线路一起偏转，后果会在下一章立刻回响。"), tint: .royalPlum),
                ],
                proofCards: [
                    SoloEntryProofCard(id: "dialogue-preview", kind: .dialogue, title: SoloLocalization.localized("对话预览"), detail: SoloLocalization.localized("你一句藏锋或摊牌，都会让人物对你的判断立刻变味。"), tint: palettePreset),
                    SoloEntryProofCard(id: "choice-preview", kind: .choice, title: SoloLocalization.localized("分支预览"), detail: SoloLocalization.localized("一次回答方式的变化，可能就是另一条剑路的入口。"), tint: .royalPlum),
                    SoloEntryProofCard(id: "dossier-preview", kind: .dossier, title: dossierTitle, detail: SoloLocalization.localized("角色态度、当前局势和你自己的命格变化都会被沉淀下来。"), tint: .moonJade),
                    SoloEntryProofCard(id: "route-preview", kind: .routeMap, title: routeMapTitle, detail: SoloLocalization.localized("公开路线展示方向，真正高价值的暗线则要靠你自己逼出来。"), tint: .sapphireMist),
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
                title: SoloLocalization.localized(title),
                detail: SoloLocalization.localized(detail),
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
                title: SoloLocalization.localized(title),
                detail: SoloLocalization.localized(detail),
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
                title: SoloLocalization.localized(title),
                detail: SoloLocalization.localized(detail),
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
