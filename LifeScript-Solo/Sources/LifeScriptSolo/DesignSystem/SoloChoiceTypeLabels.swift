import Foundation

extension ChoiceNode.ChoiceType {
    var displayName: String {
        switch rawValue {
        case Self.keyDecision.rawValue:
            return SoloLocalization.localized("关键抉择")
        case Self.styleChoice.rawValue:
            return SoloLocalization.localized("爽感风格")
        case Self.characterPref.rawValue:
            return SoloLocalization.localized("角色推进")
        default:
            return SoloLocalization.localized(rawValue)
        }
    }
}
