import SwiftUI

struct SoloCarouselEntry: Identifiable {
    let character: Character
    let relation: RelationshipState?
    let intel: SoloCharacterIntel

    var id: String { character.id }
}

struct SoloCharacterCarousel: View {
    let entries: [SoloCarouselEntry]
    @Binding var focusedIndex: Int

    @GestureState private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 220
    private let cardHeight: CGFloat = 300
    private let spacing: CGFloat = 120
    private let maxTilt: Double = 45

    private var continuousIndex: Double {
        Double(focusedIndex) - Double(dragOffset) / spacing
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(Array(entries.enumerated()), id: \.element.id) { i, item in
                    let dist = Double(i) - continuousIndex
                    let absDist = abs(dist)

                    SoloCarouselCard(
                        character: item.character,
                        relation: item.relation,
                        intel: item.intel,
                        isFocused: absDist < 0.5
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(scaleFor(absDist))
                    .opacity(opacityFor(absDist))
                    .rotation3DEffect(
                        .degrees(rotationFor(dist)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.65
                    )
                    .offset(x: xOffsetFor(dist))
                    .zIndex(zIndexFor(absDist))
                    .allowsHitTesting(absDist < 1.5)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            focusedIndex = i
                        }
                    }
                }
            }
            .frame(height: cardHeight + 6)
            .contentShape(Rectangle())
            .gesture(swipeGesture)
            .animation(.interactiveSpring(response: 0.30, dampingFraction: 0.86), value: dragOffset)

            pageIndicator
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                guard !entries.isEmpty else { return }
                let velocity = value.predictedEndTranslation.width - value.translation.width
                let projected = value.translation.width + velocity * 0.4
                let steps = Int(round(-projected / spacing))
                let target = min(max(focusedIndex + steps, 0), entries.count - 1)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    focusedIndex = target
                }
            }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(entries.indices, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(i == focusedIndex ? SoloTheme.gold : Color.white.opacity(0.18))
                    .frame(width: i == focusedIndex ? 18 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: focusedIndex)
    }

    private func xOffsetFor(_ dist: Double) -> CGFloat {
        let base = dist * spacing
        let curve = sin(dist * 0.55) * 30
        return CGFloat(base + curve)
    }

    private func rotationFor(_ dist: Double) -> Double {
        max(-maxTilt, min(maxTilt, -dist * 36))
    }

    private func scaleFor(_ absDist: Double) -> CGFloat {
        CGFloat(max(0.72, 1.0 - absDist * 0.20))
    }

    private func opacityFor(_ absDist: Double) -> Double {
        max(0.30, 1.0 - absDist * 0.38)
    }

    private func zIndexFor(_ absDist: Double) -> Double {
        100 - absDist * 10
    }
}

