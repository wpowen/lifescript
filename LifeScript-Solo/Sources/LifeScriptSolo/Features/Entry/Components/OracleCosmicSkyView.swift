import SwiftUI

// MARK: - Cosmic Sky View

struct OracleCosmicSkyView: View {
    let nodes: [SoloOracleRelicNode]
    let shellShattered: Bool
    let cosmosPhase: CGFloat
    let pulsePhase: CGFloat
    let reduceMotion: Bool
    var onRelicTap: (SoloOracleRelicNode) -> Void

    var body: some View {
        ZStack {
            OracleCosmicBackground(
                reduceMotion: reduceMotion,
                cosmosPhase: cosmosPhase
            )
            .allowsHitTesting(false)

            OracleMeteorRelicField(
                nodes: nodes,
                reduceMotion: reduceMotion,
                pulsePhase: pulsePhase,
                onRelicTap: onRelicTap
            )
        }
        .opacity(shellShattered ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6), value: shellShattered)
    }
}

// MARK: - Cosmic Background

private struct OracleCosmicBackground: View {
    let reduceMotion: Bool
    let cosmosPhase: CGFloat

    var body: some View {
        ZStack {
            // Layered depth: base gradient + procedural nebula canvas + stars
            Color(red: 0.01, green: 0.01, blue: 0.04)

            nebulaCanvas

            starCanvas
        }
    }

    // MARK: - Procedural Nebula Canvas (all background atmosphere in one pass)

