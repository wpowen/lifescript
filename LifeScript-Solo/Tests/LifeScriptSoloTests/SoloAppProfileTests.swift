import XCTest
@testable import LifeScriptSolo

final class SoloAppProfileTests: XCTestCase {
    func test_resolve_usesApocalypseDefaultsWhenInfoDictionaryMissingOverrides() {
        let profile = SoloAppProfile.resolve(infoDictionary: [:])

        XCTAssertEqual(profile.storyID, "apocalypse_001")
        XCTAssertEqual(profile.branding.appDisplayName, "灰烬执政官")
        XCTAssertEqual(profile.branding.storyDisplayName, "灰烬执政官")
        XCTAssertEqual(profile.branding.palettePreset, .ashCrimson)
        XCTAssertEqual(profile.branding.entryEyebrow, "末日剧场 · 互动长篇")
        XCTAssertEqual(profile.branding.promise, "你不是在旁观末日。你是在决定谁能活到明天。")
        XCTAssertEqual(profile.branding.routeMapTitle, "灾变路线")
        XCTAssertEqual(profile.branding.landing.primaryActionTitle, "进入避难夜")
        XCTAssertEqual(profile.branding.landing.identityLabel, "当前生存身份")
    }

    func test_resolve_readsStoryAndBrandingOverridesFromInfoDictionary() {
        let profile = SoloAppProfile.resolve(
            infoDictionary: [
                "SoloStoryID": "business_001",
                "SoloPalettePreset": "sapphireMist",
                "SoloEntryEyebrow": "权谋商战 · 互动长篇",
                "SoloPromise": "这一局不是看你能不能赢，而是看你打算牺牲掉什么。",
                "SoloContinueHint": "回到牌桌，看看上一轮下注正在逼谁露出底牌。",
                "SoloCurrentRunTitle": "当前牌局",
                "SoloRecapTitle": "上一轮回响",
                "SoloStageTitle": "当前牌桌",
                "SoloObjectiveTitle": "眼下筹码",
                "SoloDossierTitle": "人物与筹码",
                "SoloRouteMapTitle": "牌局路线",
                "SoloSettlementTitle": "本轮影响",
                "SoloChapterUnitName": "幕",
                "SoloAtmosphereLine": "真正危险的从来不是输赢，而是谁先看懂谁。",
                "SoloOrnamentSymbol": "crown.fill",
                "SoloEntryInteractivePrompt": "你说过的话，会被记住；你按下去的每一步，都会改变牌桌上的关系。",
                "SoloEntryPrimaryActionTitle": "进入第一幕",
                "SoloEntrySecondaryActionTitle": "先看世界观",
                "SoloEntryIdentityLabel": "当前身份",
                "SoloEntryDossierSubtitle": "看谁已经站到你这一边，又有谁在等你露出破绽。",
                "SoloEntryRouteMapSubtitle": "看公开路线，也看那些暂时还不愿意亮出来的牌。",
                "SoloEntryHookTitle": "第一条讯息",
                "SoloEntryHookBody": "你以为自己只是迟到了一步，实际上整张牌桌都已经先开始了。",
                "SoloEntryValueCards": [
                    [
                        "id": "dialogue",
                        "title": "不是普通阅读",
                        "detail": "人物会记住你的态度与回应。",
                        "tint": "sapphireMist"
                    ]
                ],
                "SoloEntryFlowSteps": [
                    [
                        "id": "enter",
                        "title": "进入剧情",
                        "detail": "以第一人称被卷入事件。",
                        "tint": "emberGold"
                    ]
                ],
                "SoloEntryProofCards": [
                    [
                        "id": "route",
                        "kind": "routeMap",
                        "title": "路线图预览",
                        "detail": "不同分支会改变局势与人物站位。",
                        "tint": "royalPlum"
                    ]
                ],
                "CFBundleDisplayName": "局中局"
            ]
        )

        XCTAssertEqual(profile.storyID, "business_001")
        XCTAssertEqual(profile.branding.appDisplayName, "局中局")
        XCTAssertEqual(profile.branding.routeMapTitle, "牌局路线")
        XCTAssertEqual(profile.branding.chapterUnitName, "幕")
        XCTAssertEqual(profile.branding.palettePreset, .sapphireMist)
        XCTAssertEqual(profile.branding.landing.interactivePrompt, "你说过的话，会被记住；你按下去的每一步，都会改变牌桌上的关系。")
        XCTAssertEqual(profile.branding.landing.primaryActionTitle, "进入第一幕")
        XCTAssertEqual(profile.branding.landing.secondaryActionTitle, "先看世界观")
        XCTAssertEqual(profile.branding.landing.identityLabel, "当前身份")
        XCTAssertEqual(profile.branding.landing.dossierSubtitle, "看谁已经站到你这一边，又有谁在等你露出破绽。")
        XCTAssertEqual(profile.branding.landing.routeMapSubtitle, "看公开路线，也看那些暂时还不愿意亮出来的牌。")
        XCTAssertEqual(profile.branding.landing.hookTitle, "第一条讯息")
        XCTAssertEqual(profile.branding.landing.hookBody, "你以为自己只是迟到了一步，实际上整张牌桌都已经先开始了。")
        XCTAssertEqual(profile.branding.landing.valueCards.map(\.title), ["不是普通阅读"])
        XCTAssertEqual(profile.branding.landing.flowSteps.map(\.title), ["进入剧情"])
        XCTAssertEqual(profile.branding.landing.proofCards.map(\.kind), [.routeMap])
    }
}
