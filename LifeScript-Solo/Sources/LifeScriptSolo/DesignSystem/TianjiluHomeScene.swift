import SwiftUI

struct TianjiluHomeScene: View {
    let illustration: SoloArtworkAsset
    let animationsEnabled: Bool

    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @State private var isLive = false

    init(
        illustration: SoloArtworkAsset = TianjiluArtworkCatalog.homeHeroMaster,
        animationsEnabled: Bool = true
    ) {
        self.illustration = illustration
        self.animationsEnabled = animationsEnabled
    }

    var body: some View {
        GeometryReader { geo in
            if reduceMotion || !animationsEnabled || !isLive {
                scene(size: geo.size, t: 0)
            } else {
                TimelineView(.animation(minimumInterval: 0.10)) { timeline in
                    scene(size: geo.size, t: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .clipped()
        .onAppear {
            guard !reduceMotion && animationsEnabled else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isLive = true
            }
        }
    }

    private func scene(size: CGSize, t: Double) -> some View {
        let waveA = reduceMotion ? 0.0 : sin(t * .pi / 6.8)
        let waveB = reduceMotion ? 0.0 : cos(t * .pi / 8.4)
        let waveC = reduceMotion ? 0.0 : sin(t * .pi / 11.7 + 1.1)
        let waveD = reduceMotion ? 0.0 : cos(t * .pi / 15.0 + 0.7)

        return ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.01, green: 0.05, blue: 0.10), location: 0.00),
                    .init(color: Color(red: 0.03, green: 0.10, blue: 0.16), location: 0.22),
                    .init(color: Color(red: 0.04, green: 0.16, blue: 0.22), location: 0.48),
                    .init(color: Color(red: 0.04, green: 0.12, blue: 0.15), location: 0.74),
                    .init(color: Color.black, location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            SoloBundledArtworkImage(resourceName: illustration.resourceName, contentMode: .fill)
                .frame(width: size.width * 1.08, height: size.height * 1.06)
                .scaleEffect(1.03 + CGFloat(waveD) * 0.012)
                .offset(
                    x: CGFloat(waveA) * -10,
                    y: CGFloat(waveB) * 10 - size.height * 0.03
                )
                .saturation(0.94)
                .contrast(1.06)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.clear,
                            Color.black.opacity(0.34),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RadialGradient(
                        colors: [
                            Color(red: 0.90, green: 0.82, blue: 0.56).opacity(0.18 + waveC * 0.06),
                            Color.clear,
                        ],
                        center: UnitPoint(x: 0.64, y: 0.30),
                        startRadius: 4,
                        endRadius: size.width * 0.42
                    )
                    .blendMode(.screen)
                )

            cloudBank(
                width: size.width * 1.22,
                height: size.height * 0.28,
                opacity: 0.30,
                blur: 32,
                color: Color(red: 0.78, green: 0.86, blue: 0.90),
                x: size.width * 0.48 + CGFloat(waveA) * 12,
                y: size.height * 0.22 + CGFloat(waveB) * 7
            )

            cloudBank(
                width: size.width * 0.96,
                height: size.height * 0.20,
                opacity: 0.20,
                blur: 24,
                color: Color(red: 0.40, green: 0.80, blue: 0.76),
                x: size.width * 0.58 + CGFloat(waveB) * 10,
                y: size.height * 0.38 + CGFloat(waveC) * 8
            )

            Canvas { ctx, canvasSize in
                drawStars(ctx: ctx, size: canvasSize)
                drawFateThreads(ctx: ctx, size: canvasSize, t: t)
                drawCelestialDust(ctx: ctx, size: canvasSize, t: t)
            }

            cliffShadow(size: size)
                .fill(Color.black.opacity(0.42))
                .blur(radius: 18)
                .offset(y: size.height * 0.05)

            observatoryHalo(size: size, t: t)

            cloudBank(
                width: size.width * 1.36,
                height: size.height * 0.30,
                opacity: 0.24,
                blur: 40,
                color: Color(red: 0.90, green: 0.96, blue: 0.98),
                x: size.width * 0.42 - CGFloat(waveA) * 16,
                y: size.height * 0.74 + CGFloat(waveD) * 10
            )

            cloudBank(
                width: size.width * 1.18,
                height: size.height * 0.24,
                opacity: 0.18,
                blur: 34,
                color: Color(red: 0.34, green: 0.67, blue: 0.69),
                x: size.width * 0.60 + CGFloat(waveC) * 14,
                y: size.height * 0.84 + CGFloat(waveB) * 8
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.30),
                    Color.black.opacity(0.88),
                    Color.black,
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.42),
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.12, blue: 0.18).opacity(0.36),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.40)
            )
        }
        .frame(width: size.width, height: size.height)
    }

    private func cloudBank(
        width: CGFloat,
        height: CGFloat,
        opacity: Double,
        blur: CGFloat,
        color: Color,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        ZStack {
            Ellipse()
                .fill(color.opacity(opacity))
                .frame(width: width, height: height)

            Ellipse()
                .fill(Color.white.opacity(opacity * 0.72))
                .frame(width: width * 0.72, height: height * 0.68)
                .offset(x: width * 0.14, y: -height * 0.02)

            Ellipse()
                .fill(color.opacity(opacity * 0.60))
                .frame(width: width * 0.58, height: height * 0.55)
                .offset(x: -width * 0.18, y: height * 0.06)
        }
        .blur(radius: blur)
        .position(x: x, y: y)
    }

    private func observatoryHalo(size: CGSize, t: Double) -> some View {
        let haloSize = min(size.width * 0.36, 220)
        let slowSpin = Angle.degrees(reduceMotion ? 0 : t * 3.4)
        let fastSpin = Angle.degrees(reduceMotion ? 0 : -t * 5.2)

        return ZStack {
            Circle()
                .trim(from: 0.08, to: 0.84)
                .stroke(
                    LinearGradient(
                        colors: [
                            SoloTheme.gold.opacity(0.72),
                            SoloTheme.jade.opacity(0.24),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                .rotationEffect(slowSpin)

            Circle()
                .trim(from: 0.24, to: 0.94)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            SoloTheme.gold.opacity(0.22),
                            SoloTheme.gold.opacity(0.68),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [2.5, 8])
                )
                .rotationEffect(fastSpin)

            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                SoloTheme.gold.opacity(0.24),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1.2, height: haloSize * 0.92)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
        .frame(width: haloSize, height: haloSize)
        .blur(radius: 0.2)
        .opacity(0.60)
        .position(x: size.width * 0.83, y: size.height * 0.82)
    }

    private func cliffShadow(size: CGSize) -> Path {
        var path = Path()
        let w = size.width
        let h = size.height

        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.92))
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.82),
            control1: CGPoint(x: w * 0.04, y: h * 0.88),
            control2: CGPoint(x: w * 0.12, y: h * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.48, y: h * 0.86),
            control1: CGPoint(x: w * 0.30, y: h * 0.88),
            control2: CGPoint(x: w * 0.38, y: h * 0.84)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.80),
            control1: CGPoint(x: w * 0.58, y: h * 0.86),
            control2: CGPoint(x: w * 0.68, y: h * 0.74)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.90),
            control1: CGPoint(x: w * 0.86, y: h * 0.84),
            control2: CGPoint(x: w * 0.94, y: h * 0.89)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }

    private func drawStars(ctx: GraphicsContext, size: CGSize) {
        let stars: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.08, 0.06, 1.2, 0.66), (0.14, 0.04, 0.9, 0.42), (0.18, 0.12, 1.4, 0.54),
            (0.24, 0.07, 1.1, 0.58), (0.31, 0.03, 1.8, 0.70), (0.36, 0.15, 1.0, 0.40),
            (0.44, 0.05, 1.2, 0.48), (0.52, 0.10, 1.0, 0.44), (0.60, 0.06, 1.6, 0.62),
            (0.68, 0.04, 1.2, 0.46), (0.76, 0.11, 1.4, 0.50), (0.84, 0.07, 1.1, 0.46),
            (0.92, 0.12, 1.7, 0.58), (0.12, 0.19, 1.0, 0.34), (0.40, 0.18, 1.1, 0.30),
            (0.74, 0.19, 1.0, 0.32), (0.90, 0.22, 1.1, 0.26),
        ]

        for (x, y, radius, opacity) in stars {
            let rect = CGRect(
                x: size.width * x - radius,
                y: size.height * y - radius,
                width: radius * 2,
                height: radius * 2
            )
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(Color.white.opacity(Double(opacity)))
            )
        }
    }

    private func drawFateThreads(ctx: GraphicsContext, size: CGSize, t: Double) {
        let lines: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.18, 0.32, 0.18, 1.00),
            (0.04, 0.24, 0.42, 0.16, 1.35),
            (0.00, 0.30, 0.48, 0.20, 1.70),
            (0.18, 0.16, 0.68, 0.14, 2.10),
            (0.40, 0.12, 1.00, 0.18, 2.45),
        ]

        for (startX, startY, endX, endY, phase) in lines {
            let start = CGPoint(x: size.width * startX, y: size.height * startY)
            let end = CGPoint(x: size.width * endX, y: size.height * endY)
            let control = CGPoint(
                x: (start.x + end.x) * 0.5,
                y: min(start.y, end.y) - size.height * 0.08
            )

            var path = Path()
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)

            ctx.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        SoloTheme.gold.opacity(0.30),
                        SoloTheme.gold.opacity(0.82),
                        SoloTheme.jade.opacity(0.26),
                    ]),
                    startPoint: start,
                    endPoint: end
                ),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
            )

            let progress = CGFloat((sin(t * 0.9 + Double(phase)) + 1.0) * 0.5)
            let spark = quadPoint(start: start, control: control, end: end, t: progress)
            let sparkleRect = CGRect(x: spark.x - 2.4, y: spark.y - 2.4, width: 4.8, height: 4.8)
            ctx.fill(
                Path(ellipseIn: sparkleRect),
                with: .color(SoloTheme.gold.opacity(0.88))
            )
        }
    }

    private func drawCelestialDust(ctx: GraphicsContext, size: CGSize, t: Double) {
        let particles: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.10, 0.20, 1.4, 0.52), (0.18, 0.28, 1.2, 0.44), (0.28, 0.24, 1.8, 0.48),
            (0.37, 0.33, 1.6, 0.42), (0.52, 0.26, 1.2, 0.46), (0.66, 0.22, 1.4, 0.40),
            (0.76, 0.31, 1.0, 0.36), (0.86, 0.26, 1.6, 0.42), (0.92, 0.36, 1.2, 0.34),
            (0.20, 0.56, 1.2, 0.22), (0.38, 0.62, 1.4, 0.24), (0.56, 0.58, 1.0, 0.20),
            (0.78, 0.66, 1.8, 0.22), (0.88, 0.72, 1.2, 0.18),
        ]

        for (index, particle) in particles.enumerated() {
            let phase = t * 0.35 + Double(index) * 0.42
            let dx = CGFloat(sin(phase)) * size.width * 0.006
            let dy = CGFloat(cos(phase)) * size.height * 0.008
            let rect = CGRect(
                x: size.width * particle.0 + dx,
                y: size.height * particle.1 + dy,
                width: particle.2 * 2,
                height: particle.2 * 2
            )
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(Color.white.opacity(Double(particle.3)))
            )
        }
    }

    private func quadPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x
            + 2 * oneMinusT * t * control.x
            + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y
            + 2 * oneMinusT * t * control.y
            + t * t * end.y
        return CGPoint(x: x, y: y)
    }
}