    @ViewBuilder
    private var nebulaCanvas: some View {
        if reduceMotion {
            Canvas { context, size in
                Self.drawNebulae(context: &context, size: size, phase: 0)
            }
        } else {
            TimelineView(.animation(minimumInterval: 0.06)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    Self.drawNebulae(context: &context, size: size, phase: time)
                }
            }
        }
    }

    /// Draws the entire xianxia sky atmosphere: layered nebula clouds, qi ribbons, and vortex
    private static func drawNebulae(context: inout GraphicsContext, size: CGSize, phase: Double) {
        let w = size.width
        let h = size.height

        // ── Layer 1: Deep-space base tint (subtle asymmetric gradient feel via radial blobs) ──
        for blob in nebulaBlobs {
            let drift = sin(phase * blob.driftSpeed + blob.driftPhase) * blob.driftAmp
            let cx = w * blob.cx + CGFloat(drift)
            let cy = h * blob.cy + CGFloat(cos(phase * blob.driftSpeed * 0.7 + blob.driftPhase) * blob.driftAmp * 0.6)
            let rx = w * blob.rx
            let ry = h * blob.ry
            let breathe = 0.85 + sin(phase * blob.breatheSpeed + blob.driftPhase * 2.0) * 0.15

            // Draw 3 concentric layers per blob for smooth falloff
            for layer in 0..<3 {
                let layerFrac = CGFloat(layer) / 3.0
                let scale = 0.35 + layerFrac * 0.65
                let alpha = blob.peakAlpha * (1.0 - layerFrac * 0.7) * breathe
                let rect = CGRect(
                    x: cx - rx * scale,
                    y: cy - ry * scale,
                    width: rx * scale * 2,
                    height: ry * scale * 2
                )
                context.fill(
                    Ellipse().path(in: rect),
                    with: .color(Color(red: blob.r, green: blob.g, blue: blob.b).opacity(alpha))
                )
            }
        }

        // ── Layer 2: Qi ribbons (light streaks as chains of soft ellipses) ──
        for ribbon in qiRibbons {
            let drift = sin(phase * ribbon.speed + ribbon.phase) * ribbon.amplitude
            let yCenter = h * ribbon.yNorm + CGFloat(drift)
            let angle = ribbon.angle + sin(phase * 0.3 + ribbon.phase) * 2.0
            let radians = angle * .pi / 180.0

            let halfLen = w * ribbon.lengthFrac * 0.5
            let cosA = CGFloat(cos(radians))
            let sinA = CGFloat(sin(radians))
            let xCenter = w * ribbon.xNorm

            let segments = 16
            for seg in 0..<segments {
                let t = (CGFloat(seg) / CGFloat(segments - 1)) * 2.0 - 1.0
                let envelope = 1.0 - t * t
                let px = xCenter + cosA * t * halfLen
                let py = yCenter + sinA * t * halfLen
                let dotR = ribbon.thickness * (0.6 + envelope * 0.8)
                let alpha = ribbon.opacity * Double(envelope)

                let rect = CGRect(x: px - dotR, y: py - dotR * 0.4, width: dotR * 2, height: dotR * 0.8)
                context.fill(
                    Ellipse().path(in: rect),
                    with: .color(Color(red: ribbon.r, green: ribbon.g, blue: ribbon.b).opacity(alpha))
                )
            }
        }

        // ── Layer 3: Central vortex glow (subtle radial light suggesting portal energy) ──
        let vortexPulse = 0.5 + sin(phase * 0.6) * 0.15
        let vortexCx = w * 0.50
        let vortexCy = h * 0.48
        for ring in 0..<5 {
            let frac = CGFloat(ring) / 5.0
            let radius = min(w, h) * (0.12 + frac * 0.28)
            let alpha = (0.06 - frac * 0.012) * vortexPulse
            let rect = CGRect(
                x: vortexCx - radius,
                y: vortexCy - radius,
                width: radius * 2,
                height: radius * 2
            )
            // Alternate warm/cool tints for depth
            let isWarm = ring % 2 == 0
            let color = isWarm
                ? Color(red: 0.6, green: 0.35, blue: 0.1).opacity(alpha)
                : Color(red: 0.15, green: 0.2, blue: 0.5).opacity(alpha * 0.8)
            context.fill(Ellipse().path(in: rect), with: .color(color))
        }
    }

    // MARK: Nebula Blob Data

    private struct NebulaBlob {
        let cx: CGFloat;  let cy: CGFloat    // center (normalized)
        let rx: CGFloat;  let ry: CGFloat    // radii (normalized)
        let r: Double;    let g: Double;     let b: Double
        let peakAlpha: Double
        let driftSpeed: Double; let driftPhase: Double; let driftAmp: Double
        let breatheSpeed: Double
    }

    private static let nebulaBlobs: [NebulaBlob] = [
        // Upper-left golden celestial qi
        NebulaBlob(cx: 0.28, cy: 0.22, rx: 0.40, ry: 0.30,
                   r: 0.85, g: 0.60, b: 0.15, peakAlpha: 0.12,
                   driftSpeed: 0.18, driftPhase: 0.0, driftAmp: 12.0, breatheSpeed: 0.4),
        // Right crimson demon qi
        NebulaBlob(cx: 0.75, cy: 0.35, rx: 0.32, ry: 0.28,
                   r: 0.65, g: 0.10, b: 0.12, peakAlpha: 0.10,
                   driftSpeed: 0.14, driftPhase: 1.8, driftAmp: 10.0, breatheSpeed: 0.35),
        // Center deep purple void
        NebulaBlob(cx: 0.45, cy: 0.50, rx: 0.35, ry: 0.32,
                   r: 0.25, g: 0.06, b: 0.45, peakAlpha: 0.11,
                   driftSpeed: 0.10, driftPhase: 3.2, driftAmp: 6.0, breatheSpeed: 0.30),
        // Lower-left jade essence
        NebulaBlob(cx: 0.22, cy: 0.68, rx: 0.30, ry: 0.24,
                   r: 0.08, g: 0.42, b: 0.32, peakAlpha: 0.09,
                   driftSpeed: 0.16, driftPhase: 2.4, driftAmp: 8.0, breatheSpeed: 0.38),
        // Upper-right teal dao aura
        NebulaBlob(cx: 0.70, cy: 0.18, rx: 0.26, ry: 0.22,
                   r: 0.08, g: 0.30, b: 0.48, peakAlpha: 0.08,
                   driftSpeed: 0.12, driftPhase: 4.6, driftAmp: 7.0, breatheSpeed: 0.32),
        // Bottom-right amber warmth
        NebulaBlob(cx: 0.78, cy: 0.75, rx: 0.28, ry: 0.20,
                   r: 0.70, g: 0.40, b: 0.08, peakAlpha: 0.07,
                   driftSpeed: 0.15, driftPhase: 5.1, driftAmp: 9.0, breatheSpeed: 0.28),
        // Central dark indigo depth (adds richness to background)
        NebulaBlob(cx: 0.50, cy: 0.42, rx: 0.50, ry: 0.45,
                   r: 0.04, g: 0.03, b: 0.15, peakAlpha: 0.18,
                   driftSpeed: 0.06, driftPhase: 0.5, driftAmp: 4.0, breatheSpeed: 0.20),
        // Lower center mystical purple haze
        NebulaBlob(cx: 0.45, cy: 0.80, rx: 0.34, ry: 0.18,
                   r: 0.35, g: 0.12, b: 0.50, peakAlpha: 0.06,
                   driftSpeed: 0.11, driftPhase: 1.2, driftAmp: 5.0, breatheSpeed: 0.25),
    ]

    // MARK: Qi Ribbon Data

    private struct QiRibbon {
        let xNorm: CGFloat; let yNorm: CGFloat
        let lengthFrac: CGFloat; let thickness: CGFloat
        let angle: Double
        let r: Double; let g: Double; let b: Double
        let opacity: Double
        let speed: Double; let phase: Double; let amplitude: Double
    }

    private static let qiRibbons: [QiRibbon] = [
        // Golden horizontal streak
        QiRibbon(xNorm: 0.50, yNorm: 0.36, lengthFrac: 1.1, thickness: 8,
                 angle: -3.0, r: 0.90, g: 0.70, b: 0.20, opacity: 0.06,
                 speed: 0.20, phase: 0.0, amplitude: 10.0),
        // Purple diagonal ribbon
        QiRibbon(xNorm: 0.45, yNorm: 0.60, lengthFrac: 0.9, thickness: 6,
                 angle: 8.0, r: 0.45, g: 0.15, b: 0.60, opacity: 0.05,
                 speed: 0.15, phase: 2.1, amplitude: 8.0),
        // Teal thin streak — upper
        QiRibbon(xNorm: 0.55, yNorm: 0.20, lengthFrac: 0.7, thickness: 4,
                 angle: -5.0, r: 0.10, g: 0.40, b: 0.50, opacity: 0.04,
                 speed: 0.18, phase: 3.8, amplitude: 6.0),
        // Faint crimson low ribbon
        QiRibbon(xNorm: 0.40, yNorm: 0.78, lengthFrac: 0.8, thickness: 5,
                 angle: 4.0, r: 0.70, g: 0.15, b: 0.10, opacity: 0.035,
                 speed: 0.12, phase: 5.3, amplitude: 7.0),
    ]

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
                    drawShootingStar(context: &context, size: size, time: time, period: 10.0,
                                    startNorm: (0.12, 0.06), endNorm: (0.82, 0.42))
                    drawShootingStar(context: &context, size: size, time: time, period: 7.0,
                                    startNorm: (0.88, 0.10), endNorm: (0.18, 0.55))
                    drawShootingStar(context: &context, size: size, time: time, period: 14.0,
                                    startNorm: (0.05, 0.50), endNorm: (0.75, 0.85))
                    drawSpiritParticles(context: &context, size: size, time: time)
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
                let glowRect = rect.insetBy(dx: -3, dy: -3)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.25))
                )
            }
        }
    }

    /// Floating golden qi particles that drift upward — xianxia spiritual energy
    private func drawSpiritParticles(context: inout GraphicsContext, size: CGSize, time: Double) {
        for particle in Self.spiritParticles {
            let cycle = Self.fract(time * particle.speed + particle.phase)
            // Float upward
            let x = size.width * particle.x + sin(time * particle.wobbleFreq + particle.phase) * 8
            let baseY = size.height * particle.y
            let y = baseY - cycle * size.height * 0.4
            guard y > 0, y < size.height else { continue }

            let fadeCurve = sin(Double(cycle) * .pi) // fade in and out
            let opacity = particle.brightness * fadeCurve

            let r = particle.radius * CGFloat(0.8 + fadeCurve * 0.4)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(
                Circle().path(in: rect),
                with: .color(Color(red: particle.tintR, green: particle.tintG, blue: particle.tintB).opacity(opacity))
            )
            // Soft glow
            let glowRect = rect.insetBy(dx: -r * 0.6, dy: -r * 0.6)
            context.fill(
                Circle().path(in: glowRect),
                with: .color(Color(red: particle.tintR, green: particle.tintG, blue: particle.tintB).opacity(opacity * 0.2))
            )
        }
    }

    private func drawShootingStar(
        context: inout GraphicsContext, size: CGSize, time: Double,
        period: Double, startNorm: (Double, Double), endNorm: (Double, Double)
    ) {
        let phase = time.truncatingRemainder(dividingBy: period)
        let streakDuration = 1.0
        guard phase < streakDuration else { return }

        let progress = phase / streakDuration
        let startX = size.width * startNorm.0
        let startY = size.height * startNorm.1
        let endX = size.width * endNorm.0
        let endY = size.height * endNorm.1

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
        (0..<120).map { i in
            let seed = Double(i)
            let x = fract(sin(seed * 127.1 + 311.7) * 43758.5453)
            let y = fract(sin(seed * 269.5 + 183.3) * 43758.5453)
            let radius = 1.0 + fract(sin(seed * 419.2 + 371.9) * 43758.5453) * 3.2
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

    private static let spiritParticles: [SpiritParticle] = {
        (0..<30).map { i in
            let seed = Double(i) + 500
            let x = fract(sin(seed * 173.1 + 411.7) * 43758.5453)
            let y = fract(sin(seed * 341.5 + 219.3) * 43758.5453)
            let radius = 1.2 + fract(sin(seed * 517.2 + 129.9) * 43758.5453) * 2.0
            let speed = 0.08 + fract(sin(seed * 613.3 + 341.1) * 43758.5453) * 0.12
            let phase = fract(sin(seed * 267.4 + 891.3) * 43758.5453)
            let brightness = 0.15 + fract(sin(seed * 431.7 + 141.8) * 43758.5453) * 0.25
            let wobbleFreq = 0.4 + fract(sin(seed * 711.3 + 181.7) * 43758.5453) * 0.8
            // Color: mix of gold, jade, purple
            let tintPick = Int(seed) % 3
            let r: Double = tintPick == 0 ? 1.0 : (tintPick == 1 ? 0.3 : 0.6)
            let g: Double = tintPick == 0 ? 0.75 : (tintPick == 1 ? 0.7 : 0.25)
            let b: Double = tintPick == 0 ? 0.2 : (tintPick == 1 ? 0.5 : 0.7)
            return SpiritParticle(
                x: CGFloat(x), y: CGFloat(y),
                radius: CGFloat(radius),
                speed: speed, phase: phase,
                brightness: brightness, wobbleFreq: wobbleFreq,
                tintR: r, tintG: g, tintB: b
            )
        }
    }()
}

private struct SpiritParticle {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let speed: Double
    let phase: Double
    let brightness: Double
    let wobbleFreq: Double
    let tintR: Double
    let tintG: Double
    let tintB: Double
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

// MARK: - Meteor Relic Field

private struct OracleMeteorRelicField: View {
    let nodes: [SoloOracleRelicNode]
    let reduceMotion: Bool
    let pulsePhase: CGFloat
    var onRelicTap: (SoloOracleRelicNode) -> Void

    var body: some View {
        if reduceMotion {
            staticRelicLayout
        } else {
            OracleMeteorAnimatedField(
                nodes: nodes,
                pulsePhase: pulsePhase,
                onRelicTap: onRelicTap
            )
        }
    }

    private var staticRelicLayout: some View {
        GeometryReader { geo in
            ForEach(nodes) { node in
                OracleStaticRelic(node: node, containerSize: geo.size, pulsePhase: pulsePhase)
                    .onTapGesture { onRelicTap(node) }
            }
        }
    }
}

// MARK: - Static Relic (reduceMotion fallback)

private struct OracleStaticRelic: View {
    let node: SoloOracleRelicNode
    let containerSize: CGSize
    let pulsePhase: CGFloat

    var body: some View {
        relicContent
            .position(
                x: containerSize.width * node.position.x,
                y: containerSize.height * node.position.y
            )
    }

    private var relicContent: some View {
        let d = node.diameter
        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: d, height: d)

            Circle()
                .fill(node.tint.opacity(0.12 + Double(pulsePhase) * 0.08))
                .frame(width: d + 20, height: d + 20)
                .blur(radius: 12)

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
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))

            Text(node.title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(node.tint.opacity(0.7))
                .offset(y: d / 2 + 12)
        }
        .contentShape(Circle().size(width: d + 40, height: d + 40))
    }
}

