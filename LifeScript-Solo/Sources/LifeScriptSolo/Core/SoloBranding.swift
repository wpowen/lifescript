import Foundation

enum SoloPalettePreset: String, Sendable {
    case ashCrimson
    case emberGold
    case moonJade
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

struct SoloEntrySnapshot: Sendable {
    let branding: SoloBranding
    let progress: SoloProgressSummary
    let currentStageTitle: String
    let currentStageSummary: String
    let currentObjective: String
    let currentObjectiveSummary: String
    let recapSummary: String?
    let hiddenRouteHint: String?
    let visibleRouteTitles: [String]
    let currentIdentityValue: String
    let destinyStatusLine: String
    let hookLine: String
    let experienceStats: [SoloEntryExperienceStat]
}

struct SoloRouteMapSnapshot: Sendable {
    let currentChapterID: String?
    let currentStageID: String?
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
    let relationshipSpotlight: SoloRelationshipSpotlight?
}
