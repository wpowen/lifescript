import Foundation

/// A book (novel) in the LifeScript library.
/// Content is loaded from JSON; user progress is stored in SwiftData.
struct Book: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let author: String
    let coverImageName: String
    let synopsis: String
    let genre: Genre
    let tags: [String]
    let interactionTags: [String]
    let totalChapters: Int
    let freeChapters: Int
    let characters: [Character]
    let initialStats: ProtagonistStats

    enum Genre: String, Codable, Sendable, CaseIterable {
        case urbanReversal = "都市逆袭"
        case cultivation = "修仙升级"
        case suspenseSurvival = "悬疑生存"
        case businessWar = "职场商战"
        case apocalypsePower = "末日爽文"

        var displayName: String { rawValue }

        var iconName: String {
            switch self {
            case .urbanReversal: return "building.2"
            case .cultivation: return "flame"
            case .suspenseSurvival: return "eye.trianglebadge.exclamationmark"
            case .businessWar: return "chart.line.uptrend.xyaxis"
            case .apocalypsePower: return "bolt.trianglebadge.exclamationmark.fill"
            }
        }
    }
}