// MARK: - Animated Meteor Field

private struct OracleMeteorAnimatedField: View {
    let nodes: [SoloOracleRelicNode]
    let pulsePhase: CGFloat
    var onRelicTap: (SoloOracleRelicNode) -> Void

    @State private var trajectories: [MeteorTrajectory] = []
    @State private var catchFlash: String?

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let containerSize = geo.size

                ZStack {
                    // Comet tails drawn in Canvas for performance
                    Canvas { context, size in
                        for trajectory in trajectories {
                            guard !trajectory.isCaught else { continue }
                            let t = (time - trajectory.startTime) / trajectory.duration
                            guard t >= 0, t <= 1 else { continue }
                            drawCometTail(
                                context: &context, size: size,
                                trajectory: trajectory, t: t
                            )
                        }
                    }
                    .allowsHitTesting(false)

                    // Relic views as tappable overlays
                    ForEach(trajectories) { trajectory in
                        let t = (time - trajectory.startTime) / trajectory.duration
                        if t >= 0, t <= 1, !trajectory.isCaught {
                            let posX = lerp(trajectory.startX, trajectory.endX, clamp01(t)) * containerSize.width
                            let posY = lerp(trajectory.startY, trajectory.endY, clamp01(t)) * containerSize.height
                            let rotation = time * trajectory.rotationSpeed

                            OracleMeteorRelicView(
                                node: trajectory.node,
                                pulsePhase: pulsePhase,
                                isFlashing: catchFlash == trajectory.node.id,
                                sizeFactor: trajectory.sizeFactor
                            )
                            .rotationEffect(.degrees(rotation))
                            .position(x: posX, y: posY)
                            .onTapGesture {
                                catchMeteor(id: trajectory.id, node: trajectory.node)
                            }
                        }
                    }
                }
                .onAppear {
                    initializeTrajectories(time: time)
                }
                .onChange(of: time) { _, newTime in
                    recycleTrajectories(time: newTime)
                }
            }
        }
    }

    // MARK: - Trajectory Management

    private func initializeTrajectories(time: Double) {
        guard trajectories.isEmpty else { return }
        trajectories = nodes.enumerated().map { index, node in
            MeteorTrajectory.random(
                node: node,
                startTime: time + Double(index) * 0.8,
                id: "\(node.id)-0"
            )
        }
    }

    private func recycleTrajectories(time: Double) {
        for i in trajectories.indices {
            let traj = trajectories[i]
            let t = (time - traj.startTime) / traj.duration
            if t > 1.0 || traj.isCaught {
                let delay = Double.random(in: 1.0...3.0)
                trajectories[i] = MeteorTrajectory.random(
                    node: traj.node,
                    startTime: time + delay,
                    id: "\(traj.node.id)-\(Int(time))"
                )
            }
        }
    }

    private func catchMeteor(id: String, node: SoloOracleRelicNode) {
        catchFlash = node.id
        onRelicTap(node)

        if let idx = trajectories.firstIndex(where: { $0.id == id }) {
            trajectories[idx].isCaught = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if catchFlash == node.id {
                catchFlash = nil
            }
        }
    }

    // MARK: - Comet Tail Rendering

    private func drawCometTail(
        context: inout GraphicsContext, size: CGSize,
        trajectory: MeteorTrajectory, t: Double
    ) {
        let headX = lerp(trajectory.startX, trajectory.endX, clamp01(t)) * size.width
        let headY = lerp(trajectory.startY, trajectory.endY, clamp01(t)) * size.height
        let dx = trajectory.endX - trajectory.startX
        let dy = trajectory.endY - trajectory.startY
        let angle = atan2(dy, dx)
        let scaledDiameter = trajectory.node.diameter * trajectory.sizeFactor
        let tailLen: CGFloat = 60 + scaledDiameter * 0.3
        let tailX = headX - cos(angle) * tailLen
        let tailY = headY - sin(angle) * tailLen

        var trail = Path()
        trail.move(to: CGPoint(x: tailX, y: tailY))
        trail.addLine(to: CGPoint(x: headX, y: headY))

        let tintColor = trajectory.node.tint
        context.stroke(
            trail,
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    tintColor.opacity(0.15),
                    tintColor.opacity(0.5),
                    .white.opacity(0.6),
                ]),
                startPoint: CGPoint(x: tailX, y: tailY),
                endPoint: CGPoint(x: headX, y: headY)
            ),
            lineWidth: 3.0
        )

        // Glow around the head
        let glowRect = CGRect(
            x: headX - scaledDiameter * 0.4,
            y: headY - scaledDiameter * 0.4,
            width: scaledDiameter * 0.8,
            height: scaledDiameter * 0.8
        )
        context.fill(
            Circle().path(in: glowRect),
            with: .color(tintColor.opacity(0.08))
        )
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        a + (b - a) * CGFloat(t)
    }

    private func clamp01(_ t: Double) -> Double {
        min(1, max(0, t))
    }
}

