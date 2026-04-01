import SwiftUI

// MARK: - Shell Shatter View

struct OracleShellShatterView: View {
    let shatterProgress: CGFloat
    let pulsePhase: CGFloat
    let shellFrame: CGRect
    var onShellTap: () -> Void

    private var isShattered: Bool { shatterProgress > 0.01 }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                intactShell

                shardExplosion

                OracleShockwaveRing(progress: min(shatterProgress / 0.4, 1.0))
                    .position(x: shellFrame.midX, y: shellFrame.midY)

                OracleShockwaveRing(progress: min(max(shatterProgress - 0.06, 0) / 0.35, 1.0))
                    .scaleEffect(0.82)
                    .opacity(0.65)
                    .position(x: shellFrame.midX, y: shellFrame.midY)

                OracleLightningCracks(pulsePhase: pulsePhase, shatterProgress: shatterProgress)
                    .frame(width: shellFrame.width * 0.86, height: shellFrame.height * 0.84)
                    .position(x: shellFrame.midX, y: shellFrame.midY)
                    .opacity(max(0.0, 1.0 - shatterProgress * 2.8))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onShellTap() }
        .allowsHitTesting(!isShattered)
        .opacity(shatterProgress > 0.85 ? max(0, 1.0 - (shatterProgress - 0.85) * 6.0) : 1.0)
    }

    // MARK: - Intact Shell

    private var intactShell: some View {
        shellImage
            .frame(width: shellFrame.width, height: shellFrame.height)
            .clipped()
            .position(x: shellFrame.midX, y: shellFrame.midY)
            .opacity(max(0.0, 1.0 - shatterProgress * 5.0))
            .scaleEffect(1.0 - min(shatterProgress, 0.2) * 0.15)
    }

    // MARK: - Shard Explosion

    private var shardExplosion: some View {
        ForEach(shards) { shard in
            let rawBurst = (shatterProgress - shard.staggerDelay) / max(0.001, 0.42 - shard.staggerDelay * 0.4)
            let burst = min(max(rawBurst, 0), 1)
            let curve = sin(Double(burst) * .pi) * shard.curvature
            shardView(for: shard, burst: burst, curve: CGFloat(curve))
        }
    }

    private var shellImage: some View {
        SoloBundledArtworkImage(resourceName: "tianjilu_oracle_shell_closed", contentMode: .fill)
    }

    private func shardOpacity(burst: CGFloat, delay: CGFloat) -> CGFloat {
        let appear = min(max((shatterProgress - delay) * 12.0, 0.0), 1.0)
        let fade = max(0.0, 1.0 - burst * 1.1)
        return appear * fade
    }

    @ViewBuilder
    private func shardView(for shard: OracleShellShardSpec, burst: CGFloat, curve: CGFloat) -> some View {
        let shardMask = OracleShellShardMask(points: shard.points)
            .frame(width: shellFrame.width, height: shellFrame.height)
        let shardOutline = OracleShellShardMask(points: shard.points)
            .stroke(SoloTheme.gold.opacity(max(0, 0.7 - Double(burst))), lineWidth: 1.6)
            .frame(width: shellFrame.width, height: shellFrame.height)
            .blur(radius: 1.0)
        let xOffset = shard.travel.width * burst + curve * 16
        let yOffset = shard.travel.height * burst + curve * 12
        let glowOpacity = max(0, 0.22 - Double(burst) * 0.3)

        shellImage
            .frame(width: shellFrame.width, height: shellFrame.height)
            .clipped()
            .mask(shardMask)
            .overlay(shardOutline)
            .position(x: shellFrame.midX, y: shellFrame.midY)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(shard.rotation * Double(burst)))
            .opacity(shardOpacity(burst: burst, delay: shard.staggerDelay))
            .shadow(color: SoloTheme.gold.opacity(glowOpacity), radius: 8, y: 5)
    }

    // MARK: - Shard Definitions (9 shards for full-bleed coverage)

    private var shards: [OracleShellShardSpec] {
        [
            .init(id: 0,
                  points: [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.36, y: 0.0),
                           CGPoint(x: 0.30, y: 0.28), CGPoint(x: 0.0, y: 0.22)],
                  travel: CGSize(width: -252, height: -196), rotation: -42,
                  staggerDelay: 0.02, curvature: 14),
            .init(id: 1,
                  points: [CGPoint(x: 0.36, y: 0.0), CGPoint(x: 0.68, y: 0.0),
                           CGPoint(x: 0.60, y: 0.30), CGPoint(x: 0.30, y: 0.28)],
                  travel: CGSize(width: 20, height: -220), rotation: 12,
                  staggerDelay: 0.01, curvature: -10),
            .init(id: 2,
                  points: [CGPoint(x: 0.68, y: 0.0), CGPoint(x: 1.0, y: 0.0),
                           CGPoint(x: 1.0, y: 0.26), CGPoint(x: 0.60, y: 0.30)],
                  travel: CGSize(width: 274, height: -207), rotation: 46,
                  staggerDelay: 0.03, curvature: -12),
            .init(id: 3,
                  points: [CGPoint(x: 0.0, y: 0.22), CGPoint(x: 0.30, y: 0.28),
                           CGPoint(x: 0.34, y: 0.58), CGPoint(x: 0.0, y: 0.55)],
                  travel: CGSize(width: -294, height: -30), rotation: -58,
                  staggerDelay: 0.06, curvature: 18),
            .init(id: 4,
                  points: [CGPoint(x: 0.30, y: 0.28), CGPoint(x: 0.60, y: 0.30),
                           CGPoint(x: 0.64, y: 0.56), CGPoint(x: 0.50, y: 0.68),
                           CGPoint(x: 0.34, y: 0.58)],
                  travel: CGSize(width: 0, height: 280), rotation: 16,
                  staggerDelay: 0.0, curvature: -8),
            .init(id: 5,
                  points: [CGPoint(x: 0.60, y: 0.30), CGPoint(x: 1.0, y: 0.26),
                           CGPoint(x: 1.0, y: 0.56), CGPoint(x: 0.64, y: 0.56)],
                  travel: CGSize(width: 310, height: 17), rotation: 62,
                  staggerDelay: 0.04, curvature: 16),
            .init(id: 6,
                  points: [CGPoint(x: 0.0, y: 0.55), CGPoint(x: 0.34, y: 0.58),
                           CGPoint(x: 0.38, y: 0.88), CGPoint(x: 0.0, y: 1.0)],
                  travel: CGSize(width: -269, height: 314), rotation: -32,
                  staggerDelay: 0.08, curvature: -20),
            .init(id: 7,
                  points: [CGPoint(x: 0.34, y: 0.58), CGPoint(x: 0.50, y: 0.68),
                           CGPoint(x: 0.64, y: 0.56), CGPoint(x: 0.66, y: 0.86),
                           CGPoint(x: 0.38, y: 0.88)],
                  travel: CGSize(width: 10, height: 322), rotation: -14,
                  staggerDelay: 0.05, curvature: 14),
            .init(id: 8,
                  points: [CGPoint(x: 0.64, y: 0.56), CGPoint(x: 1.0, y: 0.56),
                           CGPoint(x: 1.0, y: 1.0), CGPoint(x: 0.66, y: 0.86)],
                  travel: CGSize(width: 291, height: 322), rotation: 32,
                  staggerDelay: 0.07, curvature: 22),
        ]
    }
}

