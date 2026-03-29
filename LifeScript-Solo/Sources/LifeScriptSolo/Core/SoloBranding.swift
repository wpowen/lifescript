import Foundation

enum SoloPalettePreset: String, Sendable {
    case ashCrimson
    case emberGold
    case moonJade
    case oracleJade
    case royalPlum
    case sapphireMist
}

struct SoloEntryValueCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let tint: SoloPalettePreset
}

struct SoloEntryFlowStep: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let tint: SoloPalettePreset
}

enum SoloEntryProofKind: String, Equatable, Sendable {
    case dialogue
    case choice
    case dossier
    case routeMap
    case timeline
}

struct SoloEntryProofCard: Equatable, Identifiable, Sendable {
    let id: String
    let kind: SoloEntryProofKind
    let title: String
    let detail: String
    let tint: SoloPalettePreset
}

struct SoloEntryLandingConfig: Equatable, Sendable {
    let interactivePrompt: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let identityLabel: String
    let dossierSubtitle: String
    let routeMapSubtitle: String
    let hookTitle: String
    let hookBody: String
    let valueCards: [SoloEntryValueCard]
    let flowSteps: [SoloEntryFlowStep]
    let proofCards: [SoloEntryProofCard]
}

struct SoloEntryExperienceStat: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let valueText: String
}

struct SoloBranding: Equatable, Sendable {
    let appDisplayName: String
    let storyDisplayName: String
    let entryEyebrow: String
    let promise: String
    let continueHint: String
    let currentRunTitle: String
    let recapTitle: String
    let currentStageTitle: String
    let objectiveTitle: String
    let dossierTitle: String
    let routeMapTitle: String
    let settlementTitle: String
    let chapterUnitName: String
    let atmosphereLine: String
    let ornamentSymbol: String
    let palettePreset: SoloPalettePreset
    let landing: SoloEntryLandingConfig
}

struct SoloWorldStatDelta: Sendable, Equatable {
    let name: String
    let value: Int
    let delta: Int
}

struct SoloWorldCharacterStatus: Sendable, Equatable {
    let characterId: String
    let name: String
    let attitudeLabel: String
}

enum SoloDestinyRiskLevel: String, Sendable {
    case abundant
    case steady
    case strained
    case critical
}

struct SoloDestinyStatus: Sendable, Equatable {
    let level: SoloDestinyRiskLevel
    let headline: String
    let detail: String
    let value: Int
    let thresholdHint: String
}

struct SoloEntrySnapshot: Sendable {
    let branding: SoloBranding
    let progress: SoloProgressSummary
    let generatedChapterCount: Int
    let plannedChapterCount: Int
    let currentStageTitle: String
    let currentStageSummary: String
    let currentObjective: String
    let currentObjectiveSummary: String
    let recapSummary: String?
    let hiddenRouteHint: String?
    let visibleRouteTitles: [String]
    let currentIdentityValue: String
    let destinyStatusLine: String
    let serialReleaseLine: String
    let destinyStatus: SoloDestinyStatus
    let hookLine: String
    let experienceStats: [SoloEntryExperienceStat]
    let worldStatDeltas: [SoloWorldStatDelta]
    let worldCharacters: [SoloWorldCharacterStatus]
}

struct SoloRouteMapSnapshot: Sendable {
    let currentChapterID: String?
    let currentStageID: String?
    let currentStageTitle: String?
    let currentObjective: String?
    let generatedChapterCount: Int
    let plannedChapterCount: Int
    let destinyStatus: SoloDestinyStatus
    let completedChapterIDs: Set<String>
}

struct SoloDossierModuleCard: Identifiable, Sendable {
    let id: String
    let title: String
    let valueText: String
    let detailText: String
    let tint: SoloPalettePreset
}

struct SoloDossierStatCard: Identifiable, Sendable {
    let id: String
    let title: String
    let value: Int
    let tint: SoloPalettePreset
}

struct SoloRelationshipSpotlight: Sendable {
    let characterName: String
    let characterTitle: String
    let attitudeLabel: String
    let reason: String?
}

struct SoloDossierSnapshot: Sendable {
    let statCards: [SoloDossierStatCard]
    let moduleCards: [SoloDossierModuleCard]
    let destinyStatus: SoloDestinyStatus
    let relationshipSpotlight: SoloRelationshipSpotlight?
}
