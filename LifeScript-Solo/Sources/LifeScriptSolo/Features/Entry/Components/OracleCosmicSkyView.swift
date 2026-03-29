import SwiftUI

// MARK: - Cosmic Sky View

struct OracleCosmicSkyView: View {
    let nodes: [SoloOracleRelicNode]
    let revealProgress: CGFloat
    let cosmosPhase: CGFloat
    let pulsePhase: CGFloat
    let reduceMotion: Bool
    var onRelicTap: (SoloOracleRelicNode) -> Void
    var onBackgroundTap: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onBackgroundTap() }

            OracleCosmicBackground(
                reduceMotion: reduceMotion,
                cosmosPhase: cosmosPhase
            )
            .allowsHitTesting(false)

            OracleFloatingRelicField(
                nodes: nodes,
                reduceMotion: reduceMotion,
                pulsePhase: pulsePhase,
                onRelicTap: onRelicTap
            )
        }
        .opacity(cosmicOpacity)
    }

    private var cosmicOpacity: Double {
        min(1.0, max(0.0, Double(revealProgress - 0.15) / 0.5))
    }
}

// MARK: - Cosmic Background

private struct OracleCosmicBackground: View {
    let reduceMotion: Bool
    let cosmosPhase: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                    Color(red: 0.05, green: 0.03, blue: 0.08),
                    Color(red: 0.02, green: 0.04, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            nebulaLayers

            starCanvas
        }
    }

    // MARK: Nebulae

    private var nebulaLayers: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [SoloTheme.gold.opacity(0.10), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.38
                        )
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.height * 0.4)
                    .rotationEffect(.degrees(-8 + Double(cosmosPhase) * 5))
                    .blur(radius: 32)
                    .offset(
                        x: -geo.size.width * 0.12 + CGFloat(cosmosPhase) * 14,
                        y: -geo.size.height * 0.18 + CGFloat(cosmosPhase) * 8
                    )

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [SoloTheme.crimson.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: geo.size.width * 0.34
                        )
                    )
                    .frame(width: geo.size.width * 0.55, height: geo.size.height * 0.35)
                    .rotationEffect(.degrees(14 - Double(cosmosPhase) * 6))
                    .blur(radius: 36)
                    .offset(
                        x: geo.size.width * 0.18 - CGFloat(cosmosPhase) * 10,
                        y: geo.size.height * 0.16 - CGFloat(cosmosPhase) * 6
                    )

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [SoloTheme.jade.opacity(0.07), Color.clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: geo.size.width * 0.30
                        )
                    )
                    .frame(width: geo.size.width * 0.50, height: geo.size.height * 0.30)
                    .rotationEffect(.degrees(-6 + Double(cosmosPhase) * 4))
                    .blur(radius: 28)
                    .offset(
                        x: CGFloat(cosmosPhase) * 8,
                        y: geo.size.height * 0.24 + CGFloat(cosmosPhase) * 10
                    )
            }
        }
    }

    // MARK: Stars Canvas

    @ViewBuilder
    private var starCanvas: some View {
        if reduceMotion {
            Canvas { context, size in
                drawStars(context: &context, size: size, time: 0)
            }
        } else {
            TimelineView(.animation(minimumInterval: 0.10)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    drawStars(context: &context, size: size, time: time)
                    drawShootingStar(context: &context, size: size, time: time)
                }
            }
        }
    }

    private func drawStars(context: inout GraphicsContext, size: CGSize, time: Double) {
        for star in Self.stars {
            let twinkle = sin(time * star.twinkleFreq + star.twinklePhase)
            let opacity = star.baseOpacity * (0.55 + 0.45 * twinkle)
            let color = Color(
                red: Double(star.tintR),
                green: Double(star.tintG),
                blue: Double(star.tintB)
            ).opacity(opacity)

            let x = size.width * star.x
            let y = size.height * star.y
            let r = star.radius * CGFloat(0.8 + 0.2 * twinkle)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)

            context.fill(Circle().path(in: rect), with: .color(color))

            if star.radius > 2.5 {
                let glowRect = rect.insetBy(dx: -2, dy: -2)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.2))
                )
            }
        }
    }

    private func drawShootingStar(context: inout GraphicsContext, size: CGSize, time: Double) {
        let period = 10.0
        let phase = time.truncatingRemainder(dividingBy: period)
        let streakDuration = 1.0
        guard phase < streakDuration else { return }

        let progress = phase / streakDuration
        let startX = size.width * 0.12
        let startY = size.height * 0.06
        let endX = size.width * 0.82
        let endY = size.height * 0.42

        let headX = startX + (endX - startX) * progress
        let headY = startY + (endY - startY) * progress
        let tailFactor = min(progress, 1 - progress) * 2
        let tailLen = tailFactor * 80
        let angle = atan2(Double(endY - startY), Double(endX - startX))
        let cosA = CGFloat(cos(angle))
        let sinA = CGFloat(sin(angle))
        let tailX = headX - cosA * tailLen
        let tailY = headY - sinA * tailLen

        var trail = Path()
        trail.move(to: CGPoint(x: tailX, y: tailY))
        trail.addLine(to: CGPoint(x: headX, y: headY))

        context.stroke(
            trail,
            with: .linearGradient(
                Gradient(colors: [.clear, .white.opacity(0.7)]),
                startPoint: CGPoint(x: tailX, y: tailY),
                endPoint: CGPoint(x: headX, y: headY)
            ),
            lineWidth: 1.5
        )

        let headRect = CGRect(x: headX - 2.5, y: headY - 2.5, width: 5, height: 5)
        context.fill(Circle().path(in: headRect), with: .color(.white.opacity(0.85)))
    }

    // MARK: Star Data (procedural, computed once)

    private static func fract(_ x: Double) -> Double { x - floor(x) }

    private static let stars: [CosmicStar] = {
        (0..<65).map { i in
            let seed = Double(i)
            let x = fract(sin(seed * 127.1 + 311.7) * 43758.5453)
            let y = fract(sin(seed * 269.5 + 183.3) * 43758.5453)
            let radius = 1.0 + fract(sin(seed * 419.2 + 371.9) * 43758.5453) * 2.8
            let freq = 0.6 + fract(sin(seed * 731.3 + 541.1) * 43758.5453) * 2.4
            let phase = fract(sin(seed * 167.4 + 892.3) * 43758.5453) * .pi * 2
            let brightness = 0.35 + fract(sin(seed * 531.7 + 241.8) * 43758.5453) * 0.65
            let tintPick = Int(seed) % 3
            let r: CGFloat = tintPick == 0 ? 1.0 : (tintPick == 1 ? 0.85 : 0.7)
            let g: CGFloat = tintPick == 0 ? 0.88 : (tintPick == 1 ? 0.75 : 0.9)
            let b: CGFloat = tintPick == 0 ? 0.65 : (tintPick == 1 ? 0.72 : 0.95)
            return CosmicStar(
                x: CGFloat(x), y: CGFloat(y),
                radius: CGFloat(radius),
                twinkleFreq: freq, twinklePhase: phase,
                baseOpacity: brightness,
                tintR: r, tintG: g, tintB: b
            )
        }
    }()
}

