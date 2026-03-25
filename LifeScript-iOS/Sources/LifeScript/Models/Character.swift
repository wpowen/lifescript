import Foundation

/// A character in a book's story
struct Character: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let title: String           // e.g. "三长老", "林家大小姐"
    let avatarImageName: String
    let description: String
    let role: CharacterRole

    enum CharacterRole: String, Codable, Sendable {
        case protagonist = "主角"
        case ally = "盟友"
        case rival = "宿敌"
        case loveInterest = "红颜"
        case mentor = "师尊"
        case family = "家族"
        case neutral = "中立"
        case antagonist = "反派"
    }
}