// MARK: - Shockwave Ring

private struct OracleShockwaveRing: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            SoloTheme.gold.opacity(0.9),
                            Color.white.opacity(0.7),
                            SoloTheme.gold.opacity(0.8),
                            Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.6),
                            SoloTheme.gold.opacity(0.9),
                        ],
                        center: .center
                    ),
                    lineWidth: max(0.5, 6 * (1 - progress))
                )
                .frame(width: 20 + 500 * progress, height: 20 + 500 * progress)

            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: max(0.3, 2 * (1 - progress)))
                .frame(width: 30 + 520 * progress, height: 30 + 520 * progress)
                .blur(radius: 2)
        }
        .opacity(Double(max(0.0, 1.0 - progress * 1.6)))
        .blur(radius: progress * 3)
    }
}

// MARK: - Lightning Cracks

private struct OracleLightningCracks: View {
    let pulsePhase: CGFloat
    let shatterProgress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                crackPath(in: geo.size)
                    .stroke(
                        Color(red: 0.28, green: 0.18, blue: 0.06).opacity(0.76),
                        lineWidth: 7
                    )

                crackPath(in: geo.size)
                    .trim(from: 0.0, to: min(1.0, 0.18 + shatterProgress * 0.82))
                    .stroke(
                        LinearGradient(
                            colors: [
                                SoloTheme.gold.opacity(0.5 + Double(pulsePhase) * 0.25),
                                SoloTheme.crimson.opacity(0.92),
                                Color.white.opacity(0.6),
                                SoloTheme.gold.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 2.6 + shatterProgress * 3.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: SoloTheme.gold.opacity(0.4 + Double(pulsePhase) * 0.22), radius: 16)
                    .shadow(color: Color.white.opacity(0.15), radius: 4)
            }
        }
    }

    private func crackPath(in size: CGSize) -> Path {
        Path { path in
            let w = size.width
            let h = size.height

            path.move(to: CGPoint(x: w * 0.48, y: h * 0.14))
            path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.28))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.36))
            path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.46))
            path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.58))
            path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.72))
            path.addLine(to: CGPoint(x: w * 0.24, y: h * 0.82))

            path.move(to: CGPoint(x: w * 0.45, y: h * 0.28))
            path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.24))
            path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.16))

            path.move(to: CGPoint(x: w * 0.42, y: h * 0.46))
            path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.66, y: h * 0.44))
            path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.56))
            path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.68))

            path.move(to: CGPoint(x: w * 0.54, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.68))
            path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.84))

            path.move(to: CGPoint(x: w * 0.38, y: h * 0.36))
            path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.40))
            path.addLine(to: CGPoint(x: w * 0.14, y: h * 0.48))

            path.move(to: CGPoint(x: w * 0.66, y: h * 0.44))
            path.addLine(to: CGPoint(x: w * 0.80, y: h * 0.32))

            path.move(to: CGPoint(x: w * 0.36, y: h * 0.58))
            path.addLine(to: CGPoint(x: w * 0.26, y: h * 0.56))
            path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.64))

            path.move(to: CGPoint(x: w * 0.76, y: h * 0.56))
            path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.52))
        }
    }
}

// MARK: - Private Types

private struct OracleShellShardSpec: Identifiable {
    let id: Int
    let points: [CGPoint]
    let travel: CGSize
    let rotation: Double
    let staggerDelay: CGFloat
    let curvature: Double
}

struct OracleShellShardMask: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: rect.width * first.x, y: rect.height * first.y))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: rect.width * point.x, y: rect.height * point.y))
            }
            path.closeSubpath()
        }
    }
}
