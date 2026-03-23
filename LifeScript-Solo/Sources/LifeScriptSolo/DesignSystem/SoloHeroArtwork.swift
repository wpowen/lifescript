import SwiftUI

// Cinematic procedural artwork for the entry hero screen.
// Game-engine inspired: particle system, dynamic glow, detailed silhouettes.
// All sizing is explicit via GeometryReader — no collapsed-frame bugs.
// Only rendered on the entry screen; reading uses SoloBackdrop.
struct SoloHeroArtwork: View {
    let preset: SoloPalettePreset
    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // ── 0: Sky gradient ────────────────────────────────────────
                LinearGradient(stops: skyStops, startPoint: .top, endPoint: .bottom)
                    .frame(width: w, height: h)

                // ── 1: Stars ───────────────────────────────────────────────
                Canvas { ctx, sz in drawStars(ctx: ctx, size: sz) }
                    .frame(width: w, height: h)

                // ── 2: Deep atmospheric smoke ──────────────────────────────
                smokeLayer(w: w, h: h)

                // ── 3: Silhouettes (distant + near) ───────────────────────
                Canvas { ctx, sz in drawSilhouettes(ctx: ctx, size: sz) }
                    .frame(width: w, height: h)

                // ── 4: Animated glow + particles ──────────────────────────
                if reduceMotion {
                    glowLayer(w: w, h: h, t: 0)
                } else {
                    TimelineView(.animation) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        let shake = meteorShake(t: t)
                        ZStack {
                            glowLayer(w: w, h: h, t: t)
                            // Falling debris in upper sky (fire themes)
                            if preset == .ashCrimson || preset == .emberGold || preset == .royalPlum {
                                Canvas { ctx, sz in drawDebris(ctx: ctx, size: sz, t: t) }
                                    .frame(width: w, height: h)
                            }
                            Canvas { ctx, sz in drawParticles(ctx: ctx, size: sz, t: t) }
                                .frame(width: w, height: h)
                            // Meteor impact event (fire/apocalypse themes)
                            if preset == .ashCrimson || preset == .emberGold {
                                Canvas { ctx, sz in drawMeteorEvent(ctx: ctx, size: sz, t: t) }
                                    .frame(width: w, height: h)
                            }
                            // Rare lightning flash
                            if preset == .ashCrimson || preset == .royalPlum {
                                lightningFlash(w: w, h: h, t: t)
                            }
                        }
                        .frame(width: w, height: h)
                        .offset(x: shake.x, y: shake.y)
                    }
                    .frame(width: w, height: h)
                }

                // ── 5: Vignette (cinematic darkening at edges) ─────────────
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.65)],
                    center: .center,
                    startRadius: w * 0.22,
                    endRadius: w * 0.82
                )
                .frame(width: w, height: h)

                // ── 6: Bottom dissolve → seamless into app black ──────────
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.82), Color.black],
                    startPoint: UnitPoint(x: 0.5, y: 0.48),
                    endPoint: .bottom
                )
                .frame(width: w, height: h)
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Sky Gradient
    // ─────────────────────────────────────────────────────────────────────────

    private var skyStops: [Gradient.Stop] {
        switch preset {
        case .ashCrimson:
            // Apocalypse: deep crimson-purple zenith → burning orange horizon
            return [
                .init(color: Color(red: 0.12, green: 0.03, blue: 0.10), location: 0.00),
                .init(color: Color(red: 0.16, green: 0.04, blue: 0.10), location: 0.15),
                .init(color: Color(red: 0.24, green: 0.06, blue: 0.08), location: 0.35),
                .init(color: Color(red: 0.44, green: 0.10, blue: 0.06), location: 0.58),
                .init(color: Color(red: 0.64, green: 0.18, blue: 0.05), location: 0.78),
                .init(color: Color(red: 0.74, green: 0.26, blue: 0.04), location: 0.92),
                .init(color: Color(red: 0.60, green: 0.20, blue: 0.03), location: 1.00),
            ]
        case .moonJade:
            return [
                .init(color: Color(red: 0.04, green: 0.08, blue: 0.16), location: 0.00),
                .init(color: Color(red: 0.04, green: 0.10, blue: 0.20), location: 0.22),
                .init(color: Color(red: 0.05, green: 0.14, blue: 0.26), location: 0.50),
                .init(color: Color(red: 0.06, green: 0.20, blue: 0.30), location: 0.76),
                .init(color: Color(red: 0.07, green: 0.26, blue: 0.34), location: 1.00),
            ]
        case .royalPlum:
            return [
                .init(color: Color(red: 0.10, green: 0.03, blue: 0.16), location: 0.00),
                .init(color: Color(red: 0.16, green: 0.04, blue: 0.24), location: 0.28),
                .init(color: Color(red: 0.28, green: 0.07, blue: 0.38), location: 0.55),
                .init(color: Color(red: 0.42, green: 0.12, blue: 0.52), location: 0.78),
                .init(color: Color(red: 0.50, green: 0.16, blue: 0.58), location: 1.00),
            ]
        case .emberGold:
            return [
                .init(color: Color(red: 0.10, green: 0.04, blue: 0.04), location: 0.00),
                .init(color: Color(red: 0.16, green: 0.06, blue: 0.05), location: 0.26),
                .init(color: Color(red: 0.32, green: 0.13, blue: 0.04), location: 0.52),
                .init(color: Color(red: 0.56, green: 0.26, blue: 0.04), location: 0.75),
                .init(color: Color(red: 0.70, green: 0.36, blue: 0.04), location: 0.92),
                .init(color: Color(red: 0.58, green: 0.28, blue: 0.03), location: 1.00),
            ]
        case .sapphireMist:
            return [
                .init(color: Color(red: 0.04, green: 0.06, blue: 0.16), location: 0.00),
                .init(color: Color(red: 0.05, green: 0.10, blue: 0.22), location: 0.28),
                .init(color: Color(red: 0.07, green: 0.16, blue: 0.34), location: 0.58),
                .init(color: Color(red: 0.10, green: 0.24, blue: 0.46), location: 0.80),
                .init(color: Color(red: 0.12, green: 0.30, blue: 0.52), location: 1.00),
            ]
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Stars
    // ─────────────────────────────────────────────────────────────────────────

    private let starData: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.06,0.04,1.4,0.80),(0.14,0.08,1.0,0.55),(0.21,0.02,1.8,0.90),
        (0.29,0.11,1.2,0.65),(0.38,0.05,2.2,0.85),(0.45,0.02,1.1,0.60),
        (0.52,0.07,1.6,0.75),(0.60,0.03,1.3,0.65),(0.68,0.09,2.4,0.92),
        (0.75,0.04,1.0,0.55),(0.82,0.07,1.5,0.70),(0.91,0.02,1.2,0.60),
        (0.96,0.11,1.8,0.80),(0.10,0.17,1.2,0.50),(0.24,0.21,0.9,0.45),
        (0.35,0.14,1.4,0.60),(0.48,0.19,1.1,0.48),(0.63,0.16,1.6,0.65),
        (0.78,0.18,1.0,0.45),(0.88,0.21,1.3,0.55),(0.03,0.27,1.1,0.38),
        (0.17,0.31,1.2,0.42),(0.44,0.27,0.9,0.38),(0.72,0.29,1.4,0.48),
        (0.95,0.25,1.0,0.40),(0.57,0.13,0.8,0.52),(0.85,0.14,1.2,0.48),
        (0.33,0.07,0.7,0.60),(0.54,0.16,0.9,0.44),(0.70,0.22,0.8,0.36),
        (0.12,0.33,0.7,0.30),(0.85,0.30,0.9,0.36),(0.42,0.34,0.8,0.32),
    ]

    private func drawStars(ctx: GraphicsContext, size: CGSize) {
        // Fire themes: dim stars (sky too bright near horizon)
        let scale: CGFloat = preset == .moonJade ? 1.0 : preset == .sapphireMist ? 0.85 : 0.55
        for (sx, sy, r, a) in starData {
            guard sy < 0.38 else { continue }
            let cx = sx * size.width
            let cy = sy * size.height * 0.85
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(Double(a * scale))))
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Smoke / Atmospheric Haze
    // ─────────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func smokeLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Wide smoke band at mid-horizon
            Ellipse()
                .fill(smokeColor.opacity(0.42))
                .frame(width: w * 1.20, height: h * 0.28)
                .position(x: w * 0.48, y: h * 0.65)
                .blur(radius: 30)

            // Secondary smoke band
            Ellipse()
                .fill(smokeColor.opacity(0.30))
                .frame(width: w * 0.85, height: h * 0.20)
                .position(x: w * 0.68, y: h * 0.58)
                .blur(radius: 22)

            // Fire-themed: rising smoke columns from ruin sites
            if preset == .ashCrimson || preset == .emberGold {
                // Left column
                Ellipse()
                    .fill(smokeColor.opacity(0.22))
                    .frame(width: w * 0.18, height: h * 0.55)
                    .position(x: w * 0.22, y: h * 0.50)
                    .blur(radius: 16)
                // Right column
                Ellipse()
                    .fill(smokeColor.opacity(0.18))
                    .frame(width: w * 0.14, height: h * 0.44)
                    .position(x: w * 0.72, y: h * 0.53)
                    .blur(radius: 14)
                // Center column (tallest)
                Ellipse()
                    .fill(smokeColor.opacity(0.16))
                    .frame(width: w * 0.22, height: h * 0.60)
                    .position(x: w * 0.44, y: h * 0.45)
                    .blur(radius: 18)
            }

            if preset == .moonJade {
                // Mist tendrils across mountain base
                Ellipse()
                    .fill(Color(red: 0.12, green: 0.42, blue: 0.42).opacity(0.22))
                    .frame(width: w * 1.5, height: h * 0.32)
                    .position(x: w * 0.50, y: h * 0.60)
                    .blur(radius: 36)
                Ellipse()
                    .fill(Color(red: 0.08, green: 0.30, blue: 0.36).opacity(0.16))
                    .frame(width: w * 1.2, height: h * 0.22)
                    .position(x: w * 0.35, y: h * 0.52)
                    .blur(radius: 28)
            }
        }
        .frame(width: w, height: h)
    }

    private var smokeColor: Color {
        switch preset {
        case .ashCrimson:   Color(red: 0.20, green: 0.09, blue: 0.06)
        case .moonJade:     Color(red: 0.08, green: 0.24, blue: 0.28)
        case .royalPlum:    Color(red: 0.20, green: 0.08, blue: 0.28)
        case .emberGold:    Color(red: 0.22, green: 0.12, blue: 0.04)
        case .sapphireMist: Color(red: 0.06, green: 0.14, blue: 0.32)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Silhouettes
    // ─────────────────────────────────────────────────────────────────────────

    private func drawSilhouettes(ctx: GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        if preset == .moonJade {
            // Distant misty peaks
            ctx.fill(distantMountainPath(w: w, h: h),
                     with: .color(Color(red: 0.03, green: 0.08, blue: 0.14).opacity(0.85)))
            // Near mountain
            ctx.fill(mountainPath(w: w, h: h), with: .color(.black))
        } else {
            // Distant destroyed city
            ctx.fill(distantCityPath(w: w, h: h),
                     with: .color(Color(red: 0.06, green: 0.03, blue: 0.03).opacity(0.90)))
            // Near ruined foreground
            ctx.fill(cityPath(w: w, h: h), with: .color(.black))
        }
    }

    // Ruined distant skyline (mid-depth)
    private func distantCityPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        let baseY = h * 0.68
        // Segments as (x_fraction, height_fraction)
        let buildings: [(CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.00, 0.06), (0.06, 0.14, 0.04), (0.10, 0.00, 0.05),
            (0.15, 0.18, 0.06), (0.21, 0.08, 0.04), (0.25, 0.22, 0.05),
            (0.30, 0.12, 0.07), (0.37, 0.26, 0.05), (0.42, 0.16, 0.04),
            (0.46, 0.28, 0.06), (0.52, 0.14, 0.05), (0.57, 0.20, 0.07),
            (0.64, 0.10, 0.04), (0.68, 0.24, 0.06), (0.74, 0.08, 0.05),
            (0.79, 0.18, 0.04), (0.83, 0.12, 0.06), (0.89, 0.20, 0.05),
            (0.94, 0.06, 0.06), (1.00, 0.00, 0.00),
        ]
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseY))
        for i in 0..<(buildings.count - 1) {
            let (x1, bh1, _) = buildings[i]
            let (x2, bh2, _) = buildings[i + 1]
            let topY1 = baseY - bh1 * h * 0.26
            let topY2 = baseY - bh2 * h * 0.26
            p.addLine(to: CGPoint(x: x1 * w, y: topY1))
            p.addLine(to: CGPoint(x: x2 * w, y: topY2))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }

    // Near ruined foreground with collapsed structures and rubble
    private func cityPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        let baseY = h * 0.80
        // Irregular ruined profile — jagged collapsed walls
        let profile: [(CGFloat, CGFloat)] = [
            (0.00, 0.00), (0.04, 0.22), (0.08, 0.16), (0.11, 0.32),
            (0.14, 0.20), (0.18, 0.38), (0.22, 0.24), (0.26, 0.44),
            (0.29, 0.30), (0.33, 0.48), (0.37, 0.34), (0.40, 0.52),
            (0.43, 0.36), (0.47, 0.50), (0.50, 0.40), (0.54, 0.58),
            (0.57, 0.44), (0.61, 0.52), (0.64, 0.36), (0.68, 0.48),
            (0.71, 0.30), (0.75, 0.42), (0.78, 0.24), (0.82, 0.36),
            (0.85, 0.18), (0.89, 0.28), (0.92, 0.12), (0.96, 0.22),
            (1.00, 0.10), (1.00, 0.00),
        ]
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseY))
        for (fx, fh) in profile {
            p.addLine(to: CGPoint(x: fx * w, y: baseY - fh * h * 0.22))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }

    // Distant mountain peaks (moonJade)
    private func distantMountainPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        let baseY = h * 0.70
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseY))
        p.addCurve(to: CGPoint(x: w * 0.20, y: baseY - h * 0.20),
                   control1: CGPoint(x: w * 0.06, y: baseY),
                   control2: CGPoint(x: w * 0.14, y: baseY - h * 0.18))
        p.addCurve(to: CGPoint(x: w * 0.40, y: baseY - h * 0.08),
                   control1: CGPoint(x: w * 0.28, y: baseY - h * 0.22),
                   control2: CGPoint(x: w * 0.34, y: baseY))
        p.addCurve(to: CGPoint(x: w * 0.62, y: baseY - h * 0.28),
                   control1: CGPoint(x: w * 0.48, y: baseY - h * 0.06),
                   control2: CGPoint(x: w * 0.54, y: baseY - h * 0.22))
        p.addCurve(to: CGPoint(x: w * 0.82, y: baseY - h * 0.10),
                   control1: CGPoint(x: w * 0.72, y: baseY - h * 0.30),
                   control2: CGPoint(x: w * 0.78, y: baseY - h * 0.04))
        p.addCurve(to: CGPoint(x: w, y: baseY),
                   control1: CGPoint(x: w * 0.88, y: baseY - h * 0.14),
                   control2: CGPoint(x: w * 0.94, y: baseY))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }

    // Near mountain (moonJade)
    private func mountainPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        let baseY = h * 0.82
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseY))
        p.addCurve(to: CGPoint(x: w * 0.28, y: baseY - h * 0.38),
                   control1: CGPoint(x: w * 0.08, y: baseY),
                   control2: CGPoint(x: w * 0.18, y: baseY - h * 0.32))
        p.addCurve(to: CGPoint(x: w * 0.50, y: baseY - h * 0.16),
                   control1: CGPoint(x: w * 0.38, y: baseY - h * 0.42),
                   control2: CGPoint(x: w * 0.44, y: baseY - h * 0.10))
        p.addCurve(to: CGPoint(x: w * 0.76, y: baseY - h * 0.44),
                   control1: CGPoint(x: w * 0.58, y: baseY - h * 0.18),
                   control2: CGPoint(x: w * 0.64, y: baseY - h * 0.36))
        p.addCurve(to: CGPoint(x: w, y: baseY),
                   control1: CGPoint(x: w * 0.88, y: baseY - h * 0.46),
                   control2: CGPoint(x: w * 0.94, y: baseY))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Dynamic Glow
    // ─────────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func glowLayer(w: CGFloat, h: CGFloat, t: Double) -> some View {
        let pulse  = sin(t * 0.65) * 0.14 + 0.86   // 0.72…1.00
        let pulse2 = sin(t * 1.10 + 1.4) * 0.12 + 0.88
        let pulse3 = sin(t * 0.42 + 0.7) * 0.18 + 0.82

        ZStack {
            // ── Massive horizon bloom ──────────────────────────────────────
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [primaryGlow.opacity(0.82 * pulse), primaryGlow.opacity(0.28), .clear],
                        center: .center, startRadius: 0, endRadius: w * 0.58
                    )
                )
                .frame(width: w * 1.30, height: h * 0.50)
                .position(x: w * glowCX, y: h * 0.72)
                .blur(radius: 12)

            // ── Fire hotspot / light source ────────────────────────────────
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [hotspot.opacity(0.92 * pulse2), primaryGlow.opacity(0.55), .clear],
                        center: .center, startRadius: 0, endRadius: w * 0.24
                    )
                )
                .frame(width: w * 0.48, height: h * 0.26)
                .position(x: w * hotspotCX, y: h * 0.73)
                .blur(radius: 6)

            // ── Secondary fire column (left side) ─────────────────────────
            if preset == .ashCrimson || preset == .emberGold {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [primaryGlow.opacity(0.55 * pulse3), primaryGlow.opacity(0.14), .clear],
                            center: .center, startRadius: 0, endRadius: w * 0.18
                        )
                    )
                    .frame(width: w * 0.36, height: h * 0.52)
                    .position(x: w * 0.22, y: h * 0.62)
                    .blur(radius: 10)

                // Right fire column
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [primaryGlow.opacity(0.40 * pulse2), .clear],
                            center: .center, startRadius: 0, endRadius: w * 0.14
                        )
                    )
                    .frame(width: w * 0.28, height: h * 0.40)
                    .position(x: w * 0.74, y: h * 0.66)
                    .blur(radius: 8)
            }

            // ── Ground reflected fire ──────────────────────────────────────
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [primaryGlow.opacity(0.50 * pulse), primaryGlow.opacity(0.10), .clear],
                        center: .center, startRadius: 0, endRadius: w * 0.52
                    )
                )
                .frame(width: w * 1.05, height: h * 0.18)
                .position(x: w * glowCX, y: h * 0.90)
                .blur(radius: 12)

            // ── Moon orb (cultivation) ────────────────────────────────────
            if preset == .moonJade {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.72 * pulse), Color(red: 0.60, green: 0.92, blue: 0.82).opacity(0.40), .clear],
                            center: .center, startRadius: 0, endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .position(x: w * 0.74, y: h * 0.16)
                    .blur(radius: 5)
                // Moon corona
                Circle()
                    .fill(Color(red: 0.42, green: 0.78, blue: 0.72).opacity(0.18 * pulse))
                    .frame(width: 280, height: 280)
                    .position(x: w * 0.74, y: h * 0.16)
                    .blur(radius: 20)
            }
        }
        .frame(width: w, height: h)
    }

    private var primaryGlow: Color {
        switch preset {
        case .ashCrimson:   Color(red: 0.90, green: 0.38, blue: 0.08)
        case .moonJade:     Color(red: 0.24, green: 0.76, blue: 0.64)
        case .royalPlum:    Color(red: 0.68, green: 0.22, blue: 0.88)
        case .emberGold:    Color(red: 0.95, green: 0.64, blue: 0.12)
        case .sapphireMist: Color(red: 0.26, green: 0.58, blue: 0.96)
        }
    }
    private var hotspot: Color {
        switch preset {
        case .ashCrimson:   Color(red: 1.00, green: 0.74, blue: 0.24)
        case .moonJade:     Color(red: 0.78, green: 0.98, blue: 0.90)
        case .royalPlum:    Color(red: 0.90, green: 0.66, blue: 1.00)
        case .emberGold:    Color(red: 1.00, green: 0.90, blue: 0.44)
        case .sapphireMist: Color(red: 0.68, green: 0.88, blue: 1.00)
        }
    }
    private var glowCX:    CGFloat { preset == .moonJade ? 0.50 : 0.40 }
    private var hotspotCX: CGFloat { preset == .moonJade ? 0.74 : 0.38 }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Lightning Flash (rare dramatic effect)
    // ─────────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func lightningFlash(w: CGFloat, h: CGFloat, t: Double) -> some View {
        // Flash every ~14s for 0.18s window
        let cycle = t.truncatingRemainder(dividingBy: 14.0)
        let flashAlpha: Double = cycle < 0.08 ? cycle / 0.08 :
                                 cycle < 0.18 ? (0.18 - cycle) / 0.10 : 0
        if flashAlpha > 0 {
            Color.white.opacity(flashAlpha * 0.18)
                .frame(width: w, height: h)
                .allowsHitTesting(false)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Particle System
    // ─────────────────────────────────────────────────────────────────────────

    private func drawParticles(ctx: GraphicsContext, size: CGSize, t: Double) {
        switch preset {
        case .ashCrimson, .emberGold: drawEmbers(ctx: ctx, w: size.width, h: size.height, t: t)
        case .moonJade:               drawWisps(ctx: ctx, w: size.width, h: size.height, t: t)
        case .royalPlum:              drawAshParticles(ctx: ctx, w: size.width, h: size.height, t: t)
        case .sapphireMist:           drawWisps(ctx: ctx, w: size.width, h: size.height, t: t)
        }
    }

    // Rising ember sparks — golden ratio spread, sinusoidal drift
    private func drawEmbers(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: Double) {
        let count = 52
        let phi: Double = 1.6180339887
        for i in 0..<count {
            let fi = Double(i)
            // Deterministic base x using golden ratio
            let baseX = (fi * phi).truncatingRemainder(dividingBy: 1.0)
            // Only span lower portion of screen (ruins area)
            let startX = 0.08 + baseX * 0.82
            // Each particle has own period 3.5–6.5s
            let period = 3.5 + (fi * 0.23).truncatingRemainder(dividingBy: 3.0)
            // Phase offset so they don't all start at same y
            let phase = (fi * 1.37).truncatingRemainder(dividingBy: period)
            let localT = (t + phase).truncatingRemainder(dividingBy: period)
            let progress = localT / period  // 0…1

            // Rise: start near bottom of silhouette, rise toward mid-screen
            let yCurrent = (0.88 - progress * 0.70) * h

            // Skip if below artwork area
            guard yCurrent > h * 0.10 && yCurrent < h * 0.90 else { continue }

            // Wind drift: different frequency per ember
            let driftFreq = 1.8 + (fi * 0.31).truncatingRemainder(dividingBy: 1.4)
            let drift = sin(t * driftFreq + fi * 0.9) * 0.028
            let x = CGFloat(startX + drift) * w

            // Fade: appear at 0…18%, full 18–68%, fade 68–100%
            let alpha: Double
            if progress < 0.18 { alpha = progress / 0.18 }
            else if progress < 0.68 { alpha = 1.0 }
            else { alpha = (1.0 - progress) / 0.32 }

            // Size: embers start small, grow briefly, then shrink
            let sizeMod = progress < 0.25 ? progress / 0.25 : progress < 0.65 ? 1.0 : (1.0 - progress) / 0.35
            let r = CGFloat(1.8 + (fi * 0.17).truncatingRemainder(dividingBy: 2.0)) * CGFloat(sizeMod)

            // Color: hot center (white-yellow) → orange → red as cooling
            let heatFade = 1.0 - progress * 0.7
            let emberC = preset == .emberGold
                ? Color(red: 1.0, green: 0.84 * heatFade, blue: 0.20 * heatFade)
                : Color(red: 1.0, green: 0.64 * heatFade, blue: 0.12 * heatFade)

            // Glow halo
            let haloR = r * 3.8
            let haloRect = CGRect(x: x - haloR, y: yCurrent - haloR, width: haloR * 2, height: haloR * 2)
            ctx.fill(Path(ellipseIn: haloRect),
                     with: .color(primaryGlow.opacity(alpha * 0.22 * sizeMod)))

            // Core ember
            let rect = CGRect(x: x - r, y: yCurrent - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(emberC.opacity(alpha * 0.92)))
        }
    }

    // Floating jade wisps — cultivation / sapphire themes
    private func drawWisps(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: Double) {
        let count = 28
        let phi: Double = 1.6180339887
        let wispColor = preset == .moonJade
            ? Color(red: 0.42, green: 0.88, blue: 0.76)
            : Color(red: 0.52, green: 0.78, blue: 0.98)
        for i in 0..<count {
            let fi = Double(i)
            let baseY = 0.38 + (fi * phi).truncatingRemainder(dividingBy: 1.0) * 0.44
            let period = 6.0 + (fi * 0.47).truncatingRemainder(dividingBy: 4.0)
            let phase = (fi * 2.14).truncatingRemainder(dividingBy: period)
            let localT = (t + phase).truncatingRemainder(dividingBy: period)
            let progress = localT / period

            let x = CGFloat(progress) * w * 1.2 - w * 0.10
            let y = CGFloat(baseY) * h + CGFloat(sin(t * 0.7 + fi * 1.3)) * h * 0.022

            guard x > -10 && x < w + 10 else { continue }
            let alpha: Double = progress < 0.12 ? progress / 0.12 : progress > 0.88 ? (1 - progress) / 0.12 : 1.0
            let r = CGFloat(1.4 + (fi * 0.19).truncatingRemainder(dividingBy: 1.6))
            let haloR = r * 4.5
            let haloRect = CGRect(x: x - haloR, y: y - haloR, width: haloR * 2, height: haloR * 2)
            ctx.fill(Path(ellipseIn: haloRect), with: .color(wispColor.opacity(alpha * 0.18)))
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(wispColor.opacity(alpha * 0.85)))
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Falling Debris (upper sky)
    // ─────────────────────────────────────────────────────────────────────────
    // Tumbling building fragments fall from the top of the sky downward,
    // simulating structures collapsing in the ruined city below.

    private func drawDebris(ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width, h = size.height
        let count = 28
        let phi: Double = 1.6180339887

        for i in 0..<count {
            let fi = Double(i)
            // Deterministic x spawn position (golden ratio spread)
            let baseX = (fi * phi).truncatingRemainder(dividingBy: 1.0)

            // Fall period: 6–14s, each piece has own rhythm
            let period = 6.0 + (fi * 0.83).truncatingRemainder(dividingBy: 8.0)
            // Staggered start so screen is filled immediately
            let phase  = (fi * 3.17).truncatingRemainder(dividingBy: period)
            let localT = (t + phase).truncatingRemainder(dividingBy: period)
            let progress = localT / period  // 0…1 top→bottom

            // Fall range: top of screen (y=0) down to silhouette top (y≈0.44)
            let yCurrent = progress * h * 0.46

            // Sinusoidal horizontal drift (wind-carried tumble)
            let driftAmp = 0.012 + (fi * 0.007).truncatingRemainder(dividingBy: 0.018)
            let driftFreq = 0.6 + (fi * 0.18).truncatingRemainder(dividingBy: 0.8)
            let drift = sin(t * driftFreq + fi * 2.3) * driftAmp
            let x = CGFloat(baseX + drift) * w

            // Fade: 0–12% fade-in, full 12–82%, 82–100% fade-out
            let alpha: Double
            if progress < 0.12      { alpha = progress / 0.12 }
            else if progress < 0.82 { alpha = 1.0 }
            else                    { alpha = (1.0 - progress) / 0.18 }

            // Piece dimensions: mix of chunky blocks and thin shards
            let isBlock = (i % 3 != 2)
            let baseW = CGFloat(isBlock
                ? 3.0 + (fi * 0.44).truncatingRemainder(dividingBy: 6.0)
                : 1.5 + (fi * 0.28).truncatingRemainder(dividingBy: 2.5))
            let aspect  = isBlock ? 0.55 : 2.8   // block≈square, shard≈thin
            let pieceW  = baseW
            let pieceH  = baseW * aspect

            // Cumulative rotation as piece tumbles
            let rotSpeed = (0.4 + (fi * 0.19).truncatingRemainder(dividingBy: 1.2))
                         * (i.isMultiple(of: 2) ? 1.0 : -1.0)
            let angle = t * rotSpeed + fi * 1.87

            // Colour: dark concrete/steel, occasional burning edge
            let isBurning = (i % 6 == 0)
            let pieceAlpha = alpha * (isBurning ? 0.80 : 0.65)
            let pieceColor: Color = isBurning
                ? Color(red: 0.48, green: 0.18, blue: 0.06)
                : Color(red: 0.20, green: 0.13, blue: 0.10)

            // Build rotated rect via Path + AffineTransform
            let rect = CGRect(x: -pieceW / 2, y: -pieceH / 2, width: pieceW, height: pieceH)
            let transform = CGAffineTransform(translationX: x, y: yCurrent)
                .rotated(by: angle)
            let rotatedPath = Path(rect).applying(transform)
            ctx.fill(rotatedPath, with: .color(pieceColor.opacity(pieceAlpha)))

            // Burning pieces get a faint orange glow halo
            if isBurning {
                let glowR = pieceW * 3.0
                let glowRect = CGRect(x: x - glowR, y: yCurrent - glowR,
                                      width: glowR * 2, height: glowR * 2)
                ctx.fill(Path(ellipseIn: glowRect),
                         with: .color(primaryGlow.opacity(alpha * 0.18)))
            }
        }
    }

    // Swirling ash particles — royal / dark themes
    private func drawAshParticles(ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: Double) {
        let count = 36
        let phi: Double = 1.6180339887
        for i in 0..<count {
            let fi = Double(i)
            let baseX = (fi * phi).truncatingRemainder(dividingBy: 1.0)
            let period = 8.0 + (fi * 0.34).truncatingRemainder(dividingBy: 5.0)
            let phase = (fi * 1.88).truncatingRemainder(dividingBy: period)
            let localT = (t + phase).truncatingRemainder(dividingBy: period)
            let progress = localT / period
            let yCurrent = (0.80 - progress * 0.55) * h
            let drift = sin(t * 1.2 + fi * 1.1) * 0.040 + cos(t * 0.6 + fi * 0.7) * 0.020
            let x = CGFloat(baseX + drift) * w
            guard yCurrent > h * 0.08 else { continue }
            let alpha = progress < 0.20 ? progress / 0.20 : progress < 0.75 ? 1.0 : (1.0 - progress) / 0.25
            let r = CGFloat(0.9 + (fi * 0.13).truncatingRemainder(dividingBy: 1.4))
            let ashColor = Color(red: 0.72, green: 0.48, blue: 0.88)
            let rect = CGRect(x: x - r, y: yCurrent - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(ashColor.opacity(alpha * 0.70)))
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Meteor Impact System
    // ─────────────────────────────────────────────────────────────────────────
    // Cycle: every 24s
    //  0.0 – 3.0s : meteor streaks from top-right (off-screen) to city
    //  3.0 – 3.3s : white impact flash
    //  3.0 – 5.5s : shockwave rings expand
    //  3.0 – 7.0s : fireball expands then fades
    //  3.0 – 9.0s : debris scatter + gravity fall
    //  3.0 – 18.0s: crater afterglow fades
    //  18.0 – 24.0s: quiet sky (normal particle effects only)

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Meteor Timing Constants
    // Total cycle 28s:
    //  Phase 1 — distant glint:    0.0 – 1.0s  (tiny bright dot, barely visible)
    //  Phase 2 — approach:         1.0 – 4.5s  (grows, accelerates, trail builds)
    //  Phase 3 — pre-impact flash: 4.2 – 4.5s  (brightness spike, ~0.3s before impact)
    //  Phase 4 — impact:           4.5s         (white flash + shake)
    //  Phase 5 — explosion:        4.5 – 12s    (fireball, shockwave, debris)
    //  Phase 6 — aftermath:        4.5 – 26s    (crater glow, smoke fade)
    //  Quiet:                      26 – 28s
    // ─────────────────────────────────────────────────────────────────────────
    private let mPeriod: Double = 28.0
    private let mFall:   Double = 4.5   // impact moment
    private let mApproachStart: Double = 1.0

    private func mImpact(_ w: CGFloat, _ h: CGFloat) -> CGPoint {
        CGPoint(x: w * 0.54, y: h * 0.74)
    }
    private func mOrigin(_ w: CGFloat, _ h: CGFloat) -> CGPoint {
        // Far off-screen upper-right — creates a steep dramatic angle
        CGPoint(x: w * 1.18, y: h * -0.22)
    }

    // ── Screen shake + brightness feedback ────────────────────────────────
    func meteorShake(t: Double) -> CGPoint {
        let cycle = t.truncatingRemainder(dividingBy: mPeriod)
        let post  = cycle - mFall
        guard post > 0 && post < 0.90 else { return .zero }
        let shakeT = post / 0.90
        // Damped multi-frequency oscillation (primary + secondary bounce)
        let mag = (sin(shakeT * .pi * 11.0) * 0.70 + sin(shakeT * .pi * 4.5) * 0.30)
                * pow(1.0 - shakeT, 1.3) * 12.0
        return CGPoint(x: mag, y: mag * 0.50)
    }

    // ── Main draw entry ────────────────────────────────────────────────────
    private func drawMeteorEvent(ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width, h = size.height
        let cycle = t.truncatingRemainder(dividingBy: mPeriod)
        let imp   = mImpact(w, h)
        let org   = mOrigin(w, h)

        if cycle < mFall {
            let rawProg = max(0, (cycle - mApproachStart) / (mFall - mApproachStart))

            // Phase 1 (0 – 1s): distant glint — tiny bright speck at entry point
            if cycle < mApproachStart {
                let glintT     = cycle / mApproachStart
                let glintAlpha = glintT < 0.4 ? glintT / 0.4 : 1.0
                // Start position: visible top-right corner of sky
                let gx: CGFloat = w * 0.88, gy: CGFloat = h * 0.04
                // Tiny core
                ctx.fill(Path(ellipseIn: CGRect(x: gx-2, y: gy-2, width: 4, height: 4)),
                         with: .color(Color.white.opacity(glintAlpha * 0.85)))
                // Soft glow
                ctx.fill(Path(ellipseIn: CGRect(x: gx-10, y: gy-10, width: 20, height: 20)),
                         with: .color(Color(red: 1.0, green: 0.75, blue: 0.30).opacity(glintAlpha * 0.32)))
                // Flicker
                let flicker = sin(cycle * 28.0) * 0.15 + 0.85
                ctx.fill(Path(ellipseIn: CGRect(x: gx-1.5, y: gy-1.5, width: 3, height: 3)),
                         with: .color(Color.white.opacity(glintAlpha * flicker)))
            }

            drawMeteorFall(ctx: ctx, w: w, h: h, rawProg: rawProg,
                           cycle: cycle, imp: imp, org: org)
        }

        let post = cycle - mFall
        if post > 0 { drawMeteorImpact(ctx: ctx, w: w, h: h, post: post, imp: imp) }
    }

    // ── Fall phase — cinematic rocky meteor ───────────────────────────────
    // Speed curve: starts as a tiny distant glint, accelerates hard into ground.
    // Size grows with proximity (perspective), trail lengthens with speed.
    // Pre-impact: brightness spikes 0.3s before contact.
    private func drawMeteorFall(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                                rawProg: Double, cycle: Double, imp: CGPoint, org: CGPoint) {
        // Strong ease-in: crawls in from far, accelerates sharply near ground
        let prog  = pow(rawProg, 2.8)
        // Speed proxy for visual intensity
        let speed = pow(rawProg, 0.55)
        // Pre-impact brightness spike: ramp from 0→1 over final 0.3s before impact
        let preImpact = max(0.0, (cycle - (mFall - 0.30)) / 0.30)  // 0→1 in last 0.3s

        let mx = CGFloat(org.x + (imp.x - org.x) * prog)
        let my = CGFloat(org.y + (imp.y - org.y) * prog)

        let ddx = imp.x - org.x, ddy = imp.y - org.y
        let dlen = sqrt(ddx*ddx + ddy*ddy)
        let ndx = ddx / dlen, ndy = ddy / dlen
        let pdx = -ndy, pdy = ndx     // perpendicular

        // Scale: starts tiny (distant), grows with proximity (perspective)
        // At rawProg=0: radius≈4px (distant speck)
        // At rawProg=1: radius≈58px (massive rock filling sky)
        let rockR: CGFloat = 4 + CGFloat(speed) * 54

        // Pre-impact full-screen flash (sky brightens as meteor compresses atmosphere)
        if preImpact > 0 {
            let flashRect = CGRect(x: 0, y: 0, width: w, height: h)
            ctx.fill(Path(flashRect),
                     with: .color(Color(red: 1.0, green: 0.72, blue: 0.30).opacity(preImpact * 0.35)))
        }

        // ── WIDE PLASMA TRAIL ─────────────────────────────────────────────
        let trailLen = CGFloat(speed) * 0.58 * sqrt(w*w + h*h)

        // Outer soft smoke halo (widest, darkest)
        let haloSegs = 30
        for s in 0..<haloSegs {
            let sf = Double(s) / Double(haloSegs)
            let hn = 1.0 - sf
            let tx = mx - CGFloat(sf) * ndx * trailLen
            let ty = my - CGFloat(sf) * ndy * trailLen
            let hw = (rockR * 2.2) * CGFloat(pow(hn, 0.55))
            let alpha = pow(hn, 2.2) * 0.35 * speed
            ctx.fill(Path(ellipseIn: CGRect(x: tx-hw, y: ty-hw*0.55, width: hw*2, height: hw*1.1)),
                     with: .color(Color(red: 0.32, green: 0.10, blue: 0.02).opacity(alpha)))
        }

        // Hot plasma core trail (narrower, much brighter)
        let coreSegs = 60
        for s in stride(from: coreSegs-1, through: 0, by: -1) {
            let sf = Double(s) / Double(coreSegs)
            let hn = 1.0 - sf

            let tx = mx - CGFloat(sf) * ndx * trailLen
            let ty = my - CGFloat(sf) * ndy * trailLen

            // Width: tapers back, with turbulent oscillation
            let baseW = (rockR + 10) * CGFloat(pow(hn, 0.65))
            let t1 = sf * 15.0 + rawProg * 18.0
            let turb = sin(t1) * 0.28 + sin(t1 * 1.618 + 1.0) * 0.16
            let hw = baseW * CGFloat(1.0 + turb * (1.0 - hn) * 0.8)

            // Temperature banding — periodic bright "shock diamonds"
            let shockDiamond = max(0.0, sin(sf * 22.0 + rawProg * 6.0)) * 0.30

            let color: Color
            let baseAlpha: Double
            if hn > 0.82 {
                color = Color(red: 1.0, green: 0.97, blue: 0.85)
                baseAlpha = 0.90
            } else if hn > 0.62 {
                color = Color(red: 1.0, green: 0.76, blue: 0.28)
                baseAlpha = 0.80
            } else if hn > 0.40 {
                color = Color(red: 0.98, green: 0.40, blue: 0.07)
                baseAlpha = 0.68
            } else if hn > 0.20 {
                color = Color(red: 0.68, green: 0.17, blue: 0.03)
                baseAlpha = 0.52
            } else {
                color = Color(red: 0.30, green: 0.08, blue: 0.02)
                baseAlpha = 0.35
            }
            let alpha = (pow(hn, 1.3) * baseAlpha + shockDiamond * hn) * speed

            ctx.fill(Path(ellipseIn: CGRect(x: tx-hw, y: ty-hw*0.52, width: hw*2, height: hw*1.04)),
                     with: .color(color.opacity(alpha)))
        }

        // ── DETACHED BOULDER CHUNKS IN WAKE ──────────────────────────────
        let chunkDefs: [(Double, Double, CGFloat)] = [
            (0.10,  0.055, 9),  (0.19, -0.048, 7),  (0.30,  0.072, 11),
            (0.22, -0.080, 6),  (0.42,  0.038, 8),  (0.35, -0.062, 10),
            (0.52,  0.055, 6),  (0.46, -0.038, 7),  (0.62,  0.042, 5),
            (0.58, -0.060, 8),  (0.70,  0.028, 6),  (0.66, -0.050, 5),
        ]
        for (lag, drift, baseSize) in chunkDefs {
            guard lag < speed * 1.1 else { continue }
            let cx = mx - CGFloat(lag) * ndx * trailLen + CGFloat(drift) * pdx * trailLen
            let cy = my - CGFloat(lag) * ndy * trailLen + CGFloat(drift) * pdy * trailLen
            let fade = min(1.0, (speed - lag * 0.85)) * 0.92
            guard fade > 0 else { continue }

            // Build mini multi-sphere chunk
            let cr = baseSize * CGFloat(0.7 + speed * 0.5)
            drawRockMass(ctx: ctx, cx: cx, cy: cy, radius: cr,
                         rot: rawProg * 1.4 + lag * 8.0,
                         heatDir: CGPoint(x: ndx, y: ndy),
                         speed: speed, fade: fade, isChunk: true)
        }

        // ── BOW SHOCK (atmospheric compression ahead of rock) ────────────
        let bowDist = rockR * 2.4
        let bowX = mx + ndx * bowDist, bowY = my + ndy * bowDist
        let bowR = rockR * 2.1
        ctx.fill(Path(ellipseIn: CGRect(x: bowX-bowR, y: bowY-bowR*0.55, width: bowR*2, height: bowR*1.1)),
                 with: .color(Color.white.opacity(0.09 * speed)))
        // Tighter inner bow shock
        let bR2 = rockR * 1.3
        ctx.fill(Path(ellipseIn: CGRect(x: bowX-bR2, y: bowY-bR2*0.45, width: bR2*2, height: bR2*0.9)),
                 with: .color(Color.white.opacity(0.14 * speed)))

        // ── MAIN ROCK BODY ────────────────────────────────────────────────
        drawRockMass(ctx: ctx, cx: mx, cy: my, radius: rockR,
                     rot: rawProg * 0.28,
                     heatDir: CGPoint(x: ndx, y: ndy),
                     speed: speed, fade: 1.0, isChunk: false)
    }

    // ── Multi-sphere rock renderer (reused for main body + chunks) ────────
    // Builds an irregular boulder from overlapping spheres — industry standard
    // technique for making rocky shapes without polygon artifacts.
    private func drawRockMass(ctx: GraphicsContext,
                               cx: CGFloat, cy: CGFloat, radius: CGFloat,
                               rot: Double, heatDir: CGPoint,
                               speed: Double, fade: Double, isChunk: Bool) {
        // Sphere positions that compose the rock mass (relative to centre)
        // (dx, dy, radius_fraction)
        let spheres: [(CGFloat, CGFloat, CGFloat)] = isChunk ? [
            ( 0.00,  0.00, 1.00),
            (-0.38, -0.24, 0.62),
            ( 0.40,  0.12, 0.58),
            (-0.16,  0.42, 0.50),
            ( 0.24, -0.36, 0.46),
            (-0.46,  0.10, 0.40),
            ( 0.16,  0.40, 0.44),
        ] : [
            ( 0.00,  0.00, 1.00),  // main body
            (-0.42, -0.20, 0.68),  // upper-left lobe
            ( 0.44,  0.08, 0.62),  // right protrusion
            (-0.16,  0.46, 0.56),  // lower bump
            ( 0.26, -0.40, 0.52),  // upper-right chunk
            (-0.48,  0.26, 0.46),  // lower-left ear
            ( 0.20,  0.42, 0.48),  // lower-right
            (-0.32, -0.46, 0.42),  // upper-left small
            ( 0.50, -0.22, 0.40),  // upper-right small
            (-0.54,  0.02, 0.36),  // far left
            ( 0.38,  0.36, 0.38),  // lower mid-right
            ( 0.02, -0.52, 0.34),  // top-centre
        ]

        // ── Pass 1: dark rock base (all spheres) ──────────────────────────
        for (dx, dy, rf) in spheres {
            let angle = atan2(Double(dy), Double(dx)) + rot
            let dist  = sqrt(dx*dx + dy*dy) * radius
            let sx = cx + cos(angle) * dist
            let sy = cy + sin(angle) * dist * 0.90
            let sr = radius * rf

            // Sphere depth: edge spheres slightly lighter (catching reflected fire)
            let edgeness = sqrt(dx*dx + dy*dy)  // 0=center, 1=edge
            let brightness = 0.13 + edgeness * 0.06
            ctx.fill(Path(ellipseIn: CGRect(x: sx-sr, y: sy-sr, width: sr*2, height: sr*2)),
                     with: .color(Color(red: brightness,
                                        green: brightness * 0.68,
                                        blue: brightness * 0.50).opacity(fade)))
        }

        // ── Pass 2: surface pockmarks / craters ───────────────────────────
        let pitCount = isChunk ? 4 : 14
        for pit in 0..<pitCount {
            let fp   = Double(pit)
            let pAng = fp * 0.628 + rot + 0.4
            let pD   = radius * CGFloat(0.15 + (fp * 0.058).truncatingRemainder(dividingBy: 0.52))
            let px   = cx + cos(pAng) * pD
            let py   = cy + sin(pAng) * pD * 0.90
            let pr   = radius * CGFloat(0.055 + (fp * 0.011).truncatingRemainder(dividingBy: 0.065))
            // Dark pit
            ctx.fill(Path(ellipseIn: CGRect(x: px-pr, y: py-pr, width: pr*2, height: pr*2)),
                     with: .color(Color(red: 0.06, green: 0.04, blue: 0.03).opacity(fade * 0.80)))
            // Bright rim (lit by fire glow)
            let rimR = pr * 0.4
            ctx.fill(Path(ellipseIn: CGRect(x: px-rimR-pr*0.3, y: py-rimR, width: rimR*2, height: rimR*2)),
                     with: .color(Color(red: 0.55, green: 0.30, blue: 0.12).opacity(fade * 0.45)))
        }

        // ── Pass 3: magma cracks radiating from centre ────────────────────
        let crackCount = isChunk ? 3 : 9
        for c in 0..<crackCount {
            let fc    = Double(c)
            let cAng  = rot + fc * (Double.pi * 2 / Double(crackCount)) + 0.3
            let wobble = sin(fc * 1.7 + rot * 2.1) * 0.40
            let innerR = radius * 0.10
            let outerR = radius * CGFloat(0.48 + (fc * 0.082).truncatingRemainder(dividingBy: 0.40))
            let midAng = cAng + wobble * 0.5
            let midR   = outerR * 0.52

            var crack = Path()
            crack.move(to: CGPoint(x: cx + cos(cAng) * innerR, y: cy + sin(cAng) * innerR * 0.90))
            crack.addQuadCurve(
                to:      CGPoint(x: cx + cos(cAng + wobble) * outerR,
                                 y: cy + sin(cAng + wobble) * outerR * 0.90),
                control: CGPoint(x: cx + cos(midAng) * midR,
                                 y: cy + sin(midAng) * midR * 0.90))

            // Wide glow (magma pooled in crack)
            ctx.stroke(crack, with: .color(Color(red: 0.90, green: 0.40, blue: 0.05).opacity(fade * 0.75 * speed)),
                       lineWidth: radius * 0.055)
            // Mid orange
            ctx.stroke(crack, with: .color(Color(red: 1.00, green: 0.70, blue: 0.18).opacity(fade * 0.82 * speed)),
                       lineWidth: radius * 0.030)
            // White-hot core thread
            ctx.stroke(crack, with: .color(Color(red: 1.00, green: 0.95, blue: 0.75).opacity(fade * 0.65 * speed)),
                       lineWidth: radius * 0.012)
        }

        // ── Pass 4: directional atmospheric heating (key to 3-D feel) ────
        // The hemisphere facing the travel direction is white-hot from friction.
        // Each sphere gets a specular highlight on its leading face.
        let heatIntensity = min(1.0, speed * 1.8) * fade
        for (dx, dy, rf) in spheres.prefix(isChunk ? 4 : 7) {
            let angle = atan2(Double(dy), Double(dx)) + rot
            let dist  = sqrt(dx*dx + dy*dy) * radius
            let sx = cx + cos(angle) * dist
            let sy = cy + sin(angle) * dist * 0.90
            let sr = radius * rf

            // How much this sphere faces the incoming heat direction
            // dot product between sphere-centre direction and travel direction
            let spDot = cos(angle) * Double(heatDir.x) + sin(angle) * Double(heatDir.y)
            let exposure = max(0.0, 0.5 + spDot * 0.5)  // 0=away, 1=facing

            // Specular highlight offset toward leading direction
            let hlX = sx + heatDir.x * sr * CGFloat(0.40 * exposure)
            let hlY = sy + heatDir.y * sr * CGFloat(0.40 * exposure)
            let hlR = sr * CGFloat(0.55 + exposure * 0.30)

            // Orange outer glow (atmospheric heating)
            ctx.fill(Path(ellipseIn: CGRect(x: hlX-hlR, y: hlY-hlR, width: hlR*2, height: hlR*2)),
                     with: .color(Color(red: 1.0, green: 0.55, blue: 0.12).opacity(heatIntensity * exposure * 0.70)))
            // Yellow-white specular
            let spR = hlR * 0.58
            ctx.fill(Path(ellipseIn: CGRect(x: hlX-spR, y: hlY-spR, width: spR*2, height: spR*2)),
                     with: .color(Color(red: 1.0, green: 0.90, blue: 0.60).opacity(heatIntensity * exposure * 0.75)))
            // Pure white hot spot (only most-exposed spheres)
            if exposure > 0.65 {
                let wpR = spR * 0.45
                ctx.fill(Path(ellipseIn: CGRect(x: hlX-wpR, y: hlY-wpR, width: wpR*2, height: wpR*2)),
                         with: .color(Color.white.opacity(heatIntensity * (exposure - 0.65) / 0.35 * 0.90)))
            }
        }

        // Global leading-edge blaze (covers the whole front of the rock)
        let blX = cx + heatDir.x * radius * 0.50
        let blY = cy + heatDir.y * radius * 0.50
        let blR = radius * 0.80
        ctx.fill(Path(ellipseIn: CGRect(x: blX-blR, y: blY-blR, width: blR*2, height: blR*2)),
                 with: .color(Color.white.opacity(heatIntensity * 0.50)))
    }

    // ── Impact + explosion phase ───────────────────────────────────────────
    private func drawMeteorImpact(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                                  post: Double, imp: CGPoint) {
        let ix = imp.x, iy = imp.y

        // 1. Impact flash — pure white spike then rapid fade
        if post < 0.55 {
            let fAlpha = post < 0.05 ? post / 0.05 : (0.55 - post) / 0.50
            let fr = CGRect(x: 0, y: 0, width: w, height: h)
            ctx.fill(Path(fr), with: .color(Color.white.opacity(fAlpha * 0.88)))
            // Orange tint bleeding through at the edges (heat stain)
            ctx.fill(Path(fr), with: .color(Color(red: 1.0, green: 0.55, blue: 0.10)
                .opacity(fAlpha * 0.30)))
        }

        // Post-flash bloom (0.05 – 1.5s): sky stays brightened
        if post > 0.05 && post < 1.5 {
            let bloomT = (post - 0.05) / 1.45
            let fr = CGRect(x: 0, y: 0, width: w, height: h)
            ctx.fill(Path(fr), with: .color(Color(red: 1.0, green: 0.45, blue: 0.08)
                .opacity((1.0 - bloomT) * (1.0 - bloomT) * 0.22)))
        }

        // 2. Shockwave rings — three waves at different speeds
        if post < 3.5 {
            drawShockwaveRing(ctx: ctx, ix: ix, iy: iy, post: post,
                              delay: 0.00, duration: 2.2, maxR: w * 0.72,
                              color: Color.white, lineW: 4.0)
            drawShockwaveRing(ctx: ctx, ix: ix, iy: iy, post: post,
                              delay: 0.15, duration: 2.8, maxR: w * 0.60,
                              color: Color(red: 1.0, green: 0.80, blue: 0.30), lineW: 2.5)
            drawShockwaveRing(ctx: ctx, ix: ix, iy: iy, post: post,
                              delay: 0.35, duration: 3.5, maxR: w * 0.48,
                              color: Color(red: 0.90, green: 0.38, blue: 0.06), lineW: 1.5)
        }

        // Ground dust ring (wide flat ellipse at base, slower)
        if post < 5.0 {
            let dustT  = min(1.0, post / 5.0)
            let dustR  = CGFloat(pow(dustT, 0.45)) * w * 0.55
            let dustA  = (1.0 - dustT) * (1.0 - dustT) * 0.55
            ctx.fill(Path(ellipseIn: CGRect(x: ix-dustR, y: iy-dustR*0.18,
                                            width: dustR*2, height: dustR*0.36)),
                     with: .color(Color(red: 0.55, green: 0.28, blue: 0.08).opacity(dustA)))
        }

        // 3. Fireball — scaled up for 58px meteor (was 0.22w, now 0.38w)
        if post < 5.5 {
            let fT = post / 5.5
            let fireR: CGFloat
            if fT < 0.28 { fireR = CGFloat(fT / 0.28) * w * 0.38 }
            else          { fireR = CGFloat(1.0 - (fT - 0.28) / 0.72 * 0.60) * w * 0.38 }
            let fAlpha = pow(1.0 - fT, 1.3) * 0.95
            let layers: [(CGFloat, CGFloat, Color)] = [
                (2.60, 0.28, Color(red: 0.40, green: 0.08, blue: 0.02)),
                (1.90, 0.48, Color(red: 0.85, green: 0.24, blue: 0.04)),
                (1.35, 0.72, Color(red: 1.00, green: 0.58, blue: 0.10)),
                (0.80, 0.88, Color(red: 1.00, green: 0.88, blue: 0.55)),
                (0.35, 1.00, Color.white),
            ]
            for (mult, la, lc) in layers {
                let lr = fireR * mult
                ctx.fill(Path(ellipseIn: CGRect(x: ix-lr, y: iy-lr*0.65, width: lr*2, height: lr*1.30)),
                         with: .color(lc.opacity(fAlpha * la)))
            }
        }

        // 4. Debris — bigger chunks matching larger meteor
        let debrisCount = 28
        for i in 0..<debrisCount {
            let fi = Double(i)
            let lifetime = 5.0 + (fi * 0.32).truncatingRemainder(dividingBy: 4.5)
            guard post < lifetime else { continue }
            let dT = post / lifetime

            let baseAngle = (fi / Double(debrisCount)) * 2.0 * .pi
            let angle = baseAngle + sin(fi * 1.7) * 0.35
            // Faster, wider scatter for a bigger rock
            let spd = 0.32 + (fi * 0.042).truncatingRemainder(dividingBy: 0.36)

            let dx = cos(angle) * spd * w * CGFloat(dT)
            let dy = sin(angle) * spd * h * 0.55 * CGFloat(dT)
                   + CGFloat(dT * dT) * h * 0.26   // gravity
            let dbX = ix + dx, dbY = iy + dy
            guard dbX > -30 && dbX < w+30 && dbY < h+30 else { continue }

            let dAlpha = pow(1.0 - dT, 1.5) * 0.92
            // Chunks are much bigger (8–22px) for a 58px meteor
            let dSize = CGFloat(8.0 + (fi * 1.0).truncatingRemainder(dividingBy: 14.0))
                      * CGFloat(1.0 - dT * 0.45)
            let rotation = post * (1.6 + fi * 0.35) + fi * 2.1
            let isHot = (dT < 0.60) && (i % 3 != 0)
            let dColor: Color = isHot
                ? (dT < 0.28 ? Color(red: 1.0, green: 0.88, blue: 0.45)
                             : Color(red: 1.0, green: 0.52, blue: 0.10))
                : Color(red: 0.32, green: 0.18, blue: 0.09)

            let dRect = CGRect(x: -dSize/2, y: -dSize*0.45, width: dSize, height: dSize*0.90)
            let xf = CGAffineTransform(translationX: dbX, y: dbY).rotated(by: rotation)
            ctx.fill(Path(dRect).applying(xf), with: .color(dColor.opacity(dAlpha)))

            if isHot {
                let gr = dSize * 3.2
                ctx.fill(Path(ellipseIn: CGRect(x: dbX-gr, y: dbY-gr, width: gr*2, height: gr*2)),
                         with: .color(Color(red: 1.0, green: 0.52, blue: 0.10).opacity(dAlpha * 0.32)))
            }
        }

        // 5. Ground crack lines (appear 0.2s after impact, persist ~20s)
        if post > 0.2 && post < 20.0 {
            let crackIntro = min(1.0, (post - 0.2) / 0.6)  // fast reveal
            let crackFade  = max(0.0, 1.0 - pow((post - 0.2) / 20.0, 1.0))
            let crackAlpha = crackIntro * crackFade
            // Crack length grows as they propagate outward
            let maxCrackLen = w * 0.30 * CGFloat(min(1.0, (post - 0.2) / 1.2))
            let crackCount  = 12

            for c in 0..<crackCount {
                let fc       = Double(c)
                // Fan in all directions from crater, irregular spacing
                let angle    = fc / Double(crackCount) * 2.0 * .pi + fc * 0.18
                // Each crack has different length (30–100% of max)
                let lenFrac  = CGFloat(0.30 + (fc * 0.068).truncatingRemainder(dividingBy: 0.70))
                let crackLen = maxCrackLen * lenFrac

                // Crack path: starts at crater edge, branches outward with slight curve
                let startR   = w * 0.038  // starts just outside crater rim
                let sx       = ix + cos(angle) * startR
                let sy       = iy + sin(angle) * startR * 0.40  // perspective flatten
                let ex       = ix + cos(angle) * (startR + crackLen)
                let ey       = iy + sin(angle) * (startR + crackLen) * 0.40
                // Control point: slight perpendicular bend
                let bend     = CGFloat(sin(fc * 1.3 + 0.5)) * crackLen * 0.20
                let cx_ctrl  = (sx + ex) / 2 - sin(angle) * bend
                let cy_ctrl  = (sy + ey) / 2 + cos(angle) * bend * 0.40

                var crack = Path()
                crack.move(to:      CGPoint(x: sx, y: sy))
                crack.addQuadCurve(to:      CGPoint(x: ex, y: ey),
                                   control: CGPoint(x: cx_ctrl, y: cy_ctrl))

                // Dark crack gap (the split in the ground)
                ctx.stroke(crack, with: .color(Color.black.opacity(crackAlpha * 0.90)), lineWidth: 3.5)
                // Molten glow inside crack
                ctx.stroke(crack, with: .color(Color(red: 1.0, green: 0.55, blue: 0.08).opacity(crackAlpha * 0.75)), lineWidth: 1.4)
                // White-hot thread at crack centre
                ctx.stroke(crack, with: .color(Color(red: 1.0, green: 0.92, blue: 0.65).opacity(crackAlpha * 0.50 * crackIntro)), lineWidth: 0.5)

                // Secondary branch (every other crack)
                if c % 2 == 0 && crackLen > maxCrackLen * 0.4 {
                    let branchAngle = angle + 0.4 + fc * 0.05
                    let branchLen   = crackLen * 0.45
                    let bMidX = (sx + ex) / 2, bMidY = (sy + ey) / 2
                    let bex   = bMidX + cos(branchAngle) * branchLen
                    let bey   = bMidY + sin(branchAngle) * branchLen * 0.40
                    var branch = Path()
                    branch.move(to: CGPoint(x: bMidX, y: bMidY))
                    branch.addLine(to: CGPoint(x: bex, y: bey))
                    ctx.stroke(branch, with: .color(Color.black.opacity(crackAlpha * 0.70)), lineWidth: 2.0)
                    ctx.stroke(branch, with: .color(Color(red: 1.0, green: 0.50, blue: 0.06).opacity(crackAlpha * 0.55)), lineWidth: 0.8)
                }
            }
        }

        // 6. Crater afterglow + rising smoke column (scaled up)
        if post < 22.0 {
            let glowIntro = min(1.0, post / 0.6)
            let glowFade  = 1.0 - pow(post / 22.0, 1.1)
            let gA = glowIntro * glowFade

            // Rising smoke column (tall vertical ellipse expanding upward)
            let smokeAge  = min(1.0, post / 3.0)
            let smokeH    = h * 0.45 * CGFloat(smokeAge)
            let smokeW    = w * 0.22 * CGFloat(0.4 + smokeAge * 0.6)
            for ring in 0..<6 {
                let rf = Double(ring) / 6.0
                let rW = smokeW * CGFloat(1.0 + rf * 1.4)
                let rH = smokeH * CGFloat(0.5 + rf * 0.8)
                let rA = (1.0 - rf) * gA * 0.40
                ctx.fill(Path(ellipseIn: CGRect(x: ix-rW, y: iy-rH, width: rW*2, height: rH)),
                         with: .color(Color(red: 0.20, green: 0.08, blue: 0.03).opacity(rA)))
            }

            // Crater fire glow (bigger: 0.12w instead of 0.068w)
            let craterR = CGFloat(min(1.0, post / 0.4)) * w * 0.12
            let cratLayers: [(CGFloat, Color)] = [
                (2.5, Color(red: 0.55, green: 0.15, blue: 0.03)),
                (1.6, Color(red: 1.00, green: 0.48, blue: 0.06)),
                (0.9, Color(red: 1.00, green: 0.85, blue: 0.45)),
                (0.4, Color.white),
            ]
            for (m, c) in cratLayers {
                let cr = craterR * m
                ctx.fill(Path(ellipseIn: CGRect(x: ix-cr, y: iy-cr*0.48, width: cr*2, height: cr*0.96)),
                         with: .color(c.opacity(gA * (post < 0.8 ? 0.98 : 0.70))))
            }
        }
    }

    // ── Shockwave ring helper ──────────────────────────────────────────────
    private func drawShockwaveRing(ctx: GraphicsContext, ix: CGFloat, iy: CGFloat,
                                   post: Double, delay: Double, duration: Double,
                                   maxR: CGFloat, color: Color, lineW: CGFloat) {
        let t = post - delay
        guard t > 0 && t < duration else { return }
        let prog  = t / duration
        let ringR = maxR * CGFloat(pow(prog, 0.55))
        let alpha = pow(1.0 - prog, 2.2) * 0.85
        // Flattened ellipse (perspective ground ring)
        var rp = Path()
        rp.addEllipse(in: CGRect(x: ix - ringR, y: iy - ringR * 0.36,
                                 width: ringR * 2, height: ringR * 0.72))
        ctx.stroke(rp, with: .color(color.opacity(alpha)),
                   lineWidth: lineW * CGFloat(1.0 - prog * 0.6))
    }
}
