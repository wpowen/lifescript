import SwiftUI

// MARK: - Shared Models

enum SoloOracleRelicDepth: Double, CaseIterable {
    case far = 0
    case mid = 1
    case near = 2

    var scale: CGFloat {
        switch self {
        case .far: return 0.78
        case .mid: return 1.0
        case .near: return 1.24
        }
    }

    var blur: CGFloat {
        switch self {
        case .far: return 1.1
        case .mid: return 0.2
        case .near: return 0
        }
    }

    var glow: CGFloat {
        switch self {
        case .far: return 10
        case .mid: return 14
        case .near: return 20
        }
    }

    var drift: CGSize {
        switch self {
        case .far: return CGSize(width: 10, height: 8)
        case .mid: return CGSize(width: 18, height: 12)
        case .near: return CGSize(width: 24, height: 16)
        }
    }

    var opacity: Double {
        switch self {
        case .far: return 0.62
        case .mid: return 0.84
        case .near: return 1.0
        }
    }

    var zIndex: Double { rawValue }
}

struct SoloOracleRelicNode: Identifiable {
    let id: String
    let title: String
    let asset: SoloArtworkAsset
    let tint: Color
    let position: CGPoint
    let diameter: CGFloat
    let depth: SoloOracleRelicDepth
    let phaseOffset: Double
}

// MARK: - Main Module

struct SoloEntryOracleShellModule: View {
    let snapshot: SoloEntrySnapshot

    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @State private var revealProgress: CGFloat = 0.0
    @State private var pulsePhase: CGFloat = 0.0
    @State private var cosmosPhase: CGFloat = 0.0
    @State private var acquiredArtifact: SoloOracleRelicNode?
    @State private var showAcquisition = false

    var body: some View {
        VStack(spacing: 0) {
            shellStage
        }
        .padding(14)
        .soloPanel(.hero, prominence: 0.18)
        .onAppear { startAmbientAnimations() }
    }

    // MARK: - Stage

    private var shellStage: some View {
        GeometryReader { geo in
            let stageSize = geo.size
            let shellWidth = min(stageSize.width * 0.84, 480)
            let shellHeight = shellWidth * 0.79
            let shellFrame = CGRect(
                x: (stageSize.width - shellWidth) / 2,
                y: (stageSize.height - shellHeight) / 2,
                width: shellWidth,
                height: shellHeight
            )

            ZStack {
                stageBackground

                OracleCosmicSkyView(
                    nodes: relicNodes,
                    revealProgress: revealProgress,
                    cosmosPhase: cosmosPhase,
                    pulsePhase: pulsePhase,
                    reduceMotion: reduceMotion,
                    onRelicTap: { node in handleArtifactTap(node) },
                    onBackgroundTap: { toggleShell() }
                )
                .allowsHitTesting(revealProgress > 0.5 && !showAcquisition)

                OracleShellShatterView(
                    revealProgress: revealProgress,
                    pulsePhase: pulsePhase,
                    shellFrame: shellFrame,
                    onShellTap: { toggleShell() }
                )

                stageOverlay

                if showAcquisition, let artifact = acquiredArtifact {
                    OracleArtifactAcquisitionOverlay(
                        artifact: artifact,
                        reduceMotion: reduceMotion,
                        onDismiss: { dismissAcquisition() }
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(stageBorder)
        }
        .frame(height: 456)
    }

    // MARK: - Background & Overlay

    private var stageBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.03, blue: 0.03),
                        Color(red: 0.09, green: 0.06, blue: 0.05),
                        Color(red: 0.02, green: 0.03, blue: 0.06),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var stageOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            SoloTheme.gold.opacity(0.10 + Double(revealProgress) * 0.12),
                            SoloTheme.crimson.opacity(0.10 + Double(pulsePhase) * 0.12),
                            SoloTheme.jade.opacity(0.08 + Double(cosmosPhase) * 0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 220, style: .continuous)
                .fill(SoloTheme.gold.opacity(0.05 + Double(revealProgress) * 0.08))
                .frame(width: 280, height: 88)
                .blur(radius: 34)
                .offset(y: 140)
        }
        .allowsHitTesting(false)
    }