// MARK: - Meteor Relic View

private struct OracleMeteorRelicView: View {
    let node: SoloOracleRelicNode
    let pulsePhase: CGFloat
    let isFlashing: Bool
    var sizeFactor: CGFloat = 1.0

    var body: some View {
        let d = node.diameter * sizeFactor
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: d, height: d)

            Circle()
                .fill(node.tint.opacity(0.12 + Double(pulsePhase) * 0.08))
                .frame(width: d + 20, height: d + 20)
                .blur(radius: 12)

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
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))

            Circle()
                .stroke(node.tint.opacity(0.25 + Double(pulsePhase) * 0.15), lineWidth: 0.6)
                .frame(width: d + 14, height: d + 14)
                .blur(radius: 2)

            Text(node.title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(node.tint.opacity(0.7))
                .offset(y: d / 2 + 12)
        }
        .shadow(color: node.tint.opacity(0.15), radius: 12, y: 6)
        .scaleEffect(isFlashing ? 1.3 : 1.0)
        .opacity(isFlashing ? 0.4 : 1.0)
        .animation(.easeOut(duration: 0.3), value: isFlashing)
        .contentShape(Circle().size(width: d + 40, height: d + 40))
    }
}

// MARK: - Meteor Trajectory

private struct MeteorTrajectory: Identifiable {
    let id: String
    let node: SoloOracleRelicNode
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    var startTime: Double
    let duration: Double
    let rotationSpeed: Double
    let sizeFactor: CGFloat  // random scale multiplier (0.45–1.35)
    var isCaught: Bool = false

