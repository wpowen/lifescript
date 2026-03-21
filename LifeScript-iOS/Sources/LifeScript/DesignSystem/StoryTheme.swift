import SwiftUI

struct StoryPalette {
    let primary: Color
    let secondary: Color
    let tertiary: Color
}

extension Book.Genre {
    var palette: StoryPalette {
        switch self {
        case .urbanReversal:
            StoryPalette(primary: .accentGold, secondary: .accentCrimson, tertiary: .accentSky)
        case .cultivation:
            StoryPalette(primary: .accentEmerald, secondary: .accentGold, tertiary: .accentSky)
        case .suspenseSurvival:
            StoryPalette(primary: .accentCrimson, secondary: .accentSky, tertiary: .accentAmber)
        case .businessWar:
            StoryPalette(primary: .accentSky, secondary: .accentGold, tertiary: .accentEmerald)
        }
    }

    var sceneName: String {
        switch self {
        case .urbanReversal:
            "都市夜场"
        case .cultivation:
            "仙门试炼"
        case .suspenseSurvival:
            "危机现场"
        case .businessWar:
            "权谋牌桌"
        }
    }

    var controlPrompt: String {
        switch self {
        case .urbanReversal:
            "选一条最爽的逆袭路线，直接推动局势反转。"
        case .cultivation:
            "在突破、隐忍和奇遇之间，决定主角修行的气口。"
        case .suspenseSurvival:
            "每一步都关乎存活与真相，节奏和判断都不能慢。"
        case .businessWar:
            "你要操盘的是局势、人心和时机，不只是输赢。"
        }
    }
}

extension Book {
    var palette: StoryPalette { genre.palette }

    var sceneSummary: String {
        "\(genre.sceneName) · \(genre.displayName)"
    }
}

extension SatisfactionType {
    var accentColor: Color {
        switch self {
        case .immediatePower:
            .accentCrimson
        case .delayedRevenge:
            .accentAmber
        case .cunningScheme:
            .accentSky
        case .dominantCrush:
            .accentGold
        case .emotionalPlay:
            .accentViolet
        case .undercover:
            .accentEmerald
        }
    }
}

extension ChoiceNode.ChoiceType {
    var displayName: String {
        switch self {
        case .keyDecision:
            "关键抉择"
        case .styleChoice:
            "爽感风格"
        case .characterPref:
            "角色推进"
        }
    }
}