private struct CosmicStar {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let twinkleFreq: Double
    let twinklePhase: Double
    let baseOpacity: Double
    let tintR: CGFloat
    let tintG: CGFloat
    let tintB: CGFloat
}

// MARK: - Floating Relic Field

private struct OracleFloatingRelicField: View {
    let nodes: [SoloOracleRelicNode]
    let reduceMotion: Bool
    let pulsePhase: CGFloat
    var onRelicTap: (SoloOracleRelicNode) -> Void

    var body: some View {
        if reduceMotion {
            staticRelicLayout
        } else {
            TimelineView(.animation(minimumInterval: 0.10)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    ForEach(nodes) { node in
                        OracleFloatingRelic(
                            node: node,
                            time: time,
                            containerSize: geo.size,
                            pulsePhase: pulsePhase
                        )
                        .onTapGesture { onRelicTap(node) }
                    }
                }
            }
        }
    }

    private var staticRelicLayout: some View {
        GeometryReader { geo in
            ForEach(nodes) { node in
                OracleFloatingRelic(
                    node: node,
                    time: 0,
                    containerSize: geo.size,
                    pulsePhase: pulsePhase
                )
                .onTapGesture { onRelicTap(node) }
            }
        }
    }
}

// MARK: - Individual Floating Relic

private struct OracleFloatingRelic: View {
    let node: SoloOracleRelicNode
    let time: Double
    let containerSize: CGSize
    let pulsePhase: CGFloat

    var body: some View {
        let drift = computeDrift()
        let posX = containerSize.width * node.position.x + drift.x
        let posY = containerSize.height * node.position.y + drift.y
        let selfRotation = time * (2.0 + node.phaseOffset * 1.5)
        let breathScale = 1.0 + sin(time * 1.2 + node.phaseOffset * 3) * 0.04

        return relicContent
            .scaleEffect(node.depth.scale * breathScale)
            .rotationEffect(.degrees(selfRotation))
            .blur(radius: node.depth.blur)
            .position(x: posX, y: posY)
            .zIndex(node.depth.zIndex)
    }

    private var relicContent: some View {
        let d = node.diameter
        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: d, height: d)

            Circle()
                .fill(node.tint.opacity(0.12 + Double(pulsePhase) * 0.08))
                .frame(width: d + node.depth.glow, height: d + node.depth.glow)
                .blur(radius: node.depth.glow * 0.8)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            node.tint.opacity(0.8),
                            SoloTheme.gold.opacity(0.5),
                            node.tint.opacity(0.8),
                        ],
                        center: .center
                    ),
                    lineWidth: 1.6
                )
                .frame(width: d + 4, height: d + 4)

            SoloBundledArtworkImage(resourceName: node.asset.resourceName, contentMode: .fill)
                .frame(width: d - 10, height: d - 10)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )

            Circle()
                .stroke(node.tint.opacity(0.25 + Double(pulsePhase) * 0.15), lineWidth: 0.6)
                .frame(width: d + 14, height: d + 14)
                .blur(radius: 2)

            Text(node.title)
                .font(.system(size: 10, weight: .medium, design: .serif))
                .foregroundStyle(node.tint.opacity(0.7))
                .offset(y: d / 2 + 10)
        }
        .shadow(color: node.tint.opacity(0.15), radius: node.depth.glow * 0.6, y: 6)
        .contentShape(Circle().size(width: d + 20, height: d + 20))
    }

    /// 多频率 sin/cos 叠加产生不规则漂移轨迹
    private func computeDrift() -> CGPoint {
        let p = node.phaseOffset
        let amp = node.depth.drift

        let x1 = sin(time * (0.12 + p * 0.04) + p * 2.1) * amp.width
        let y1 = cos(time * (0.15 + p * 0.03) + p * 1.7) * amp.height
        let x2 = cos(time * (0.28 + p * 0.06) + p * 3.4) * amp.width * 0.4
        let y2 = sin(time * (0.22 + p * 0.05) + p * 4.2) * amp.height * 0.35

        return CGPoint(x: x1 + x2, y: y1 + y2)
    }
}
