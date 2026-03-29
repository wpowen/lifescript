import Foundation

struct SoloRouteMapHubSnapshot: Sendable, Equatable {
    let currentObjective: String
    let stageLine: String
    let pressureLine: String
    let destinySummary: String
    let destinyStatus: SoloDestinyStatus
    let destinyCard: SoloRouteMapHubCard
    let heartsCard: SoloRouteMapHubCard
    let darklineCard: SoloRouteMapHubCard
}

struct SoloRouteMapHubCard: Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let statusLine: String
    let badge: String
    let callToAction: String
}

struct SoloDestinyAtlasSnapshot: Sendable, Equatable {
    let stageNodes: [SoloDestinyStageNode]
    let currentStageTitle: String
    let omenLine: String
    let pressureLine: String
    let progressLine: String
}

struct SoloDestinyStageNode: Sendable, Equatable, Identifiable {
    enum Visibility: Sendable, Equatable {
        case passed
        case current
        case veiled
    }

    let id: String
    let title: String
    let summary: String
    let visibility: Visibility
    let completedChapterCount: Int
    let totalChapterCount: Int
}

struct SoloHumanHeartsSnapshot: Sendable, Equatable {
    let spotlightLine: String
    let pressureLine: String
    let rings: [SoloHeartRing]
}

struct SoloHeartRing: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let characterIDs: [String]
}

struct SoloDarklineBoardSnapshot: Sendable, Equatable {
    let discoveredSignals: [SoloDarklineSignal]
    let approachingSignals: [SoloDarklineSignal]
    let sealedCount: Int
    let totalSignalCount: Int
    let boardLine: String

    var revealRatio: Double {
        guard totalSignalCount > 0 else { return 0 }
        return Double(discoveredSignals.count) / Double(totalSignalCount)
    }

    var revealLabel: String {
        "\(discoveredSignals.count) / \(totalSignalCount)"
    }
}

struct SoloDarklineSignal: Sendable, Equatable, Identifiable {
    enum State: Sendable, Equatable {
        case discovered
        case approaching
    }

    let id: String
    let title: String
    let hint: String
    let sourceStageTitle: String
    let sourceChapterTitle: String
    let state: State
}
