import SwiftUI

// MARK: - Acquisition Overlay

struct OracleArtifactAcquisitionOverlay: View {
    let artifact: SoloOracleRelicNode
    let reduceMotion: Bool
    var onDismiss: () -> Void

    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            dimBackground

            if phase >= 1 {
                OracleAcquisitionBurst(
                    tint: artifact.tint,
                    phase: phase,
                    reduceMotion: reduceMotion
                )
                .transition(.opacity)
            }

            if phase >= 2 {
                artifactReveal
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }

            if phase >= 3 {
                OracleArtifactDetailCard(
                    artifact: artifact,
                    onDismiss: onDismiss
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { startAnimationSequence() }
        .onTapGesture { handleTap() }
    }

    // MARK: - Background Dim

    private var dimBackground: some View {
        Color.black
            .opacity(phase >= 1 ? 0.6 : 0.0)
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.3), value: phase)
    }

    // MARK: - Artifact Reveal

    private var artifactReveal: some View {
        let d: CGFloat = 120
        return ZStack {
            Circle()
                .fill(artifact.tint.opacity(0.15))
                .frame(width: d + 40, height: d + 40)
                .blur(radius: 20)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            SoloTheme.gold.opacity(0.9),
                            artifact.tint.opacity(0.7),
                            SoloTheme.gold.opacity(0.9),
                        ],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: d + 10, height: d + 10)
                .shadow(color: SoloTheme.gold.opacity(0.4), radius: 12)

            SoloBundledArtworkImage(
                resourceName: artifact.asset.resourceName,
                contentMode: .fill
            )
            .frame(width: d - 8, height: d - 8)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .offset(y: -80)
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        let baseDuration: Double = reduceMotion ? 0.05 : 0.3

        withAnimation(.easeOut(duration: baseDuration)) {
            phase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + baseDuration) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                phase = 2
            }
        }

        let cardDelay = reduceMotion ? baseDuration + 0.1 : baseDuration + 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + cardDelay) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                phase = 3
            }
        }
    }

    private func handleTap() {
        if phase >= 3 {
            onDismiss()
        }
    }
}

// MARK: - Acquisition Burst

private struct OracleAcquisitionBurst: View {
    let tint: Color
    let phase: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            burstRings

            if !reduceMotion {
                burstParticles
            }
        }
    }

    private var burstRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let delay = Double(i) * 0.12
                let isActive = phase >= 1
                let ringScale: CGFloat = isActive ? (1.8 + CGFloat(i) * 0.5) : 0.2

                Circle()
                    .stroke(
                        tint.opacity(isActive ? max(0, 0.5 - Double(i) * 0.15) : 0),
                        lineWidth: max(0.5, 3 - CGFloat(i))
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(ringScale)
                    .blur(radius: CGFloat(i) * 2)
                    .animation(
                        reduceMotion
                            ? .linear(duration: 0.05)
                            : .easeOut(duration: 0.6).delay(delay),
                        value: phase
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SoloTheme.gold.opacity(phase >= 1 ? 0.8 : 0),
                            tint.opacity(phase >= 1 ? 0.3 : 0),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: phase >= 2 ? 180 : 60
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 20)
                .opacity(phase >= 2 ? 0.15 : 0.6)
                .animation(
                    reduceMotion ? .linear(duration: 0.05) : .easeInOut(duration: 0.5),
                    value: phase
                )
        }
        .offset(y: -80)
    }

    private var burstParticles: some View {
        ZStack {
            ForEach(Self.sparks, id: \.id) { spark in
                let isActive = phase >= 1
                let angle = spark.angle * .pi / 180
                let distance: CGFloat = isActive ? spark.distance : 0

                Capsule(style: .continuous)
                    .fill(spark.tint.opacity(isActive ? spark.opacity : 0))
                    .frame(width: spark.length, height: spark.width)
                    .rotationEffect(.degrees(spark.angle))
                    .offset(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance - 80
                    )
                    .scaleEffect(isActive ? (phase >= 2 ? 0.3 : 1.0) : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(spark.delay),
                        value: phase
                    )
            }
        }
    }

    private static let sparks: [BurstSpark] = {
        let tints: [Color] = [SoloTheme.gold, SoloTheme.crimson, SoloTheme.gold,
                               SoloTheme.jade, SoloTheme.gold, SoloTheme.crimson]
        return (0..<18).map { i in
            let angle = Double(i) * 20.0 + Double.random(in: -8...8)
            let dist: CGFloat = CGFloat.random(in: 80...160)
            return BurstSpark(
                id: i,
                angle: angle,
                distance: dist,
                length: CGFloat.random(in: 14...28),
                width: CGFloat.random(in: 2...4),
                tint: tints[i % tints.count],
                opacity: Double.random(in: 0.5...0.85),
                delay: Double(i) * 0.02
            )
        }
    }()
}

private struct BurstSpark: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let length: CGFloat
    let width: CGFloat
    let tint: Color
    let opacity: Double
    let delay: Double
}

// MARK: - Detail Card

private struct OracleArtifactDetailCard: View {
    let artifact: SoloOracleRelicNode
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)

            Text("天机显现")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(SoloTheme.gold.opacity(0.7))
                .tracking(4)

            VStack(spacing: 8) {
                Text(artifact.asset.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.white)

                Text(artifact.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(artifact.tint.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(artifact.tint.opacity(0.12))
                            .overlay(
                                Capsule().stroke(artifact.tint.opacity(0.2), lineWidth: 0.6)
                            )
                    )
            }

            if let caption = artifact.asset.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            } else if !artifact.asset.subtitle.isEmpty {
                Text(artifact.asset.subtitle)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }

            Button(action: onDismiss) {
                Text("收下")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [SoloTheme.gold, SoloTheme.gold.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: SoloTheme.gold.opacity(0.25), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    SoloTheme.gold.opacity(0.3),
                                    Color.white.opacity(0.08),
                                    artifact.tint.opacity(0.15),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .offset(y: 60)
    }
}