    private var stageBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        SoloTheme.gold.opacity(0.30 + Double(pulsePhase) * 0.12),
                        Color.white.opacity(0.06),
                        SoloTheme.jade.opacity(0.14 + Double(revealProgress) * 0.10),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            pulsePhase = 1.0
        }
        withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
            cosmosPhase = 1.0
        }
    }

    // MARK: - Interaction

    private func toggleShell() {
        guard !showAcquisition else { return }
        let target: CGFloat = revealProgress > 0.6 ? 0.0 : 1.0
        let animation: Animation = reduceMotion
            ? .easeInOut(duration: 0.18)
            : .interactiveSpring(response: 0.84, dampingFraction: 0.82, blendDuration: 0.18)
        withAnimation(animation) {
            revealProgress = target
        }
    }

    private func handleArtifactTap(_ node: SoloOracleRelicNode) {
        guard !showAcquisition else { return }
        acquiredArtifact = node
        withAnimation(.easeOut(duration: 0.2)) {
            showAcquisition = true
        }
    }

    private func dismissAcquisition() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showAcquisition = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            acquiredArtifact = nil
        }
    }

    // MARK: - Relic Data

    private var relicNodes: [SoloOracleRelicNode] {
        let vol = TianjiluArtworkCatalog.volume(
            for: max(snapshot.progress.currentChapterNumber, 1)
        )

        return [
            SoloOracleRelicNode(
                id: "secret-realm", title: "秘境",
                asset: vol.banner, tint: SoloTheme.jade,
                position: CGPoint(x: 0.50, y: 0.26), diameter: 106,
                depth: .far, phaseOffset: 0.15
            ),
            SoloOracleRelicNode(
                id: "dragon-vein", title: "龙脉",
                asset: SoloArtworkAsset(
                    resourceName: "tianjilu_artifact_dragon_vein_map",
                    title: "龙脉图", subtitle: "", caption: nil
                ),
                tint: SoloTheme.gold,
                position: CGPoint(x: 0.20, y: 0.30), diameter: 72,
                depth: .far, phaseOffset: 0.45
            ),
            SoloOracleRelicNode(
                id: "battleframe", title: "战迹",
                asset: vol.keyframe, tint: SoloTheme.crimson,
                position: CGPoint(x: 0.82, y: 0.34), diameter: 68,
                depth: .far, phaseOffset: 0.72
            ),
            SoloOracleRelicNode(
                id: "ancient-cover", title: "古卷",
                asset: vol.cover, tint: SoloTheme.gold,
                position: CGPoint(x: 0.12, y: 0.56), diameter: 68,
                depth: .mid, phaseOffset: 0.32
            ),
            SoloOracleRelicNode(
                id: "tianjilu-page", title: "天机录",
                asset: TianjiluArtworkCatalog.welcomeArtifact, tint: SoloTheme.gold,
                position: CGPoint(x: 0.33, y: 0.49), diameter: 86,
                depth: .mid, phaseOffset: 0.58
            ),
            SoloOracleRelicNode(
                id: "demon-weapon", title: "魔兵",
                asset: SoloArtworkAsset(
                    resourceName: "tianjilu_artifact_demon_weapon",
                    title: "魔兵断锋", subtitle: "", caption: nil
                ),
                tint: SoloTheme.crimson,
                position: CGPoint(x: 0.78, y: 0.52), diameter: 84,
                depth: .mid, phaseOffset: 0.84
            ),
            SoloOracleRelicNode(
                id: "beast-seal", title: "兽魂",
                asset: SoloArtworkAsset(
                    resourceName: "tianjilu_artifact_beast_soul_seal",
                    title: "兽魂封印", subtitle: "", caption: nil
                ),
                tint: SoloTheme.crimson,
                position: CGPoint(x: 0.56, y: 0.58), diameter: 92,
                depth: .mid, phaseOffset: 1.12
            ),
            SoloOracleRelicNode(
                id: "destiny-board", title: "命盘",
                asset: TianjiluArtworkCatalog.darklineArtifact, tint: SoloTheme.jade,
                position: CGPoint(x: 0.22, y: 0.76), diameter: 104,
                depth: .near, phaseOffset: 1.34
            ),
            SoloOracleRelicNode(
                id: "spiritual-sea", title: "灵海",
                asset: SoloArtworkAsset(
                    resourceName: "tianjilu_spiritual_sea",
                    title: "灵海", subtitle: "", caption: nil
                ),
                tint: SoloTheme.jade,
                position: CGPoint(x: 0.52, y: 0.82), diameter: 96,
                depth: .near, phaseOffset: 1.64
            ),
            SoloOracleRelicNode(
                id: "imperial-vault", title: "帝城",
                asset: SoloArtworkAsset(
                    resourceName: "tianjilu_imperial_capital",
                    title: "帝城", subtitle: "", caption: nil
                ),
                tint: SoloTheme.gold,
                position: CGPoint(x: 0.82, y: 0.78), diameter: 90,
                depth: .near, phaseOffset: 1.88
            ),
        ]
    }
}