    static func random(node: SoloOracleRelicNode, startTime: Double, id: String) -> MeteorTrajectory {
        let edge = Int.random(in: 0...3) // 0=top, 1=right, 2=bottom, 3=left
        let exitEdge = (edge + 2 + Int.random(in: -1...1) + 4) % 4 // roughly opposite

        let startPt = edgePoint(edge: edge)
        let endPt = edgePoint(edge: exitEdge)
        let duration = Double.random(in: 5.0...9.0)
        let rotation = Double.random(in: 8...30) * (Bool.random() ? 1.0 : -1.0)
        let sizeFactor = CGFloat.random(in: 0.45...1.35)

        return MeteorTrajectory(
            id: id,
            node: node,
            startX: startPt.x,
            startY: startPt.y,
            endX: endPt.x,
            endY: endPt.y,
            startTime: startTime,
            duration: duration,
            rotationSpeed: rotation,
            sizeFactor: sizeFactor
        )
    }

    private static func edgePoint(edge: Int) -> CGPoint {
        let margin: CGFloat = 0.15
        let pos = CGFloat.random(in: 0.1...0.9)
        switch edge {
        case 0: return CGPoint(x: pos, y: -margin)       // top
        case 1: return CGPoint(x: 1.0 + margin, y: pos)  // right
        case 2: return CGPoint(x: pos, y: 1.0 + margin)  // bottom
        default: return CGPoint(x: -margin, y: pos)       // left
        }
    }
}

// MARK: - Sling-Ring Portal Border (Doctor Strange style)

struct OracleFireworkBorderView: View {
    let cornerRadius: CGFloat
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            staticGlowBorder
        } else {
            GeometryReader { _ in
                ZStack {
                    // Layer 1: Soft ambient glow halo (SwiftUI blur)
                    portalGlowHalo

                    // Layer 2: All spark streams + scattered embers (single Canvas)
                    portalSparkCanvas
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Static Fallback

    private var staticGlowBorder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius - 3, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.15),
                            Color(red: 0.9, green: 0.4, blue: 0.05).opacity(0.10),
                            Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )
                .blur(radius: 12)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.15).opacity(0.7),
                            Color(red: 1.0, green: 0.45, blue: 0.05).opacity(0.5),
                            Color(red: 1.0, green: 0.7, blue: 0.15).opacity(0.7),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.05).opacity(0.5), radius: 12)
        }
    }

    // MARK: - Ambient Glow Halo (SwiftUI layers — soft orange bloom)

    private var portalGlowHalo: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let breathA = 0.16 + sin(time * 0.8) * 0.05
            let breathB = 0.12 + sin(time * 1.3 + 1.2) * 0.04
            let rot = time * 8.0

            ZStack {
                // Outermost heat bloom — very wide, very soft
                RoundedRectangle(cornerRadius: cornerRadius - 6, style: .continuous)
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(red: 1.0, green: 0.45, blue: 0.02).opacity(breathA * 0.5),
                                Color(red: 1.0, green: 0.30, blue: 0.01).opacity(breathB * 0.3),
                                Color(red: 1.0, green: 0.55, blue: 0.08).opacity(breathA * 0.4),
                                Color(red: 0.9, green: 0.30, blue: 0.01).opacity(breathB * 0.4),
                                Color(red: 1.0, green: 0.45, blue: 0.02).opacity(breathA * 0.5),
                            ],
                            center: .center,
                            angle: .degrees(rot * 0.4)
                        ),
                        lineWidth: 50
                    )
                    .blur(radius: 28)

                // Wide diffuse orange halo — the "heat" around the portal ring
                RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.05).opacity(breathA),
                                Color(red: 1.0, green: 0.35, blue: 0.02).opacity(breathB * 0.7),
                                Color(red: 1.0, green: 0.65, blue: 0.15).opacity(breathA * 0.9),
                                Color(red: 0.95, green: 0.40, blue: 0.02).opacity(breathB),
                                Color(red: 1.0, green: 0.55, blue: 0.05).opacity(breathA),
                            ],
                            center: .center,
                            angle: .degrees(rot)
                        ),
                        lineWidth: 36
                    )
                    .blur(radius: 18)

                // Tighter bright core glow — the "white-hot" inner ring edge
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.5).opacity(breathA + 0.08),
                                Color(red: 1.0, green: 0.55, blue: 0.1).opacity(breathB + 0.06),
                                Color.white.opacity(0.18),
                                Color(red: 1.0, green: 0.70, blue: 0.2).opacity(breathA + 0.04),
                                Color(red: 1.0, green: 0.50, blue: 0.08).opacity(breathB + 0.07),
                                Color(red: 1.0, green: 0.85, blue: 0.5).opacity(breathA + 0.08),
                            ],
                            center: .center,
                            angle: .degrees(-rot * 0.6)
                        ),
                        lineWidth: 10
                    )
                    .blur(radius: 5)
            }
        }
    }

    // MARK: - Spark Stream Canvas

    private var portalSparkCanvas: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                Self.drawSlingRingPortal(
                    context: &context, size: size,
                    time: time, cornerRadius: cornerRadius
                )
            }
        }
    }

    // MARK: - Main Drawing Routine

    private static func drawSlingRingPortal(
        context: inout GraphicsContext, size: CGSize,
        time: Double, cornerRadius: CGFloat
    ) {
        let points = perimeterPoints(size: size, cornerRadius: cornerRadius)
        let normals = perimeterNormals(points: points, size: size)
        let tangents = perimeterTangents(points: points)
        guard !points.isEmpty else { return }
        let N = Double(points.count)

        // ── 1. Base ring stroke (pulsing hot wire) ──
        let borderPath = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: CGRect(origin: .zero, size: size))
        let wirePulse = 0.40 + sin(time * 1.6) * 0.08
        context.stroke(
            borderPath,
            with: .color(Color(red: 1.0, green: 0.65, blue: 0.12).opacity(wirePulse)),
            lineWidth: 2.2
        )
        // Wider dim stroke for thickness illusion
        context.stroke(
            borderPath,
            with: .color(Color(red: 1.0, green: 0.45, blue: 0.05).opacity(wirePulse * 0.4)),
            lineWidth: 7.0
        )

        // ── 2. Primary spark stream (clockwise, fast) ──
        drawSparkStream(
            context: &context, points: points, tangents: tangents, normals: normals,
            time: time, count: 320, speed: 0.22,
            trailLen: (14.0, 32.0), width: (1.2, 3.2),
            normalSpread: 12.0, brightnessRange: (0.5, 1.0),
            colorSet: .primary
        )

        // ── 3. Secondary spark stream (counter-clockwise, slightly slower) ──
        drawSparkStream(
            context: &context, points: points, tangents: tangents, normals: normals,
            time: time, count: 220, speed: -0.16,
            trailLen: (10.0, 26.0), width: (1.0, 2.6),
            normalSpread: 10.0, brightnessRange: (0.35, 0.85),
            colorSet: .secondary
        )

        // ── 4. Tertiary micro-spark stream (fast, sparse, white-hot) ──
        drawSparkStream(
            context: &context, points: points, tangents: tangents, normals: normals,
            time: time, count: 90, speed: 0.35,
            trailLen: (6.0, 16.0), width: (0.8, 1.8),
            normalSpread: 8.0, brightnessRange: (0.7, 1.0),
            colorSet: .whiteHot
        )

        // ── 5. Scattered outward embers (sparks flying off the ring) ──
        drawScatteredEmbers(
            context: &context, points: points, normals: normals, tangents: tangents,
            time: time, count: 120, N: N
        )

        // ── 6. Inner inward embers (sparks drifting into the portal) ──
        drawInwardEmbers(
            context: &context, points: points, normals: normals,
            time: time, count: 65, N: N
        )
    }

    // MARK: - Spark Stream Drawing

    private enum SparkColorSet {
        case primary    // orange-gold dominant
        case secondary  // deeper red-orange
        case whiteHot   // white-yellow
    }

    private static func sparkColor(seed: Double, brightness: Double, set: SparkColorSet) -> Color {
        let mix = fract(sin(seed * 741.3 + 312.7) * 43758.5453)
        switch set {
        case .primary:
            let r = 1.0
            let g = 0.50 + mix * 0.25 + brightness * 0.15
            let b = 0.02 + mix * 0.08
            return Color(red: r, green: g, blue: b)
        case .secondary:
            let r = 0.95 + mix * 0.05
            let g = 0.30 + mix * 0.20 + brightness * 0.10
            let b = 0.02 + mix * 0.05
            return Color(red: r, green: g, blue: b)
        case .whiteHot:
            let r = 1.0
            let g = 0.80 + mix * 0.15
            let b = 0.45 + mix * 0.30
            return Color(red: r, green: g, blue: b)
        }
    }

    private static func drawSparkStream(
        context: inout GraphicsContext,
        points: [CGPoint], tangents: [CGPoint], normals: [CGPoint],
        time: Double, count: Int, speed: Double,
        trailLen: (Double, Double), width: (Double, Double),
        normalSpread: Double, brightnessRange: (Double, Double),
        colorSet: SparkColorSet
    ) {
        let N = Double(points.count)
        let pc = points.count

        for i in 0..<count {
            let seed = Double(i)

            // Position along perimeter — each spark has its own phase, all moving at `speed`
            let baseOffset = fract(sin(seed * 127.1 + 311.7) * 43758.5453)
            let phase = fract(baseOffset + time * speed)
            let idx = Int(phase * N) % pc

            let pos = points[idx]
            let tan = tangents[idx]
            let norm = normals[idx]

            // Perpendicular offset (sparks don't all sit exactly on the border)
            let normalOffset = (fract(sin(seed * 419.2 + 371.9) * 43758.5453) - 0.5) * 2.0 * normalSpread
            let px = pos.x + norm.x * normalOffset
            let py = pos.y + norm.y * normalOffset

            // Spark trail length
            let tLen = trailLen.0 + fract(sin(seed * 531.7 + 241.8) * 43758.5453) * (trailLen.1 - trailLen.0)
            let sparkWidth = width.0 + fract(sin(seed * 167.4 + 892.3) * 43758.5453) * (width.1 - width.0)

            // Trail direction = tangent (or reverse for negative speed)
            let dir: CGFloat = speed > 0 ? 1.0 : -1.0
            let tailX = px - tan.x * tLen * dir
            let tailY = py - tan.y * tLen * dir

            // Brightness — flickers with time
            let flicker = 0.7 + sin(time * 8.0 + seed * 3.7) * 0.3
            let baseBright = brightnessRange.0 + fract(sin(seed * 213.7 + 491.2) * 43758.5453) * (brightnessRange.1 - brightnessRange.0)
            let brightness = baseBright * flicker

            let color = sparkColor(seed: seed, brightness: brightness, set: colorSet)

            // Draw the elongated spark as a gradient line
            var trail = Path()
            trail.move(to: CGPoint(x: tailX, y: tailY))
            trail.addLine(to: CGPoint(x: px, y: py))

            context.stroke(
                trail,
                with: .linearGradient(
                    Gradient(colors: [
                        color.opacity(0),
                        color.opacity(brightness * 0.5),
                        color.opacity(brightness),
                    ]),
                    startPoint: CGPoint(x: tailX, y: tailY),
                    endPoint: CGPoint(x: px, y: py)
                ),
                lineWidth: sparkWidth
            )

            // Bright head dot
            let headR = sparkWidth * 0.6
            let headRect = CGRect(x: px - headR, y: py - headR, width: headR * 2, height: headR * 2)
            context.fill(
                Circle().path(in: headRect),
                with: .color(Color.white.opacity(brightness * 0.6))
            )
        }
    }

    // MARK: - Scattered Outward Embers

    private static func drawScatteredEmbers(
        context: inout GraphicsContext,
        points: [CGPoint], normals: [CGPoint], tangents: [CGPoint],
        time: Double, count: Int, N: Double
    ) {
        let pc = points.count
        for i in 0..<count {
            let seed = Double(i) + 1000
            let cycle = fract(time * (0.25 + fract(sin(seed * 173.1) * 43758.5453) * 0.15) + seed * 0.47)
            let lifetime = 0.6
            guard cycle < lifetime else { continue }

            let fadeT = cycle / lifetime
            let opacity = (1.0 - fadeT) * (1.0 - fadeT) * 0.70  // quadratic fade

            // Spawn on border
            let spawnPhase = fract(seed * 0.0314 + time * 0.06)
            let idx = Int(spawnPhase * N) % pc
            let basePos = points[idx]
            let norm = normals[idx]
            let tan = tangents[idx]

            // Fly outward with tangential drift
            let outDist = cycle * (55.0 + fract(sin(seed * 317.9) * 43758.5453) * 75.0)
            let tanDrift = (fract(sin(seed * 641.7) * 43758.5453) - 0.5) * cycle * 45.0
            let px = basePos.x + norm.x * outDist + tan.x * tanDrift
            let py = basePos.y + norm.y * outDist + tan.y * tanDrift

            let sz = (2.0 + fract(sin(seed * 213.7) * 43758.5453) * 3.5) * (1.0 - fadeT * 0.5)

            // Hot orange → dim red
            let r = 1.0
            let g = 0.50 - fadeT * 0.25 + fract(sin(seed * 891.3) * 43758.5453) * 0.15
            let b = 0.03

            let rect = CGRect(x: px - sz / 2, y: py - sz / 2, width: sz, height: sz)
            context.fill(
                Circle().path(in: rect),
                with: .color(Color(red: r, green: g, blue: b).opacity(opacity))
            )
        }
    }

    // MARK: - Inward Embers (into the portal)

    private static func drawInwardEmbers(
        context: inout GraphicsContext,
        points: [CGPoint], normals: [CGPoint],
        time: Double, count: Int, N: Double
    ) {
        let pc = points.count
        for i in 0..<count {
            let seed = Double(i) + 2000
            let cycle = fract(time * (0.3 + fract(sin(seed * 271.3) * 43758.5453) * 0.12) + seed * 0.53)
            let lifetime = 0.55
            guard cycle < lifetime else { continue }

            let fadeT = cycle / lifetime
            let opacity = (1.0 - fadeT * fadeT) * 0.50

            let spawnPhase = fract(seed * 0.0412 + time * 0.05)
            let idx = Int(spawnPhase * N) % pc
            let basePos = points[idx]
            let norm = normals[idx]

            // Drift inward
            let inDist = cycle * (24.0 + fract(sin(seed * 417.2) * 43758.5453) * 30.0)
            let wobble = sin(time * 4.0 + seed * 2.3) * 3.0
            let tx = -norm.y
            let ty = norm.x
            let px = basePos.x - norm.x * inDist + tx * wobble
            let py = basePos.y - norm.y * inDist + ty * wobble

            let sz = (1.2 + fract(sin(seed * 513.7) * 43758.5453) * 2.0) * (1.0 - fadeT * 0.7)

            let r = 1.0
            let g = 0.65 + fract(sin(seed * 741.3) * 43758.5453) * 0.20 - fadeT * 0.15
            let b = 0.15 + fract(sin(seed * 941.1) * 43758.5453) * 0.15

            let rect = CGRect(x: px - sz / 2, y: py - sz / 2, width: sz, height: sz)
            context.fill(
                Circle().path(in: rect),
                with: .color(Color(red: r, green: g, blue: b).opacity(opacity))
            )
        }
    }

    // MARK: - Utilities

    private static func fract(_ x: Double) -> Double { x - floor(x) }

    // MARK: - Perimeter Geometry

    static func perimeterPoints(size: CGSize, cornerRadius: CGFloat) -> [CGPoint] {
        let r = min(cornerRadius, min(size.width, size.height) / 2)
        let w = size.width
        let h = size.height
        var pts: [CGPoint] = []
        let segE = 60  // segments per edge
        let segC = 18  // segments per corner

        // Top edge
        for i in 0...segE {
            let t = CGFloat(i) / CGFloat(segE)
            pts.append(CGPoint(x: r + (w - 2 * r) * t, y: 0))
        }
        // Top-right corner
        for i in 0...segC {
            let a = -CGFloat.pi / 2 + CGFloat.pi / 2 * CGFloat(i) / CGFloat(segC)
            pts.append(CGPoint(x: w - r + r * cos(a), y: r + r * sin(a)))
        }
        // Right edge
        for i in 0...segE {
            let t = CGFloat(i) / CGFloat(segE)
            pts.append(CGPoint(x: w, y: r + (h - 2 * r) * t))
        }
        // Bottom-right corner
        for i in 0...segC {
            let a = CGFloat(i) / CGFloat(segC) * CGFloat.pi / 2
            pts.append(CGPoint(x: w - r + r * cos(a), y: h - r + r * sin(a)))
        }
        // Bottom edge
        for i in 0...segE {
            let t = CGFloat(i) / CGFloat(segE)
            pts.append(CGPoint(x: w - r - (w - 2 * r) * t, y: h))
        }
        // Bottom-left corner
        for i in 0...segC {
            let a = CGFloat.pi / 2 + CGFloat.pi / 2 * CGFloat(i) / CGFloat(segC)
            pts.append(CGPoint(x: r + r * cos(a), y: h - r + r * sin(a)))
        }
        // Left edge
        for i in 0...segE {
            let t = CGFloat(i) / CGFloat(segE)
            pts.append(CGPoint(x: 0, y: h - r - (h - 2 * r) * t))
        }
        // Top-left corner
        for i in 0...segC {
            let a = CGFloat.pi + CGFloat.pi / 2 * CGFloat(i) / CGFloat(segC)
            pts.append(CGPoint(x: r + r * cos(a), y: r + r * sin(a)))
        }
        return pts
    }

    /// Outward-facing unit normals.
    static func perimeterNormals(points: [CGPoint], size: CGSize) -> [CGPoint] {
        let cx = size.width / 2
        let cy = size.height / 2
        return points.map { pt in
            let dx = pt.x - cx
            let dy = pt.y - cy
            let len = sqrt(dx * dx + dy * dy)
            guard len > 0.001 else { return CGPoint(x: 0, y: -1) }
            return CGPoint(x: dx / len, y: dy / len)
        }
    }

    /// Unit tangent vectors (direction of travel along perimeter).
    static func perimeterTangents(points: [CGPoint]) -> [CGPoint] {
        let n = points.count
        return (0..<n).map { i in
            let next = points[(i + 1) % n]
            let prev = points[(i - 1 + n) % n]
            let dx = next.x - prev.x
            let dy = next.y - prev.y
            let len = sqrt(dx * dx + dy * dy)
            guard len > 0.001 else { return CGPoint(x: 1, y: 0) }
            return CGPoint(x: dx / len, y: dy / len)
        }
    }
}
